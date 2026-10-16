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
use crate::analysismode::overflow::SubI32;
use crate::analysismode::overflow::SubU32;
use crate::analysismode::VccChecker;
use crate::analysismode::VccContext;
use crate::bbtrack::BasicBlockEntry;
use crate::caller::ViolatedProperty;
use crate::error::Map2CheckError;
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
        s.set_false(property, line, fname);
        Ok(first)
    }) {
        Ok(true) => termination::on_violation(end_of_program),
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

fn violated_property_from_raw(raw: i32) -> Option<ViolatedProperty> {
    match raw {
        0 => Some(ViolatedProperty::Overflow),
        1 => Some(ViolatedProperty::MemsafetyFree),
        2 => Some(ViolatedProperty::MemsafetyDeref),
        3 => Some(ViolatedProperty::MemsafetyMemtrack),
        4 => Some(ViolatedProperty::MemsafetyMemcleanup),
        5 => Some(ViolatedProperty::Reachability),
        6 => Some(ViolatedProperty::Concurrency),
        7 => Some(ViolatedProperty::None),
        8 => Some(ViolatedProperty::Assert),
        9 => Some(ViolatedProperty::Unknown),
        _ => None,
    }
}

/// Failure policy at the `extern "C"` boundary (issue #8).
///
/// Every `#[no_mangle]` export runs its body through this function
/// (enforced by `tests/ffi_guard_coverage.rs`).
///
/// - Unwinding profiles (`dev`, `release`, `runtime`; `panic = "unwind"`):
///   a panic is caught here with `catch_unwind`, a diagnostic is written to
///   stderr and `default` is returned, so no unwind ever reaches C.
/// - `panic = "abort"` builds (the future KLEE build): `catch_unwind` cannot
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

/// Initialises all containers. Must be called before any tracking function.
/// With an analysis mode set, also removes the property files
/// (`map2check_property*`) that an earlier run left in the current
/// directory, so they cannot be read as this run's verdict.
#[no_mangle]
pub extern "C" fn map2check_init() {
    ffi_guard(
        || {
            state::init();
            termination::on_init();
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

/// End of the analysed program. Prints the JSON report. With an analysis
/// mode set it is develop's `map2check_success()`
/// (`Map2CheckFunctions.c:67-70`, `:89-102`): writes `NONE` to
/// `map2check_property`, runs the end-of-program verdict of the mode, writes
/// the witness files when `map2check_enable_witness()` was called, and
/// returns; when the verdict is a violation it writes that property instead
/// and aborts. The JSON is printed after the verdict.
#[no_mangle]
pub extern "C" fn map2check_success() {
    ffi_guard(
        || {
            let print = |s: &state::AnalysisState| {
                if let Err(e) = output::print_json(s) {
                    log_error(&e);
                }
            };
            if !termination::on_success(print) {
                if let Err(e) = state::with_state(|s| output::print_json(s)) {
                    log_error(&e);
                }
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

/// Prints the full JSON report to stdout.
#[no_mangle]
pub extern "C" fn print_all_containers_as_json() {
    ffi_guard(
        || {
            if let Err(e) = state::with_state(|s| output::print_json(s)) {
                log_error(&e);
            }
        },
        (),
    );
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
    ($fn_name:ident, $variant:ident, $rust_ty:ty, $c_ty:ty, $field:ident) => {
        /// # Safety
        /// `value` must be null or point to a valid value of the expected type.
        /// `function_name` must be null or a valid null-terminated C string.
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
                    let raw_value = if value.is_null() {
                        <$c_ty>::default()
                    } else {
                        // SAFETY: caller guarantees value points to a valid value.
                        unsafe { *value }
                    };
                    match state::with_state(|s| {
                        let step = s.next_step();
                        s.nondets.push(NonDetEntry::new(
                            step,
                            line as u32,
                            scope as u32,
                            fname,
                            NonDetValue::$variant(raw_value as $rust_ty),
                        ));
                        let entry = Box::new(non_det_log_t {
                            tqe_next: std::ptr::null_mut(),
                            tqe_prev: std::ptr::null_mut(),
                            step: step as std::os::raw::c_long,
                            line,
                            scope,
                            type_var,
                            value: LegacyNonDetData { $field: value },
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

nondet_ffi!(map2check_save_nondet_log_int, Int, i32, i32, i);
nondet_ffi!(map2check_save_nondet_log_uint, UInt, u32, u32, u);
nondet_ffi!(
    map2check_save_nondet_log_long,
    Long,
    i64,
    std::os::raw::c_long,
    l
);
nondet_ffi!(
    map2check_save_nondet_log_char,
    Char,
    i8,
    std::os::raw::c_char,
    c
);
nondet_ffi!(map2check_save_nondet_log_float, Float, f32, f32, f);
nondet_ffi!(map2check_save_nondet_log_double, Double, f64, f64, d);

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
/// instead, as develop does.
///
/// # Safety
/// `ptr_address` may be null (null malloc result is valid C).
#[no_mangle]
pub unsafe extern "C" fn map2check_map_malloc(ptr_address: *const std::os::raw::c_void, size: i32) {
    ffi_guard(
        || {
            if size < 0 {
                return;
            }
            if malloc_returned_null(ptr_address) {
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
/// `UNKNOWN` instead, as develop's `map2check_calloc` does.
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
            if quantity < 0 || size < 0 {
                return;
            }
            if malloc_returned_null(ptr_address) {
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

/// # Safety
/// `var_name` and `function_name` must be null or valid null-terminated C strings.
#[no_mangle]
pub unsafe extern "C" fn map2check_map_free(
    var_name: *const std::os::raw::c_char,
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
                s.memtrack.push(entry.with_origin(MemOrigin::Free));
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
                    match state::with_state(|s| {
                        let first = s.result.ok;
                        s.set_false(property, line_number as u32, fname);
                        output::print_json(s)?;
                        Ok(first)
                    }) {
                        Ok(true) => termination::on_violation(false),
                        Ok(false) => {}
                        Err(e) => log_error(&e),
                    }
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

/// Checks whether freeing `ptr` is valid.
///
/// # Safety
/// `function_name` must be null or a valid null-terminated C string; `ptr` may be null.
#[no_mangle]
pub unsafe extern "C" fn map2check_check_free(
    _name: *const std::os::raw::c_char,
    ptr: *const std::os::raw::c_void,
    _scope: u32,
    line: u32,
    function_name: *const std::os::raw::c_char,
) {
    ffi_guard(
        || {
            if !check_active(Check::Free) {
                return;
            }
            // SAFETY: caller guarantees function_name is valid or null.
            let fname = unsafe { c_str(function_name) };
            let ctx = VccContext::new(line, 0, fname);
            run_vcc_check(
                FreeChecker {
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
