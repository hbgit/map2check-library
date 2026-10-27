// SPDX-License-Identifier: GPL-3.0-only
//
// FFI boundary: #[unsafe(no_mangle)] extern "C" functions that Map2Check's LLVM Pass calls.
// This is the ONLY module that contains unsafe code.
// Every unsafe block is annotated with a SAFETY comment.

use std::ffi::CStr;

// Importações desmembradas para evitar bugs do cbindgen
use crate::analysismode::assert::AssertChecker;
use crate::analysismode::memory::DerefChecker;
use crate::analysismode::memory::FreeChecker;
use crate::analysismode::memory::FreeResolvedChecker;
use crate::analysismode::memory::LoadChecker;
use crate::analysismode::mode;
use crate::analysismode::mode::AnalysisMode;
use crate::analysismode::mode::Check;
use crate::analysismode::overflow::AddI32;
use crate::analysismode::overflow::AddU32;
use crate::analysismode::overflow::DivI32;
use crate::analysismode::overflow::DivU32;
use crate::analysismode::overflow::MulI32;
use crate::analysismode::overflow::MulU32;
use crate::analysismode::overflow::NegI32;
use crate::analysismode::overflow::ShlI32;
use crate::analysismode::overflow::ShrI32;
use crate::analysismode::overflow::ShrU32;
use crate::analysismode::overflow::SignedBinop;
use crate::analysismode::overflow::SignedOp;
use crate::analysismode::overflow::SubI32;
use crate::analysismode::overflow::SubU32;
use crate::analysismode::VccChecker;
use crate::analysismode::VccContext;
use crate::bbtrack::BasicBlockEntry;
use crate::caller::ViolatedProperty;
use crate::error::Map2CheckError;
use crate::memtrack::c_mode::FreeOutcome;
use crate::memtrack::c_mode::MemMode;
use crate::memtrack::MemOrigin;
use crate::memtrack::MemTrackEntry;
use crate::nondet::NonDetEntry;
use crate::nondet::NonDetValue;
use crate::output;
use crate::output::termination;
use crate::state;

// — Helpers —————————————————————————————————————————————————————————————————

/// Convert a raw C string to &str, returning "" on null or invalid UTF-8.
///
/// # Safety
/// `ptr` must be null or point to a valid, null-terminated C string that
/// remains valid for the duration of the call.
unsafe fn c_str<'a>(ptr: *const std::os::raw::c_char) -> &'a str {
    if ptr.is_null() {
        return "";
    }
    // SAFETY: caller guarantees ptr is a valid null-terminated C string.
    unsafe { CStr::from_ptr(ptr) }.to_str().unwrap_or("")
}

// A assinatura foi encurtada porque importamos o Map2CheckError ali em cima
fn log_error(e: &Map2CheckError) {
    eprintln!("[map2check] error: {e}");
}

/// Records a violation (the first one is final, SD-03). When it is the
/// first and a Map2Check analysis mode is set, the run ends here as in
/// develop's `map2check_error()`: the result files are written and the
/// process aborts (`output::termination`). `end_of_program` marks the
/// end-of-program verdict.
fn record_violation(property: ViolatedProperty, line: u32, fname: &str, end_of_program: bool) {
    match state::with_state(|s| {
        let first = s.result.ok;
        if first && end_of_program {
            s.end_of_program = true;
        }
        s.set_false(property, line, fname);
        Ok(first)
    }) {
        Ok(true) => termination::on_violation(),
        Ok(false) => {}
        Err(e) => log_error(&e),
    }
}

/// Runs `checker`, records a violation if it finds one, and returns whether
/// the check passed (`false` on a violation or an internal error).
fn run_vcc_check(checker: impl VccChecker, ctx: &VccContext, line: u32, fname: &str) -> bool {
    match checker.check(ctx) {
        Ok(crate::analysismode::VccOutcome::Violated { property }) => {
            record_violation(property, line, fname, false);
            false
        }
        Ok(crate::analysismode::VccOutcome::Safe) => true,
        Err(e) => {
            log_error(&e);
            false
        }
    }
}

/// Whether `check` reports violations in the selected analysis mode.
fn check_active(check: Check) -> bool {
    mode::check_enabled(state::config().mode, check)
}

/// The C value of `enum ViolatedProperty` (`Map2CheckTypes.h:80-91`), the
/// discriminant of [`ViolatedProperty`]; 10 is `Concurrency`.
fn violated_property_from_raw(raw: i32) -> Option<ViolatedProperty> {
    [
        ViolatedProperty::None,
        ViolatedProperty::Unknown,
        ViolatedProperty::MemsafetyFree,
        ViolatedProperty::MemsafetyDeref,
        ViolatedProperty::MemsafetyMemtrack,
        ViolatedProperty::Reachability,
        ViolatedProperty::Overflow,
        ViolatedProperty::Assert,
        ViolatedProperty::MemsafetyMemcleanup,
        ViolatedProperty::DivByZero,
        ViolatedProperty::Concurrency,
    ]
    .into_iter()
    .find(|p| *p as i32 == raw)
}

/// Failure policy at the `extern "C"` boundary (issue #8).
///
/// Every `#[no_mangle]` export runs its body through this function
/// (enforced by `tests/ffi_guard_coverage.rs`).
///
/// - Unwinding profiles (`dev`, `release`, `runtime`; `panic = "unwind"`):
///   a panic is caught here with `catch_unwind`, a diagnostic is written to
///   stderr and `default` is returned, so no unwind ever reaches C.
/// - `panic = "abort"` builds (the KLEE runtime, `klee/Cargo.toml`): `catch_unwind` cannot
///   intercept anything; a panic aborts the process immediately and there is
///   no recovery. Exports therefore must not rely on panics for control flow.
///
/// Deliberate process termination (`__VERIFIER_error`, `__VERIFIER_assume(0)`)
/// is not a failure and bypasses recovery by design.
pub(crate) fn ffi_guard<T>(f: impl FnOnce() -> T, default: T) -> T {
    match std::panic::catch_unwind(std::panic::AssertUnwindSafe(f)) {
        Ok(value) => value,
        Err(_) => {
            eprintln!("[map2check] panic in FFI boundary; recovering safely");
            default
        }
    }
}

// ── Initialisation ────────────────────────────────────────────────────────────

/// `map2check_init` of the C runtime (`Map2CheckFunctions.c:29-40`), which
/// the Map2Check passes call first: starts a fresh analysis through the
/// `analysis_init` of the selected mode (every container, counter, result and
/// flag is cleared) and keeps the configuration, mode included. Must be
/// called before any tracking function. `is_sv_comp` only sets develop's
/// `sv_comp`, which nothing reads, so it is accepted and ignored. Like
/// develop, it leaves the property files of an earlier run alone.
#[no_mangle]
pub extern "C" fn map2check_init(is_sv_comp: std::os::raw::c_int) {
    ffi_guard(
        || {
            let _ = is_sv_comp;
            state::init();
        },
        (),
    );
}

/// Resets the global analysis state without aborting the caller.
#[no_mangle]
pub extern "C" fn map2check_reset() {
    ffi_guard(state::reset, ());
}

// ── Result management ─────────────────────────────────────────────────────────

/// End of the analysed program. With the mode unset, prints the JSON
/// report. With an analysis mode set it prints nothing and is develop's
/// `map2check_success()`
/// (`Map2CheckFunctions.c:67-70`, `:89-102`): writes `NONE` to
/// `map2check_property`, runs the end-of-program verdict of the mode, writes
/// the witness files when `map2check_enable_witness()` was called, and
/// returns; when the verdict is a violation it writes that property instead
/// and aborts.
#[no_mangle]
pub extern "C" fn map2check_success() {
    ffi_guard(
        || {
            if !termination::on_success() {
                output::print_report_unless_mode_set();
            }
        },
        (),
    );
}

/// Records a verification failure.
///
/// # Safety
/// `function_name` must be null or a valid null-terminated C string.
#[no_mangle]
pub unsafe extern "C" fn set_false_result(
    prp: i32,
    line_number: i32,
    function_name: *const std::os::raw::c_char,
) {
    ffi_guard(
        || {
            let Some(property) = violated_property_from_raw(prp) else {
                eprintln!("[map2check] invalid violated-property value: {prp}");
                return;
            };
            // SAFETY: caller guarantees function_name is a valid C string or null.
            let fname = unsafe { c_str(function_name) };
            record_violation(property, line_number as u32, fname, false);
        },
        (),
    );
}

/// Returns the currently violated property.
#[no_mangle]
pub extern "C" fn get_current_property() -> ViolatedProperty {
    ffi_guard(
        || state::with_state(|s| Ok(s.result.property)).unwrap_or(ViolatedProperty::None),
        ViolatedProperty::None,
    )
}

/// Returns the current step counter value.
#[no_mangle]
pub extern "C" fn get_current_step() -> u64 {
    ffi_guard(
        || state::with_state(|s| Ok(s.current_step())).unwrap_or(0),
        0,
    )
}

/// Advances and returns the step counter. Unlike `get_current_step`, this
/// mutates the counter — analogous to `get_next_step`/`next_current_step` in
/// the C library.
#[no_mangle]
pub extern "C" fn get_next_step() -> u64 {
    ffi_guard(|| state::with_state(|s| Ok(s.next_step())).unwrap_or(0), 0)
}

/// Prints the full JSON report to stdout when no analysis mode is set. With
/// a mode set (a Map2Check run) it prints nothing: the result goes to the
/// files, and the analysed program's stdout stays clean.
#[no_mangle]
pub extern "C" fn print_all_containers_as_json() {
    ffi_guard(output::print_report_unless_mode_set, ());
}

/// Resets violation metadata without clearing tracking containers.
/// Host/test-only: the Map2Check passes never call it. It clears a recorded
/// violation by design, bypassing the first-violation rule (#36, SD-03).
#[no_mangle]
pub extern "C" fn vcc_reset_meta_data() {
    ffi_guard(
        || {
            if let Err(e) = state::with_state(|s| {
                s.result.property = ViolatedProperty::None;
                s.result.ok = true;
                s.result.line = 0;
                s.result.function_name.clear();
                s.failed_free = None;
                s.got_error = false;
                Ok(())
            }) {
                log_error(&e);
            }
        },
        (),
    );
}

/// Selects the memcleanup property for the end-of-program leak check.
/// Effect: `map2check_check_mem_endprog` reports a leak as
/// `MemsafetyMemcleanup` instead of `MemsafetyMemtrack`. The option is
/// configuration: `map2check_init()` and `map2check_reset()` keep it.
#[no_mangle]
pub extern "C" fn map2check_set_memcleanup() {
    ffi_guard(
        || {
            state::update_config(|c| c.memcleanup = true);
        },
        (),
    );
}

/// Marks NULL as valid for load checks.
/// Effect: `map2check_check_load` treats a NULL `ptr` as safe once this has
/// been called, instead of flagging it as `MemsafetyDeref`. Kept across
/// `map2check_init()` and `map2check_reset()`.
#[no_mangle]
pub extern "C" fn map2check_set_null_is_valid() {
    ffi_guard(
        || {
            state::update_config(|c| c.null_is_valid = true);
        },
        (),
    );
}

/// Turns on witness generation, as linking `WitnessGeneration.c` instead of
/// `WitnessGenerationNone.c` does in develop (`caller.cpp:624-640`). Effect:
/// when a Map2Check run ends (an analysis mode is set), the library also
/// writes `track_bb_log.st`, `heap_log.csv`, `allocation_log.csv` and
/// `list_log.csv` (memory modes), and on a violation `klee_log.csv` and
/// `map2check_checked_error`. Configuration: kept by `map2check_init()` and
/// `map2check_reset()`. The Map2Check frontend links a constructor that
/// calls it into the witness binary.
#[no_mangle]
pub extern "C" fn map2check_enable_witness() {
    ffi_guard(
        || {
            state::update_config(|c| c.witness = true);
        },
        (),
    );
}

/// Selects the analysis mode, as the frontend of Map2Check `develop` does by
/// linking one `AnalysisMode*.c` per run (`caller.cpp:575-612`). The
/// instrumented program calls it before `map2check_init()` with one of the
/// `AnalysisMode` values (`AnalysisMode_None` 0 to `AnalysisMode_Target` 5).
/// Any other value is ignored with a diagnostic on stderr and leaves the mode
/// as it was. The mode is configuration: `map2check_init()` and
/// `map2check_reset()` keep it. Until a valid value is set the mode is unset
/// and every check is active. Per-mode effects are in
/// `rust/src/analysismode/mode.rs`.
#[no_mangle]
pub extern "C" fn map2check_set_mode(mode: i32) {
    ffi_guard(
        || {
            let Some(mode) = analysis_mode_from_raw(mode) else {
                eprintln!("[map2check] invalid analysis mode: {mode}");
                return;
            };
            state::update_config(|c| c.mode = Some(mode));
        },
        (),
    );
}

fn analysis_mode_from_raw(raw: i32) -> Option<AnalysisMode> {
    match raw {
        0 => Some(AnalysisMode::None),
        1 => Some(AnalysisMode::Memtrack),
        2 => Some(AnalysisMode::Memcleanup),
        3 => Some(AnalysisMode::Overflow),
        4 => Some(AnalysisMode::Assert),
        5 => Some(AnalysisMode::Target),
        _ => None,
    }
}

/// Records that the target function was reached, without ending the process.
/// Same property as `map2check_target_function` of the `develop` C runtime
/// (`TARGET_REACHED`, `Map2CheckFunctions.c:61-65`), which then ends the run;
/// here the first violation stays final (SD-03) and the caller keeps running.
///
/// # Safety
/// `func` must be null or a valid null-terminated C string.
pub(crate) unsafe fn mark_target_reached(
    func: *const std::os::raw::c_char,
    _scope: i32,
    line: i32,
) {
    // SAFETY: caller guarantees func is a valid C string or null.
    let fname = unsafe { c_str(func) };
    record_violation(ViolatedProperty::Reachability, line as u32, fname, false);
}

/// Called by the target pass when the target function (e.g. `reach_error`)
/// is reached. Records `Reachability` (develop's `TARGET-REACHED`) at `line`
/// in `func`, in every mode, and returns: ending the run is Task 2.4 (SD-15).
/// `scope` is accepted for ABI compatibility and ignored, as in develop.
///
/// # Safety
/// `func` must be null or a valid null-terminated C string.
#[no_mangle]
pub unsafe extern "C" fn map2check_reach_target(
    func: *const std::os::raw::c_char,
    scope: i32,
    line: i32,
) {
    ffi_guard(
        || {
            // SAFETY: caller guarantees func is a valid C string or null.
            unsafe { mark_target_reached(func, scope, line) }
        },
        (),
    );
}

// ── C runtime ABI: Map2CheckFunctions, TrackBBLog, PropertyGenerator ────────
//
// `Map2CheckFunctions.c`, `TrackBBLog.c` and `PropertyGenerator.c` of
// Map2Check `develop`, with their C signatures. The C-only helpers of those
// files (`write_property_<x>`, `trackbb_new_row`, `is_in_tracked`,
// `trackbb_log_to_file`) are private to the Rust core (SD-22).

/// `map2check_get_current_step` (`Map2CheckFunctions.c:42`): develop's
/// `Map2CheckCurrentStep`, 0 after `map2check_init`.
#[no_mangle]
pub extern "C" fn map2check_get_current_step() -> std::os::raw::c_uint {
    ffi_guard(|| state::with_state(|s| Ok(s.c_step)).unwrap_or(0), 0)
}

/// `map2check_next_current_step` (`Map2CheckFunctions.c:43`): adds 1 to the
/// counter `map2check_get_current_step` reads, wrapping as a C `unsigned`.
#[no_mangle]
pub extern "C" fn map2check_next_current_step() {
    ffi_guard(
        || {
            if let Err(e) = state::with_state(|s| {
                s.c_step = s.c_step.wrapping_add(1);
                Ok(())
            }) {
                log_error(&e);
            }
        },
        (),
    );
}

