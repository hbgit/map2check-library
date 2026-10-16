// SPDX-License-Identifier: GPL-3.0-only
//
// Unit tests for every `extern "C"` export of `ffi.rs` (issue #29).
// Each test calls the export the way the C side would and checks its effect
// on the global `AnalysisState`. `tests/ffi_exports_checklist.rs` fails when
// a symbol of `include/map2check.h` is not called from this file.

use super::*;
use crate::state::{self, AnalysisState};
use std::os::raw::c_void;
use std::sync::MutexGuard;

/// Takes the global test lock and starts from an empty analysis state.
fn fresh() -> MutexGuard<'static, ()> {
    let guard = state::test_lock();
    state::reset();
    state::reset_config();
    guard
}

/// Reads a value out of the global state.
fn snapshot<R>(f: impl FnOnce(&AnalysisState) -> R) -> R {
    state::with_state(|s| Ok(f(s))).unwrap()
}

/// A fake address: the library only stores and compares addresses, it never
/// dereferences them.
fn addr(a: usize) -> *const c_void {
    a as *const c_void
}

fn assert_ok() {
    let (ok, property) = snapshot(|s| (s.result.ok, s.result.property));
    assert!(ok, "esperava resultado ok, veio {property:?}");
    assert_eq!(property, ViolatedProperty::None);
}

fn assert_violated(property: ViolatedProperty, line: u32, function_name: &str) {
    let result = snapshot(|s| s.result.clone());
    assert!(!result.ok, "esperava violação {property:?}");
    assert_eq!(result.property, property);
    assert_eq!(result.line, line);
    assert_eq!(result.function_name, function_name);
}

// ── Initialisation ──────────────────────────────────────────────────────────

#[test]
fn init_leaves_state_empty_and_ok() {
    let _guard = fresh();
    map2check_init();
    assert_ok();
    assert_eq!(snapshot(|s| s.current_step()), 0);
    assert!(snapshot(|s| s.memtrack.is_empty()
        && s.nondets.is_empty()
        && s.bbtrack.is_empty()));
}

#[test]
fn second_init_starts_from_clean_state() {
    let _guard = fresh();
    map2check_init();
    // SAFETY: fake addresses are only stored, never dereferenced.
    unsafe { map2check_map_malloc(addr(0x1000), 8) };
    // SAFETY: C-string literal is valid and null-terminated.
    unsafe { set_false_result(5, 7, c"main".as_ptr()) };
    map2check_set_memcleanup();
    map2check_set_null_is_valid();
    let mut value: i32 = 3;
    // SAFETY: `value` outlives the call; the name is a valid C string.
    unsafe { map2check_save_nondet_log_int(1, 0, 0, &mut value, c"main".as_ptr()) };
    let _ = get_next_step();
    assert!(snapshot(|s| s.current_step() > 0 && !s.nondets.is_empty()));

    map2check_init();

    assert_ok();
    snapshot(|s| {
        assert_eq!(s.current_step(), 0);
        assert!(s.memtrack.is_empty());
        assert!(s.nondets.is_empty());
        assert!(s.bbtrack.is_empty());
        assert!(s.legacy_nondet_logs.is_empty());
        assert_eq!(s.result.line, 0);
        assert!(s.result.function_name.is_empty());
    });
}

#[test]
fn reset_clears_records_result_step_and_flags() {
    let _guard = fresh();
    // SAFETY: null pointer is a valid malloc result.
    unsafe { map2check_map_malloc(addr(0x1000), 16) };
    // SAFETY: C-string literal is valid and null-terminated.
    unsafe { set_false_result(5, 7, c"main".as_ptr()) };
    map2check_set_memcleanup();
    map2check_set_null_is_valid();

    map2check_reset();

    assert_ok();
    snapshot(|s| {
        assert_eq!(s.current_step(), 0);
        assert!(s.memtrack.is_empty());
    });
}

// ── Result management ───────────────────────────────────────────────────────

#[test]
fn success_does_not_change_state() {
    let _guard = fresh();
    // SAFETY: fake address is never dereferenced.
    unsafe { map2check_map_malloc(addr(0x1000), 16) };
    map2check_success();
    assert_ok();
    assert_eq!(snapshot(|s| s.memtrack.len()), 1);
}

#[test]
fn set_false_result_records_property_line_and_function() {
    let _guard = fresh();
    // SAFETY: C-string literal is valid and null-terminated.
    unsafe { set_false_result(5, 42, c"main".as_ptr()) };
    assert_violated(ViolatedProperty::Reachability, 42, "main");
}

#[test]
fn set_false_result_ignores_unknown_property() {
    let _guard = fresh();
    // SAFETY: C-string literal is valid and null-terminated.
    unsafe { set_false_result(99, 42, c"main".as_ptr()) };
    assert_ok();
}

#[test]
fn set_false_result_accepts_null_function_name() {
    let _guard = fresh();
    // SAFETY: null is an accepted function_name.
    unsafe { set_false_result(0, 3, std::ptr::null()) };
    assert_violated(ViolatedProperty::Overflow, 3, "");
}

#[test]
fn get_current_property_reflects_last_violation() {
    let _guard = fresh();
    assert_eq!(get_current_property(), ViolatedProperty::None);
    // SAFETY: C-string literal is valid and null-terminated.
    unsafe { set_false_result(2, 1, c"f".as_ptr()) };
    assert_eq!(get_current_property(), ViolatedProperty::MemsafetyDeref);
}

#[test]
fn get_current_step_reads_without_advancing() {
    let _guard = fresh();
    assert_eq!(get_current_step(), 0);
    // SAFETY: fake address is never dereferenced.
    unsafe { map2check_map_malloc(addr(0x1000), 8) };
    assert_eq!(get_current_step(), 1);
    assert_eq!(get_current_step(), 1);
}

#[test]
fn get_next_step_advances_the_counter() {
    let _guard = fresh();
    assert_eq!(get_next_step(), 1);
    assert_eq!(get_next_step(), 2);
    assert_eq!(snapshot(|s| s.current_step()), 2);
}

#[test]
fn print_all_containers_as_json_does_not_change_state() {
    let _guard = fresh();
    // SAFETY: C-string literal is valid and null-terminated.
    unsafe { map2check_save_basic_block_log(3, c"main".as_ptr()) };
    print_all_containers_as_json();
    assert_ok();
    assert_eq!(snapshot(|s| s.bbtrack.len()), 1);
}

#[test]
fn vcc_reset_meta_data_clears_result_but_keeps_records() {
    let _guard = fresh();
    // SAFETY: fake address is never dereferenced.
    unsafe { map2check_map_malloc(addr(0x1000), 8) };
    // SAFETY: C-string literal is valid and null-terminated.
    unsafe { set_false_result(1, 9, c"main".as_ptr()) };

    vcc_reset_meta_data();

    let result = snapshot(|s| s.result.clone());
    assert!(result.ok);
    assert_eq!(result.property, ViolatedProperty::None);
    assert_eq!(result.line, 0);
    assert!(result.function_name.is_empty());
    assert_eq!(result.step, 1, "o contador de passos não é zerado");
    assert_eq!(snapshot(|s| s.memtrack.len()), 1);
}

#[test]
fn set_memcleanup_enables_end_of_program_check() {
    let _guard = fresh();
    assert!(!state::config().memcleanup);
    map2check_set_memcleanup();
    assert!(state::config().memcleanup);
}

#[test]
fn set_null_is_valid_sets_the_flag() {
    let _guard = fresh();
    assert!(!state::config().null_is_valid);
    map2check_set_null_is_valid();
    assert!(state::config().null_is_valid);
}

// ── NonDet tracking ─────────────────────────────────────────────────────────

