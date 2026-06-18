// SPDX-License-Identifier: GPL-3.0-only
//
// FFI boundary: #[unsafe(no_mangle)] extern "C" functions that Map2Check's LLVM Pass calls.
// This is the ONLY module that contains unsafe code.
// Every unsafe block is annotated with a SAFETY comment.

use std::ffi::CStr;

use crate::{
    analysismode::{
        assert::AssertChecker,
        memory::{DerefChecker, FreeChecker, LoadChecker, MemCleanupChecker},
        overflow::{
            AddI32, AddU32, DivI32, DivU32, MulI32, MulU32, NegI32, ShlI32, ShrI32, ShrU32,
            SubI32, SubU32,
        },
        VccChecker, VccContext,
    },
    bbtrack::BasicBlockEntry,
    caller::ViolatedProperty,
    memtrack::MemTrackEntry,
    nondet::{NonDetEntry, NonDetValue},
    output, state,
};

// ── Helpers ───────────────────────────────────────────────────────────────────

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

fn log_error(e: &crate::error::Map2CheckError) {
    eprintln!("[map2check] error: {e}");
}

fn run_vcc_check(checker: impl VccChecker, ctx: &VccContext, line: u32, fname: &str) {
    match checker.check(ctx) {
        Ok(crate::analysismode::VccOutcome::Violated { property }) => {
            if let Err(e) = state::with_state(|s| {
                s.set_false(property, line, fname);
                Ok(())
            }) {
                log_error(&e);
            }
        }
        Ok(crate::analysismode::VccOutcome::Safe) => {}
        Err(e) => log_error(&e),
    }
}

// ── Initialisation ────────────────────────────────────────────────────────────

/// Initialises all containers. Must be called before any tracking function.
#[unsafe(no_mangle)]
pub extern "C" fn map2check_init() {
    state::init();
}

// ── Result management ─────────────────────────────────────────────────────────

/// Records a verification success and prints the JSON report.
#[unsafe(no_mangle)]
pub extern "C" fn map2check_success() {
    if let Err(e) = state::with_state(|s| {
        s.result.ok = true;
        output::print_json(s)
    }) {
        log_error(&e);
    }
}

/// Records a verification failure.
///
/// # Safety
/// `function_name` must be null or a valid null-terminated C string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn set_false_result(
    prp: ViolatedProperty,
    line_number: i32,
    function_name: *const std::os::raw::c_char,
) {
    // SAFETY: caller guarantees function_name is a valid C string or null.
    let fname = unsafe { c_str(function_name) };
    if let Err(e) = state::with_state(|s| {
        s.set_false(prp, line_number as u32, fname);
        Ok(())
    }) {
        log_error(&e);
    }
}

/// Returns the currently violated property.
#[unsafe(no_mangle)]
pub extern "C" fn get_current_property() -> ViolatedProperty {
    state::with_state(|s| Ok(s.result.property)).unwrap_or(ViolatedProperty::None)
}

/// Returns the current step counter value.
#[unsafe(no_mangle)]
pub extern "C" fn get_current_step() -> u64 {
    state::with_state(|s| Ok(s.current_step())).unwrap_or(0)
}

/// Prints the full JSON report to stdout.
#[unsafe(no_mangle)]
pub extern "C" fn print_all_containers_as_json() {
    if let Err(e) = state::with_state(|s| output::print_json(s)) {
        log_error(&e);
    }
}

/// Resets violation metadata without clearing tracking containers.
#[unsafe(no_mangle)]
pub extern "C" fn vcc_reset_meta_data() {
    if let Err(e) = state::with_state(|s| {
        s.result.property = ViolatedProperty::None;
        s.result.ok = true;
        s.result.line = 0;
        s.result.function_name.clear();
        Ok(())
    }) {
        log_error(&e);
    }
}

/// Enables memcleanup checking at end of program.
#[unsafe(no_mangle)]
pub extern "C" fn map2check_set_memcleanup() {}

/// Marks NULL as valid for the current scope's pointer checks.
#[unsafe(no_mangle)]
pub extern "C" fn map2check_set_null_is_valid() {}