/// `map2check_track_bb` (`Map2CheckFunctions.c:49-55`): appends a row for
/// the basic block at `line` of `function_name` unless a row of that line
/// exists (`is_in_tracked`), so the first function name of a line stays.
/// The rows are `track_bb_log.st` of the witness.
///
/// # Safety
/// `function_name` must be null or a valid null-terminated C string.
#[no_mangle]
pub unsafe extern "C" fn map2check_track_bb(
    line: std::os::raw::c_uint,
    function_name: *const std::os::raw::c_char,
) {
    ffi_guard(
        || {
            // SAFETY: caller guarantees function_name is a valid C string or null.
            let fname = unsafe { c_str(function_name) };
            if let Err(e) = state::with_state(|s| {
                if !crate::bbtrack::is_in_tracked(line, &s.bbtrack) {
                    let step = s.next_step();
                    s.bbtrack
                        .push(crate::bbtrack::trackbb_new_row(step, line, fname));
                }
                Ok(())
            }) {
                log_error(&e);
            }
        },
        (),
    );
}

/// `map2check_target_function` (`Map2CheckFunctions.c:61-65`), which the
/// target pass calls when the target function is reached: records
/// `TARGET_REACHED` at `line` in `func_name`; `scope` is not used. With a
/// mode set the run ends as develop's does (`map2check_property` has
/// `TARGET-REACHED`, abort); unset, it returns (SD-15).
///
/// # Safety
/// `func_name` must be null or a valid null-terminated C string.
#[no_mangle]
pub unsafe extern "C" fn map2check_target_function(
    func_name: *const std::os::raw::c_char,
    scope: std::os::raw::c_int,
    line: std::os::raw::c_int,
) {
    ffi_guard(
        || {
            // SAFETY: caller guarantees func_name is a valid C string or null.
            unsafe { mark_target_reached(func_name, scope, line) }
        },
        (),
    );
}

/// `map2check_error` (`Map2CheckFunctions.c:72-75`): marks the run as
/// failed (`gotError`) and calls `map2check_exit`, which skips the
/// end-of-program verdict and, with a mode set, writes the witness files
/// (when enabled) and aborts. It writes no property file; develop's callers
/// write theirs first. Without a mode it returns (SD-03, SD-14).
#[no_mangle]
pub extern "C" fn map2check_error() {
    ffi_guard(termination::map2check_error, ());
}

/// `map2check_exit` (`Map2CheckFunctions.c:89-102`): with no error yet, runs
/// the end-of-program verdict of the mode (a leak writes its property files);
/// then writes the witness files when enabled, runs `map2check_destroy`, and
/// on an error writes `map2check_checked_error` (witness on) and aborts.
/// Unlike `map2check_success` it writes no `NONE`. Without a mode nothing is
/// written and it returns (SD-03, SD-14).
#[no_mangle]
pub extern "C" fn map2check_exit() {
    ffi_guard(termination::map2check_exit, ());
}

/// `map2check_destroy` (`Map2CheckFunctions.c:77-87`): releases the
/// basic-block log and the containers of the mode (`analysis_destroy`),
/// once per run; a second call does nothing until `map2check_init`.
#[no_mangle]
pub extern "C" fn map2check_destroy() {
    ffi_guard(
        || {
            let config = state::config();
            if let Err(e) = state::with_state(|s| {
                termination::destroy(config, s);
                Ok(())
            }) {
                log_error(&e);
            }
        },
        (),
    );
}

/// `write_property` (`PropertyGenerator.c:50-106`): writes
/// `map2check_property` with the text of `violated` and, for FALSE-FREE,
/// FALSE-DEREF, FALSE-MEMTRACK, FALSE-MEMCLEANUP, OVERFLOW and ASSERT, its
/// `map2check_property_<prp>` file, into the current directory, whatever
/// the mode; `Line: %d` and `Function: %s` as develop prints them. It does
/// not record a violation or end the run. `Concurrency`, outside the C
/// switch, leaves `map2check_property` empty.
///
/// # Safety
/// `violated` must be one of the `ViolatedProperty` values (C `NONE` 0 to
/// `FALSE_DIVBYZERO` 9, or 10); `function_name` must be null or a valid
/// null-terminated C string.
#[no_mangle]
pub unsafe extern "C" fn write_property(
    violated: ViolatedProperty,
    line: std::os::raw::c_int,
    function_name: *const std::os::raw::c_char,
) {
    ffi_guard(
        || {
            // SAFETY: caller guarantees function_name is a valid C string or null.
            let fname = unsafe { c_str(function_name) };
            termination::write_property(violated, line, fname);
        },
        (),
    );
}

/// Core entry point of `generate_aux_files` (`WitnessGeneration.c:15-29`),
/// which the IR module `WitnessGeneration.bc` forwards to (D7): writes
/// `track_bb_log.st`, the logs of the memory modes and, when `violation` is
/// nonzero or `MAP2CHECK_SEED_REPLAY` is set, `klee_log.csv`, into the
/// current directory. `trackbb_log` is develop's container pointer; the core
/// reads its own state, so it is ignored and may be null.
///
/// # Safety
/// `trackbb_log` is never dereferenced.
#[no_mangle]
pub unsafe extern "C" fn __m2c_rt_witness_generate_aux_files(
    trackbb_log: *mut std::os::raw::c_void,
    violation: std::os::raw::c_char,
) {
    ffi_guard(
        || {
            let _ = trackbb_log;
            termination::rt_generate_aux_files(violation != 0);
        },
        (),
    );
}

/// Core entry point of `generate_confirmation_file`
/// (`WitnessGeneration.c:32-36`), which `WitnessGeneration.bc` forwards to
/// (D7): writes `END OF TIME` to `map2check_checked_error`.
#[no_mangle]
pub extern "C" fn __m2c_rt_witness_generate_confirmation_file() {
    ffi_guard(termination::rt_generate_confirmation_file, ());
}

// ── C runtime ABI: AnalysisModeOverflow (core entry points, D7) ─────────────
//
// `AnalysisModeOverflow.c` of Map2Check `develop`. The C names
// (`analysis_*`, `map2check_binop_*`, `overflowError`) are defined only by
// the generated IR module `AnalysisModeOverflow.bc`
// (`scripts/runtime-ir/gen_ll.py`), which forwards each one to the
// `__m2c_rt_overflow_<name>` below: every analysis mode defines
// `analysis_*`, so the core must not. `divisionByZeroError` and
// `unknown_not_supported` have no caller outside the C module and stay
// private (SD-22). The checks are `SignedBinop` (`analysismode::overflow`).

/// The signed binops of `AnalysisModeOverflow.c:197-276`: on a violation,
/// `overflowError` (FALSE_OVERFLOW, `:185-188`) or `divisionByZeroError`
/// (FALSE_DIVBYZERO, `:192-195`), which write the property files and call
/// `map2check_error`. No mode gate: linking the module is the mode. `scope`
/// is not used, as in C.
///
/// # Safety
/// `function_name` must be null or a valid null-terminated C string.
unsafe fn rt_overflow_signed(
    op: SignedOp,
    param1: i64,
    param2: i64,
    width: std::os::raw::c_uint,
    line: std::os::raw::c_uint,
    function_name: *const std::os::raw::c_char,
) {
    let checker = SignedBinop {
        op,
        lhs: param1,
        rhs: param2,
        bits: width,
    };
    if let Some(property) = checker.violation() {
        // SAFETY: caller guarantees function_name is valid or null.
        let fname = unsafe { c_str(function_name) };
        record_violation(property, line, fname, false);
    }
}

/// `analysis_init` of the overflow mode (`AnalysisModeOverflow.c:279`). The C
/// body is empty: linking this module is what selects the overflow mode
/// (`caller.cpp:575-612`), so the core entry point selects
/// `AnalysisMode_Overflow`, which turns on the result files and the abort
/// of the first violation (SD-14). Nothing else changes.
#[no_mangle]
pub extern "C" fn __m2c_rt_overflow_analysis_init() {
    ffi_guard(
        || state::update_config(|c| c.mode = Some(AnalysisMode::Overflow)),
        (),
    );
}

/// `analysis_destroy` of the overflow mode (`AnalysisModeOverflow.c:281`):
/// empty, the mode keeps no data.
#[no_mangle]
pub extern "C" fn __m2c_rt_overflow_analysis_destroy() {
    ffi_guard(|| (), ());
}

/// `analysis_is_program_correct` of the overflow mode
/// (`AnalysisModeOverflow.c:283`): always TRUE (1).
#[no_mangle]
pub extern "C" fn __m2c_rt_overflow_analysis_is_program_correct() -> std::os::raw::c_char {
    ffi_guard(|| 1, 1)
}

/// `analysis_generate_aux_witness_files` of the overflow mode
/// (`AnalysisModeOverflow.c:285`): empty.
#[no_mangle]
pub extern "C" fn __m2c_rt_overflow_analysis_generate_aux_witness_files() {
    ffi_guard(|| (), ());
}

/// `overflowError` (`AnalysisModeOverflow.c:185-188`):
/// `write_property(FALSE_OVERFLOW, line, function_name)` and
/// `map2check_error()`. Here: records `OVERFLOW` at `line` in
/// `function_name` (the first violation stays final, SD-03); with a mode set
/// the property files are written and the process aborts. NULL reads as "".
///
/// # Safety
/// `function_name` must be null or a valid null-terminated C string.
#[allow(non_snake_case)]
#[no_mangle]
pub unsafe extern "C" fn __m2c_rt_overflow_overflowError(
    line: std::os::raw::c_uint,
    function_name: *const std::os::raw::c_char,
) {
    ffi_guard(
        || {
            // SAFETY: caller guarantees function_name is valid or null.
            let fname = unsafe { c_str(function_name) };
            record_violation(ViolatedProperty::Overflow, line, fname, false);
        },
        (),
    );
}

/// `map2check_binop_add` (`AnalysisModeOverflow.c:197-206`): `OVERFLOW` when `param1 + param2` leaves the range of `width`.
/// Operands sign-extended to 64 bits, `width` the bit width of the result
/// type (0 or 64 and above mean 64). See `rt_overflow_signed`.
///
/// # Safety
/// `function_name` must be null or a valid null-terminated C string.
#[no_mangle]
pub unsafe extern "C" fn __m2c_rt_overflow_map2check_binop_add(
    param1: i64,
    param2: i64,
    width: std::os::raw::c_uint,
    line: std::os::raw::c_uint,
    scope: std::os::raw::c_uint,
    function_name: *const std::os::raw::c_char,
) {
    ffi_guard(
        || {
            let _ = scope;
            // SAFETY: forwarded caller contract.
            unsafe { rt_overflow_signed(SignedOp::Add, param1, param2, width, line, function_name) }
        },
        (),
    );
}

/// `map2check_binop_sub` (`AnalysisModeOverflow.c:208-217`): `OVERFLOW` when `param1 - param2` leaves the range of `width`.
/// Operands sign-extended to 64 bits, `width` the bit width of the result
/// type (0 or 64 and above mean 64). See `rt_overflow_signed`.
///
/// # Safety
/// `function_name` must be null or a valid null-terminated C string.
#[no_mangle]
pub unsafe extern "C" fn __m2c_rt_overflow_map2check_binop_sub(
    param1: i64,
    param2: i64,
    width: std::os::raw::c_uint,
    line: std::os::raw::c_uint,
    scope: std::os::raw::c_uint,
    function_name: *const std::os::raw::c_char,
) {
    ffi_guard(
        || {
            let _ = scope;
            // SAFETY: forwarded caller contract.
            unsafe { rt_overflow_signed(SignedOp::Sub, param1, param2, width, line, function_name) }
        },
        (),
    );
}

/// `map2check_binop_mul` (`AnalysisModeOverflow.c:234-243`): `OVERFLOW` when `param1 * param2` leaves the range of `width`.
/// Operands sign-extended to 64 bits, `width` the bit width of the result
/// type (0 or 64 and above mean 64). See `rt_overflow_signed`.
///
/// # Safety
/// `function_name` must be null or a valid null-terminated C string.
#[no_mangle]
pub unsafe extern "C" fn __m2c_rt_overflow_map2check_binop_mul(
    param1: i64,
    param2: i64,
    width: std::os::raw::c_uint,
    line: std::os::raw::c_uint,
    scope: std::os::raw::c_uint,
    function_name: *const std::os::raw::c_char,
) {
    ffi_guard(
        || {
            let _ = scope;
            // SAFETY: forwarded caller contract.
            unsafe { rt_overflow_signed(SignedOp::Mul, param1, param2, width, line, function_name) }
        },
        (),
    );
}

/// `map2check_binop_sdiv` (`AnalysisModeOverflow.c:250-262`): `FALSE-DIVBYZERO` when `param2` is 0, `OVERFLOW` for MIN / -1 of `width`.
/// Operands sign-extended to 64 bits, `width` the bit width of the result
/// type (0 or 64 and above mean 64). See `rt_overflow_signed`.
///
/// # Safety
/// `function_name` must be null or a valid null-terminated C string.
#[no_mangle]
pub unsafe extern "C" fn __m2c_rt_overflow_map2check_binop_sdiv(
    param1: i64,
    param2: i64,
    width: std::os::raw::c_uint,
    line: std::os::raw::c_uint,
    scope: std::os::raw::c_uint,
    function_name: *const std::os::raw::c_char,
) {
    ffi_guard(
        || {
            let _ = scope;
            // SAFETY: forwarded caller contract.
            unsafe { rt_overflow_signed(SignedOp::Div, param1, param2, width, line, function_name) }
        },
        (),
    );
}

/// `map2check_binop_srem` (`AnalysisModeOverflow.c:264-276`): `FALSE-DIVBYZERO` when `param2` is 0, `OVERFLOW` for MIN % -1 of `width` (undefined in C).
/// Operands sign-extended to 64 bits, `width` the bit width of the result
/// type (0 or 64 and above mean 64). See `rt_overflow_signed`.
///
/// # Safety
/// `function_name` must be null or a valid null-terminated C string.
#[no_mangle]
pub unsafe extern "C" fn __m2c_rt_overflow_map2check_binop_srem(
    param1: i64,
    param2: i64,
    width: std::os::raw::c_uint,
    line: std::os::raw::c_uint,
    scope: std::os::raw::c_uint,
    function_name: *const std::os::raw::c_char,
) {
    ffi_guard(
        || {
            let _ = scope;
            // SAFETY: forwarded caller contract.
            unsafe { rt_overflow_signed(SignedOp::Rem, param1, param2, width, line, function_name) }
        },
        (),
    );
}

/// `map2check_binop_add_uint` (`AnalysisModeOverflow.c:224-227`): a deliberate
/// no-op, as in C (`:219-223`): unsigned wraparound is well-defined and is
/// not an overflow under SV-COMP's no-overflow property.
#[no_mangle]
pub extern "C" fn __m2c_rt_overflow_map2check_binop_add_uint(
    param1: u64,
    param2: u64,
    width: std::os::raw::c_uint,
    line: std::os::raw::c_uint,
    scope: std::os::raw::c_uint,
    function_name: *const std::os::raw::c_char,
) {
    ffi_guard(
        || {
            let _ = (param1, param2, width, line, scope, function_name);
        },
        (),
    );
}

/// `map2check_binop_sub_uint` (`AnalysisModeOverflow.c:229-232`): a deliberate
/// no-op, as in C (`:219-223`): unsigned wraparound is well-defined and is
/// not an overflow under SV-COMP's no-overflow property.
#[no_mangle]
pub extern "C" fn __m2c_rt_overflow_map2check_binop_sub_uint(
    param1: u64,
    param2: u64,
    width: std::os::raw::c_uint,
    line: std::os::raw::c_uint,
    scope: std::os::raw::c_uint,
    function_name: *const std::os::raw::c_char,
) {
    ffi_guard(
        || {
            let _ = (param1, param2, width, line, scope, function_name);
        },
        (),
    );
}

/// `map2check_binop_mul_uint` (`AnalysisModeOverflow.c:245-248`): a deliberate
/// no-op, as in C (`:219-223`): unsigned wraparound is well-defined and is
/// not an overflow under SV-COMP's no-overflow property.
#[no_mangle]
pub extern "C" fn __m2c_rt_overflow_map2check_binop_mul_uint(
    param1: u64,
    param2: u64,
    width: std::os::raw::c_uint,
    line: std::os::raw::c_uint,
    scope: std::os::raw::c_uint,
    function_name: *const std::os::raw::c_char,
) {
    ffi_guard(
        || {
            let _ = (param1, param2, width, line, scope, function_name);
        },
        (),
    );
}