/// Checks the single nondet record and the legacy C record returned for it.
fn assert_nondet(record: *mut non_det_log_t, expected: NonDetValue) {
    assert!(!record.is_null());
    // SAFETY: the record is owned by the global state, which no one resets
    // while the test lock is held.
    let legacy = unsafe { &*record };
    assert_eq!(legacy.step, 1);
    assert_eq!(legacy.line, 10);
    assert_eq!(legacy.scope, 2);
    snapshot(|s| {
        assert_eq!(s.nondets.len(), 1);
        let entry = &s.nondets[0];
        assert_eq!(entry.step, 1);
        assert_eq!(entry.line, 10);
        assert_eq!(entry.scope, 2);
        assert_eq!(entry.function_name, "f");
        assert_eq!(entry.value, expected);
        assert_eq!(s.legacy_nondet_logs.len(), 1);
    });
}

#[test]
fn save_nondet_log_int_records_value() {
    let _guard = fresh();
    let mut value: i32 = -7;
    // SAFETY: value and the C-string literal outlive the call.
    let record = unsafe { map2check_save_nondet_log_int(10, 2, 0, &mut value, c"f".as_ptr()) };
    assert_nondet(record, NonDetValue::Int(-7));
}

#[test]
fn save_nondet_log_int_with_null_value_records_zero() {
    let _guard = fresh();
    // SAFETY: null value is accepted; the C-string literal outlives the call.
    let record =
        unsafe { map2check_save_nondet_log_int(10, 2, 0, std::ptr::null_mut(), c"f".as_ptr()) };
    assert_nondet(record, NonDetValue::Int(0));
}

#[test]
fn save_nondet_log_uint_records_value() {
    let _guard = fresh();
    let mut value: u32 = u32::MAX;
    // SAFETY: value and the C-string literal outlive the call.
    let record = unsafe { map2check_save_nondet_log_uint(10, 2, 1, &mut value, c"f".as_ptr()) };
    assert_nondet(record, NonDetValue::UInt(u32::MAX));
}

#[test]
fn save_nondet_log_long_records_value() {
    let _guard = fresh();
    let mut value: std::os::raw::c_long = -5;
    // SAFETY: value and the C-string literal outlive the call.
    let record = unsafe { map2check_save_nondet_log_long(10, 2, 2, &mut value, c"f".as_ptr()) };
    assert_nondet(record, NonDetValue::Long(-5));
}

#[test]
fn save_nondet_log_char_records_value() {
    let _guard = fresh();
    // 65 ('A') fits both signed and unsigned `c_char` (aarch64 uses u8).
    let mut value: std::os::raw::c_char = 65;
    // SAFETY: value and the C-string literal outlive the call.
    let record = unsafe { map2check_save_nondet_log_char(10, 2, 3, &mut value, c"f".as_ptr()) };
    assert_nondet(record, NonDetValue::Char(65));
}

#[test]
fn save_nondet_log_float_records_value() {
    let _guard = fresh();
    let mut value: f32 = 1.5;
    // SAFETY: value and the C-string literal outlive the call.
    let record = unsafe { map2check_save_nondet_log_float(10, 2, 4, &mut value, c"f".as_ptr()) };
    assert_nondet(record, NonDetValue::Float(1.5));
}

#[test]
fn save_nondet_log_double_records_value() {
    let _guard = fresh();
    let mut value: f64 = -2.25;
    // SAFETY: value and the C-string literal outlive the call.
    let record = unsafe { map2check_save_nondet_log_double(10, 2, 5, &mut value, c"f".as_ptr()) };
    assert_nondet(record, NonDetValue::Double(-2.25));
}

// ── Basic-block tracking ────────────────────────────────────────────────────

#[test]
fn save_basic_block_log_records_block() {
    let _guard = fresh();
    // SAFETY: C-string literal is valid and null-terminated.
    let record = unsafe { map2check_save_basic_block_log(7, c"main".as_ptr()) };
    assert!(!record.is_null());
    // SAFETY: the record is owned by the global state, kept alive under the lock.
    let legacy = unsafe { &*record };
    assert_eq!((legacy.step, legacy.line), (1, 7));
    snapshot(|s| {
        assert_eq!(s.bbtrack.len(), 1);
        assert_eq!(s.bbtrack[0].step, 1);
        assert_eq!(s.bbtrack[0].line, 7);
        assert_eq!(s.bbtrack[0].function_name, "main");
    });
}

#[test]
fn legacy_records_are_returned_unlinked() {
    let _guard = fresh();
    let mut value: i32 = 1;
    // SAFETY: C-string literals are valid; `value` outlives the calls.
    let (bb1, bb2, nd) = unsafe {
        (
            map2check_save_basic_block_log(1, c"main".as_ptr()),
            map2check_save_basic_block_log(2, c"main".as_ptr()),
            map2check_save_nondet_log_int(3, 0, 0, &mut value, c"main".as_ptr()),
        )
    };
    // SAFETY: the records are owned by the global state, kept alive under the lock.
    let (bb1, bb2, nd) = unsafe { (&*bb1, &*bb2, &*nd) };
    for (next, prev) in [
        (bb1.tqe_next.is_null(), bb1.tqe_prev.is_null()),
        (bb2.tqe_next.is_null(), bb2.tqe_prev.is_null()),
        (nd.tqe_next.is_null(), nd.tqe_prev.is_null()),
    ] {
        assert!(next && prev, "registro legado ligado a uma lista");
    }
    assert_eq!((bb1.step, bb2.step, nd.step), (1, 2, 3));
}

#[test]
fn is_in_trackbb_container_reports_recorded_lines() {
    let _guard = fresh();
    assert_eq!(map2check_is_in_trackbb_container(7), 0);
    // SAFETY: C-string literal is valid and null-terminated.
    unsafe { map2check_save_basic_block_log(7, c"main".as_ptr()) };
    assert_eq!(map2check_is_in_trackbb_container(7), 1);
    assert_eq!(map2check_is_in_trackbb_container(8), 0);
}

// ── Memory tracking ─────────────────────────────────────────────────────────

/// Returns the only memtrack record, failing if there is not exactly one.
fn only_memtrack() -> crate::memtrack::MemTrackEntry {
    snapshot(|s| {
        assert_eq!(s.memtrack.len(), 1, "esperava exatamente um registro");
        s.memtrack[0].clone()
    })
}

#[test]
fn map_alloca_records_static_stack_slot() {
    let _guard = fresh();
    // SAFETY: C-string literal is valid; fake address is never dereferenced.
    unsafe { map2check_map_alloca(c"x".as_ptr(), addr(0x2000), 8, 4, 3, 1) };
    let e = only_memtrack();
    assert_eq!((e.step, e.line, e.scope), (1, 3, 1));
    assert_eq!((e.var_addr, e.points_to), (0x2000, 0x2000));
    assert_eq!((e.size_destiny, e.size_primitive), (8, 4));
    assert_eq!(e.ptr_name, "x");
    assert!(!e.is_dynamic && !e.is_free);
}

#[test]
fn map_alloca_ignores_negative_size() {
    let _guard = fresh();
    // SAFETY: C-string literal is valid; fake address is never dereferenced.
    unsafe { map2check_map_alloca(c"x".as_ptr(), addr(0x2000), -1, 4, 3, 1) };
    assert!(snapshot(|s| s.memtrack.is_empty()));
}

#[test]
fn map_non_static_alloca_records_static_slot_of_elements_times_primitive() {
    // develop: `map2check_non_static_alloca` calls `map2check_alloca` with
    // `size * size_of_primitive` (AnalysisModeMemtrack.c:368-372).
    let _guard = fresh();
    // SAFETY: C-string literal is valid; fake address is never dereferenced.
    unsafe { map2check_map_non_static_alloca(c"vla".as_ptr(), addr(0x2000), 10, 4, 5, 2) };
    let e = only_memtrack();
    assert_eq!((e.line, e.scope), (5, 2));
    assert_eq!((e.size_destiny, e.size_primitive), (40, 4));
    assert_eq!((e.var_addr, e.points_to), (0x2000, 0x2000));
    assert_eq!(e.ptr_name, "vla");
    assert!(!e.is_dynamic && !e.is_free);
}