// ── NonDet tracking ───────────────────────────────────────────────────────────

macro_rules! nondet_ffi {
    ($fn_name:ident, $variant:ident, $rust_ty:ty, $c_ty:ty) => {
        /// # Safety
        /// `function_name` must be null or a valid null-terminated C string.
        #[unsafe(no_mangle)]
        pub unsafe extern "C" fn $fn_name(
            line: i32,
            scope: i32,
            value: $c_ty,
            function_name: *const std::os::raw::c_char,
        ) {
            // SAFETY: caller guarantees function_name is a valid C string or null.
            let fname = unsafe { c_str(function_name) };
            if let Err(e) = state::with_state(|s| {
                let step = s.next_step();
                s.nondets.push(NonDetEntry::new(
                    step,
                    line as u32,
                    scope as u32,
                    fname,
                    NonDetValue::$variant(value as $rust_ty),
                ));
                Ok(())
            }) {
                log_error(&e);
            }
        }
    };
}

nondet_ffi!(map2check_save_nondet_log_int,    Int,    i32, i32);
nondet_ffi!(map2check_save_nondet_log_uint,   UInt,   u32, u32);
nondet_ffi!(map2check_save_nondet_log_long,   Long,   i64, i64);
nondet_ffi!(map2check_save_nondet_log_char,   Char,   u8,  u8);
nondet_ffi!(map2check_save_nondet_log_float,  Float,  f32, f32);
nondet_ffi!(map2check_save_nondet_log_double, Double, f64, f64);

// ── Basic-block tracking ──────────────────────────────────────────────────────

/// Records execution of a basic block.
///
/// # Safety
/// `function_name` must be null or a valid null-terminated C string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn map2check_save_basic_block_log(
    line: i32,
    function_name: *const std::os::raw::c_char,
) {
    // SAFETY: caller guarantees function_name is a valid C string or null.
    let fname = unsafe { c_str(function_name) };
    if let Err(e) = state::with_state(|s| {
        let step = s.next_step();
        s.bbtrack.push(BasicBlockEntry::new(step, line as u32, fname));
        Ok(())
    }) {
        log_error(&e);
    }
}

/// Returns 1 if `line` was recorded as executed, 0 otherwise.
#[unsafe(no_mangle)]
pub extern "C" fn map2check_is_in_trackbb_container(line: i32) -> i32 {
    state::with_state(|s| {
        Ok(
            if crate::bbtrack::contains_line(&s.bbtrack, line as u32) {
                1
            } else {
                0
            },
        )
    })
    .unwrap_or(0)
}

// ── Memory tracking ───────────────────────────────────────────────────────────

/// # Safety
/// `var_name` must be null or a valid null-terminated C string; `ptr_address` may be null.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn map2check_map_alloca(
    var_name: *const std::os::raw::c_char,
    ptr_address: *const std::os::raw::c_void,
    size: i32,
    size_primitive: i32,
    line_number: i32,
    scope: i32,
) {
    // SAFETY: caller guarantees var_name is a valid C string or null.
    let name = unsafe { c_str(var_name) };
    let addr = ptr_address as usize;
    if let Err(e) = state::with_state(|s| {
        let step = s.next_step();
        s.memtrack.push(MemTrackEntry::new(
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
        ));
        Ok(())
    }) {
        log_error(&e);
    }
}

/// # Safety
/// `ptr_address` may be null (null malloc result is valid C).
#[unsafe(no_mangle)]
pub unsafe extern "C" fn map2check_map_malloc(
    ptr_address: *const std::os::raw::c_void,
    size: i32,
) {
    let addr = ptr_address as usize;
    if let Err(e) = state::with_state(|s| {
        let step = s.next_step();
        let mut entry = MemTrackEntry::new(
            step, 0, 0, addr, addr, false, false, "", "", size as usize, 1, false,
        );
        entry.set_malloc();
        s.memtrack.push(entry);
        Ok(())
    }) {
        log_error(&e);
    }
}