// ── C runtime ABI: AnalysisModeAssert and AnalysisModeNone (core entry points, D7) ──
//
// `AnalysisModeAssert.c` and `AnalysisModeNone.c` of Map2Check `develop`. As
// for the overflow mode, the C names (`analysis_*`, `map2check_assert`,
// `__VERIFIER_assert`) are defined only by the generated IR modules
// `AnalysisModeAssert.bc` and `AnalysisModeNone.bc`
// (`scripts/runtime-ir/gen_ll.py`), never by this library. `__VERIFIER_assert`
// is an empty function in the IR (`AnalysisModeAssert.c:25-27`), so it has no
// core entry point. `analysis_init` of both modules forwards to the entry
// point that selects the mode: linking the module is what picks it in C
// (`caller.cpp:575-612`). `REACHABILITY_MODE` and `COVER_BRANCHES_MODE` both
// link `AnalysisModeNone.c`, so they cannot be told apart at link time; the
// none module selects `AnalysisMode_None`, whose checks are all inactive,
// exactly as the C module defines no check.

/// `analysis_init` of the assert mode (`AnalysisModeAssert.c:29-31`). The C
/// body is empty; the core entry point selects `AnalysisMode_Assert`
/// (result files and abort on the first violation, SD-14). Nothing else
/// changes.
#[no_mangle]
pub extern "C" fn __m2c_rt_assert_analysis_init() {
    ffi_guard(
        || state::update_config(|c| c.mode = Some(AnalysisMode::Assert)),
        (),
    );
}

/// `analysis_destroy` of the assert mode (`AnalysisModeAssert.c:33-35`):
/// empty.
#[no_mangle]
pub extern "C" fn __m2c_rt_assert_analysis_destroy() {
    ffi_guard(|| (), ());
}

/// `analysis_is_program_correct` of the assert mode
/// (`AnalysisModeAssert.c:37`): always TRUE (1).
#[no_mangle]
pub extern "C" fn __m2c_rt_assert_analysis_is_program_correct() -> std::os::raw::c_char {
    ffi_guard(|| 1, 1)
}

/// `analysis_generate_aux_witness_files` of the assert mode
/// (`AnalysisModeAssert.c:39-41`): empty.
#[no_mangle]
pub extern "C" fn __m2c_rt_assert_analysis_generate_aux_witness_files() {
    ffi_guard(|| (), ());
}

/// `map2check_assert` (`AnalysisModeAssert.c:18-23`): when `condition` is 0,
/// `write_property(ASSERT, line, func_name)` and `map2check_error()`. Here:
/// records `ASSERT` at `line` in `func_name` (the first violation stays
/// final, SD-03); with a mode set the property files are written and the
/// process aborts. NULL reads as "". No mode gate: linking the module is the
/// mode.
///
/// # Safety
/// `func_name` must be null or a valid null-terminated C string.
#[no_mangle]
pub unsafe extern "C" fn __m2c_rt_assert_map2check_assert(
    condition: std::os::raw::c_int,
    line: std::os::raw::c_int,
    func_name: *const std::os::raw::c_char,
) {
    ffi_guard(
        || {
            // SAFETY: caller guarantees func_name is a valid C string or null.
            let fname = unsafe { c_str(func_name) };
            let ctx = VccContext::new(line as u32, 0, fname);
            match (AssertChecker {
                expression: condition,
            })
            .check(&ctx)
            {
                Ok(crate::analysismode::VccOutcome::Violated { property }) => {
                    record_violation(property, line as u32, fname, false);
                }
                Ok(crate::analysismode::VccOutcome::Safe) => {}
                Err(e) => log_error(&e),
            }
        },
        (),
    );
}

/// `analysis_init` of the none mode (`AnalysisModeNone.c:11-13`). The C body
/// is empty; the core entry point selects `AnalysisMode_None`, which turns on
/// the result files and the abort of the first violation (SD-14), so that
/// `map2check_target_function` ends the run as in C.
#[no_mangle]
pub extern "C" fn __m2c_rt_none_analysis_init() {
    ffi_guard(
        || state::update_config(|c| c.mode = Some(AnalysisMode::None)),
        (),
    );
}

/// `analysis_destroy` of the none mode (`AnalysisModeNone.c:15-17`): empty.
#[no_mangle]
pub extern "C" fn __m2c_rt_none_analysis_destroy() {
    ffi_guard(|| (), ());
}

/// `analysis_is_program_correct` of the none mode (`AnalysisModeNone.c:19`):
/// always TRUE (1).
#[no_mangle]
pub extern "C" fn __m2c_rt_none_analysis_is_program_correct() -> std::os::raw::c_char {
    ffi_guard(|| 1, 1)
}

/// `analysis_generate_aux_witness_files` of the none mode
/// (`AnalysisModeNone.c:21-23`): empty.
#[no_mangle]
pub extern "C" fn __m2c_rt_none_analysis_generate_aux_witness_files() {
    ffi_guard(|| (), ());
}

// ── C runtime ABI: AnalysisModeMemtrack (core entry points, D7) ─────────────
//
// `AnalysisModeMemtrack.c` of Map2Check `develop`. The C names (`analysis_*`,
// the 12 memory `map2check_*` the pass calls and `map2check_wasm_*`) are
// defined only by the generated IR module `AnalysisModeMemtrack.bc`
// (`scripts/runtime-ir/gen_ll.py`), each forwarding to the
// `__m2c_rt_memtrack_<name>` below with the signature of the C definition.
// The logs (`heap_log`, `allocation_log`, `list_log`), `ERROR_DEREF` and
// `update_reference_list_log` stay private (SD-22): `AnalysisState::c_memory`
// (`memtrack::c_mode`). `ContainerRealloc.bc`, `ContainerBTree.bc`,
// `BTree.bc`, `AllocationLog.bc`, `ListLog.bc` and `HeapLog.bc` are empty IR:
// one Rust container serves the Array and `--btree` builds (D3).
//
// The rules take a `MemMode`, and so do the `rt_mem_*` helpers below: the
// memcleanup module (Task 2.6, below) shares them. No mode gate: linking the module
// is the mode. On a violation the C writes the property files and calls
// `map2check_error()`; here the violation is recorded and, with a mode set,
// the files are written and the run aborts (`record_violation`). The rows
// the C appends before it reports are appended first, so the witness logs
// match. NULL strings read as "".

/// The bytes of a C string, `b""` for NULL.
///
/// # Safety
/// `ptr` must be null or a valid null-terminated C string.
unsafe fn c_bytes<'a>(ptr: *const std::os::raw::c_char) -> &'a [u8] {
    if ptr.is_null() {
        return b"";
    }
    // SAFETY: caller guarantees a valid null-terminated C string.
    unsafe { CStr::from_ptr(ptr) }.to_bytes()
}

/// Runs `f` on the drop-in memory logs and the C step counter.
fn with_c_memory<R>(
    default: R,
    f: impl FnOnce(&mut crate::memtrack::c_mode::CMemory, &mut u32) -> R,
) -> R {
    match state::with_state(|s| Ok(f(&mut s.c_memory, &mut s.c_step))) {
        Ok(r) => r,
        Err(e) => {
            log_error(&e);
            default
        }
    }
}

/// `analysis_init` of the memory modes (`AnalysisModeMemtrack.c:125-130`):
/// selects `mode` (linking the module is what picks it in C) and starts new
/// logs with `ERROR_DEREF` clear.
fn rt_mem_analysis_init(mode: AnalysisMode) {
    state::update_config(|c| c.mode = Some(mode));
    with_c_memory((), |m, _| m.clear());
}

/// `analysis_is_program_correct` of the memory modes
/// (`AnalysisModeMemtrack.c:138-146`): on a leak, `write_property` of its
/// property (which writes `map2check_property` and its own file) and FALSE.
/// It records nothing and does not end the run; `map2check_exit` does.
fn rt_mem_is_program_correct(mode: MemMode) -> std::os::raw::c_char {
    match with_c_memory(None, |m, _| m.is_program_correct(mode)) {
        Some(property) => {
            termination::write_property(property, 0, "");
            0
        }
        None => 1,
    }
}

/// `analysis_generate_aux_witness_files` of the memory modes
/// (`AnalysisModeMemtrack.c:148-152`).
fn rt_mem_generate_aux_witness_files() {
    if let Some(dir) = termination::output_dir() {
        if let Err(e) = state::with_state(|s| {
            termination::write_c_memory_logs(&dir, &s.c_memory);
            Ok(())
        }) {
            log_error(&e);
        }
    }
}

/// `map2check_check_cstring` (`AnalysisModeMemtrack.c:159-166`).
///
/// # Safety
/// `string` must be null, or every byte up to its terminator that lies in a
/// tracked block must be readable.
unsafe fn rt_mem_check_cstring(mode: MemMode, string: *const std::os::raw::c_char) {
    with_c_memory((), |m, _| {
        m.check_cstring(mode, string as u64, |at| {
            // SAFETY: `at` is read only after `map2check_load` found it inside
            // a tracked block, as the C reads `string[i]`; caller contract.
            unsafe { *(at as usize as *const u8) }
        })
    });
}

/// `map2check_check_deref` (`AnalysisModeMemtrack.c:309-315`).
///
/// # Safety
/// `function_name` must be null or a valid null-terminated C string.
unsafe fn rt_mem_check_deref(
    mode: MemMode,
    line: std::os::raw::c_int,
    function_name: *const std::os::raw::c_char,
) {
    if with_c_memory(false, |m, _| m.check_deref(mode)) {
        // SAFETY: caller contract.
        let fname = unsafe { c_str(function_name) };
        // The result keeps lines as u32; the C `int` is stored as its bit
        // pattern and the property files print it back with `%d`
        // (`write_property_files`: `line as i32`), so a negative line reads
        // as in C.
        let line = u32::from_ne_bytes(line.to_ne_bytes());
        record_violation(ViolatedProperty::MemsafetyDeref, line, fname, false);
    }
}

/// `map2check_free_resolved_address` (`AnalysisModeMemtrack.c:176-195`).
///
/// # Safety
/// `function_name` must be null or a valid null-terminated C string.
unsafe fn rt_mem_free_resolved_address(
    mode: MemMode,
    ptr: *const std::os::raw::c_void,
    line: std::os::raw::c_uint,
    function_name: *const std::os::raw::c_char,
    is_null_valid: std::os::raw::c_short,
) {
    let outcome = with_c_memory(FreeOutcome::Released, |m, step| {
        m.free_resolved_address(mode, step, ptr as u64, line, is_null_valid)
    });
    if outcome == FreeOutcome::InvalidFree {
        // SAFETY: caller contract.
        let fname = unsafe { c_str(function_name) };
        record_violation(ViolatedProperty::MemsafetyFree, line, fname, false);
    }
}

/// `map2check_add_store_pointer` (`AnalysisModeMemtrack.c:258-307`).
///
/// # Safety
/// `name` and `function_name` must be null or valid null-terminated C strings.
unsafe fn rt_mem_add_store_pointer(
    var: *const std::os::raw::c_void,
    value: *const std::os::raw::c_void,
    scope: std::os::raw::c_uint,
    name: *const std::os::raw::c_char,
    line: std::os::raw::c_int,
    function_name: *const std::os::raw::c_char,
) {
    // SAFETY: caller contract.
    let (name, fname) = unsafe { (c_bytes(name), c_bytes(function_name)) };
    with_c_memory((), |m, step| {
        m.add_store_pointer(step, var as u64, value as u64, scope, name, line, fname)
    });
}

/// `map2check_malloc` (`AnalysisModeMemtrack.c:317-335`): a NULL block
/// (low 32 bits zero) is `write_property_unknown` + `map2check_error`.
fn rt_mem_malloc(ptr: *const std::os::raw::c_void, size: std::os::raw::c_int) {
    if !with_c_memory(true, |m, _| m.malloc(ptr as u64, size)) {
        record_violation(ViolatedProperty::Unknown, 0, "", false);
    }
}

/// `map2check_calloc` (`AnalysisModeMemtrack.c:347-349`).
fn rt_mem_calloc(
    ptr: *const std::os::raw::c_void,
    quantity: std::os::raw::c_int,
    size: std::os::raw::c_int,
) {
    if !with_c_memory(true, |m, _| m.calloc(ptr as u64, quantity, size)) {
        record_violation(ViolatedProperty::Unknown, 0, "", false);
    }
}

/// `map2check_posix` (`AnalysisModeMemtrack.c:340-345`): reads the block
/// from `*(void **)ptr`, `map2check_malloc` of it, then the store of it into
/// `ptr` with scope 1, name "pointer", line 1 and function "cocoiso". A
/// NULL `ptr` is ignored (develop dereferences it).
///
/// # Safety
/// `ptr` must be null or point to a readable `void *`.
unsafe fn rt_mem_posix(ptr: *const std::os::raw::c_void, size: std::os::raw::c_int) {
    if ptr.is_null() {
        return;
    }
    // SAFETY: caller guarantees a readable `void *`; unaligned-safe read.
    let block = unsafe { ptr.cast::<*const std::os::raw::c_void>().read_unaligned() };
    if !with_c_memory(true, |m, _| m.malloc(block as u64, size)) {
        record_violation(ViolatedProperty::Unknown, 0, "", false);
        return;
    }
    with_c_memory((), |m, step| {
        m.add_store_pointer(step, ptr as u64, block as u64, 1, b"pointer", 1, b"cocoiso")
    });
}

/// `map2check_free` (`AnalysisModeMemtrack.c:351-378`): `ptr` is the slot of
/// the pointer variable; the block is read from `*(long *)ptr`. A NULL `ptr`
/// is ignored (develop dereferences it).
///
/// # Safety
/// `name` and `function_name` must be null or valid null-terminated C
/// strings; `ptr` must be null or point to a readable `long`.
unsafe fn rt_mem_free(
    mode: MemMode,
    name: *const std::os::raw::c_char,
    ptr: *const std::os::raw::c_void,
    scope: std::os::raw::c_uint,
    line: std::os::raw::c_uint,
    function_name: *const std::os::raw::c_char,
) {
    if ptr.is_null() {
        return;
    }
    // SAFETY: caller guarantees a readable `long`; unaligned-safe read.
    let points_to = unsafe { ptr.cast::<u64>().read_unaligned() };
    // SAFETY: caller contract.
    let (name, fname) = unsafe { (c_bytes(name), c_bytes(function_name)) };
    let outcome = with_c_memory(FreeOutcome::Released, |m, step| {
        m.free(mode, step, name, ptr as u64, points_to, scope, line, fname)
    });
    if outcome == FreeOutcome::InvalidFree {
        // SAFETY: caller contract.
        let fname = unsafe { c_str(function_name) };
        record_violation(ViolatedProperty::MemsafetyFree, line, fname, false);
    }
}

/// `map2check_alloca` (`AnalysisModeMemtrack.c:386-391`).
///
/// # Safety
/// `name` must be null or a valid null-terminated C string.
unsafe fn rt_mem_alloca(
    name: *const std::os::raw::c_char,
    ptr: *const std::os::raw::c_void,
    size: std::os::raw::c_int,
    size_of_primitive: std::os::raw::c_int,
    line: std::os::raw::c_int,
    scope: std::os::raw::c_int,
) {
    // SAFETY: caller contract.
    let name = unsafe { c_bytes(name) };
    with_c_memory((), |m, _| {
        m.alloca(name, ptr as u64, size, size_of_primitive, line, scope)
    });
}

/// `map2check_non_static_alloca` (`AnalysisModeMemtrack.c:380-384`).
///
/// # Safety
/// `name` must be null or a valid null-terminated C string.
unsafe fn rt_mem_non_static_alloca(
    name: *const std::os::raw::c_char,
    ptr: *const std::os::raw::c_void,
    size: std::os::raw::c_int,
    size_of_primitive: std::os::raw::c_int,
    line: std::os::raw::c_int,
    scope: std::os::raw::c_int,
) {
    // SAFETY: caller contract.
    let name = unsafe { c_bytes(name) };
    with_c_memory((), |m, _| {
        m.non_static_alloca(name, ptr as u64, size, size_of_primitive, line, scope)
    });
}