#[test]
fn sd12_vla_is_not_a_leak_and_size_is_elements() {
    // SD-12 / #38: a VLA is a static slot (never a leak) and `size` is an
    // element count multiplied by `size_primitive`.
    let _guard = fresh();
    // SAFETY: C-string literals are valid; fake addresses are never dereferenced.
    unsafe { map2check_map_non_static_alloca(c"vla".as_ptr(), addr(0x2000), 4, 4, 3, 0) };
    map2check_set_memcleanup();
    map2check_check_mem_endprog();
    assert_ok();

    state::reset();
    // SAFETY: as above.
    unsafe {
        map2check_map_non_static_alloca(c"vla".as_ptr(), addr(0x2000), 4, 4, 3, 0);
        map2check_check_load(addr(0x2008), 4, 0, 4, c"main".as_ptr());
        map2check_check_load(addr(0x200c), 4, 0, 4, c"main".as_ptr());
    }
    assert_ok();
    // SAFETY: as above.
    unsafe { map2check_check_load(addr(0x2010), 5, 0, 4, c"main".as_ptr()) };
    assert_violated(ViolatedProperty::MemsafetyDeref, 5, "main");
}

#[test]
fn map_non_static_alloca_ignores_negative_or_overflowing_size() {
    let _guard = fresh();
    // SAFETY: C-string literals are valid; fake address is never dereferenced.
    unsafe {
        map2check_map_non_static_alloca(c"vla".as_ptr(), addr(0x2000), -1, 4, 3, 0);
        map2check_map_non_static_alloca(c"vla".as_ptr(), addr(0x2000), 4, -4, 3, 0);
    }
    assert!(snapshot(|s| s.memtrack.is_empty()));
    if usize::BITS == 32 {
        // SAFETY: as above.
        unsafe {
            map2check_map_non_static_alloca(c"vla".as_ptr(), addr(0x2000), i32::MAX, 4, 3, 0)
        };
        assert!(snapshot(|s| s.memtrack.is_empty()));
    }
}

#[test]
fn map_funct_address_records_pointer_sized_slot() {
    let _guard = fresh();
    // SAFETY: C-string literal is valid; fake address is never dereferenced.
    unsafe { map2check_map_funct_address(c"foo".as_ptr(), addr(0x4000)) };
    let e = only_memtrack();
    let width = std::mem::size_of::<*const c_void>();
    assert_eq!((e.var_addr, e.points_to), (0x4000, 0x4000));
    assert_eq!((e.size_destiny, e.size_primitive), (width, width));
    assert_eq!(e.ptr_name, "foo");
    assert!(!e.is_dynamic && !e.is_free);
}

#[test]
fn map_malloc_records_heap_allocation() {
    let _guard = fresh();
    // SAFETY: fake address is never dereferenced.
    unsafe { map2check_map_malloc(addr(0x1000), 16) };
    let e = only_memtrack();
    assert_eq!(
        (e.points_to, e.size_destiny, e.size_primitive),
        (0x1000, 16, 1)
    );
    assert!(e.is_dynamic && !e.is_free);
}

#[test]
fn map_malloc_ignores_negative_size() {
    let _guard = fresh();
    // SAFETY: fake address is never dereferenced.
    unsafe { map2check_map_malloc(addr(0x1000), -16) };
    assert!(snapshot(|s| s.memtrack.is_empty()));
}

#[test]
fn map_calloc_records_quantity_times_size() {
    let _guard = fresh();
    // SAFETY: fake address is never dereferenced.
    unsafe { map2check_map_calloc(addr(0x1000), 4, 8) };
    let e = only_memtrack();
    assert_eq!((e.points_to, e.size_destiny), (0x1000, 32));
    assert!(e.is_dynamic && !e.is_free);
}

#[test]
fn map_calloc_ignores_negative_arguments() {
    let _guard = fresh();
    // SAFETY: fake address is never dereferenced.
    unsafe {
        map2check_map_calloc(addr(0x1000), -1, 8);
        map2check_map_calloc(addr(0x1000), 4, -8);
    }
    assert!(snapshot(|s| s.memtrack.is_empty()));
}

#[test]
fn map_free_records_released_slot() {
    let _guard = fresh();
    // SAFETY: C-string literals are valid; fake address is never dereferenced.
    unsafe { map2check_map_free(c"p".as_ptr(), addr(0x1000), 1, 9, c"main".as_ptr()) };
    let e = only_memtrack();
    assert_eq!(
        (e.line, e.scope, e.var_addr, e.size_destiny),
        (9, 1, 0x1000, 0)
    );
    assert_eq!(
        (e.ptr_name.as_str(), e.function_name.as_str()),
        ("p", "main")
    );
    assert!(e.is_free && !e.is_dynamic);
}

#[test]
fn map_store_pointer_records_points_to() {
    let _guard = fresh();
    // SAFETY: C-string literals are valid; fake addresses are never dereferenced.
    unsafe {
        map2check_map_store_pointer(
            addr(0x3000),
            addr(0x1000),
            2,
            c"p".as_ptr(),
            11,
            c"main".as_ptr(),
        )
    };
    let e = only_memtrack();
    assert_eq!((e.var_addr, e.points_to), (0x3000, 0x1000));
    assert_eq!((e.line, e.scope, e.size_destiny), (11, 2, 0));
    assert_eq!(
        (e.ptr_name.as_str(), e.function_name.as_str()),
        ("p", "main")
    );
    assert!(!e.is_dynamic && !e.is_free);
}

// ── Analysis mode: assert ───────────────────────────────────────────────────

#[test]
fn is_valid_assert_true_keeps_result_ok() {
    let _guard = fresh();
    // SAFETY: C-string literal is valid and null-terminated.
    unsafe { map2check_is_valid_assert(5, c"main".as_ptr(), 1) };
    assert_ok();
}

#[test]
fn is_valid_assert_false_reports_assert() {
    // develop: map2check_assert writes ASSERT (AnalysisModeAssert.c:18-23),
    // not TARGET-REACHED (Task 2.3).
    let _guard = fresh();
    // SAFETY: C-string literal is valid and null-terminated.
    unsafe { map2check_is_valid_assert(5, c"main".as_ptr(), 0) };
    assert_violated(ViolatedProperty::Assert, 5, "main");
}

// ── Analysis mode: overflow ─────────────────────────────────────────────────

/// Runs `op` once with operands that must be safe and once with operands that
/// must overflow, starting from a fresh state each time.
fn check_overflow_pair(safe: impl FnOnce(), overflowing: impl FnOnce()) {
    state::reset();
    safe();
    assert_ok();
    state::reset();
    overflowing();
    assert_violated(ViolatedProperty::Overflow, 4, "f");
}

#[test]
fn binop_add_int_detects_overflow() {
    let _guard = fresh();
    // SAFETY (all calls below): C-string literal is valid and null-terminated.
    check_overflow_pair(
        || unsafe { map2check_binop_add_int(1, 2, 4, 0, c"f".as_ptr()) },
        || unsafe { map2check_binop_add_int(i32::MAX, 1, 4, 0, c"f".as_ptr()) },
    );
}

#[test]
fn binop_sub_int_detects_overflow() {
    let _guard = fresh();
    // SAFETY (all calls below): C-string literal is valid and null-terminated.
    check_overflow_pair(
        || unsafe { map2check_binop_sub_int(5, 3, 4, 0, c"f".as_ptr()) },
        || unsafe { map2check_binop_sub_int(i32::MIN, 1, 4, 0, c"f".as_ptr()) },
    );
}

