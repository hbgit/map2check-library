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
use crate::analysismode::memory::LoadChecker;
use crate::analysismode::memory::MemCleanupChecker;
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
use crate::memtrack::MemTrackEntry;
use crate::nondet::NonDetEntry;
use crate::nondet::NonDetValue;
use crate::output;
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

fn reset_result_metadata() {
    if let Err(e) = state::with_state(|s| {
        s.result.ok = true;
        s.result.property = ViolatedProperty::None;
        s.result.line = 0;
        s.result.function_name.clear();
        Ok(())
    }) {
        log_error(&e);
    }
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
        _ => None,
    }
}

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
#[no_mangle]
pub extern "C" fn map2check_init() {
    ffi_guard(state::init, ());
}

/// Resets the global analysis state without aborting the caller.
#[no_mangle]
pub extern "C" fn map2check_reset() {
    ffi_guard(state::reset, ());
}

// ── Result management ─────────────────────────────────────────────────────────

/// Records a verification success and prints the JSON report.
#[no_mangle]
pub extern "C" fn map2check_success() {
    ffi_guard(
        || {
            if let Err(e) = state::with_state(|s| output::print_json(s)) {
                log_error(&e);
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
            if let Err(e) = state::with_state(|s| {
                s.set_false(property, line_number as u32, fname);
                Ok(())
            }) {
                log_error(&e);
            }
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

/// Enables memcleanup checking at end of program.
#[no_mangle]
pub extern "C" fn map2check_set_memcleanup() {
    ffi_guard(
        || {
            if let Err(e) = state::with_state(|s| {
                s.memcleanup_enabled = true;
                Ok(())
            }) {
                log_error(&e);
            }
        },
        (),
    );
}

/// Marks NULL as valid for the current scope's pointer checks.
#[no_mangle]
pub extern "C" fn map2check_set_null_is_valid() {
    ffi_guard(
        || {
            if let Err(e) = state::with_state(|s| {
                s.null_is_valid = true;
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
    u8,
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
        },
        (),
    );
}

/// Records a non-static stack allocation.
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
        || unsafe {
            map2check_map_alloca(
                var_name,
                ptr_address,
                size,
                size_primitive,
                line_number,
                scope,
            )
        },
        (),
    );
}

/// Records a function address.
///
/// # Safety
/// `var_name` must be null or a valid null-terminated C string.
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
            if let Err(e) = state::with_state(|s| {
                let step = s.next_step();
                s.memtrack.push(MemTrackEntry::new(
                    step, 0, 0, addr, 0, false, false, name, "", 0, 0, false,
                ));
                Ok(())
            }) {
                log_error(&e);
            }
        },
        (),
    );
}

/// # Safety
/// `ptr_address` may be null (null malloc result is valid C).
#[no_mangle]
pub unsafe extern "C" fn map2check_map_malloc(ptr_address: *const std::os::raw::c_void, size: i32) {
    ffi_guard(
        || {
            if size < 0 {
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
                s.memtrack.push(entry);
                Ok(())
            }) {
                log_error(&e);
            }
        },
        (),
    );
}

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
                s.memtrack.push(entry);
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
                s.memtrack.push(entry);
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
            reset_result_metadata();
            // SAFETY: caller guarantees function_name is valid or null.
            let fname = unsafe { c_str(function_name) };
            if size < 0 {
                if let Err(e) = state::with_state(|s| {
                    s.set_false(ViolatedProperty::MemsafetyDeref, line as u32, fname);
                    Ok(())
                }) {
                    log_error(&e);
                }
                return;
            }
            let is_null_valid = state::with_state(|s| Ok(s.null_is_valid)).unwrap_or(false);
            let ctx = VccContext::new(line as u32, scope, fname);
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
            reset_result_metadata();
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

/// Checks whether freeing a resolved address is valid.
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
            reset_result_metadata();
            // SAFETY: caller guarantees function_name is valid or null.
            let fname = unsafe { c_str(function_name) };
            if ptr.is_null() && is_null_valid != 0 {
                return;
            }
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
            reset_result_metadata();
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

/// Checks for memory leaks at end of program.
#[no_mangle]
pub extern "C" fn map2check_check_mem_endprog() {
    ffi_guard(
        || {
            reset_result_metadata();
            if !state::with_state(|s| Ok(s.memcleanup_enabled)).unwrap_or(false) {
                return;
            }
            let ctx = VccContext::new(0, 0, "end_of_program");
            run_vcc_check(MemCleanupChecker, &ctx, 0, "end_of_program");
        },
        (),
    );
}