/// `map2check_function` (`AnalysisModeMemtrack.c:393-397`).
///
/// # Safety
/// `name` must be null or a valid null-terminated C string.
unsafe fn rt_mem_function(name: *const std::os::raw::c_char, ptr: *const std::os::raw::c_void) {
    // SAFETY: caller contract.
    let name = unsafe { c_bytes(name) };
    with_c_memory((), |m, _| m.function(name, ptr as u64));
}

/// `analysis_init` of the memtrack mode (`AnalysisModeMemtrack.c:125-130`):
/// selects `AnalysisMode_Memtrack` and starts new logs, `ERROR_DEREF` clear.
#[no_mangle]
pub extern "C" fn __m2c_rt_memtrack_analysis_init() {
    ffi_guard(|| rt_mem_analysis_init(AnalysisMode::Memtrack), ());
}

/// `analysis_destroy` of the memtrack mode (`AnalysisModeMemtrack.c:132-136`):
/// frees the three logs.
#[no_mangle]
pub extern "C" fn __m2c_rt_memtrack_analysis_destroy() {
    ffi_guard(|| with_c_memory((), |m, _| m.clear()), ());
}

/// `analysis_is_program_correct` of the memtrack mode
/// (`AnalysisModeMemtrack.c:138-146`): when `valid_allocation_log` finds a
/// leaked block (it appends a freed row for each), writes FALSE-MEMTRACK to
/// `map2check_property` and `map2check_property_memtrack` and returns 0;
/// otherwise 1.
#[no_mangle]
pub extern "C" fn __m2c_rt_memtrack_analysis_is_program_correct() -> std::os::raw::c_char {
    ffi_guard(|| rt_mem_is_program_correct(MemMode::Memtrack), 1)
}

/// `analysis_generate_aux_witness_files` of the memtrack mode
/// (`AnalysisModeMemtrack.c:148-152`): `heap_log.csv`, `allocation_log.csv`
/// and `list_log.csv` in the current directory, in the C formats.
#[no_mangle]
pub extern "C" fn __m2c_rt_memtrack_analysis_generate_aux_witness_files() {
    ffi_guard(rt_mem_generate_aux_witness_files, ());
}

/// `map2check_check_cstring` (`AnalysisModeMemtrack.c:159-166`): every byte
/// up to the terminator must lie in a tracked block (`map2check_load` of 1
/// byte); stops before the first invalid byte with `ERROR_DEREF` set, which
/// the caller's `map2check_check_deref` reports. NULL does nothing.
///
/// # Safety
/// `string` must be null, or each byte of it that lies in a tracked block,
/// up to its terminator, must be readable.
#[no_mangle]
pub unsafe extern "C" fn __m2c_rt_memtrack_map2check_check_cstring(
    string: *const std::os::raw::c_char,
) {
    // SAFETY: forwarded caller contract.
    ffi_guard(
        || unsafe { rt_mem_check_cstring(MemMode::Memtrack, string) },
        (),
    );
}

/// `map2check_load` (`AnalysisModeMemtrack.c:168-174`): sets `ERROR_DEREF`
/// when neither a heap-log row (stack slot, function) nor a live allocation
/// covers the `size` bytes at `ptr`. Reports nothing by itself.
#[no_mangle]
pub extern "C" fn __m2c_rt_memtrack_map2check_load(
    ptr: *const std::os::raw::c_void,
    size: std::os::raw::c_int,
) {
    ffi_guard(
        || with_c_memory((), |m, _| m.load(MemMode::Memtrack, ptr as u64, size)),
        (),
    );
}

/// `map2check_free_resolved_address` (`AnalysisModeMemtrack.c:176-195`):
/// NULL with `is_null_valid` returns; `is_invalid_free` (`ListLog.c:95-118`)
/// records FALSE-FREE at `line`; otherwise the block's row is freed and every
/// pointer to it gets a FREE row (`update_reference_list_log`).
///
/// # Safety
/// `function_name` must be null or a valid null-terminated C string; `ptr`
/// is never dereferenced.
#[no_mangle]
pub unsafe extern "C" fn __m2c_rt_memtrack_map2check_free_resolved_address(
    ptr: *const std::os::raw::c_void,
    line: std::os::raw::c_uint,
    function_name: *const std::os::raw::c_char,
    is_null_valid: std::os::raw::c_short,
) {
    ffi_guard(
        || {
            // SAFETY: forwarded caller contract.
            unsafe {
                rt_mem_free_resolved_address(
                    MemMode::Memtrack,
                    ptr,
                    line,
                    function_name,
                    is_null_valid,
                )
            }
        },
        (),
    );
}

/// `map2check_add_store_pointer` (`AnalysisModeMemtrack.c:258-307`): appends
/// a list row for `var = value` with the status of `value` in the allocation
/// log, unless the variable's newest row is the same, then updates the
/// other pointers to `value`.
///
/// # Safety
/// `name` and `function_name` must be null or valid null-terminated C
/// strings; `var` and `value` are never dereferenced.
#[no_mangle]
pub unsafe extern "C" fn __m2c_rt_memtrack_map2check_add_store_pointer(
    var: *const std::os::raw::c_void,
    value: *const std::os::raw::c_void,
    scope: std::os::raw::c_uint,
    name: *const std::os::raw::c_char,
    line: std::os::raw::c_int,
    function_name: *const std::os::raw::c_char,
) {
    ffi_guard(
        || {
            // SAFETY: forwarded caller contract.
            unsafe { rt_mem_add_store_pointer(var, value, scope, name, line, function_name) }
        },
        (),
    );
}

/// `map2check_check_deref` (`AnalysisModeMemtrack.c:309-315`): when
/// `ERROR_DEREF` is set, records FALSE-DEREF at `line` in `function_name`.
///
/// # Safety
/// `function_name` must be null or a valid null-terminated C string.
#[no_mangle]
pub unsafe extern "C" fn __m2c_rt_memtrack_map2check_check_deref(
    line: std::os::raw::c_int,
    function_name: *const std::os::raw::c_char,
) {
    ffi_guard(
        || {
            // SAFETY: forwarded caller contract.
            unsafe { rt_mem_check_deref(MemMode::Memtrack, line, function_name) }
        },
        (),
    );
}

/// `map2check_malloc` (`AnalysisModeMemtrack.c:317-335`): records the block,
/// reviving the row of a known address with the new size. A NULL block (its
/// low 32 bits zero, `int addr = (long)ptr`) records UNKNOWN
/// (`map2check_property__unknown`) and ends the run.
#[no_mangle]
pub extern "C" fn __m2c_rt_memtrack_map2check_malloc(
    ptr: *const std::os::raw::c_void,
    size: std::os::raw::c_int,
) {
    ffi_guard(|| rt_mem_malloc(ptr, size), ());
}

/// `map2check_posix` (`AnalysisModeMemtrack.c:340-345`), for
/// `posix_memalign(ptr, ...)`: `map2check_malloc(*ptr, size)` and the store
/// of the block into `ptr` (scope 1, "pointer", line 1, "cocoiso").
///
/// # Safety
/// `ptr` must be null or point to a readable `void *`.
#[no_mangle]
pub unsafe extern "C" fn __m2c_rt_memtrack_map2check_posix(
    ptr: *const std::os::raw::c_void,
    size: std::os::raw::c_int,
) {
    // SAFETY: forwarded caller contract.
    ffi_guard(|| unsafe { rt_mem_posix(ptr, size) }, ());
}

/// `map2check_calloc` (`AnalysisModeMemtrack.c:347-349`):
/// `map2check_malloc(ptr, quantity * size)`, an `int` product.
#[no_mangle]
pub extern "C" fn __m2c_rt_memtrack_map2check_calloc(
    ptr: *const std::os::raw::c_void,
    quantity: std::os::raw::c_int,
    size: std::os::raw::c_int,
) {
    ffi_guard(|| rt_mem_calloc(ptr, quantity, size), ());
}

/// `map2check_free` (`AnalysisModeMemtrack.c:351-378`): `ptr` is the slot of
/// the pointer variable `name`. A NULL block does nothing; otherwise a FREE
/// row for the variable is appended, then `is_invalid_free` records
/// FALSE-FREE at `line`, or the block is released and every pointer to it
/// gets a FREE row.
///
/// # Safety
/// `name` and `function_name` must be null or valid null-terminated C
/// strings; `ptr` must be null or point to a readable `long`.
#[no_mangle]
pub unsafe extern "C" fn __m2c_rt_memtrack_map2check_free(
    name: *const std::os::raw::c_char,
    ptr: *const std::os::raw::c_void,
    scope: std::os::raw::c_uint,
    line: std::os::raw::c_uint,
    function_name: *const std::os::raw::c_char,
) {
    ffi_guard(
        || {
            // SAFETY: forwarded caller contract.
            unsafe { rt_mem_free(MemMode::Memtrack, name, ptr, scope, line, function_name) }
        },
        (),
    );
}

/// `map2check_non_static_alloca` (`AnalysisModeMemtrack.c:380-384`):
/// `map2check_alloca` of `size * size_of_primitive` bytes (an `int` product).
///
/// # Safety
/// `name` must be null or a valid null-terminated C string; `ptr` is never
/// dereferenced.
#[no_mangle]
pub unsafe extern "C" fn __m2c_rt_memtrack_map2check_non_static_alloca(
    name: *const std::os::raw::c_char,
    ptr: *const std::os::raw::c_void,
    size: std::os::raw::c_int,
    size_of_primitive: std::os::raw::c_int,
    line: std::os::raw::c_int,
    scope: std::os::raw::c_int,
) {
    // SAFETY: forwarded caller contract.
    ffi_guard(
        || unsafe { rt_mem_non_static_alloca(name, ptr, size, size_of_primitive, line, scope) },
        (),
    );
}

/// `map2check_alloca` (`AnalysisModeMemtrack.c:386-391`): a heap-log row
/// (`HeapLog.c:22-32`) for the stack slot `name` of `size` bytes at `ptr`.
///
/// # Safety
/// `name` must be null or a valid null-terminated C string; `ptr` is never
/// dereferenced.
#[no_mangle]
pub unsafe extern "C" fn __m2c_rt_memtrack_map2check_alloca(
    name: *const std::os::raw::c_char,
    ptr: *const std::os::raw::c_void,
    size: std::os::raw::c_int,
    size_of_primitive: std::os::raw::c_int,
    line: std::os::raw::c_int,
    scope: std::os::raw::c_int,
) {
    // SAFETY: forwarded caller contract.
    ffi_guard(
        || unsafe { rt_mem_alloca(name, ptr, size, size_of_primitive, line, scope) },
        (),
    );
}

/// `map2check_function` (`AnalysisModeMemtrack.c:393-397`): a heap-log row
/// of size 1 for the function `name` at `ptr`.
///
/// # Safety
/// `name` must be null or a valid null-terminated C string; `ptr` is never
/// dereferenced.
#[no_mangle]
pub unsafe extern "C" fn __m2c_rt_memtrack_map2check_function(
    name: *const std::os::raw::c_char,
    ptr: *const std::os::raw::c_void,
) {
    // SAFETY: forwarded caller contract.
    ffi_guard(|| unsafe { rt_mem_function(name, ptr) }, ());
}

/// `map2check_wasm_malloc` (`AnalysisModeMemtrack.c:403-416`): the block of
/// the lifted `malloc` at linear-memory `offset`, in the same allocation log
/// as `map2check_malloc`; offsets 0 and `(uint64_t)-1` are ignored.
#[no_mangle]
pub extern "C" fn __m2c_rt_memtrack_map2check_wasm_malloc(offset: u64, size: u64) {
    ffi_guard(|| with_c_memory((), |m, _| m.wasm_malloc(offset, size)), ());
}

/// `map2check_wasm_free` (`AnalysisModeMemtrack.c:418-428`): frees the row of
/// `offset`; an offset with no row records FALSE-FREE at `line`, function "".
#[no_mangle]
pub extern "C" fn __m2c_rt_memtrack_map2check_wasm_free(offset: u64, line: std::os::raw::c_int) {
    ffi_guard(
        || {
            if !with_c_memory(true, |m, _| m.wasm_free(offset)) {
                // The C `int` line as its bit pattern (see rt_mem_check_deref).
                let line = u32::from_ne_bytes(line.to_ne_bytes());
                record_violation(ViolatedProperty::MemsafetyFree, line, "", false);
            }
        },
        (),
    );
}

/// `map2check_wasm_check_access` (`AnalysisModeMemtrack.c:430-436`): an
/// access outside every live block records OVERFLOW at line 0, function ""
/// (`FALSE_OVERFLOW`, SD-19).
#[no_mangle]
pub extern "C" fn __m2c_rt_memtrack_map2check_wasm_check_access(offset: u64, access_size: u64) {
    ffi_guard(
        || {
            if !with_c_memory(true, |m, _| m.wasm_check_access(offset, access_size)) {
                record_violation(ViolatedProperty::Overflow, 0, "", false);
            }
        },
        (),
    );
}

// ── C runtime ABI: AnalysisModeMemcleanup (core entry points, D7) ───────────
//
// `AnalysisModeMemcleanup.c` of Map2Check `develop`. The module
// `AnalysisModeMemcleanup.bc` (`scripts/runtime-ir/gen_ll.py`) defines the
// four `analysis_*` functions and the 12 memory `map2check_*` the pass calls
// and forwards each one to `__m2c_rt_memcleanup_<name>` below. It has no
// `map2check_wasm_*`. Linking the module picks the mode (`MemMode`); the
// rules and the logs are the memtrack ones (`rt_mem_*`, `memtrack::c_mode`).
// What differs in C is in `MemMode::Memcleanup`: the verdict needs a pointer
// variable to the last leak (`:138-148`), `map2check_load`,
// `map2check_check_cstring` and `map2check_check_deref` are empty (`:158`,
// `:159`, `:294`), and `error = FALSE` in both release functions (`:168`,
// `:342`). A release with no allocation row is SD-23.

/// `analysis_init` of the memcleanup mode (`AnalysisModeMemcleanup.c:125-130`):
/// selects `AnalysisMode_Memcleanup` and starts new logs.
#[no_mangle]
pub extern "C" fn __m2c_rt_memcleanup_analysis_init() {
    ffi_guard(|| rt_mem_analysis_init(AnalysisMode::Memcleanup), ());
}

/// `analysis_destroy` of the memcleanup mode (`AnalysisModeMemcleanup.c:132-136`):
/// frees the three logs.
#[no_mangle]
pub extern "C" fn __m2c_rt_memcleanup_analysis_destroy() {
    ffi_guard(|| with_c_memory((), |m, _| m.clear()), ());
}

/// `analysis_is_program_correct` of the memcleanup mode
/// (`AnalysisModeMemcleanup.c:138-148`): when `valid_allocation_log` finds a
/// leaked block and a pointer variable still refers to it
/// (`is_memcleanup_error`, `ListLog.c:40-65`), writes FALSE-MEMCLEANUP to
/// `map2check_property` and `map2check_property_memcleanup` and returns 0;
/// otherwise 1.
#[no_mangle]
pub extern "C" fn __m2c_rt_memcleanup_analysis_is_program_correct() -> std::os::raw::c_char {
    ffi_guard(|| rt_mem_is_program_correct(MemMode::Memcleanup), 1)
}

/// `analysis_generate_aux_witness_files` of the memcleanup mode
/// (`AnalysisModeMemcleanup.c:150-154`): the same three logs as memtrack.
#[no_mangle]
pub extern "C" fn __m2c_rt_memcleanup_analysis_generate_aux_witness_files() {
    ffi_guard(rt_mem_generate_aux_witness_files, ());
}

/// `map2check_check_cstring` (`AnalysisModeMemcleanup.c:160`): empty.
///
/// # Safety
/// `string` is never read.
#[no_mangle]
pub unsafe extern "C" fn __m2c_rt_memcleanup_map2check_check_cstring(
    string: *const std::os::raw::c_char,
) {
    // SAFETY: forwarded caller contract.
    ffi_guard(
        || unsafe { rt_mem_check_cstring(MemMode::Memcleanup, string) },
        (),
    );
}