#[test]
fn binop_mul_int_detects_overflow() {
    let _guard = fresh();
    // SAFETY (all calls below): C-string literal is valid and null-terminated.
    check_overflow_pair(
        || unsafe { map2check_binop_mul_int(6, 7, 4, 0, c"f".as_ptr()) },
        || unsafe { map2check_binop_mul_int(i32::MAX, 2, 4, 0, c"f".as_ptr()) },
    );
}

#[test]
fn binop_div_int_detects_min_over_minus_one_and_zero_divisor() {
    let _guard = fresh();
    // SAFETY (all calls below): C-string literal is valid and null-terminated.
    check_overflow_pair(
        || unsafe { map2check_binop_div_int(7, 2, 4, 0, c"f".as_ptr()) },
        || unsafe { map2check_binop_div_int(i32::MIN, -1, 4, 0, c"f".as_ptr()) },
    );
    check_overflow_pair(
        || unsafe { map2check_binop_div_int(-7, 2, 4, 0, c"f".as_ptr()) },
        || unsafe { map2check_binop_div_int(7, 0, 4, 0, c"f".as_ptr()) },
    );
}

#[test]
fn binop_neg_int_detects_min() {
    let _guard = fresh();
    // SAFETY (all calls below): C-string literal is valid and null-terminated.
    check_overflow_pair(
        || unsafe { map2check_binop_neg_int(5, 0, 4, 0, c"f".as_ptr()) },
        || unsafe { map2check_binop_neg_int(i32::MIN, 0, 4, 0, c"f".as_ptr()) },
    );
}

#[test]
fn binop_shl_int_detects_overflow_negative_lhs_and_wide_shift() {
    let _guard = fresh();
    // SAFETY (all calls below): C-string literal is valid and null-terminated.
    check_overflow_pair(
        || unsafe { map2check_binop_shl_int(1, 30, 4, 0, c"f".as_ptr()) },
        || unsafe { map2check_binop_shl_int(1, 31, 4, 0, c"f".as_ptr()) },
    );
    check_overflow_pair(
        || unsafe { map2check_binop_shl_int(0, 31, 4, 0, c"f".as_ptr()) },
        || unsafe { map2check_binop_shl_int(-1, 1, 4, 0, c"f".as_ptr()) },
    );
    check_overflow_pair(
        || unsafe { map2check_binop_shl_int(3, 0, 4, 0, c"f".as_ptr()) },
        || unsafe { map2check_binop_shl_int(1, 32, 4, 0, c"f".as_ptr()) },
    );
}

#[test]
fn binop_shr_int_detects_wide_shift() {
    let _guard = fresh();
    // SAFETY (all calls below): C-string literal is valid and null-terminated.
    check_overflow_pair(
        || unsafe { map2check_binop_shr_int(-8, 31, 4, 0, c"f".as_ptr()) },
        || unsafe { map2check_binop_shr_int(8, 32, 4, 0, c"f".as_ptr()) },
    );
}

#[test]
fn binop_add_unsigned_detects_overflow() {
    let _guard = fresh();
    // SAFETY (all calls below): C-string literal is valid and null-terminated.
    check_overflow_pair(
        || unsafe { map2check_binop_add_unsigned(u32::MAX - 1, 1, 4, 0, c"f".as_ptr()) },
        || unsafe { map2check_binop_add_unsigned(u32::MAX, 1, 4, 0, c"f".as_ptr()) },
    );
}

#[test]
fn binop_sub_unsigned_detects_wraparound() {
    let _guard = fresh();
    // SAFETY (all calls below): C-string literal is valid and null-terminated.
    check_overflow_pair(
        || unsafe { map2check_binop_sub_unsigned(1, 1, 4, 0, c"f".as_ptr()) },
        || unsafe { map2check_binop_sub_unsigned(0, 1, 4, 0, c"f".as_ptr()) },
    );
}

#[test]
fn binop_mul_unsigned_detects_overflow() {
    let _guard = fresh();
    // SAFETY (all calls below): C-string literal is valid and null-terminated.
    check_overflow_pair(
        || unsafe { map2check_binop_mul_unsigned(65_535, 65_537, 4, 0, c"f".as_ptr()) },
        || unsafe { map2check_binop_mul_unsigned(u32::MAX, 2, 4, 0, c"f".as_ptr()) },
    );
}

#[test]
fn binop_div_unsigned_detects_zero_divisor() {
    let _guard = fresh();
    // SAFETY (all calls below): C-string literal is valid and null-terminated.
    check_overflow_pair(
        || unsafe { map2check_binop_div_unsigned(u32::MAX, 2, 4, 0, c"f".as_ptr()) },
        || unsafe { map2check_binop_div_unsigned(1, 0, 4, 0, c"f".as_ptr()) },
    );
}

#[test]
fn binop_shr_unsigned_detects_wide_shift() {
    let _guard = fresh();
    // SAFETY (all calls below): C-string literal is valid and null-terminated.
    check_overflow_pair(
        || unsafe { map2check_binop_shr_unsigned(u32::MAX, 31, 4, 0, c"f".as_ptr()) },
        || unsafe { map2check_binop_shr_unsigned(1, 32, 4, 0, c"f".as_ptr()) },
    );
}

// ── Analysis mode: memory ───────────────────────────────────────────────────

#[test]
fn check_load_accepts_access_inside_allocation() {
    let _guard = fresh();
    // SAFETY: C-string literal is valid; fake addresses are never dereferenced.
    unsafe {
        map2check_map_malloc(addr(0x1000), 16);
        map2check_check_load(addr(0x1008), 12, 0, 8, c"main".as_ptr());
    }
    assert_ok();
}

#[test]
fn check_load_rejects_access_past_allocation_end() {
    let _guard = fresh();
    // SAFETY: C-string literal is valid; fake addresses are never dereferenced.
    unsafe {
        map2check_map_malloc(addr(0x1000), 16);
        map2check_check_load(addr(0x100c), 12, 0, 8, c"main".as_ptr());
    }
    assert_violated(ViolatedProperty::MemsafetyDeref, 12, "main");
}

#[test]
fn check_load_rejects_negative_size() {
    let _guard = fresh();
    // SAFETY: C-string literal is valid; fake addresses are never dereferenced.
    unsafe {
        map2check_map_malloc(addr(0x1000), 16);
        map2check_check_load(addr(0x1000), 12, 0, -1, c"main".as_ptr());
    }
    assert_violated(ViolatedProperty::MemsafetyDeref, 12, "main");
}

#[test]
fn check_load_null_depends_on_null_is_valid() {
    let _guard = fresh();
    // SAFETY: C-string literal is valid; null is never dereferenced.
    unsafe { map2check_check_load(std::ptr::null(), 12, 0, 4, c"main".as_ptr()) };
    assert_violated(ViolatedProperty::MemsafetyDeref, 12, "main");

    // The first violation is final (SD-03), so start a new analysis.
    state::reset();
    map2check_set_null_is_valid();
    // SAFETY: as above.
    unsafe { map2check_check_load(std::ptr::null(), 12, 0, 4, c"main".as_ptr()) };
    assert_ok();
}

#[test]
fn sd03_safe_check_keeps_earlier_violation() {
    // SD-03 / #36: the first violation is final. A later memory check that
    // finds the access safe must not reset the result to OK.
    let _guard = fresh();
    // SAFETY: C-string literals are valid; fake addresses are never dereferenced.
    unsafe {
        map2check_map_malloc(addr(0x1000), 16);
        set_false_result(5, 1, c"main".as_ptr());
        map2check_check_load(addr(0x1000), 2, 0, 4, c"main".as_ptr());
    }
    assert_violated(ViolatedProperty::Reachability, 1, "main");
    assert_eq!(get_current_property(), ViolatedProperty::Reachability);

    // SAFETY: as above.
    unsafe {
        map2check_check_deref(addr(0x1000), 0, 3, c"main".as_ptr());
        map2check_check_free(c"p".as_ptr(), addr(0x1000), 0, 4, c"main".as_ptr());
        map2check_check_free_resolved_address(addr(0x1000), 5, c"main".as_ptr(), 0);
        map2check_map_free(c"p".as_ptr(), addr(0x1000), 0, 5, c"main".as_ptr());
    }
    map2check_check_mem_endprog();
    map2check_set_memcleanup();
    map2check_check_mem_endprog();
    assert_violated(ViolatedProperty::Reachability, 1, "main");
}