/// # Safety
/// `ptr_address` may be null.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn map2check_map_calloc(
    ptr_address: *const std::os::raw::c_void,
    quantity: i32,
    size: i32,
) {
    let addr = ptr_address as usize;
    if let Err(e) = state::with_state(|s| {
        let step = s.next_step();
        let mut entry = MemTrackEntry::new(
            step, 0, 0, addr, addr, false, false, "", "", size as usize, 1, false,
        );
        entry.set_calloc(quantity as usize);
        s.memtrack.push(entry);
        Ok(())
    }) {
        log_error(&e);
    }
}

/// # Safety
/// `var_name` and `function_name` must be null or valid null-terminated C strings.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn map2check_map_free(
    var_name: *const std::os::raw::c_char,
    ptr_address: *const std::os::raw::c_void,
    scope: u32,
    line_number: u32,
    function_name: *const std::os::raw::c_char,
) {
    // SAFETY: caller guarantees string pointers are valid or null.
    let name = unsafe { c_str(var_name) };
    let fname = unsafe { c_str(function_name) };
    let addr = ptr_address as usize;
    if let Err(e) = state::with_state(|s| {
        let step = s.next_step();
        let mut entry = MemTrackEntry::new(
            step, line_number, scope, addr, addr, true, false, name, fname, 0, 1, false,
        );
        entry.set_free();
        s.memtrack.push(entry);
        Ok(())
    }) {
        log_error(&e);
    }
}

/// # Safety
/// `var_name` and `funct_name` must be null or valid null-terminated C strings.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn map2check_map_store_pointer(
    var_address: *const std::os::raw::c_void,
    value: *const std::os::raw::c_void,
    scope: u32,
    var_name: *const std::os::raw::c_char,
    line_number: i32,
    funct_name: *const std::os::raw::c_char,
) {
    // SAFETY: caller guarantees string pointers are valid or null.
    let name = unsafe { c_str(var_name) };
    let fname = unsafe { c_str(funct_name) };
    let var_addr = var_address as usize;
    let points_to = value as usize;
    if let Err(e) = state::with_state(|s| {
        let step = s.next_step();
        s.memtrack.push(MemTrackEntry::new(
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
        ));
        Ok(())
    }) {
        log_error(&e);
    }
}

// ── Analysis mode: assert ─────────────────────────────────────────────────────

/// Checks a user-defined assert expression.
///
/// # Safety
/// `function_name` must be null or a valid null-terminated C string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn map2check_is_valid_assert(
    line_number: i32,
    function_name: *const std::os::raw::c_char,
    expression: i32,
) {
    // SAFETY: caller guarantees function_name is a valid C string or null.
    let fname = unsafe { c_str(function_name) };
    let ctx = VccContext::new(line_number as u32, 0, fname);
    let checker = AssertChecker { expression };
    match checker.check(&ctx) {
        Ok(crate::analysismode::VccOutcome::Violated { property }) => {
            if let Err(e) = state::with_state(|s| {
                s.set_false(property, line_number as u32, fname);
                output::print_json(s)
            }) {
                log_error(&e);
            }
        }
        Ok(crate::analysismode::VccOutcome::Safe) => {}
        Err(e) => log_error(&e),
    }
}

// ── Analysis mode: overflow ───────────────────────────────────────────────────

macro_rules! overflow_ffi_binop {
    ($fn_name:ident, $checker:ident, $ty:ty) => {
        /// # Safety
        /// `function_name` must be null or a valid null-terminated C string.
        #[unsafe(no_mangle)]
        pub unsafe extern "C" fn $fn_name(
            param1: $ty,
            param2: $ty,
            line: u32,
            scope: u32,
            function_name: *const std::os::raw::c_char,
        ) {
            // SAFETY: caller guarantees function_name is valid or null.
            let fname = unsafe { c_str(function_name) };
            let ctx = VccContext::new(line, scope, fname);
            run_vcc_check($checker { lhs: param1, rhs: param2 }, &ctx, line, fname);
        }
    };
}