/// `map2check_load` (`AnalysisModeMemcleanup.c:158`): empty.
#[no_mangle]
pub extern "C" fn __m2c_rt_memcleanup_map2check_load(
    ptr: *const std::os::raw::c_void,
    size: std::os::raw::c_int,
) {
    ffi_guard(
        || with_c_memory((), |m, _| m.load(MemMode::Memcleanup, ptr as u64, size)),
        (),
    );
}

/// `map2check_free_resolved_address` (`AnalysisModeMemcleanup.c:161-180`):
/// NULL with `is_null_valid` returns; no free is invalid (`error = FALSE`,
/// `:168`); the block's row is freed and every pointer to it gets a FREE row.
/// A block with no row is SD-23.
///
/// # Safety
/// `function_name` must be null or a valid null-terminated C string; `ptr`
/// is never dereferenced.
#[no_mangle]
pub unsafe extern "C" fn __m2c_rt_memcleanup_map2check_free_resolved_address(
    ptr: *const std::os::raw::c_void,
    line: std::os::raw::c_uint,
    function_name: *const std::os::raw::c_char,
    is_null_valid: std::os::raw::c_short,
) {
    ffi_guard(
        || {
            // SAFETY: forwarded caller contract.
            unsafe {
                rt_mem_free_resolved_address(
                    MemMode::Memcleanup,
                    ptr,
                    line,
                    function_name,
                    is_null_valid,
                )
            }
        },
        (),
    );
}

/// `map2check_add_store_pointer` (`AnalysisModeMemcleanup.c:243-292`): as
/// memtrack's.
///
/// # Safety
/// `name` and `function_name` must be null or valid null-terminated C
/// strings; `var` and `value` are never dereferenced.
#[no_mangle]
pub unsafe extern "C" fn __m2c_rt_memcleanup_map2check_add_store_pointer(
    var: *const std::os::raw::c_void,
    value: *const std::os::raw::c_void,
    scope: std::os::raw::c_uint,
    name: *const std::os::raw::c_char,
    line: std::os::raw::c_int,
    function_name: *const std::os::raw::c_char,
) {
    ffi_guard(
        || {
            // SAFETY: forwarded caller contract.
            unsafe { rt_mem_add_store_pointer(var, value, scope, name, line, function_name) }
        },
        (),
    );
}

/// `map2check_check_deref` (`AnalysisModeMemcleanup.c:294`): empty.
///
/// # Safety
/// `function_name` is never read.
#[no_mangle]
pub unsafe extern "C" fn __m2c_rt_memcleanup_map2check_check_deref(
    line: std::os::raw::c_int,
    function_name: *const std::os::raw::c_char,
) {
    ffi_guard(
        || {
            // SAFETY: forwarded caller contract.
            unsafe { rt_mem_check_deref(MemMode::Memcleanup, line, function_name) }
        },
        (),
    );
}

/// `map2check_malloc` (`AnalysisModeMemcleanup.c:296-314`): as memtrack's.
#[no_mangle]
pub extern "C" fn __m2c_rt_memcleanup_map2check_malloc(
    ptr: *const std::os::raw::c_void,
    size: std::os::raw::c_int,
) {
    ffi_guard(|| rt_mem_malloc(ptr, size), ());
}

/// `map2check_posix` (`AnalysisModeMemcleanup.c:319-324`): as memtrack's.
///
/// # Safety
/// `ptr` must be null or point to a readable `void *`.
#[no_mangle]
pub unsafe extern "C" fn __m2c_rt_memcleanup_map2check_posix(
    ptr: *const std::os::raw::c_void,
    size: std::os::raw::c_int,
) {
    // SAFETY: forwarded caller contract.
    ffi_guard(|| unsafe { rt_mem_posix(ptr, size) }, ());
}

/// `map2check_calloc` (`AnalysisModeMemcleanup.c:326-328`): as memtrack's.
#[no_mangle]
pub extern "C" fn __m2c_rt_memcleanup_map2check_calloc(
    ptr: *const std::os::raw::c_void,
    quantity: std::os::raw::c_int,
    size: std::os::raw::c_int,
) {
    ffi_guard(|| rt_mem_calloc(ptr, quantity, size), ());
}

/// `map2check_free` (`AnalysisModeMemcleanup.c:330-357`): `ptr` is the slot of
/// the pointer variable `name`. A NULL block does nothing; otherwise a FREE
/// row for the variable is appended and the block is released (never
/// FALSE-FREE, `error = FALSE`, `:342`). A block with no row is SD-23.
///
/// # Safety
/// `name` and `function_name` must be null or valid null-terminated C
/// strings; `ptr` must be null or point to a readable `long`.
#[no_mangle]
pub unsafe extern "C" fn __m2c_rt_memcleanup_map2check_free(
    name: *const std::os::raw::c_char,
    ptr: *const std::os::raw::c_void,
    scope: std::os::raw::c_uint,
    line: std::os::raw::c_uint,
    function_name: *const std::os::raw::c_char,
) {
    ffi_guard(
        || {
            // SAFETY: forwarded caller contract.
            unsafe { rt_mem_free(MemMode::Memcleanup, name, ptr, scope, line, function_name) }
        },
        (),
    );
}

/// `map2check_non_static_alloca` (`AnalysisModeMemcleanup.c:359-363`): as
/// memtrack's.
///
/// # Safety
/// `name` must be null or a valid null-terminated C string; `ptr` is never
/// dereferenced.
#[no_mangle]
pub unsafe extern "C" fn __m2c_rt_memcleanup_map2check_non_static_alloca(
    name: *const std::os::raw::c_char,
    ptr: *const std::os::raw::c_void,
    size: std::os::raw::c_int,
    size_of_primitive: std::os::raw::c_int,
    line: std::os::raw::c_int,
    scope: std::os::raw::c_int,
) {
    // SAFETY: forwarded caller contract.
    ffi_guard(
        || unsafe { rt_mem_non_static_alloca(name, ptr, size, size_of_primitive, line, scope) },
        (),
    );
}

/// `map2check_alloca` (`AnalysisModeMemcleanup.c:365-370`): as memtrack's.
///
/// # Safety
/// `name` must be null or a valid null-terminated C string; `ptr` is never
/// dereferenced.
#[no_mangle]
pub unsafe extern "C" fn __m2c_rt_memcleanup_map2check_alloca(
    name: *const std::os::raw::c_char,
    ptr: *const std::os::raw::c_void,
    size: std::os::raw::c_int,
    size_of_primitive: std::os::raw::c_int,
    line: std::os::raw::c_int,
    scope: std::os::raw::c_int,
) {
    // SAFETY: forwarded caller contract.
    ffi_guard(
        || unsafe { rt_mem_alloca(name, ptr, size, size_of_primitive, line, scope) },
        (),
    );
}

/// `map2check_function` (`AnalysisModeMemcleanup.c:372-376`): as memtrack's.
///
/// # Safety
/// `name` must be null or a valid null-terminated C string; `ptr` is never
/// dereferenced.
#[no_mangle]
pub unsafe extern "C" fn __m2c_rt_memcleanup_map2check_function(
    name: *const std::os::raw::c_char,
    ptr: *const std::os::raw::c_void,
) {
    // SAFETY: forwarded caller contract.
    ffi_guard(|| unsafe { rt_mem_function(name, ptr) }, ());
}

// ── C runtime ABI: NonDetLog ────────────────────────────────────────────────
//
// `NonDetLog.c` of Map2Check `develop`. `nondet_log_to_file`,
// `new_nondet_call`, `helper_map2check_nondet_append_element`,
// `map2check_nondet_get_log` and the `nondet_log` global are private to the
// Rust core (SD-22): `crate::nondet::c_log` and `AnalysisState::c_nondet`.
// The generator modules (`map2check_non_det_<t>`, `main`, `nondet_init`...)
// are IR (Task 3.1); `nondet_init` there calls `nondet_log_init`.

/// Appends one row to the nondet log: `new_nondet_call` with the current
/// step, then `helper_map2check_nondet_append_element`, which advances the
/// step (`NonDetLog.c:117-155`). The exports wrap the call in `ffi_guard`.
///
/// # Safety
/// `function_name` must be null or a valid null-terminated C string.
unsafe fn log_c_nondet(
    kind: i32,
    line: std::os::raw::c_uint,
    scope: std::os::raw::c_uint,
    bits: u64,
    function_name: *const std::os::raw::c_char,
) {
    let name: &[u8] = if function_name.is_null() {
        b""
    } else {
        // SAFETY: caller guarantees a valid null-terminated C string.
        unsafe { CStr::from_ptr(function_name) }.to_bytes()
    };
    if let Err(e) = state::with_state(|s| {
        let call =
            crate::nondet::c_log::CNondetCall::from_parts(kind, line, scope, s.c_step, name, bits);
        s.c_step = s.c_step.wrapping_add(1);
        s.c_nondet.push(call);
        Ok(())
    }) {
        log_error(&e);
    }
}

use crate::nondet::c_log::kind as nd;

/// `as_int = *(int *)value` over a zeroed union: the int, zero-extended.
fn int_bits(v: std::os::raw::c_int) -> u64 {
    u64::from(v as u32)
}

// One export per `map2check_nondet_<t>` of `NonDetLog.c:157-228`, with the C
// signature `(unsigned line, unsigned scope, <ty> value, const char
// *function_name)` of `NonDetLog.h`. Written out, not generated by a macro,
// so that cbindgen emits them into `include/map2check.h` and
// `tests/abi/check-signatures.sh` checks them against the C header. The bits
// are the union member `new_nondet_call` stores (`:128-141`): the int for
// every integer type but the 64-bit ones, the double for DOUBLE and FLOAT
// (a float arrives widened, `:219-221`).

/// `map2check_nondet_int` (row type `INTEGER`).
///
/// # Safety
/// `function_name` must be null or a valid null-terminated C string.
#[no_mangle]
pub unsafe extern "C" fn map2check_nondet_int(
    line: std::os::raw::c_uint,
    scope: std::os::raw::c_uint,
    value: std::os::raw::c_int,
    function_name: *const std::os::raw::c_char,
) {
    ffi_guard(
        || {
            // SAFETY: forwarded from this function's contract.
            unsafe { log_c_nondet(nd::INTEGER, line, scope, int_bits(value), function_name) }
        },
        (),
    );
}

/// `map2check_nondet_char` (row type `CHAR`).
///
/// # Safety
/// `function_name` must be null or a valid null-terminated C string.
#[no_mangle]
pub unsafe extern "C" fn map2check_nondet_char(
    line: std::os::raw::c_uint,
    scope: std::os::raw::c_uint,
    value: std::os::raw::c_int,
    function_name: *const std::os::raw::c_char,
) {
    ffi_guard(
        || {
            // SAFETY: forwarded from this function's contract.
            unsafe { log_c_nondet(nd::CHAR, line, scope, int_bits(value), function_name) }
        },
        (),
    );
}

/// `map2check_nondet_pointer` (row type `POINTER`).
///
/// # Safety
/// `function_name` must be null or a valid null-terminated C string.
#[no_mangle]
pub unsafe extern "C" fn map2check_nondet_pointer(
    line: std::os::raw::c_uint,
    scope: std::os::raw::c_uint,
    value: std::os::raw::c_int,
    function_name: *const std::os::raw::c_char,
) {
    ffi_guard(
        || {
            // SAFETY: forwarded from this function's contract.
            unsafe { log_c_nondet(nd::POINTER, line, scope, int_bits(value), function_name) }
        },
        (),
    );
}

/// `map2check_nondet_ushort` (row type `USHORT`).
///
/// # Safety
/// `function_name` must be null or a valid null-terminated C string.
#[no_mangle]
pub unsafe extern "C" fn map2check_nondet_ushort(
    line: std::os::raw::c_uint,
    scope: std::os::raw::c_uint,
    value: std::os::raw::c_int,
    function_name: *const std::os::raw::c_char,
) {
    ffi_guard(
        || {
            // SAFETY: forwarded from this function's contract.
            unsafe { log_c_nondet(nd::USHORT, line, scope, int_bits(value), function_name) }
        },
        (),
    );
}

/// `map2check_nondet_short` (row type `SHORT`).
///
/// # Safety
/// `function_name` must be null or a valid null-terminated C string.
#[no_mangle]
pub unsafe extern "C" fn map2check_nondet_short(
    line: std::os::raw::c_uint,
    scope: std::os::raw::c_uint,
    value: std::os::raw::c_int,
    function_name: *const std::os::raw::c_char,
) {
    ffi_guard(
        || {
            // SAFETY: forwarded from this function's contract.
            unsafe { log_c_nondet(nd::SHORT, line, scope, int_bits(value), function_name) }
        },
        (),
    );
}

/// `map2check_nondet_long` (row type `LONG`).
///
/// # Safety
/// `function_name` must be null or a valid null-terminated C string.
#[no_mangle]
pub unsafe extern "C" fn map2check_nondet_long(
    line: std::os::raw::c_uint,
    scope: std::os::raw::c_uint,
    value: std::os::raw::c_int,
    function_name: *const std::os::raw::c_char,
) {
    ffi_guard(
        || {
            // SAFETY: forwarded from this function's contract.
            unsafe { log_c_nondet(nd::LONG, line, scope, int_bits(value), function_name) }
        },
        (),
    );
}

/// `map2check_nondet_ulong` (row type `ULONG`).
///
/// # Safety
/// `function_name` must be null or a valid null-terminated C string.
#[no_mangle]
pub unsafe extern "C" fn map2check_nondet_ulong(
    line: std::os::raw::c_uint,
    scope: std::os::raw::c_uint,
    value: std::os::raw::c_int,
    function_name: *const std::os::raw::c_char,
) {
    ffi_guard(
        || {
            // SAFETY: forwarded from this function's contract.
            unsafe { log_c_nondet(nd::ULONG, line, scope, int_bits(value), function_name) }
        },
        (),
    );
}

/// `map2check_nondet_bool` (row type `BOOL`).
///
/// # Safety
/// `function_name` must be null or a valid null-terminated C string.
#[no_mangle]
pub unsafe extern "C" fn map2check_nondet_bool(
    line: std::os::raw::c_uint,
    scope: std::os::raw::c_uint,
    value: std::os::raw::c_int,
    function_name: *const std::os::raw::c_char,
) {
    ffi_guard(
        || {
            // SAFETY: forwarded from this function's contract.
            unsafe { log_c_nondet(nd::BOOL, line, scope, int_bits(value), function_name) }
        },
        (),
    );
}

/// `map2check_nondet_uchar` (row type `UCHAR`).
///
/// # Safety
/// `function_name` must be null or a valid null-terminated C string.
#[no_mangle]
pub unsafe extern "C" fn map2check_nondet_uchar(
    line: std::os::raw::c_uint,
    scope: std::os::raw::c_uint,
    value: std::os::raw::c_int,
    function_name: *const std::os::raw::c_char,
) {
    ffi_guard(
        || {
            // SAFETY: forwarded from this function's contract.
            unsafe { log_c_nondet(nd::UCHAR, line, scope, int_bits(value), function_name) }
        },
        (),
    );
}

/// `map2check_nondet_pchar` (row type `PCHAR`).
///
/// # Safety
/// `function_name` must be null or a valid null-terminated C string.
#[no_mangle]
pub unsafe extern "C" fn map2check_nondet_pchar(
    line: std::os::raw::c_uint,
    scope: std::os::raw::c_uint,
    value: std::os::raw::c_int,
    function_name: *const std::os::raw::c_char,
) {
    ffi_guard(
        || {
            // SAFETY: forwarded from this function's contract.
            unsafe { log_c_nondet(nd::PCHAR, line, scope, int_bits(value), function_name) }
        },
        (),
    );
}

/// `map2check_nondet_size_t` (row type `SIZE_T`).
///
/// # Safety
/// `function_name` must be null or a valid null-terminated C string.
#[no_mangle]
pub unsafe extern "C" fn map2check_nondet_size_t(
    line: std::os::raw::c_uint,
    scope: std::os::raw::c_uint,
    value: std::os::raw::c_int,
    function_name: *const std::os::raw::c_char,
) {
    ffi_guard(
        || {
            // SAFETY: forwarded from this function's contract.
            unsafe { log_c_nondet(nd::SIZE_T, line, scope, int_bits(value), function_name) }
        },
        (),
    );
}