#[test]
fn sd03_later_violation_does_not_overwrite_first() {
    // SD-03 / #36: neither a later memory violation nor a later
    // `set_false_result` replaces the recorded one.
    let _guard = fresh();
    // SAFETY: C-string literals are valid; fake addresses are never dereferenced.
    unsafe {
        map2check_check_load(addr(0x9000), 7, 0, 4, c"first".as_ptr());
        map2check_check_free(c"p".as_ptr(), addr(0x9000), 0, 8, c"main".as_ptr());
        map2check_check_deref(std::ptr::null(), 0, 9, c"main".as_ptr());
        set_false_result(5, 10, c"main".as_ptr());
        map2check_binop_add_int(i32::MAX, 1, 11, 0, c"main".as_ptr());
    }
    assert_violated(ViolatedProperty::MemsafetyDeref, 7, "first");
}

// ── #11: validity follows the latest alloc/free event ───────────────────────

#[test]
fn deref_after_free_is_invalid() {
    let _guard = fresh();
    map2check_init();
    // SAFETY: C-string literals are valid; fake addresses are never dereferenced.
    unsafe {
        map2check_map_malloc(addr(0x2000), 16);
        map2check_map_free(c"p".as_ptr(), addr(0x2000), 0, 9, c"main".as_ptr());
        map2check_check_deref(addr(0x2000), 0, 10, c"main".as_ptr());
    }
    assert_violated(ViolatedProperty::MemsafetyDeref, 10, "main");
}

#[test]
fn load_after_free_is_invalid() {
    // develop: the freed row has size 0, so no live row covers the address
    // (AllocationLog.c:127-148, AnalysisModeMemtrack.c:156-162, :360-363).
    let _guard = fresh();
    // SAFETY: C-string literals are valid; fake addresses are never dereferenced.
    unsafe {
        map2check_map_malloc(addr(0x2000), 16);
        map2check_map_free(c"p".as_ptr(), addr(0x2000), 0, 9, c"main".as_ptr());
        map2check_check_load(addr(0x2004), 10, 0, 4, c"main".as_ptr());
    }
    assert_violated(ViolatedProperty::MemsafetyDeref, 10, "main");
}

#[test]
fn reallocation_at_same_address_is_valid_again() {
    // develop: `map2check_malloc` revives the existing row (is_free = FALSE,
    // new size; AnalysisModeMemtrack.c:313-317).
    let _guard = fresh();
    // SAFETY: C-string literals are valid; fake addresses are never dereferenced.
    unsafe {
        map2check_map_malloc(addr(0x2000), 16);
        map2check_map_free(c"p".as_ptr(), addr(0x2000), 0, 9, c"main".as_ptr());
        map2check_map_malloc(addr(0x2000), 16);
        map2check_check_load(addr(0x2004), 10, 0, 4, c"main".as_ptr());
        map2check_check_deref(addr(0x2000), 0, 11, c"main".as_ptr());
        map2check_check_free(c"p".as_ptr(), addr(0x2000), 0, 12, c"main".as_ptr());
        map2check_check_free_resolved_address(addr(0x2000), 13, c"main".as_ptr(), 0);
    }
    assert_ok();

    // SAFETY: as above.
    unsafe {
        map2check_map_free(c"p".as_ptr(), addr(0x2000), 0, 14, c"main".as_ptr());
        map2check_check_load(addr(0x2004), 15, 0, 4, c"main".as_ptr());
    }
    assert_violated(ViolatedProperty::MemsafetyDeref, 15, "main");
}

#[test]
fn reallocation_with_smaller_size_shrinks_the_valid_range() {
    let _guard = fresh();
    // SAFETY: C-string literals are valid; fake addresses are never dereferenced.
    unsafe {
        map2check_map_malloc(addr(0x2000), 16);
        map2check_map_free(c"p".as_ptr(), addr(0x2000), 0, 9, c"main".as_ptr());
        map2check_map_malloc(addr(0x2000), 8);
        map2check_check_load(addr(0x2004), 10, 0, 4, c"main".as_ptr());
    }
    assert_ok();
    // SAFETY: as above.
    unsafe { map2check_check_load(addr(0x2008), 11, 0, 4, c"main".as_ptr()) };
    assert_violated(ViolatedProperty::MemsafetyDeref, 11, "main");
}

#[test]
fn load_range_boundaries_of_a_live_allocation() {
    let _guard = fresh();
    // SAFETY: C-string literals are valid; fake addresses are never dereferenced.
    unsafe {
        map2check_map_malloc(addr(0x2000), 16);
        map2check_check_load(addr(0x2000), 1, 0, 16, c"main".as_ptr());
        map2check_check_load(addr(0x200c), 2, 0, 4, c"main".as_ptr());
        map2check_check_load(addr(0x200f), 3, 0, 1, c"main".as_ptr());
    }
    assert_ok();

    for (address, size, line) in [(0x1fff, 1, 4), (0x200d, 4, 5), (0x2010, 1, 6)] {
        state::reset();
        // SAFETY: as above.
        unsafe {
            map2check_map_malloc(addr(0x2000), 16);
            map2check_check_load(addr(address), line, 0, size, c"main".as_ptr());
        }
        assert_violated(ViolatedProperty::MemsafetyDeref, line as u32, "main");
    }
}

#[test]
fn pointer_store_does_not_revive_a_freed_block() {
    let _guard = fresh();
    // SAFETY: C-string literals are valid; fake addresses are never dereferenced.
    unsafe {
        map2check_map_malloc(addr(0x2000), 16);
        map2check_map_free(c"p".as_ptr(), addr(0x2000), 0, 9, c"main".as_ptr());
        map2check_map_store_pointer(
            addr(0x3000),
            addr(0x2000),
            0,
            c"q".as_ptr(),
            10,
            c"main".as_ptr(),
        );
        map2check_check_load(addr(0x2000), 11, 0, 4, c"main".as_ptr());
    }
    assert_violated(ViolatedProperty::MemsafetyDeref, 11, "main");
}

#[test]
fn check_free_accepts_live_allocation_and_null() {
    let _guard = fresh();
    // SAFETY: C-string literals are valid; fake addresses are never dereferenced.
    unsafe {
        map2check_map_malloc(addr(0x1000), 16);
        map2check_check_free(c"p".as_ptr(), addr(0x1000), 0, 20, c"main".as_ptr());
    }
    assert_ok();
    // SAFETY: as above.
    unsafe { map2check_check_free(c"p".as_ptr(), std::ptr::null(), 0, 20, c"main".as_ptr()) };
    assert_ok();
}

#[test]
fn check_free_rejects_double_free_and_untracked_address() {
    let _guard = fresh();
    // SAFETY: C-string literals are valid; fake addresses are never dereferenced.
    unsafe {
        map2check_map_malloc(addr(0x1000), 16);
        map2check_map_free(c"p".as_ptr(), addr(0x1000), 0, 19, c"main".as_ptr());
        map2check_check_free(c"p".as_ptr(), addr(0x1000), 0, 20, c"main".as_ptr());
    }
    assert_violated(ViolatedProperty::MemsafetyFree, 20, "main");

    state::reset();
    // SAFETY: as above.
    unsafe { map2check_check_free(c"p".as_ptr(), addr(0x9000), 0, 21, c"main".as_ptr()) };
    assert_violated(ViolatedProperty::MemsafetyFree, 21, "main");
}