macro_rules! overflow_ffi_shift {
    ($fn_name:ident, $checker:ident, $ty:ty) => {
        /// # Safety
        /// `function_name` must be null or a valid null-terminated C string.
        #[unsafe(no_mangle)]
        pub unsafe extern "C" fn $fn_name(
            param1: $ty,
            param2: u32,
            line: u32,
            scope: u32,
            function_name: *const std::os::raw::c_char,
        ) {
            // SAFETY: caller guarantees function_name is valid or null.
            let fname = unsafe { c_str(function_name) };
            let ctx = VccContext::new(line, scope, fname);
            run_vcc_check($checker { lhs: param1, rhs: param2 }, &ctx, line, fname);
        }
    };
}

/// # Safety
/// `function_name` must be null or a valid null-terminated C string.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn map2check_binop_neg_int(
    param1: i32,
    line: u32,
    scope: u32,
    function_name: *const std::os::raw::c_char,
) {
    // SAFETY: caller guarantees function_name is valid or null.
    let fname = unsafe { c_str(function_name) };
    let ctx = VccContext::new(line, scope, fname);
    run_vcc_check(NegI32 { val: param1 }, &ctx, line, fname);
}

overflow_ffi_binop!(map2check_binop_add_int,      AddI32, i32);
overflow_ffi_binop!(map2check_binop_sub_int,      SubI32, i32);
overflow_ffi_binop!(map2check_binop_mul_int,      MulI32, i32);
overflow_ffi_binop!(map2check_binop_div_int,      DivI32, i32);
overflow_ffi_binop!(map2check_binop_add_unsigned, AddU32, u32);
overflow_ffi_binop!(map2check_binop_sub_unsigned, SubU32, u32);
overflow_ffi_binop!(map2check_binop_mul_unsigned, MulU32, u32);
overflow_ffi_binop!(map2check_binop_div_unsigned, DivU32, u32);
overflow_ffi_shift!(map2check_binop_shl_int,      ShlI32, i32);
overflow_ffi_shift!(map2check_binop_shr_int,      ShrI32, i32);
overflow_ffi_shift!(map2check_binop_shr_unsigned, ShrU32, u32);

// ── Analysis mode: memory ─────────────────────────────────────────────────────

/// Checks whether loading from `ptr` is valid.
///
/// # Safety
/// `function_name` must be null or a valid null-terminated C string; `ptr` may be null.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn map2check_check_load(
    ptr: *const std::os::raw::c_void,
    line: i32,
    scope: u32,
    size: i32,
    function_name: *const std::os::raw::c_char,
) {
    // SAFETY: caller guarantees function_name is valid or null.
    let fname = unsafe { c_str(function_name) };
    let ctx = VccContext::new(line as u32, scope, fname);
    run_vcc_check(
        LoadChecker { address: ptr as usize, size: size as usize, is_null_valid: false },
        &ctx,
        line as u32,
        fname,
    );
}

/// Checks whether freeing `ptr` is valid.
///
/// # Safety
/// `function_name` must be null or a valid null-terminated C string; `ptr` may be null.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn map2check_check_free(
    _name: *const std::os::raw::c_char,
    ptr: *const std::os::raw::c_void,
    _scope: u32,
    line: u32,
    function_name: *const std::os::raw::c_char,
) {
    // SAFETY: caller guarantees function_name is valid or null.
    let fname = unsafe { c_str(function_name) };
    let ctx = VccContext::new(line, 0, fname);
    run_vcc_check(FreeChecker { address: ptr as usize }, &ctx, line, fname);
}

/// Checks whether dereferencing `ptr` is valid.
///
/// # Safety
/// `function_name` must be null or a valid null-terminated C string; `ptr` may be null.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn map2check_check_deref(
    ptr: *const std::os::raw::c_void,
    scope: u32,
    line: u32,
    function_name: *const std::os::raw::c_char,
) {
    // SAFETY: caller guarantees function_name is valid or null.
    let fname = unsafe { c_str(function_name) };
    let ctx = VccContext::new(line, scope, fname);
    run_vcc_check(DerefChecker { address: ptr as usize }, &ctx, line, fname);
}

/// Checks for memory leaks at end of program.
#[unsafe(no_mangle)]
pub extern "C" fn map2check_check_mem_endprog() {
    let ctx = VccContext::new(0, 0, "end_of_program");
    run_vcc_check(MemCleanupChecker, &ctx, 0, "end_of_program");
}