/// `map2check_nondet_loff_t` (row type `LOFF_T`).
///
/// # Safety
/// `function_name` must be null or a valid null-terminated C string.
#[no_mangle]
pub unsafe extern "C" fn map2check_nondet_loff_t(
    line: std::os::raw::c_uint,
    scope: std::os::raw::c_uint,
    value: std::os::raw::c_int,
    function_name: *const std::os::raw::c_char,
) {
    ffi_guard(
        || {
            // SAFETY: forwarded from this function's contract.
            unsafe { log_c_nondet(nd::LOFF_T, line, scope, int_bits(value), function_name) }
        },
        (),
    );
}

/// `map2check_nondet_sector_t` (row type `SECTOR_T`).
///
/// # Safety
/// `function_name` must be null or a valid null-terminated C string.
#[no_mangle]
pub unsafe extern "C" fn map2check_nondet_sector_t(
    line: std::os::raw::c_uint,
    scope: std::os::raw::c_uint,
    value: std::os::raw::c_int,
    function_name: *const std::os::raw::c_char,
) {
    ffi_guard(
        || {
            // SAFETY: forwarded from this function's contract.
            unsafe { log_c_nondet(nd::SECTOR_T, line, scope, int_bits(value), function_name) }
        },
        (),
    );
}

/// `map2check_nondet_uint` (row type `UINT`).
///
/// # Safety
/// `function_name` must be null or a valid null-terminated C string.
#[no_mangle]
pub unsafe extern "C" fn map2check_nondet_uint(
    line: std::os::raw::c_uint,
    scope: std::os::raw::c_uint,
    value: std::os::raw::c_int,
    function_name: *const std::os::raw::c_char,
) {
    ffi_guard(
        || {
            // SAFETY: forwarded from this function's contract.
            unsafe { log_c_nondet(nd::UINT, line, scope, int_bits(value), function_name) }
        },
        (),
    );
}

/// `map2check_nondet_u8` (row type `U8`).
///
/// # Safety
/// `function_name` must be null or a valid null-terminated C string.
#[no_mangle]
pub unsafe extern "C" fn map2check_nondet_u8(
    line: std::os::raw::c_uint,
    scope: std::os::raw::c_uint,
    value: std::os::raw::c_int,
    function_name: *const std::os::raw::c_char,
) {
    ffi_guard(
        || {
            // SAFETY: forwarded from this function's contract.
            unsafe { log_c_nondet(nd::U8, line, scope, int_bits(value), function_name) }
        },
        (),
    );
}

/// `map2check_nondet_u16` (row type `U16`).
///
/// # Safety
/// `function_name` must be null or a valid null-terminated C string.
#[no_mangle]
pub unsafe extern "C" fn map2check_nondet_u16(
    line: std::os::raw::c_uint,
    scope: std::os::raw::c_uint,
    value: std::os::raw::c_int,
    function_name: *const std::os::raw::c_char,
) {
    ffi_guard(
        || {
            // SAFETY: forwarded from this function's contract.
            unsafe { log_c_nondet(nd::U16, line, scope, int_bits(value), function_name) }
        },
        (),
    );
}

/// `map2check_nondet_u32` (row type `U32`).
///
/// # Safety
/// `function_name` must be null or a valid null-terminated C string.
#[no_mangle]
pub unsafe extern "C" fn map2check_nondet_u32(
    line: std::os::raw::c_uint,
    scope: std::os::raw::c_uint,
    value: std::os::raw::c_int,
    function_name: *const std::os::raw::c_char,
) {
    ffi_guard(
        || {
            // SAFETY: forwarded from this function's contract.
            unsafe { log_c_nondet(nd::U32, line, scope, int_bits(value), function_name) }
        },
        (),
    );
}

/// `map2check_nondet_memory_byte` (row type `MEMORY_BYTE`).
///
/// # Safety
/// `function_name` must be null or a valid null-terminated C string.
#[no_mangle]
pub unsafe extern "C" fn map2check_nondet_memory_byte(
    line: std::os::raw::c_uint,
    scope: std::os::raw::c_uint,
    value: std::os::raw::c_int,
    function_name: *const std::os::raw::c_char,
) {
    ffi_guard(
        || {
            // SAFETY: forwarded from this function's contract.
            unsafe { log_c_nondet(nd::MEMORY_BYTE, line, scope, int_bits(value), function_name) }
        },
        (),
    );
}

/// `map2check_nondet_unsigned` (row type `UNSIGNED`).
///
/// # Safety
/// `function_name` must be null or a valid null-terminated C string.
#[no_mangle]
pub unsafe extern "C" fn map2check_nondet_unsigned(
    line: std::os::raw::c_uint,
    scope: std::os::raw::c_uint,
    value: std::os::raw::c_uint,
    function_name: *const std::os::raw::c_char,
) {
    ffi_guard(
        || {
            // SAFETY: forwarded from this function's contract.
            unsafe { log_c_nondet(nd::UNSIGNED, line, scope, u64::from(value), function_name) }
        },
        (),
    );
}

/// `map2check_nondet_double` (row type `DOUBLE`).
///
/// # Safety
/// `function_name` must be null or a valid null-terminated C string.
#[no_mangle]
pub unsafe extern "C" fn map2check_nondet_double(
    line: std::os::raw::c_uint,
    scope: std::os::raw::c_uint,
    value: f64,
    function_name: *const std::os::raw::c_char,
) {
    ffi_guard(
        || {
            // SAFETY: forwarded from this function's contract.
            unsafe { log_c_nondet(nd::DOUBLE, line, scope, value.to_bits(), function_name) }
        },
        (),
    );
}

/// `map2check_nondet_float` (row type `FLOAT`).
///
/// # Safety
/// `function_name` must be null or a valid null-terminated C string.
#[no_mangle]
pub unsafe extern "C" fn map2check_nondet_float(
    line: std::os::raw::c_uint,
    scope: std::os::raw::c_uint,
    value: f64,
    function_name: *const std::os::raw::c_char,
) {
    ffi_guard(
        || {
            // SAFETY: forwarded from this function's contract.
            unsafe { log_c_nondet(nd::FLOAT, line, scope, value.to_bits(), function_name) }
        },
        (),
    );
}

/// `map2check_nondet_longlong` (row type `LONGLONG`).
///
/// # Safety
/// `function_name` must be null or a valid null-terminated C string.
#[no_mangle]
pub unsafe extern "C" fn map2check_nondet_longlong(
    line: std::os::raw::c_uint,
    scope: std::os::raw::c_uint,
    value: std::os::raw::c_longlong,
    function_name: *const std::os::raw::c_char,
) {
    ffi_guard(
        || {
            // SAFETY: forwarded from this function's contract.
            unsafe { log_c_nondet(nd::LONGLONG, line, scope, value as u64, function_name) }
        },
        (),
    );
}

/// `map2check_nondet_ulonglong` (row type `ULONGLONG`).
///
/// # Safety
/// `function_name` must be null or a valid null-terminated C string.
#[no_mangle]
pub unsafe extern "C" fn map2check_nondet_ulonglong(
    line: std::os::raw::c_uint,
    scope: std::os::raw::c_uint,
    value: std::os::raw::c_ulonglong,
    function_name: *const std::os::raw::c_char,
) {
    ffi_guard(
        || {
            // SAFETY: forwarded from this function's contract.
            unsafe { log_c_nondet(nd::ULONGLONG, line, scope, value, function_name) }
        },
        (),
    );
}

/// `nondet_log_init` (`NonDetLog.c:146`): a new, empty log. The step counter
/// is not touched.
#[no_mangle]
pub extern "C" fn nondet_log_init() {
    ffi_guard(clear_c_nondet_log, ());
}

/// `nondet_log_destroy` (`NonDetLog.c:148`): frees the log.
#[no_mangle]
pub extern "C" fn nondet_log_destroy() {
    ffi_guard(clear_c_nondet_log, ());
}

fn clear_c_nondet_log() {
    if let Err(e) = state::with_state(|s| {
        s.c_nondet = Vec::new();
        Ok(())
    }) {
        log_error(&e);
    }
}

/// Core entry point of `nondet_log_to_file` (`NonDetLog.c:50-125`) for the
/// IR of the KLEE generator (D7): writes the log of the run to `klee_log.csv`
/// in the current directory. Returns `TRUE` (1) or, when the file cannot be
/// written, `FALSE` (0).
///
/// It is only the last step of `nondet_generate_aux_witness_files`
/// (`NonDetGeneratorKlee.c:57-62`). The IR must first skip the call when
/// `__m2c_rt_nondet_log_len()` is above 1024 (`MAP2CHECK_KLEE_LOG_MAX_ROWS`)
/// and pin every row with `__m2c_rt_nondet_log_get_i64` /
/// `klee_get_value_i64` / `klee_assume` / `__m2c_rt_nondet_log_set_i64`
/// (`:33-47`); the core has no KLEE intrinsics.
#[no_mangle]
pub extern "C" fn __m2c_rt_nondet_log_to_file() -> std::os::raw::c_char {
    ffi_guard(
        || {
            let Some(dir) = termination::output_dir() else {
                return 0;
            };
            match state::with_state(|s| {
                Ok(crate::nondet::c_log::nondet_log_to_file(&s.c_nondet, &dir))
            }) {
                Ok(written) => std::os::raw::c_char::from(written),
                Err(e) => {
                    log_error(&e);
                    0
                }
            }
        },
        0,
    )
}

/// Number of rows of the nondet log (`map2check_nondet_get_log().size`,
/// `NonDetGeneratorKlee.c:57-58`).
#[no_mangle]
pub extern "C" fn __m2c_rt_nondet_log_len() -> std::os::raw::c_uint {
    ffi_guard(
        || state::with_state(|s| Ok(s.c_nondet.len() as std::os::raw::c_uint)).unwrap_or(0),
        0,
    )
}

/// The 8 bytes of the value union of row `index` as a `long long`, as
/// `memcpy(&symbolic, &call->value, sizeof(symbolic))` reads them
/// (`NonDetGeneratorKlee.c:39`): the `int` types zero-extended, the 64-bit
/// types and the doubles by bit pattern. 0 when `index` is out of range
/// (C stops at a NULL row, `:37-38`).
#[no_mangle]
pub extern "C" fn __m2c_rt_nondet_log_get_i64(index: std::os::raw::c_uint) -> i64 {
    ffi_guard(
        || {
            state::with_state(|s| {
                Ok(s.c_nondet
                    .get(index as usize)
                    .map_or(0, |c| c.value_bits() as i64))
            })
            .unwrap_or(0)
        },
        0,
    )
}

/// Writes `value` over the 8 bytes of the value union of row `index`, as
/// `memcpy(&call->value, &concrete, sizeof(concrete))` does
/// (`NonDetGeneratorKlee.c:42`). Does nothing when `index` is out of range.
#[no_mangle]
pub extern "C" fn __m2c_rt_nondet_log_set_i64(index: std::os::raw::c_uint, value: i64) {
    ffi_guard(
        || {
            if let Err(e) = state::with_state(|s| {
                if let Some(c) = s.c_nondet.get_mut(index as usize) {
                    c.set_value_bits(value as u64);
                }
                Ok(())
            }) {
                log_error(&e);
            }
        },
        (),
    );
}

// ── NonDet tracking ───────────────────────────────────────────────────────────

#[repr(C)]
#[derive(Debug)]
#[allow(non_camel_case_types)]
pub struct non_det_log_t {
    pub tqe_next: *mut non_det_log_t,
    pub tqe_prev: *mut *mut non_det_log_t,
    pub step: std::os::raw::c_long,
    pub line: std::os::raw::c_int,
    pub scope: std::os::raw::c_int,
    pub type_var: std::os::raw::c_int,
    pub value: LegacyNonDetData,
    pub function_name: *const std::os::raw::c_char,
}

#[repr(C)]
pub union LegacyNonDetData {
    pub i: *mut i32,
    pub u: *mut u32,
    pub l: *mut std::os::raw::c_long,
    pub c: *mut std::os::raw::c_char,
    pub str: [std::os::raw::c_char; 20],
    pub f: *mut f32,
    pub d: *mut f64,
    /// The `value` pointer of the families with no typed member above.
    pub p: *mut std::os::raw::c_void,
}

impl std::fmt::Debug for LegacyNonDetData {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.write_str("LegacyNonDetData")
    }
}

// SAFETY: C pointers in these compatibility records are opaque values; Rust
// stores and drops the records without dereferencing those pointers.
unsafe impl Send for non_det_log_t {}

macro_rules! nondet_ffi {
    ($fn_name:ident, $c_ty:ty, $field:ident, $zero:expr, $to_value:expr) => {
        /// # Safety
        /// `value` must be null or point to a valid value of the expected type.
        /// `function_name` must be null or a valid null-terminated C string.
        // `c_long` and friends are `i64`/`u64` on LP64 only: the widening
        // conversions in `$to_value` are no-ops there and real elsewhere.
        #[allow(clippy::useless_conversion)]
        #[no_mangle]
        pub unsafe extern "C" fn $fn_name(
            line: i32,
            scope: i32,
            type_var: i32,
            value: *mut $c_ty,
            function_name: *const std::os::raw::c_char,
        ) -> *mut non_det_log_t {
            ffi_guard(
                || {
                    // SAFETY: caller guarantees function_name is a valid C string or null.
                    let fname = unsafe { c_str(function_name) };
                    let raw_value: $c_ty = if value.is_null() {
                        $zero
                    } else {
                        // SAFETY: caller guarantees value points to a valid value.
                        unsafe { *value }
                    };
                    let to_value: fn($c_ty) -> NonDetValue = $to_value;
                    match state::with_state(|s| {
                        let step = s.next_step();
                        s.nondets.push(NonDetEntry::new(
                            step,
                            line as u32,
                            scope as u32,
                            fname,
                            to_value(raw_value),
                        ));
                        let entry = Box::new(non_det_log_t {
                            tqe_next: std::ptr::null_mut(),
                            tqe_prev: std::ptr::null_mut(),
                            step: step as std::os::raw::c_long,
                            line,
                            scope,
                            type_var,
                            value: LegacyNonDetData { $field: value as _ },
                            function_name,
                        });
                        let pointer = (&*entry) as *const non_det_log_t as *mut non_det_log_t;
                        s.legacy_nondet_logs.push(entry);
                        Ok(pointer)
                    }) {
                        Ok(pointer) => pointer,
                        Err(e) => {
                            log_error(&e);
                            std::ptr::null_mut()
                        }
                    }
                },
                std::ptr::null_mut(),
            )
        }
    };
}