#[test]
fn check_free_resolved_address_rejects_freed_target() {
    let _guard = fresh();
    // SAFETY: C-string literals are valid; fake addresses are never dereferenced.
    unsafe {
        map2check_map_malloc(addr(0x1000), 16);
        map2check_check_free_resolved_address(addr(0x1000), 30, c"main".as_ptr(), 0);
    }
    assert_ok();

    // SAFETY: as above.
    unsafe {
        map2check_map_free(c"p".as_ptr(), addr(0x1000), 0, 30, c"main".as_ptr());
        map2check_check_free_resolved_address(addr(0x1000), 31, c"main".as_ptr(), 0);
    }
    assert_violated(ViolatedProperty::MemsafetyFree, 31, "main");
}

#[test]
fn sd06_untracked_free_is_invalid() {
    // SD-06 / #37: both free paths use develop's `is_invalid_free`, which
    // reports an address with no record as an invalid free.
    let _guard = fresh();
    // SAFETY: C-string literal is valid; fake address is never dereferenced.
    unsafe { map2check_check_free_resolved_address(addr(0x5000), 3, c"main".as_ptr(), 0) };
    assert_violated(ViolatedProperty::MemsafetyFree, 3, "main");

    state::reset();
    // SAFETY: as above.
    unsafe { map2check_check_free(c"p".as_ptr(), addr(0x5000), 0, 4, c"main".as_ptr()) };
    assert_violated(ViolatedProperty::MemsafetyFree, 4, "main");
}

#[test]
fn check_free_resolved_address_rejects_stack_slot() {
    // develop: a stack slot never reaches list_log as a dynamic row, so
    // `is_invalid_free` reports it (ListLog.c:95-118).
    let _guard = fresh();
    // SAFETY: C-string literals are valid; fake address is never dereferenced.
    unsafe {
        map2check_map_alloca(c"x".as_ptr(), addr(0x6000), 8, 4, 1, 0);
        map2check_check_free_resolved_address(addr(0x6000), 5, c"main".as_ptr(), 0);
    }
    assert_violated(ViolatedProperty::MemsafetyFree, 5, "main");
}

#[test]
fn resolved_free_records_the_release_so_a_moved_realloc_is_not_a_leak() {
    // develop: `map2check_free_resolved_address` marks the block freed when
    // the check passes (AnalysisModeMemtrack.c:178-182). The pass uses it for
    // realloc: free the old block, then malloc the new one.
    let _guard = fresh();
    // SAFETY: C-string literal is valid; fake addresses are never dereferenced.
    unsafe {
        map2check_map_malloc(addr(0x1000), 16);
        map2check_check_free_resolved_address(addr(0x1000), 3, c"main".as_ptr(), 0);
        map2check_map_malloc(addr(0x2000), 32);
        map2check_check_free_resolved_address(addr(0x2000), 4, c"main".as_ptr(), 0);
    }
    map2check_set_memcleanup();
    map2check_check_mem_endprog();
    assert_ok();
}

#[test]
fn resolved_free_twice_is_an_invalid_free() {
    let _guard = fresh();
    // SAFETY: C-string literal is valid; fake address is never dereferenced.
    unsafe {
        map2check_map_malloc(addr(0x1000), 16);
        map2check_check_free_resolved_address(addr(0x1000), 3, c"main".as_ptr(), 0);
    }
    assert_ok();
    // SAFETY: as above.
    unsafe { map2check_check_free_resolved_address(addr(0x1000), 4, c"main".as_ptr(), 0) };
    assert_violated(ViolatedProperty::MemsafetyFree, 4, "main");
}

#[test]
fn load_after_resolved_free_is_invalid() {
    let _guard = fresh();
    // SAFETY: C-string literal is valid; fake address is never dereferenced.
    unsafe {
        map2check_map_malloc(addr(0x1000), 16);
        map2check_check_free_resolved_address(addr(0x1000), 3, c"main".as_ptr(), 0);
        map2check_check_load(addr(0x1000), 4, 0, 4, c"main".as_ptr());
    }
    assert_violated(ViolatedProperty::MemsafetyDeref, 4, "main");
}

#[test]
fn sd13_free_of_a_never_stored_pointer_is_valid() {
    // SD-13: `free(malloc(8))` — the block was never stored through a tracked
    // pointer store. Rust decides by the allocation record and accepts it;
    // develop scans only list_log (pointer stores) and reports FALSE_FREE.
    let _guard = fresh();
    // SAFETY: C-string literals are valid; fake addresses are never dereferenced.
    unsafe {
        map2check_map_malloc(addr(0x1000), 8);
        map2check_check_free_resolved_address(addr(0x1000), 3, c"main".as_ptr(), 0);
        map2check_map_malloc(addr(0x2000), 8);
        map2check_check_free(c"p".as_ptr(), addr(0x2000), 0, 4, c"main".as_ptr());
    }
    assert_ok();
}

#[test]
fn check_free_resolved_address_null_depends_on_flag() {
    let _guard = fresh();
    // SAFETY: C-string literal is valid; null is never dereferenced.
    unsafe { map2check_check_free_resolved_address(std::ptr::null(), 32, c"main".as_ptr(), 1) };
    assert_ok();
}

#[test]
fn check_deref_accepts_live_and_rejects_freed_null_or_untracked() {
    let _guard = fresh();
    // SAFETY: C-string literals are valid; fake addresses are never dereferenced.
    unsafe {
        map2check_map_malloc(addr(0x1000), 16);
        map2check_check_deref(addr(0x1000), 0, 40, c"main".as_ptr());
    }
    assert_ok();

    // SAFETY: as above.
    unsafe {
        map2check_map_free(c"p".as_ptr(), addr(0x1000), 0, 41, c"main".as_ptr());
        map2check_check_deref(addr(0x1000), 0, 42, c"main".as_ptr());
    }
    assert_violated(ViolatedProperty::MemsafetyDeref, 42, "main");

    // The first violation is final (SD-03), so each case starts a new analysis.
    state::reset();
    // SAFETY: as above.
    unsafe { map2check_check_deref(std::ptr::null(), 0, 43, c"main".as_ptr()) };
    assert_violated(ViolatedProperty::MemsafetyDeref, 43, "main");

    state::reset();
    // SAFETY: as above.
    unsafe { map2check_check_deref(addr(0x9000), 0, 44, c"main".as_ptr()) };
    assert_violated(ViolatedProperty::MemsafetyDeref, 44, "main");
}

#[test]
fn check_mem_endprog_reports_memtrack_until_memcleanup_is_enabled() {
    let _guard = fresh();
    // SAFETY: fake address is never dereferenced.
    unsafe { map2check_map_malloc(addr(0x1000), 16) };
    map2check_check_mem_endprog();
    assert_violated(ViolatedProperty::MemsafetyMemtrack, 0, "end_of_program");

    state::reset();
    // SAFETY: fake address is never dereferenced.
    unsafe { map2check_map_malloc(addr(0x1000), 16) };
    map2check_set_memcleanup();
    map2check_check_mem_endprog();
    assert_violated(ViolatedProperty::MemsafetyMemcleanup, 0, "end_of_program");
}

#[test]
fn check_mem_endprog_accepts_freed_allocation() {
    let _guard = fresh();
    map2check_set_memcleanup();
    // SAFETY: C-string literals are valid; fake address is never dereferenced.
    unsafe {
        map2check_map_malloc(addr(0x1000), 16);
        map2check_map_free(c"p".as_ptr(), addr(0x1000), 0, 50, c"main".as_ptr());
    }
    map2check_check_mem_endprog();
    assert_ok();
}

// ── Hand-written header declarations ────────────────────────────────────────