// One export per `map2check_nondet_<t>` of develop (`NonDetLog.c:105-150`),
// each taking a pointer to the value in the C type `NonDetGenerator.h` gives
// that family. The `type_var` argument is ignored for the row type and only
// kept in the returned record: the `enum NONDET_TYPE` of the row comes from
// the export, as develop's per-type wrappers do (`NonDetLog.c:105-128`), so
// the value's C type and the row type cannot disagree. A pass that calls the
// wrong saver therefore logs the wrong type (docs/api-deltas.md).
nondet_ffi!(map2check_save_nondet_log_int, i32, i, 0, NonDetValue::Int);
nondet_ffi!(map2check_save_nondet_log_uint, u32, u, 0, NonDetValue::UInt);
nondet_ffi!(
    map2check_save_nondet_log_unsigned,
    std::os::raw::c_uint,
    u,
    0,
    NonDetValue::Unsigned
);
nondet_ffi!(
    map2check_save_nondet_log_long,
    std::os::raw::c_long,
    l,
    0,
    |v| NonDetValue::Long(i64::from(v))
);
nondet_ffi!(
    map2check_save_nondet_log_ulong,
    std::os::raw::c_ulong,
    p,
    0,
    |v| NonDetValue::ULong(u64::from(v))
);
nondet_ffi!(
    map2check_save_nondet_log_char,
    std::os::raw::c_char,
    c,
    0,
    |v| NonDetValue::Char(i8::from_ne_bytes([v as u8]))
);
nondet_ffi!(
    map2check_save_nondet_log_uchar,
    u8,
    p,
    0,
    NonDetValue::UChar
);
nondet_ffi!(
    map2check_save_nondet_log_short,
    i16,
    p,
    0,
    NonDetValue::Short
);
nondet_ffi!(
    map2check_save_nondet_log_ushort,
    u16,
    p,
    0,
    NonDetValue::UShort
);
// develop: `typedef int bool` (NonDetGenerator.h:74).
nondet_ffi!(map2check_save_nondet_log_bool, i32, p, 0, NonDetValue::Bool);
nondet_ffi!(
    map2check_save_nondet_log_size_t,
    usize,
    p,
    0,
    NonDetValue::SizeT
);
// glibc: `typedef long long loff_t`.
nondet_ffi!(
    map2check_save_nondet_log_loff_t,
    std::os::raw::c_longlong,
    p,
    0,
    |v| NonDetValue::LoffT(i64::from(v))
);
// develop: `#define sector_t unsigned long` (NonDetGenerator.h:112).
nondet_ffi!(
    map2check_save_nondet_log_sector_t,
    std::os::raw::c_ulong,
    p,
    0,
    |v| NonDetValue::SectorT(u64::from(v))
);
nondet_ffi!(
    map2check_save_nondet_log_pointer,
    *mut std::os::raw::c_void,
    p,
    std::ptr::null_mut(),
    |v| NonDetValue::Pointer(v as usize)
);
nondet_ffi!(
    map2check_save_nondet_log_pchar,
    *mut std::os::raw::c_char,
    p,
    std::ptr::null_mut(),
    |v| NonDetValue::PChar(v as usize)
);
nondet_ffi!(
    map2check_save_nondet_log_float,
    f32,
    f,
    0.0,
    NonDetValue::Float
);
nondet_ffi!(
    map2check_save_nondet_log_double,
    f64,
    d,
    0.0,
    NonDetValue::Double
);

// ── Basic-block tracking ──────────────────────────────────────────────────────

#[repr(C)]
#[derive(Debug)]
#[allow(non_camel_case_types)]
pub struct bbtrack_log_t {
    pub tqe_next: *mut bbtrack_log_t,
    pub tqe_prev: *mut *mut bbtrack_log_t,
    pub step: std::os::raw::c_long,
    pub line: std::os::raw::c_int,
    pub function_name: *const std::os::raw::c_char,
}

// SAFETY: C pointers in this compatibility record are opaque values; Rust
// stores and drops the record without dereferencing those pointers.
unsafe impl Send for bbtrack_log_t {}

/// Records execution of a basic block.
///
/// # Safety
/// `function_name` must be null or a valid null-terminated C string.
#[no_mangle]
pub unsafe extern "C" fn map2check_save_basic_block_log(
    line: i32,
    function_name: *const std::os::raw::c_char,
) -> *mut bbtrack_log_t {
    ffi_guard(
        || {
            // SAFETY: caller guarantees function_name is a valid C string or null.
            let fname = unsafe { c_str(function_name) };
            match state::with_state(|s| {
                let step = s.next_step();
                s.bbtrack
                    .push(BasicBlockEntry::new(step, line as u32, fname));
                let entry = Box::new(bbtrack_log_t {
                    tqe_next: std::ptr::null_mut(),
                    tqe_prev: std::ptr::null_mut(),
                    step: step as std::os::raw::c_long,
                    line,
                    function_name,
                });
                let pointer = (&*entry) as *const bbtrack_log_t as *mut bbtrack_log_t;
                s.legacy_bbtrack_logs.push(entry);
                Ok(pointer)
            }) {
                Ok(pointer) => pointer,
                Err(e) => {
                    log_error(&e);
                    std::ptr::null_mut()
                }
            }
        },
        std::ptr::null_mut(),
    )
}

/// Returns 1 if `line` was recorded as executed, 0 otherwise.
#[no_mangle]
pub extern "C" fn map2check_is_in_trackbb_container(line: i32) -> i32 {
    ffi_guard(
        || {
            state::with_state(|s| {
                Ok(if crate::bbtrack::contains_line(&s.bbtrack, line as u32) {
                    1
                } else {
                    0
                })
            })
            .unwrap_or(0)
        },
        0,
    )
}

// ── Memory tracking ───────────────────────────────────────────────────────────

/// # Safety
/// `var_name` must be null or a valid null-terminated C string; `ptr_address` may be null.
#[no_mangle]
pub unsafe extern "C" fn map2check_map_alloca(
    var_name: *const std::os::raw::c_char,
    ptr_address: *const std::os::raw::c_void,
    size: i32,
    size_primitive: i32,
    line_number: i32,
    scope: i32,
) {
    ffi_guard(
        || {
            if size < 0 || size_primitive < 0 {
                return;
            }
            // SAFETY: caller guarantees var_name is a valid C string or null.
            let name = unsafe { c_str(var_name) };
            let addr = ptr_address as usize;
            if let Err(e) = state::with_state(|s| {
                let step = s.next_step();
                s.memtrack.push(
                    MemTrackEntry::new(
                        step,
                        line_number as u32,
                        scope as u32,
                        addr,
                        addr,
                        false,
                        false,
                        name,
                        "",
                        size as usize,
                        size_primitive as usize,
                        false,
                    )
                    .with_origin(MemOrigin::Alloca),
                );
                Ok(())
            }) {
                log_error(&e);
            }
        },
        (),
    );
}

/// Registers a non-static (dynamically-sized) stack allocation, e.g. a
/// variable-length array whose size is only known at runtime. `size` is the
/// element count: the slot covers `size * size_primitive` bytes. Like
/// `map2check_map_alloca`, the slot is static, so it is never a leak at end of
/// program. This matches `map2check_non_static_alloca` of the Map2Check
/// `develop` C runtime (`AnalysisModeMemtrack.c:368-372`; #38, SD-12). A
/// negative argument or a byte size that overflows drops the record (SD-09).
///
/// # Safety
/// `var_name` must be null or a valid null-terminated C string; `ptr_address` may be null.
#[no_mangle]
pub unsafe extern "C" fn map2check_map_non_static_alloca(
    var_name: *const std::os::raw::c_char,
    ptr_address: *const std::os::raw::c_void,
    size: i32,
    size_primitive: i32,
    line_number: i32,
    scope: i32,
) {
    ffi_guard(
        || {
            if size < 0 || size_primitive < 0 {
                return;
            }
            let Some(bytes) = (size as usize).checked_mul(size_primitive as usize) else {
                return;
            };
            // SAFETY: caller guarantees var_name is a valid C string or null.
            let name = unsafe { c_str(var_name) };
            let addr = ptr_address as usize;
            if let Err(e) = state::with_state(|s| {
                let step = s.next_step();
                s.memtrack.push(
                    MemTrackEntry::new(
                        step,
                        line_number as u32,
                        scope as u32,
                        addr,
                        addr,
                        false,
                        false,
                        name,
                        "",
                        bytes,
                        size_primitive as usize,
                        false,
                    )
                    .with_origin(MemOrigin::Alloca),
                );
                Ok(())
            }) {
                log_error(&e);
            }
        },
        (),
    );
}

/// Registers the address of a function as a valid pointer target, so that a
/// variable holding a function pointer (e.g. `void (*f)(void) = &foo;`) does
/// not get flagged as an invalid address by `map2check_check_load` /
/// `map2check_check_deref` when it is later read or called through.
///
/// # Safety
/// `var_name` must be null or a valid null-terminated C string; `ptr_address` may be null.
#[no_mangle]
pub unsafe extern "C" fn map2check_map_funct_address(
    var_name: *const std::os::raw::c_char,
    ptr_address: *const std::os::raw::c_void,
) {
    ffi_guard(
        || {
            // SAFETY: caller guarantees var_name is a valid C string or null.
            let name = unsafe { c_str(var_name) };
            let addr = ptr_address as usize;
            let pointer_width = std::mem::size_of::<*const std::os::raw::c_void>();
            if let Err(e) = state::with_state(|s| {
                let step = s.next_step();
                s.memtrack.push(
                    MemTrackEntry::new(
                        step,
                        0,
                        0,
                        addr,
                        addr,
                        false,
                        false,
                        name,
                        "",
                        pointer_width,
                        pointer_width,
                        false,
                    )
                    .with_origin(MemOrigin::Function),
                );
                Ok(())
            }) {
                log_error(&e);
            }
        },
        (),
    );
}

/// In the memory modes, a NULL block is develop's UNKNOWN: `map2check_malloc`
/// writes `map2check_property__unknown` and ends the run before recording
/// anything (`AnalysisModeMemtrack.c:305-311`, `AnalysisModeMemcleanup.c:295-300`).
/// Returns whether the call was handled that way.
fn malloc_returned_null(ptr_address: *const std::os::raw::c_void) -> bool {
    let memory_mode = matches!(
        state::config().mode,
        Some(AnalysisMode::Memtrack | AnalysisMode::Memcleanup)
    );
    if !(memory_mode && ptr_address.is_null()) {
        return false;
    }
    record_violation(ViolatedProperty::Unknown, 0, "", false);
    true
}

/// Records a heap allocation of `size` bytes at `ptr_address`. In the
/// memtrack and memcleanup modes a NULL `ptr_address` reports `UNKNOWN`
/// instead, as develop does, whatever `size` is; only a non-NULL block with
/// a negative size is dropped (SD-09).
///
/// # Safety
/// `ptr_address` may be null (null malloc result is valid C).
#[no_mangle]
pub unsafe extern "C" fn map2check_map_malloc(ptr_address: *const std::os::raw::c_void, size: i32) {
    ffi_guard(
        || {
            // The block before the size, as develop: a failed `malloc(n)`
            // with `n` over `i32::MAX` arrives as NULL with a negative size.
            if malloc_returned_null(ptr_address) || size < 0 {
                return;
            }
            let addr = ptr_address as usize;
            if let Err(e) = state::with_state(|s| {
                let step = s.next_step();
                let mut entry = MemTrackEntry::new(
                    step,
                    0,
                    0,
                    addr,
                    addr,
                    false,
                    false,
                    "",
                    "",
                    size as usize,
                    1,
                    false,
                );
                entry.set_malloc();
                s.memtrack.push(entry.with_origin(MemOrigin::Malloc));
                Ok(())
            }) {
                log_error(&e);
            }
        },
        (),
    );
}

/// Records a heap allocation of `quantity * size` bytes at `ptr_address`.
/// In the memtrack and memcleanup modes a NULL `ptr_address` reports
/// `UNKNOWN` instead, as develop's `map2check_calloc` does, whatever the
/// sizes are.
///
/// # Safety
/// `ptr_address` may be null.
#[no_mangle]
pub unsafe extern "C" fn map2check_map_calloc(
    ptr_address: *const std::os::raw::c_void,
    quantity: i32,
    size: i32,
) {
    ffi_guard(
        || {
            // The block first, as in `map2check_map_malloc`.
            if malloc_returned_null(ptr_address) || quantity < 0 || size < 0 {
                return;
            }
            let quantity = quantity as usize;
            let size = size as usize;
            if size.checked_mul(quantity).is_none() {
                return;
            }
            let addr = ptr_address as usize;
            if let Err(e) = state::with_state(|s| {
                let step = s.next_step();
                let mut entry = MemTrackEntry::new(
                    step, 0, 0, addr, addr, false, false, "", "", size, 1, false,
                );
                if !entry.set_calloc(quantity) {
                    return Ok(());
                }
                s.memtrack.push(entry.with_origin(MemOrigin::Malloc));
                Ok(())
            }) {
                log_error(&e);
            }
        },
        (),
    );
}

/// Records a `posix_memalign(memptr, alignment, size)` that the program just
/// made: `ptr_address` is `memptr`, the `void **` the block was written
/// through. As develop's `map2check_posix` (`AnalysisModeMemtrack.c:327-333`),
/// reads the block from `*ptr_address`, records it as `map2check_map_malloc`
/// does, then records the store of the block into `*ptr_address` with
/// scope 1, line 1, variable name `pointer` and function `cocoiso`, the
/// values develop passes. A NULL `ptr_address` is ignored (SD-09); a NULL
/// block reports `UNKNOWN` in the memtrack and memcleanup modes and records
/// no store, as `map2check_map_malloc` does.
///
/// # Safety
/// `ptr_address` must be null or point to a readable `void *`.
#[no_mangle]
pub unsafe extern "C" fn map2check_map_posix_memalign(
    ptr_address: *const std::os::raw::c_void,
    size: i32,
) {
    ffi_guard(
        || {
            if ptr_address.is_null() {
                return;
            }
            let slot = ptr_address.cast::<*const std::os::raw::c_void>();
            // SAFETY: caller guarantees a non-null `ptr_address` points to a
            // readable `void *` (posix_memalign's `memptr`); the read is
            // unaligned-safe.
            let block = unsafe { slot.read_unaligned() };
            if malloc_returned_null(block) {
                return;
            }
            // SAFETY: `block` is only stored; the names are NUL-terminated
            // byte literals (cbindgen cannot parse `c""` literals).
            unsafe {
                map2check_map_malloc(block, size);
                map2check_map_store_pointer(
                    ptr_address,
                    block,
                    1,
                    b"pointer\0".as_ptr().cast(),
                    1,
                    b"cocoiso\0".as_ptr().cast(),
                );
            }
        },
        (),
    );
}

/// Records the release of the heap block `ptr_address` by `free(p)`, where
/// `var_address` is the address of the pointer variable `p` whose value the
/// program freed (develop's `map2check_free` receives that slot,
/// `MemoryTrackPass.cpp:818`). The release is keyed on the block; the slot
/// only names the variable in the legacy `list_log.csv`
/// (`AnalysisModeMemtrack.c:339-347`). The pass loads `*var_address` for
/// `ptr_address`, calls `map2check_check_free` first with the same
/// arguments, and calls neither for a NULL block.
///
/// # Safety
/// `var_name` and `function_name` must be null or valid null-terminated C strings.
/// `var_address` is only stored, never dereferenced.
#[no_mangle]
pub unsafe extern "C" fn map2check_map_free(
    var_name: *const std::os::raw::c_char,
    var_address: *const std::os::raw::c_void,
    ptr_address: *const std::os::raw::c_void,
    scope: u32,
    line_number: u32,
    function_name: *const std::os::raw::c_char,
) {
    ffi_guard(
        || {
            // SAFETY: caller guarantees string pointers are valid or null.
            let name = unsafe { c_str(var_name) };
            let fname = unsafe { c_str(function_name) };
            let addr = ptr_address as usize;
            if let Err(e) = state::with_state(|s| {
                let step = s.next_step();
                let mut entry = MemTrackEntry::new(
                    step,
                    line_number,
                    scope,
                    addr,
                    addr,
                    true,
                    false,
                    name,
                    fname,
                    0,
                    1,
                    false,
                );
                entry.set_free();
                s.memtrack.push(entry.with_origin(MemOrigin::Free {
                    var_address: var_address as usize,
                }));
                Ok(())
            }) {
                log_error(&e);
            }
        },
        (),
    );
}

/// # Safety
/// `var_name` and `funct_name` must be null or valid null-terminated C strings.
#[no_mangle]
pub unsafe extern "C" fn map2check_map_store_pointer(
    var_address: *const std::os::raw::c_void,
    value: *const std::os::raw::c_void,
    scope: u32,
    var_name: *const std::os::raw::c_char,
    line_number: i32,
    funct_name: *const std::os::raw::c_char,
) {
    ffi_guard(
        || {
            // SAFETY: caller guarantees string pointers are valid or null.
            let name = unsafe { c_str(var_name) };
            let fname = unsafe { c_str(funct_name) };
            let var_addr = var_address as usize;
            let points_to = value as usize;
            if let Err(e) = state::with_state(|s| {
                let step = s.next_step();
                s.memtrack.push(
                    MemTrackEntry::new(
                        step,
                        line_number as u32,
                        scope,
                        var_addr,
                        points_to,
                        false,
                        false,
                        name,
                        fname,
                        0,
                        1,
                        false,
                    )
                    .with_origin(MemOrigin::StorePointer),
                );
                Ok(())
            }) {
                log_error(&e);
            }
        },
        (),
    );
}