#[test]
fn macro_generated_exports_match_the_hand_written_header_declarations() {
    // O cbindgen não vê as funções geradas por `nondet_ffi!` e
    // `overflow_ffi_*!`: o `build.rs` escreve as declarações C delas à mão, e
    // `tests/compat_docs.rs` só compara o doc com o header. Estas coerções
    // quebram a compilação se a assinatura Rust mudar; ao corrigir aqui,
    // atualize também a string correspondente em `build.rs`.
    use std::os::raw::{c_char, c_long};
    type NonDet<T> =
        unsafe extern "C" fn(i32, i32, i32, *mut T, *const c_char) -> *mut non_det_log_t;
    type BinOp<T> = unsafe extern "C" fn(T, T, u32, u32, *const c_char);
    type Shift<T> = unsafe extern "C" fn(T, u32, u32, u32, *const c_char);

    let _: NonDet<i32> = map2check_save_nondet_log_int; // int *value
    let _: NonDet<u32> = map2check_save_nondet_log_uint; // unsigned int *value
    let _: NonDet<c_long> = map2check_save_nondet_log_long; // long *value
    let _: NonDet<c_char> = map2check_save_nondet_log_char; // char *value
    let _: NonDet<f32> = map2check_save_nondet_log_float; // float *value
    let _: NonDet<f64> = map2check_save_nondet_log_double; // double *value
    let _: BinOp<i32> = map2check_binop_add_int;
    let _: BinOp<i32> = map2check_binop_sub_int;
    let _: BinOp<i32> = map2check_binop_mul_int;
    let _: BinOp<i32> = map2check_binop_div_int;
    let _: BinOp<u32> = map2check_binop_add_unsigned;
    let _: BinOp<u32> = map2check_binop_sub_unsigned;
    let _: BinOp<u32> = map2check_binop_mul_unsigned;
    let _: BinOp<u32> = map2check_binop_div_unsigned;
    let _: Shift<i32> = map2check_binop_shl_int;
    let _: Shift<i32> = map2check_binop_shr_int;
    let _: Shift<u32> = map2check_binop_shr_unsigned;
}

// ── Memory-safety options (#10, SD-04, SD-05) ───────────────────────────────

#[test]
fn memcleanup_reports_leak_as_memcleanup_at_exit() {
    let _guard = fresh();
    map2check_init();
    map2check_set_memcleanup();
    // SAFETY: fake address is never dereferenced.
    unsafe { map2check_map_malloc(addr(0x3000), 32) };
    map2check_check_mem_endprog();
    assert_violated(ViolatedProperty::MemsafetyMemcleanup, 0, "end_of_program");
}

#[test]
fn without_memcleanup_leak_is_reported_as_memtrack_at_exit() {
    // develop: analysis_is_program_correct() of AnalysisModeMemtrack.c writes
    // FALSE_MEMTRACK; the leak check runs at exit in both modes.
    let _guard = fresh();
    map2check_init();
    // SAFETY: fake address is never dereferenced.
    unsafe { map2check_map_malloc(addr(0x3000), 32) };
    map2check_check_mem_endprog();
    assert_violated(ViolatedProperty::MemsafetyMemtrack, 0, "end_of_program");
}

#[test]
fn endprog_without_leak_is_ok_in_both_modes() {
    let _guard = fresh();
    map2check_check_mem_endprog();
    assert_ok();
    map2check_set_memcleanup();
    map2check_check_mem_endprog();
    assert_ok();
}

#[test]
fn endprog_keeps_an_earlier_violation() {
    // #36: the end-of-program check must not overwrite the first violation.
    let _guard = fresh();
    // SAFETY: fake address and C-string literals are valid.
    unsafe {
        map2check_map_malloc(addr(0x3000), 32);
        map2check_check_load(std::ptr::null(), 9, 0, 4, c"first".as_ptr());
    }
    map2check_check_mem_endprog();
    assert_violated(ViolatedProperty::MemsafetyDeref, 9, "first");
    map2check_set_memcleanup();
    map2check_check_mem_endprog();
    assert_violated(ViolatedProperty::MemsafetyDeref, 9, "first");
}

#[test]
fn null_is_valid_accepts_null_load() {
    let _guard = fresh();
    map2check_init();
    map2check_set_null_is_valid();
    // SAFETY: null is never dereferenced.
    unsafe { map2check_check_load(std::ptr::null(), 3, 0, 4, c"main".as_ptr()) };
    assert_ok();
}

/// Runs a leak check and a NULL load on a fresh analysis, reports the
/// (end-of-program property, null-load accepted) pair.
fn observed_options() -> (ViolatedProperty, bool) {
    state::reset();
    // SAFETY: fake address is never dereferenced.
    unsafe { map2check_map_malloc(addr(0x3000), 32) };
    map2check_check_mem_endprog();
    let leak = snapshot(|s| s.result.property);
    state::reset();
    // SAFETY: null is never dereferenced.
    unsafe { map2check_check_load(std::ptr::null(), 3, 0, 4, c"main".as_ptr()) };
    let null_ok = snapshot(|s| s.result.ok);
    state::reset();
    (leak, null_ok)
}

#[test]
fn options_survive_init_and_reset() {
    let _guard = fresh();
    map2check_set_memcleanup();
    map2check_set_null_is_valid();
    let expected = (ViolatedProperty::MemsafetyMemcleanup, true);
    assert_eq!(observed_options(), expected);

    map2check_init();
    assert_eq!(observed_options(), expected);

    map2check_reset();
    assert_eq!(observed_options(), expected);
}

#[test]
fn options_default_off() {
    let _guard = fresh();
    assert_eq!(
        observed_options(),
        (ViolatedProperty::MemsafetyMemtrack, false)
    );
}

// ── Analysis mode selection and target reachability (Task 2.3) ─────────────

const MODES: [AnalysisMode; 6] = [
    AnalysisMode::None,
    AnalysisMode::Memtrack,
    AnalysisMode::Memcleanup,
    AnalysisMode::Overflow,
    AnalysisMode::Assert,
    AnalysisMode::Target,
];

/// Starts an analysis in `mode`, as the instrumented program will.
fn start(mode: AnalysisMode) {
    state::reset();
    map2check_set_mode(mode);
    map2check_init();
}

/// Runs one violating call of each check family on a fresh analysis in
/// `mode` and returns the property each one recorded (`None` = no report).
fn reports_in(mode: AnalysisMode) -> [ViolatedProperty; 7] {
    let mut out = [ViolatedProperty::None; 7];
    let runs: [&dyn Fn(); 7] = [
        // SAFETY (all closures): C-string literals are valid; fake addresses
        // are never dereferenced.
        &|| unsafe { map2check_check_load(addr(0xdead), 1, 0, 4, c"main".as_ptr()) },
        &|| unsafe { map2check_check_deref(addr(0xdead), 0, 1, c"main".as_ptr()) },
        &|| unsafe { map2check_check_free(c"p".as_ptr(), addr(0xdead), 0, 1, c"main".as_ptr()) },
        &|| unsafe { map2check_check_free_resolved_address(addr(0xdead), 1, c"main".as_ptr(), 0) },
        &|| unsafe { map2check_binop_add_int(i32::MAX, 1, 1, 0, c"main".as_ptr()) },
        &|| unsafe { map2check_is_valid_assert(1, c"main".as_ptr(), 0) },
        &|| {
            // SAFETY: fake address is never dereferenced.
            unsafe { map2check_map_malloc(addr(0x3000), 8) };
            map2check_check_mem_endprog();
        },
    ];
    for (slot, run) in out.iter_mut().zip(runs) {
        start(mode);
        run();
        *slot = snapshot(|s| s.result.property);
    }
    out
}

use ViolatedProperty as P;

#[test]
fn mode_none_never_reports_memory_errors() {
    let _guard = fresh();
    map2check_set_mode(AnalysisMode::None);
    map2check_init();
    // SAFETY: C-string literal is valid; fake address is never dereferenced.
    unsafe { map2check_check_deref(addr(0xdead), 0, 1, c"main".as_ptr()) };
    assert_ok();
}