// ── Analysis mode: assert ─────────────────────────────────────────────────────

/// Checks a user-defined assert expression.
///
/// # Safety
/// `function_name` must be null or a valid null-terminated C string.
#[no_mangle]
pub unsafe extern "C" fn map2check_is_valid_assert(
    line_number: i32,
    function_name: *const std::os::raw::c_char,
    expression: i32,
) {
    ffi_guard(
        || {
            if !check_active(Check::Assert) {
                return;
            }
            // SAFETY: caller guarantees function_name is a valid C string or null.
            let fname = unsafe { c_str(function_name) };
            let ctx = VccContext::new(line_number as u32, 0, fname);
            let checker = AssertChecker { expression };
            match checker.check(&ctx) {
                Ok(crate::analysismode::VccOutcome::Violated { property }) => {
                    // With a mode set the run ends inside; unset, the JSON
                    // report follows the recorded violation.
                    record_violation(property, line_number as u32, fname, false);
                    output::print_report_unless_mode_set();
                }
                Ok(crate::analysismode::VccOutcome::Safe) => {}
                Err(e) => log_error(&e),
            }
        },
        (),
    );
}

// ── Analysis mode: overflow ───────────────────────────────────────────────────

macro_rules! overflow_ffi_binop {
    ($fn_name:ident, $checker:ident, $ty:ty) => {
        /// # Safety
        /// `function_name` must be null or a valid null-terminated C string.
        #[no_mangle]
        pub unsafe extern "C" fn $fn_name(
            param1: $ty,
            param2: $ty,
            line: u32,
            scope: u32,
            function_name: *const std::os::raw::c_char,
        ) {
            ffi_guard(
                || {
                    if !check_active(Check::Overflow) {
                        return;
                    }
                    // SAFETY: caller guarantees function_name is valid or null.
                    let fname = unsafe { c_str(function_name) };
                    let ctx = VccContext::new(line, scope, fname);
                    run_vcc_check(
                        $checker {
                            lhs: param1,
                            rhs: param2,
                        },
                        &ctx,
                        line,
                        fname,
                    );
                },
                (),
            );
        }
    };
}

macro_rules! overflow_ffi_shift {
    ($fn_name:ident, $checker:ident, $ty:ty) => {
        /// # Safety
        /// `function_name` must be null or a valid null-terminated C string.
        #[no_mangle]
        pub unsafe extern "C" fn $fn_name(
            param1: $ty,
            param2: u32,
            line: u32,
            scope: u32,
            function_name: *const std::os::raw::c_char,
        ) {
            ffi_guard(
                || {
                    if !check_active(Check::Overflow) {
                        return;
                    }
                    // SAFETY: caller guarantees function_name is valid or null.
                    let fname = unsafe { c_str(function_name) };
                    let ctx = VccContext::new(line, scope, fname);
                    run_vcc_check(
                        $checker {
                            lhs: param1,
                            rhs: param2,
                        },
                        &ctx,
                        line,
                        fname,
                    );
                },
                (),
            );
        }
    };
}

/// # Safety
/// `function_name` must be null or a valid null-terminated C string.
#[no_mangle]
pub unsafe extern "C" fn map2check_binop_neg_int(
    param1: i32,
    _param2: i32,
    line: u32,
    scope: u32,
    function_name: *const std::os::raw::c_char,
) {
    ffi_guard(
        || {
            if !check_active(Check::Overflow) {
                return;
            }
            // SAFETY: caller guarantees function_name is valid or null.
            let fname = unsafe { c_str(function_name) };
            let ctx = VccContext::new(line, scope, fname);
            run_vcc_check(NegI32 { val: param1 }, &ctx, line, fname);
        },
        (),
    );
}

overflow_ffi_binop!(map2check_binop_add_int, AddI32, i32);
overflow_ffi_binop!(map2check_binop_sub_int, SubI32, i32);
overflow_ffi_binop!(map2check_binop_mul_int, MulI32, i32);
overflow_ffi_binop!(map2check_binop_div_int, DivI32, i32);
overflow_ffi_binop!(map2check_binop_add_unsigned, AddU32, u32);
overflow_ffi_binop!(map2check_binop_sub_unsigned, SubU32, u32);
overflow_ffi_binop!(map2check_binop_mul_unsigned, MulU32, u32);
overflow_ffi_binop!(map2check_binop_div_unsigned, DivU32, u32);
overflow_ffi_shift!(map2check_binop_shl_int, ShlI32, i32);
overflow_ffi_shift!(map2check_binop_shr_int, ShrI32, i32);
overflow_ffi_shift!(map2check_binop_shr_unsigned, ShrU32, u32);

/// Shared body of the `map2check_binop_*_signed` exports. `a` and `b` are
/// the operands sign-extended to 64 bits and `bits` is the width of the
/// operation's result type, as the Map2Check overflow pass sends them
/// (`OverflowPass.cpp:418-440`); a width of 0 or above 64 means 64. The
/// checks are those of develop's `AnalysisModeOverflow.c:110-276`. Active
/// in unset and overflow modes only, like the other binops.
///
/// # Safety
/// `function_name` must be null or a valid null-terminated C string.
unsafe fn signed_binop(
    op: SignedOp,
    a: i64,
    b: i64,
    bits: u32,
    line: u32,
    function_name: *const std::os::raw::c_char,
) {
    if !check_active(Check::Overflow) {
        return;
    }
    // SAFETY: caller guarantees function_name is valid or null.
    let fname = unsafe { c_str(function_name) };
    let ctx = VccContext::new(line, 0, fname);
    let checker = SignedBinop {
        op,
        lhs: a,
        rhs: b,
        bits,
    };
    run_vcc_check(checker, &ctx, line, fname);
}

/// Signed `a + b`: reports `OVERFLOW` when the sum leaves the range of
/// `bits` (develop `map2check_binop_add`).
/// See [`signed_binop`] for the operands, the width and the mode gating.
///
/// # Safety
/// `function_name` must be null or a valid null-terminated C string.
#[no_mangle]
pub unsafe extern "C" fn map2check_binop_add_signed(
    a: i64,
    b: i64,
    bits: u32,
    line: u32,
    function_name: *const std::os::raw::c_char,
) {
    ffi_guard(
        // SAFETY: forwarded caller contract.
        || unsafe { signed_binop(SignedOp::Add, a, b, bits, line, function_name) },
        (),
    );
}

/// Signed `a - b`: reports `OVERFLOW` when the difference leaves the range
/// of `bits` (develop `map2check_binop_sub`).
/// See [`signed_binop`] for the operands, the width and the mode gating.
///
/// # Safety
/// `function_name` must be null or a valid null-terminated C string.
#[no_mangle]
pub unsafe extern "C" fn map2check_binop_sub_signed(
    a: i64,
    b: i64,
    bits: u32,
    line: u32,
    function_name: *const std::os::raw::c_char,
) {
    ffi_guard(
        // SAFETY: forwarded caller contract.
        || unsafe { signed_binop(SignedOp::Sub, a, b, bits, line, function_name) },
        (),
    );
}

/// Signed `a * b`: reports `OVERFLOW` when the product leaves the range of
/// `bits` (develop `map2check_binop_mul`).
/// See [`signed_binop`] for the operands, the width and the mode gating.
///
/// # Safety
/// `function_name` must be null or a valid null-terminated C string.
#[no_mangle]
pub unsafe extern "C" fn map2check_binop_mul_signed(
    a: i64,
    b: i64,
    bits: u32,
    line: u32,
    function_name: *const std::os::raw::c_char,
) {
    ffi_guard(
        // SAFETY: forwarded caller contract.
        || unsafe { signed_binop(SignedOp::Mul, a, b, bits, line, function_name) },
        (),
    );
}

/// Signed `a / b`: reports `DIVBYZERO` when `b` is 0 and `OVERFLOW` for
/// MIN / -1 of `bits` (develop `map2check_binop_sdiv`).
/// See [`signed_binop`] for the operands, the width and the mode gating.
///
/// # Safety
/// `function_name` must be null or a valid null-terminated C string.
#[no_mangle]
pub unsafe extern "C" fn map2check_binop_div_signed(
    a: i64,
    b: i64,
    bits: u32,
    line: u32,
    function_name: *const std::os::raw::c_char,
) {
    ffi_guard(
        // SAFETY: forwarded caller contract.
        || unsafe { signed_binop(SignedOp::Div, a, b, bits, line, function_name) },
        (),
    );
}

/// Signed `a % b`: reports `DIVBYZERO` when `b` is 0 and `OVERFLOW` for
/// MIN % -1 of `bits` (develop `map2check_binop_srem`).
/// See [`signed_binop`] for the operands, the width and the mode gating.
///
/// # Safety
/// `function_name` must be null or a valid null-terminated C string.
#[no_mangle]
pub unsafe extern "C" fn map2check_binop_rem_signed(
    a: i64,
    b: i64,
    bits: u32,
    line: u32,
    function_name: *const std::os::raw::c_char,
) {
    ffi_guard(
        // SAFETY: forwarded caller contract.
        || unsafe { signed_binop(SignedOp::Rem, a, b, bits, line, function_name) },
        (),
    );
}

// ── Analysis mode: memory ─────────────────────────────────────────────────────

/// Checks whether loading from `ptr` is valid.
///
/// # Safety
/// `function_name` must be null or a valid null-terminated C string; `ptr` may be null.
#[no_mangle]
pub unsafe extern "C" fn map2check_check_load(
    ptr: *const std::os::raw::c_void,
    line: i32,
    scope: u32,
    size: i32,
    function_name: *const std::os::raw::c_char,
) {
    ffi_guard(
        || {
            if !check_active(Check::Load) {
                return;
            }
            // SAFETY: caller guarantees function_name is valid or null.
            let fname = unsafe { c_str(function_name) };
            if size < 0 {
                record_violation(ViolatedProperty::MemsafetyDeref, line as u32, fname, false);
                return;
            }
            let ctx = VccContext::new(line as u32, scope, fname);
            let is_null_valid = state::config().null_is_valid;
            run_vcc_check(
                LoadChecker {
                    address: ptr as usize,
                    size: size as usize,
                    is_null_valid,
                },
                &ctx,
                line as u32,
                fname,
            );
        },
        (),
    );
}

/// Checks whether `free(p)` of the heap block `ptr` is valid, where
/// `var_address` is the address of the pointer variable `p` (the same
/// arguments as `map2check_map_free`, which the pass calls after it).
///
/// On a first violation, keeps the FREE row that develop's `map2check_free`
/// appends to `list_log.csv` before it fails (`AnalysisModeMemtrack.c:346-358`);
/// the row is not a release.
///
/// # Safety
/// `name` and `function_name` must be null or valid null-terminated C strings;
/// `ptr` and `var_address` may be null and are never dereferenced.
#[no_mangle]
pub unsafe extern "C" fn map2check_check_free(
    name: *const std::os::raw::c_char,
    var_address: *const std::os::raw::c_void,
    ptr: *const std::os::raw::c_void,
    scope: u32,
    line: u32,
    function_name: *const std::os::raw::c_char,
) {
    ffi_guard(
        || {
            if !check_active(Check::Free) {
                return;
            }
            // SAFETY: caller guarantees string pointers are valid or null.
            let fname = unsafe { c_str(function_name) };
            let ctx = VccContext::new(line, 0, fname);
            let checker = FreeChecker {
                address: ptr as usize,
            };
            match checker.check(&ctx) {
                Ok(crate::analysismode::VccOutcome::Violated { property }) => {
                    // SAFETY: as above.
                    let var_name = unsafe { c_str(name) };
                    if let Err(e) = state::with_state(|s| {
                        if s.result.ok {
                            let addr = ptr as usize;
                            let mut entry = MemTrackEntry::new(
                                0, line, scope, addr, addr, true, false, var_name, fname, 0, 1,
                                false,
                            );
                            entry.set_free();
                            s.failed_free = Some(entry.with_origin(MemOrigin::Free {
                                var_address: var_address as usize,
                            }));
                        }
                        Ok(())
                    }) {
                        log_error(&e);
                    }
                    record_violation(property, line, fname, false);
                }
                Ok(crate::analysismode::VccOutcome::Safe) => {}
                Err(e) => log_error(&e),
            }
        },
        (),
    );
}

/// Checks whether freeing an already-resolved heap `ptr` is valid — `ptr` is
/// the heap address itself (post-indirection), not the address of the
/// pointer variable that holds it (that case is `map2check_check_free`).
///
/// When the check passes, it also records the release (a free event for
/// `ptr`), as `map2check_free_resolved_address` of the Map2Check `develop` C
/// runtime does (`AnalysisModeMemtrack.c:178-182`). The pass uses this path
/// for `realloc` and for frees of a value that is not a load, so the caller
/// must not add `map2check_map_free`. Unlike this export,
/// `map2check_check_free` only checks; the pass calls `map2check_map_free`
/// after it. A NULL `ptr` is never recorded.
///
/// # Safety
/// `function_name` must be null or a valid null-terminated C string; `ptr` may be null.
#[no_mangle]
pub unsafe extern "C" fn map2check_check_free_resolved_address(
    ptr: *const std::os::raw::c_void,
    line: u32,
    function_name: *const std::os::raw::c_char,
    is_null_valid: i16,
) {
    ffi_guard(
        || {
            // SAFETY: caller guarantees function_name is valid or null.
            let fname = unsafe { c_str(function_name) };
            if ptr.is_null() && is_null_valid != 0 {
                return;
            }
            let ctx = VccContext::new(line, 0, fname);
            // An inactive check passes: the memcleanup mode never fails a
            // free but still records the release (AnalysisModeMemcleanup.c:160-179).
            let passed = !check_active(Check::FreeResolved)
                || run_vcc_check(
                    FreeResolvedChecker {
                        address: ptr as usize,
                    },
                    &ctx,
                    line,
                    fname,
                );
            if !passed || ptr.is_null() {
                return;
            }
            let addr = ptr as usize;
            if let Err(e) = state::with_state(|s| {
                let step = s.next_step();
                let mut entry = MemTrackEntry::new(
                    step, line, 0, addr, addr, true, false, "", fname, 0, 1, false,
                );
                entry.set_free();
                s.memtrack.push(entry.with_origin(MemOrigin::FreeResolved));
                Ok(())
            }) {
                log_error(&e);
            }
        },
        (),
    );
}

/// Checks whether dereferencing `ptr` is valid.
///
/// # Safety
/// `function_name` must be null or a valid null-terminated C string; `ptr` may be null.
#[no_mangle]
pub unsafe extern "C" fn map2check_check_deref(
    ptr: *const std::os::raw::c_void,
    scope: u32,
    line: u32,
    function_name: *const std::os::raw::c_char,
) {
    ffi_guard(
        || {
            if !check_active(Check::Deref) {
                return;
            }
            // SAFETY: caller guarantees function_name is valid or null.
            let fname = unsafe { c_str(function_name) };
            let ctx = VccContext::new(line, scope, fname);
            run_vcc_check(
                DerefChecker {
                    address: ptr as usize,
                },
                &ctx,
                line,
                fname,
            );
        },
        (),
    );
}

/// End-of-program verdict: runs `analysis_is_program_correct` of the selected
/// mode (`rust/src/analysismode/mode.rs`). Unset mode and memtrack report a
/// leak as `MemsafetyMemtrack`, or `MemsafetyMemcleanup` after
/// `map2check_set_memcleanup()`; memcleanup mode reports it as
/// `MemsafetyMemcleanup`; the other modes report nothing (SD-04). A violation
/// recorded earlier stays final (SD-03).
#[no_mangle]
pub extern "C" fn map2check_check_mem_endprog() {
    ffi_guard(
        || {
            let config = state::config();
            match state::with_state(|s| Ok(mode::analysis_is_program_correct(config, s))) {
                Ok(Some(property)) => record_violation(property, 0, "end_of_program", true),
                Ok(None) => {}
                Err(e) => log_error(&e),
            }
        },
        (),
    );
}

#[cfg(test)]
#[path = "ffi_tests.rs"]
mod tests;

#[cfg(test)]
#[path = "ffi_golden_tests.rs"]
mod golden_tests;