#[test]
fn mode_memtrack_reports_invalid_deref() {
    let _guard = fresh();
    map2check_set_mode(AnalysisMode::Memtrack);
    map2check_init();
    // SAFETY: C-string literal is valid; fake address is never dereferenced.
    unsafe { map2check_check_deref(addr(0xdead), 0, 1, c"main".as_ptr()) };
    assert_violated(ViolatedProperty::MemsafetyDeref, 1, "main");
}

#[test]
fn mode_none_reports_nothing() {
    let _guard = fresh();
    assert_eq!(reports_in(AnalysisMode::None), [P::None; 7]);
}

#[test]
fn mode_target_reports_nothing_from_checks() {
    let _guard = fresh();
    assert_eq!(reports_in(AnalysisMode::Target), [P::None; 7]);
}

#[test]
fn mode_memtrack_reports_memory_errors_only() {
    let _guard = fresh();
    assert_eq!(
        reports_in(AnalysisMode::Memtrack),
        [
            P::MemsafetyDeref,
            P::MemsafetyDeref,
            P::MemsafetyFree,
            P::MemsafetyFree,
            P::None,
            P::None,
            P::MemsafetyMemtrack,
        ]
    );
}

#[test]
fn mode_memcleanup_reports_only_the_leak_as_memcleanup() {
    let _guard = fresh();
    let mut expected = [P::None; 7];
    expected[6] = P::MemsafetyMemcleanup;
    assert_eq!(reports_in(AnalysisMode::Memcleanup), expected);
}

#[test]
fn mode_overflow_reports_overflow_only() {
    let _guard = fresh();
    let mut expected = [P::None; 7];
    expected[4] = P::Overflow;
    assert_eq!(reports_in(AnalysisMode::Overflow), expected);
}

#[test]
fn mode_assert_reports_assert_only() {
    let _guard = fresh();
    let mut expected = [P::None; 7];
    expected[5] = P::Assert;
    assert_eq!(reports_in(AnalysisMode::Assert), expected);
}

#[test]
fn unset_mode_keeps_every_check_active() {
    let _guard = fresh();
    let mut out = [P::None; 7];
    // Same calls as `reports_in`, without `map2check_set_mode`.
    let runs: [&dyn Fn(); 7] = [
        // SAFETY (all closures): as in `reports_in`.
        &|| unsafe { map2check_check_load(addr(0xdead), 1, 0, 4, c"main".as_ptr()) },
        &|| unsafe { map2check_check_deref(addr(0xdead), 0, 1, c"main".as_ptr()) },
        &|| unsafe { map2check_check_free(c"p".as_ptr(), addr(0xdead), 0, 1, c"main".as_ptr()) },
        &|| unsafe { map2check_check_free_resolved_address(addr(0xdead), 1, c"main".as_ptr(), 0) },
        &|| unsafe { map2check_binop_add_int(i32::MAX, 1, 1, 0, c"main".as_ptr()) },
        &|| unsafe { map2check_is_valid_assert(1, c"main".as_ptr(), 0) },
        &|| {
            // SAFETY: fake address is never dereferenced.
            unsafe { map2check_map_malloc(addr(0x3000), 8) };
            map2check_check_mem_endprog();
        },
    ];
    for (slot, run) in out.iter_mut().zip(runs) {
        state::reset();
        map2check_init();
        run();
        *slot = snapshot(|s| s.result.property);
    }
    assert_eq!(state::config().mode, None);
    assert_eq!(
        out,
        [
            P::MemsafetyDeref,
            P::MemsafetyDeref,
            P::MemsafetyFree,
            P::MemsafetyFree,
            P::Overflow,
            P::Assert,
            P::MemsafetyMemtrack,
        ]
    );
}

#[test]
fn memcleanup_option_is_an_alias_of_memcleanup_mode_for_the_leak() {
    let _guard = fresh();
    map2check_set_memcleanup();
    start(AnalysisMode::Memtrack);
    // SAFETY: fake address is never dereferenced.
    unsafe { map2check_map_malloc(addr(0x3000), 8) };
    map2check_check_mem_endprog();
    assert_violated(P::MemsafetyMemcleanup, 0, "end_of_program");
}

#[test]
fn memcleanup_mode_records_release_on_resolved_free() {
    // develop: the memcleanup free never fails but still marks the block
    // free (AnalysisModeMemcleanup.c:160-179), so it is no leak at exit.
    let _guard = fresh();
    start(AnalysisMode::Memcleanup);
    // SAFETY: C-string literal is valid; fake address is never dereferenced.
    unsafe {
        map2check_map_malloc(addr(0x3000), 8);
        map2check_check_free_resolved_address(addr(0x3000), 2, c"main".as_ptr(), 0);
    }
    map2check_check_mem_endprog();
    assert_ok();
}

#[test]
fn set_mode_is_configuration_kept_by_init_and_reset() {
    let _guard = fresh();
    for mode in MODES {
        map2check_set_mode(mode);
        map2check_init();
        assert_eq!(state::config().mode, Some(mode));
        map2check_reset();
        assert_eq!(state::config().mode, Some(mode));
    }
}

#[test]
fn reset_keeps_selected_mode() {
    let _guard = fresh();
    map2check_set_mode(AnalysisMode::Overflow);
    map2check_init();
    map2check_reset();
    assert_eq!(state::config().mode, Some(AnalysisMode::Overflow));
}

#[test]
fn reach_target_sets_target_reached() {
    let _guard = fresh();
    map2check_set_mode(AnalysisMode::Target);
    map2check_init();
    // SAFETY: C-string literal is valid and null-terminated.
    unsafe { mark_target_reached(c"reach_error".as_ptr(), 0, 12) };
    assert_violated(ViolatedProperty::Reachability, 12, "reach_error");
}

#[test]
fn map2check_reach_target_records_and_returns() {
    // develop: map2check_target_function writes TARGET_REACHED and exits
    // (Map2CheckFunctions.c:61-65). Here it records and returns; ending the
    // process belongs to Task 2.4.
    let _guard = fresh();
    start(AnalysisMode::Target);
    // SAFETY: C-string literal is valid and null-terminated.
    unsafe { map2check_reach_target(c"reach_error".as_ptr(), 0, 12) };
    assert_violated(ViolatedProperty::Reachability, 12, "reach_error");
    assert_eq!(get_current_property(), ViolatedProperty::Reachability);
}

#[test]
fn reach_target_keeps_the_first_violation() {
    let _guard = fresh();
    start(AnalysisMode::Target);
    // SAFETY: C-string literals are valid and null-terminated.
    unsafe {
        set_false_result(0, 3, c"f".as_ptr());
        map2check_reach_target(c"reach_error".as_ptr(), 0, 12);
    }
    assert_violated(ViolatedProperty::Overflow, 3, "f");
}

#[test]
fn reach_target_works_in_every_mode_and_accepts_null_name() {
    // map2check_target_function lives in Map2CheckFunctions.c, linked in
    // every mode, so it is not gated by the mode.
    let _guard = fresh();
    for mode in MODES {
        start(mode);
        // SAFETY: null is an accepted name.
        unsafe { map2check_reach_target(std::ptr::null(), 0, 7) };
        assert_violated(ViolatedProperty::Reachability, 7, "");
    }
}

#[test]
fn set_false_result_accepts_the_appended_properties() {
    let _guard = fresh();
    // SAFETY: C-string literal is valid and null-terminated.
    unsafe { set_false_result(8, 4, c"main".as_ptr()) };
    assert_violated(ViolatedProperty::Assert, 4, "main");
    state::reset();
    // SAFETY: as above.
    unsafe { set_false_result(9, 0, c"main".as_ptr()) };
    assert_violated(ViolatedProperty::Unknown, 0, "main");
}
