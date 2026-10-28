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
    map2check_init(0);
    assert_ok();
    assert_eq!(snapshot(|s| s.current_step()), 0);
    assert!(snapshot(|s| s.memtrack.is_empty()
        && s.nondets.is_empty()
        && s.bbtrack.is_empty()));
}

#[test]
fn second_init_starts_from_clean_state() {
    let _guard = fresh();
    map2check_init(0);
    // SAFETY: fake addresses are only stored, never dereferenced.
    unsafe { map2check_map_malloc(addr(0x1000), 8) };
    // SAFETY: C-string literal is valid and null-terminated.
    unsafe { set_false_result(ViolatedProperty::Reachability as i32, 7, c"main".as_ptr()) };
    map2check_set_memcleanup();
    map2check_set_null_is_valid();
    let mut value: i32 = 3;
    // SAFETY: `value` outlives the call; the name is a valid C string.
    unsafe { map2check_save_nondet_log_int(1, 0, 0, &mut value, c"main".as_ptr()) };
    let _ = get_next_step();
    assert!(snapshot(|s| s.current_step() > 0 && !s.nondets.is_empty()));

    map2check_init(0);

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
    unsafe { set_false_result(ViolatedProperty::Reachability as i32, 7, c"main".as_ptr()) };
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
    unsafe { set_false_result(ViolatedProperty::Reachability as i32, 42, c"main".as_ptr()) };
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
    unsafe { set_false_result(ViolatedProperty::Overflow as i32, 3, std::ptr::null()) };
    assert_violated(ViolatedProperty::Overflow, 3, "");
}

#[test]
fn get_current_property_reflects_last_violation() {
    let _guard = fresh();
    assert_eq!(get_current_property(), ViolatedProperty::None);
    // SAFETY: C-string literal is valid and null-terminated.
    unsafe { set_false_result(ViolatedProperty::MemsafetyDeref as i32, 1, c"f".as_ptr()) };
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
    unsafe { set_false_result(ViolatedProperty::MemsafetyFree as i32, 9, c"main".as_ptr()) };

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

/// One test per family added for the Map2Check passes (#6): the value is
/// read through the pointer in the family's C type, and the record keeps
/// the `type_var` the pass passed.
macro_rules! save_nondet_test {
    ($test:ident, $c_ty:ty, $value:expr, $expected:expr, |$p:ident| $call:expr) => {
        #[test]
        fn $test() {
            let _guard = fresh();
            let mut value: $c_ty = $value;
            let $p: *mut $c_ty = &mut value;
            // SAFETY: value and the C-string literal outlive the call.
            let record = unsafe { $call };
            assert_nondet(record, $expected);
            // SAFETY: the record is owned by the global state (see above).
            assert_eq!(unsafe { (*record).type_var }, 9);
            // A null value is accepted and records the family's zero.
            state::reset();
            let $p: *mut $c_ty = std::ptr::null_mut();
            // SAFETY: as above.
            let record = unsafe { $call };
            assert!(!record.is_null());
        }
    };
}

save_nondet_test!(
    save_nondet_log_unsigned_records_value,
    std::os::raw::c_uint,
    4_000_000_000,
    NonDetValue::Unsigned(4_000_000_000),
    |p| map2check_save_nondet_log_unsigned(10, 2, 9, p, c"f".as_ptr())
);
save_nondet_test!(
    save_nondet_log_ulong_records_value,
    std::os::raw::c_ulong,
    u64::MAX as std::os::raw::c_ulong,
    NonDetValue::ULong(u64::MAX),
    |p| map2check_save_nondet_log_ulong(10, 2, 9, p, c"f".as_ptr())
);
save_nondet_test!(
    save_nondet_log_uchar_records_value,
    u8,
    200,
    NonDetValue::UChar(200),
    |p| map2check_save_nondet_log_uchar(10, 2, 9, p, c"f".as_ptr())
);
save_nondet_test!(
    save_nondet_log_short_records_value,
    i16,
    -2,
    NonDetValue::Short(-2),
    |p| map2check_save_nondet_log_short(10, 2, 9, p, c"f".as_ptr())
);
save_nondet_test!(
    save_nondet_log_ushort_records_value,
    u16,
    65535,
    NonDetValue::UShort(65535),
    |p| map2check_save_nondet_log_ushort(10, 2, 9, p, c"f".as_ptr())
);
save_nondet_test!(
    save_nondet_log_bool_records_value,
    i32,
    1,
    NonDetValue::Bool(1),
    |p| map2check_save_nondet_log_bool(10, 2, 9, p, c"f".as_ptr())
);
save_nondet_test!(
    save_nondet_log_size_t_records_value,
    usize,
    5_000_000_000,
    NonDetValue::SizeT(5_000_000_000),
    |p| map2check_save_nondet_log_size_t(10, 2, 9, p, c"f".as_ptr())
);
save_nondet_test!(
    save_nondet_log_loff_t_records_value,
    std::os::raw::c_longlong,
    -1,
    NonDetValue::LoffT(-1),
    |p| map2check_save_nondet_log_loff_t(10, 2, 9, p, c"f".as_ptr())
);
save_nondet_test!(
    save_nondet_log_sector_t_records_value,
    std::os::raw::c_ulong,
    0x1_0000_0009,
    NonDetValue::SectorT(0x1_0000_0009),
    |p| map2check_save_nondet_log_sector_t(10, 2, 9, p, c"f".as_ptr())
);
save_nondet_test!(
    save_nondet_log_pointer_records_address,
    *mut c_void,
    0x1_2345_6789_usize as *mut c_void,
    NonDetValue::Pointer(0x1_2345_6789),
    |p| map2check_save_nondet_log_pointer(10, 2, 9, p, c"f".as_ptr())
);
save_nondet_test!(
    save_nondet_log_pchar_records_address,
    *mut std::os::raw::c_char,
    0x7fff_1234_5678_usize as *mut std::os::raw::c_char,
    NonDetValue::PChar(0x7fff_1234_5678),
    |p| map2check_save_nondet_log_pchar(10, 2, 9, p, c"f".as_ptr())
);

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
fn posix_memalign_tracks_the_block_and_the_store_like_develop() {
    // develop `map2check_posix` (AnalysisModeMemtrack.c:327-333): reads the
    // block through the `void **` the program passed to posix_memalign, then
    // `map2check_malloc(block, size)` and
    // `map2check_add_store_pointer(slot, block, 1, "pointer", 1, "cocoiso")`.
    let _guard = fresh();
    let mut slot: *const c_void = addr(0x4000);
    let slot_address = std::ptr::addr_of_mut!(slot) as usize;
    // SAFETY: `slot` is a live `void *` for the whole call.
    unsafe { map2check_map_posix_memalign(addr(slot_address), 64) };
    let (malloc, store) = snapshot(|s| {
        assert_eq!(s.memtrack.len(), 2);
        (s.memtrack[0].clone(), s.memtrack[1].clone())
    });
    assert_eq!(malloc.origin, crate::memtrack::MemOrigin::Malloc);
    assert_eq!((malloc.points_to, malloc.size_destiny), (0x4000, 64));
    assert!(malloc.is_dynamic && !malloc.is_free);
    assert_eq!(store.origin, crate::memtrack::MemOrigin::StorePointer);
    assert_eq!((store.var_addr, store.points_to), (slot_address, 0x4000));
    assert_eq!((store.scope, store.line), (1, 1));
    assert_eq!(
        (store.ptr_name.as_str(), store.function_name.as_str()),
        ("pointer", "cocoiso")
    );
    // The block is live: a load inside it is valid, one past it is not.
    // SAFETY: C-string literal is valid; fake addresses are never dereferenced.
    unsafe { map2check_check_load(addr(0x4000 + 60), 2, 0, 4, c"main".as_ptr()) };
    assert_ok();
    // SAFETY: as above.
    unsafe { map2check_check_load(addr(0x4000 + 64), 3, 0, 4, c"main".as_ptr()) };
    assert_violated(ViolatedProperty::MemsafetyDeref, 3, "main");
}

#[test]
fn posix_memalign_with_a_null_slot_is_ignored() {
    let _guard = fresh();
    // SAFETY: a NULL slot is never dereferenced (SD-09).
    unsafe { map2check_map_posix_memalign(std::ptr::null(), 64) };
    assert!(snapshot(|s| s.memtrack.is_empty()));
    assert_ok();
}

#[test]
fn posix_memalign_null_block_is_unknown_in_memory_modes() {
    // As `map2check_malloc(NULL, size)` (AnalysisModeMemtrack.c:305-311):
    // UNKNOWN, and no store follows.
    let _guard = fresh();
    map2check_set_mode(AnalysisMode::Memtrack as i32);
    map2check_init(0);
    let mut slot: *const c_void = std::ptr::null();
    // SAFETY: `slot` is a live `void *` for the whole call.
    unsafe { map2check_map_posix_memalign(std::ptr::addr_of_mut!(slot).cast(), 64) };
    assert_violated(ViolatedProperty::Unknown, 0, "");
    assert!(snapshot(|s| s.memtrack.is_empty()));
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

/// `list_log.csv` as develop would write it for the records so far.
fn list_log_rows() -> Vec<String> {
    let dir = tempfile::tempdir().unwrap();
    snapshot(|s| {
        crate::output::legacy_files::LegacyLogs::replay(
            &s.memtrack,
            &s.nondets,
            s.failed_free.as_ref(),
            false,
        )
        .write_list_log(dir.path())
    })
    .unwrap();
    std::fs::read_to_string(dir.path().join("list_log.csv"))
        .unwrap()
        .lines()
        .map(str::to_owned)
        .collect()
}

#[test]
fn list_log_free_row_names_the_variable_passed_to_free() {
    // develop `map2check_free` (AnalysisModeMemtrack.c:339-347) takes the
    // pointer variable's slot, so its FREE row names that variable even
    // when another variable holds the same block (SD-17 before Task 2.5).
    let _guard = fresh();
    // SAFETY: C-string literals are valid; fake addresses are never dereferenced.
    unsafe {
        map2check_map_malloc(addr(0x3000), 8);
        map2check_map_store_pointer(
            addr(0x10),
            addr(0x3000),
            0,
            c"p".as_ptr(),
            1,
            c"main".as_ptr(),
        );
        map2check_map_store_pointer(
            addr(0x20),
            addr(0x3000),
            0,
            c"q".as_ptr(),
            2,
            c"main".as_ptr(),
        );
        map2check_check_free(
            c"p".as_ptr(),
            addr(0x10),
            addr(0x3000),
            0,
            3,
            c"main".as_ptr(),
        );
        map2check_map_free(
            c"p".as_ptr(),
            addr(0x10),
            addr(0x3000),
            0,
            3,
            c"main".as_ptr(),
        );
    }
    assert_ok();
    let rows = list_log_rows();
    assert_eq!(rows[2], "0;0x10;0x3000;0;1;0;p;3;main;2", "{rows:#?}");
}

#[test]
fn failing_free_keeps_its_list_log_row_like_develop() {
    // develop appends the FREE row before `is_invalid_free` decides
    // (AnalysisModeMemtrack.c:346-358); the check here runs first, so it
    // keeps the row for the legacy logs.
    let _guard = fresh();
    // SAFETY: C-string literals are valid; fake addresses are never dereferenced.
    unsafe {
        map2check_map_malloc(addr(0x3000), 8);
        map2check_map_store_pointer(
            addr(0x10),
            addr(0x3000),
            0,
            c"p".as_ptr(),
            1,
            c"main".as_ptr(),
        );
        map2check_check_free(
            c"p".as_ptr(),
            addr(0x10),
            addr(0x3000),
            0,
            2,
            c"main".as_ptr(),
        );
        map2check_map_free(
            c"p".as_ptr(),
            addr(0x10),
            addr(0x3000),
            0,
            2,
            c"main".as_ptr(),
        );
        map2check_check_free(
            c"p".as_ptr(),
            addr(0x10),
            addr(0x3000),
            0,
            3,
            c"main".as_ptr(),
        );
    }
    assert_violated(ViolatedProperty::MemsafetyFree, 3, "main");
    let rows = list_log_rows();
    assert_eq!(rows.len(), 3, "{rows:#?}");
    assert_eq!(rows[2], "0;0x10;0x3000;0;1;0;p;3;main;2");
    // Not a release: the memory records are unchanged by the failed free.
    assert_eq!(snapshot(|s| s.memtrack.len()), 3);
}

#[test]
fn vcc_reset_meta_data_drops_the_failing_free_row() {
    let _guard = fresh();
    // SAFETY: C-string literals are valid; fake addresses are never dereferenced.
    unsafe {
        map2check_check_free(
            c"p".as_ptr(),
            addr(0x10),
            addr(0x3000),
            0,
            3,
            c"main".as_ptr(),
        )
    };
    assert!(snapshot(|s| s.failed_free.is_some()));
    vcc_reset_meta_data();
    assert!(snapshot(|s| s.failed_free.is_none()));
}

#[test]
fn only_the_first_violation_keeps_a_failing_free_row() {
    let _guard = fresh();
    // SAFETY: C-string literals are valid; fake addresses are never dereferenced.
    unsafe {
        map2check_binop_add_signed(i64::MAX, 1, 64, 1, c"main".as_ptr());
        map2check_check_free(
            c"p".as_ptr(),
            addr(0x10),
            addr(0x3000),
            0,
            3,
            c"main".as_ptr(),
        );
    }
    assert!(snapshot(|s| s.failed_free.is_none()));
}

#[test]
fn map_free_records_released_slot() {
    let _guard = fresh();
    // SAFETY: C-string literals are valid; fake address is never dereferenced.
    unsafe {
        map2check_map_free(
            c"p".as_ptr(),
            addr(0x10),
            addr(0x1000),
            1,
            9,
            c"main".as_ptr(),
        )
    };
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

// ── Signed binops at the operation's width (Task 2.5, AnalysisModeOverflow.c) ──

type SignedBinop = unsafe extern "C" fn(i64, i64, u32, u32, *const std::os::raw::c_char);

/// What one call of a signed binop export records on a fresh analysis.
fn signed_outcome(op: SignedBinop, a: i64, b: i64, bits: u32) -> ViolatedProperty {
    state::reset();
    // SAFETY: C-string literal is valid and null-terminated.
    unsafe { op(a, b, bits, 4, c"f".as_ptr()) };
    let result = snapshot(|s| s.result.clone());
    if !result.ok {
        assert_eq!((result.line, result.function_name.as_str()), (4, "f"));
    }
    result.property
}

/// `signed_min_for_width` / `signed_max_for_width` of develop
/// (`AnalysisModeOverflow.c:111-124`).
fn signed_bounds(bits: u32) -> (i64, i64) {
    if bits == 0 || bits >= 64 {
        (i64::MIN, i64::MAX)
    } else {
        (-(1i64 << (bits - 1)), (1i64 << (bits - 1)) - 1)
    }
}

#[test]
fn signed_binops_check_every_width_like_develop() {
    let _guard = fresh();
    let add: SignedBinop = map2check_binop_add_signed;
    let sub: SignedBinop = map2check_binop_sub_signed;
    let mul: SignedBinop = map2check_binop_mul_signed;
    let div: SignedBinop = map2check_binop_div_signed;
    let rem: SignedBinop = map2check_binop_rem_signed;
    // 8/16/32/64 are what C types give; the pass sends any width up to 64
    // (OverflowPass.cpp:426), and develop treats 0 like 64.
    for bits in [8, 16, 32, 64, 1, 24, 0] {
        let (min, max) = signed_bounds(bits);
        let cases: [(&str, SignedBinop, i64, i64, ViolatedProperty); 14] = [
            ("max+1", add, max, 1, P::Overflow),
            ("(max-1)+1", add, max - 1, 1, P::None),
            ("min-1", sub, min, 1, P::Overflow),
            ("(min+1)-1", sub, min + 1, 1, P::None),
            ("min*-1", mul, min, -1, P::Overflow),
            ("max*-1", mul, max, -1, P::None),
            ("min/-1", div, min, -1, P::Overflow),
            ("max/-1", div, max, -1, P::None),
            ("min%-1", rem, min, -1, P::Overflow),
            ("max%-1", rem, max, -1, P::None),
            ("x/0", div, max, 0, P::DivByZero),
            ("x/1", div, max, 1, P::None),
            ("x%0", rem, min, 0, P::DivByZero),
            ("x%1", rem, min, 1, P::None),
        ];
        for (name, op, a, b, expected) in cases {
            assert_eq!(
                signed_outcome(op, a, b, bits),
                expected,
                "{name} em {bits} bits ({a}, {b})"
            );
        }
    }
}

#[test]
fn signed_binops_follow_develop_on_operands_wider_than_the_width() {
    let _guard = fresh();
    let add: SignedBinop = map2check_binop_add_signed;
    let mul: SignedBinop = map2check_binop_mul_signed;
    let div: SignedBinop = map2check_binop_div_signed;
    // 64-bit predicates first (AnalysisModeOverflow.c:141-183), then the
    // range of the width: an i64 product that wraps is caught even at 8 bits.
    assert_eq!(signed_outcome(mul, i64::MAX, 2, 8), P::Overflow);
    assert_eq!(signed_outcome(add, i64::MIN, -1, 32), P::Overflow);
    assert_eq!(signed_outcome(mul, -128, -1, 8), P::Overflow);
    assert_eq!(signed_outcome(mul, 0, i64::MIN, 64), P::None);
    // Division compares only the dividend with the width's minimum (:259),
    // so MIN/-1 of a wider width is not an overflow at a narrower one.
    assert_eq!(signed_outcome(div, i64::from(i32::MIN), -1, 16), P::None);
    assert_eq!(signed_outcome(div, 0, 0, 32), P::DivByZero);
}

#[test]
fn signed_binops_are_gated_like_the_other_binops() {
    let _guard = fresh();
    let calls: [(SignedBinop, i64, i64); 3] = [
        (map2check_binop_add_signed, i64::from(i32::MAX), 1),
        (map2check_binop_div_signed, 1, 0),
        (map2check_binop_rem_signed, 1, 0),
    ];
    for mode in MODES {
        for (op, a, b) in calls {
            state::reset();
            map2check_set_mode(mode as i32);
            map2check_init(0);
            // SAFETY: C-string literal is valid and null-terminated.
            unsafe { op(a, b, 32, 4, c"f".as_ptr()) };
            let reported = !snapshot(|s| s.result.ok);
            assert_eq!(reported, mode == AnalysisMode::Overflow, "{mode:?}");
        }
    }
    state::reset_config();
    state::reset();
    // Unset mode: every check is active.
    // SAFETY: C-string literal is valid and null-terminated.
    unsafe { map2check_binop_div_signed(1, 0, 32, 4, c"f".as_ptr()) };
    assert_violated(ViolatedProperty::DivByZero, 4, "f");
}

#[test]
fn signed_binop_violation_is_final() {
    let _guard = fresh();
    // SAFETY: C-string literals are valid and null-terminated.
    unsafe {
        map2check_binop_rem_signed(1, 0, 32, 4, c"f".as_ptr());
        map2check_binop_add_signed(i64::MAX, 1, 64, 9, c"g".as_ptr());
    }
    assert_violated(ViolatedProperty::DivByZero, 4, "f");
}

#[test]
fn signed_binops_called_as_c_does() {
    let _guard = fresh();
    // As the pass emits them: i32 operands sign-extended, width 32.
    // SAFETY: C-string literals are valid and null-terminated.
    unsafe {
        map2check_binop_add_signed(-5, 3, 32, 1, c"main".as_ptr());
        map2check_binop_sub_signed(-5, 3, 32, 1, c"main".as_ptr());
        map2check_binop_mul_signed(-5, 3, 32, 1, c"main".as_ptr());
        map2check_binop_div_signed(-5, 3, 32, 1, c"main".as_ptr());
        map2check_binop_rem_signed(-5, 3, 32, 1, c"main".as_ptr());
    }
    assert_ok();
    // SAFETY: as above.
    unsafe { map2check_binop_sub_signed(i64::from(i16::MIN), 1, 16, 2, c"main".as_ptr()) };
    assert_violated(ViolatedProperty::Overflow, 2, "main");
    state::reset();
    // SAFETY: as above.
    unsafe { map2check_binop_mul_signed(i64::from(i8::MIN), -1, 8, 3, c"main".as_ptr()) };
    assert_violated(ViolatedProperty::Overflow, 3, "main");
}

#[test]
fn set_false_result_accepts_div_by_zero() {
    let _guard = fresh();
    // SAFETY: C-string literal is valid and null-terminated.
    unsafe { set_false_result(ViolatedProperty::DivByZero as i32, 3, c"main".as_ptr()) };
    assert_violated(ViolatedProperty::DivByZero, 3, "main");
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
        set_false_result(ViolatedProperty::Reachability as i32, 1, c"main".as_ptr());
        map2check_check_load(addr(0x1000), 2, 0, 4, c"main".as_ptr());
    }
    assert_violated(ViolatedProperty::Reachability, 1, "main");
    assert_eq!(get_current_property(), ViolatedProperty::Reachability);

    // SAFETY: as above.
    unsafe {
        map2check_check_deref(addr(0x1000), 0, 3, c"main".as_ptr());
        map2check_check_free(
            c"p".as_ptr(),
            addr(0x10),
            addr(0x1000),
            0,
            4,
            c"main".as_ptr(),
        );
        map2check_check_free_resolved_address(addr(0x1000), 5, c"main".as_ptr(), 0);
        map2check_map_free(
            c"p".as_ptr(),
            addr(0x10),
            addr(0x1000),
            0,
            5,
            c"main".as_ptr(),
        );
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
        map2check_check_free(
            c"p".as_ptr(),
            addr(0x10),
            addr(0x9000),
            0,
            8,
            c"main".as_ptr(),
        );
        map2check_check_deref(std::ptr::null(), 0, 9, c"main".as_ptr());
        set_false_result(ViolatedProperty::Reachability as i32, 10, c"main".as_ptr());
        map2check_binop_add_int(i32::MAX, 1, 11, 0, c"main".as_ptr());
    }
    assert_violated(ViolatedProperty::MemsafetyDeref, 7, "first");
}

// ── #11: validity follows the latest alloc/free event ───────────────────────

#[test]
fn deref_after_free_is_invalid() {
    let _guard = fresh();
    map2check_init(0);
    // SAFETY: C-string literals are valid; fake addresses are never dereferenced.
    unsafe {
        map2check_map_malloc(addr(0x2000), 16);
        map2check_map_free(
            c"p".as_ptr(),
            addr(0x10),
            addr(0x2000),
            0,
            9,
            c"main".as_ptr(),
        );
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
        map2check_map_free(
            c"p".as_ptr(),
            addr(0x10),
            addr(0x2000),
            0,
            9,
            c"main".as_ptr(),
        );
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
        map2check_map_free(
            c"p".as_ptr(),
            addr(0x10),
            addr(0x2000),
            0,
            9,
            c"main".as_ptr(),
        );
        map2check_map_malloc(addr(0x2000), 16);
        map2check_check_load(addr(0x2004), 10, 0, 4, c"main".as_ptr());
        map2check_check_deref(addr(0x2000), 0, 11, c"main".as_ptr());
        map2check_check_free(
            c"p".as_ptr(),
            addr(0x10),
            addr(0x2000),
            0,
            12,
            c"main".as_ptr(),
        );
        map2check_check_free_resolved_address(addr(0x2000), 13, c"main".as_ptr(), 0);
    }
    assert_ok();

    // SAFETY: as above.
    unsafe {
        map2check_map_free(
            c"p".as_ptr(),
            addr(0x10),
            addr(0x2000),
            0,
            14,
            c"main".as_ptr(),
        );
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
        map2check_map_free(
            c"p".as_ptr(),
            addr(0x10),
            addr(0x2000),
            0,
            9,
            c"main".as_ptr(),
        );
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
        map2check_map_free(
            c"p".as_ptr(),
            addr(0x10),
            addr(0x2000),
            0,
            9,
            c"main".as_ptr(),
        );
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
        map2check_check_free(
            c"p".as_ptr(),
            addr(0x10),
            addr(0x1000),
            0,
            20,
            c"main".as_ptr(),
        );
    }
    assert_ok();
    // SAFETY: as above.
    unsafe {
        map2check_check_free(
            c"p".as_ptr(),
            addr(0x10),
            std::ptr::null(),
            0,
            20,
            c"main".as_ptr(),
        )
    };
    assert_ok();
}

#[test]
fn check_free_rejects_double_free_and_untracked_address() {
    let _guard = fresh();
    // SAFETY: C-string literals are valid; fake addresses are never dereferenced.
    unsafe {
        map2check_map_malloc(addr(0x1000), 16);
        map2check_map_free(
            c"p".as_ptr(),
            addr(0x10),
            addr(0x1000),
            0,
            19,
            c"main".as_ptr(),
        );
        map2check_check_free(
            c"p".as_ptr(),
            addr(0x10),
            addr(0x1000),
            0,
            20,
            c"main".as_ptr(),
        );
    }
    assert_violated(ViolatedProperty::MemsafetyFree, 20, "main");

    state::reset();
    // SAFETY: as above.
    unsafe {
        map2check_check_free(
            c"p".as_ptr(),
            addr(0x10),
            addr(0x9000),
            0,
            21,
            c"main".as_ptr(),
        )
    };
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
        map2check_map_free(
            c"p".as_ptr(),
            addr(0x10),
            addr(0x1000),
            0,
            30,
            c"main".as_ptr(),
        );
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
    unsafe {
        map2check_check_free(
            c"p".as_ptr(),
            addr(0x10),
            addr(0x5000),
            0,
            4,
            c"main".as_ptr(),
        )
    };
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
        map2check_check_free(
            c"p".as_ptr(),
            addr(0x10),
            addr(0x2000),
            0,
            4,
            c"main".as_ptr(),
        );
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
        map2check_map_free(
            c"p".as_ptr(),
            addr(0x10),
            addr(0x1000),
            0,
            41,
            c"main".as_ptr(),
        );
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
        map2check_map_free(
            c"p".as_ptr(),
            addr(0x10),
            addr(0x1000),
            0,
            50,
            c"main".as_ptr(),
        );
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
    use std::os::raw::{c_longlong, c_uint, c_ulong};
    let _: NonDet<c_uint> = map2check_save_nondet_log_unsigned; // unsigned int *value
    let _: NonDet<c_ulong> = map2check_save_nondet_log_ulong; // unsigned long *value
    let _: NonDet<u8> = map2check_save_nondet_log_uchar; // unsigned char *value
    let _: NonDet<i16> = map2check_save_nondet_log_short; // short *value
    let _: NonDet<u16> = map2check_save_nondet_log_ushort; // unsigned short *value
    let _: NonDet<i32> = map2check_save_nondet_log_bool; // int *value
    let _: NonDet<usize> = map2check_save_nondet_log_size_t; // size_t *value
    let _: NonDet<c_longlong> = map2check_save_nondet_log_loff_t; // long long *value
    let _: NonDet<c_ulong> = map2check_save_nondet_log_sector_t; // unsigned long *value
    let _: NonDet<*mut c_void> = map2check_save_nondet_log_pointer; // void **value
    let _: NonDet<*mut c_char> = map2check_save_nondet_log_pchar; // char **value
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
    map2check_init(0);
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
    map2check_init(0);
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
    map2check_init(0);
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

    map2check_init(0);
    assert_eq!(observed_options(), expected);

    map2check_reset();
    assert_eq!(observed_options(), expected);
}

#[test]
fn enable_witness_is_configuration_kept_by_init_and_reset() {
    let _guard = fresh();
    assert!(!state::config().witness);
    map2check_enable_witness();
    assert!(state::config().witness);
    map2check_init(0);
    map2check_reset();
    assert!(state::config().witness);
    // Configuration only: it records nothing.
    assert_ok();
    assert_eq!(snapshot(|s| s.current_step()), 0);
}

/// `__m2c_rt_witness_enable` is the C ABI of the old
/// `map2check_enable_witness` (Task 2.10): the same configuration.
#[test]
fn witness_enable_entry_point_turns_on_the_witness_and_init_keeps_it() {
    let _guard = fresh();
    assert!(!state::config().witness);
    __m2c_rt_witness_enable();
    assert!(state::config().witness);
    map2check_init(0);
    assert!(state::config().witness);
    assert_ok();
    assert_eq!(snapshot(|s| s.current_step()), 0);
}

#[test]
fn malloc_null_reports_unknown_in_memory_modes_only() {
    // develop: map2check_malloc with a NULL block writes
    // map2check_property__unknown and ends the run (AnalysisModeMemtrack.c:305-311).
    let _guard = fresh();
    for mode in [AnalysisMode::Memtrack, AnalysisMode::Memcleanup] {
        start(mode);
        // SAFETY: a NULL block is only compared.
        unsafe { map2check_map_malloc(std::ptr::null(), 4) };
        assert_violated(ViolatedProperty::Unknown, 0, "");
        assert!(snapshot(|s| s.memtrack.is_empty()));
        start(mode);
        // SAFETY: as above.
        unsafe { map2check_map_calloc(std::ptr::null(), 2, 4) };
        assert_violated(ViolatedProperty::Unknown, 0, "");
    }
    for mode in [AnalysisMode::Overflow, AnalysisMode::None] {
        start(mode);
        // SAFETY: as above.
        unsafe { map2check_map_malloc(std::ptr::null(), 4) };
        assert_ok();
        assert_eq!(snapshot(|s| s.memtrack.len()), 1);
    }
    state::reset_config();
    state::reset();
    // SAFETY: as above.
    unsafe { map2check_map_malloc(std::ptr::null(), 4) };
    assert_ok();
}

#[test]
fn malloc_null_is_unknown_before_the_size_is_looked_at() {
    // develop tests the block before anything else (AnalysisModeMemtrack.c:305-311),
    // so a NULL block is UNKNOWN whatever the size. The pass truncates the
    // size to `int`: `malloc(4 * n)` that fails because it is over 2 GiB
    // arrives here as NULL with a negative size. Dropping that call as SD-09
    // let the program run on with the NULL block (task-2.7c-report.md).
    let _guard = fresh();
    for mode in [AnalysisMode::Memtrack, AnalysisMode::Memcleanup] {
        start(mode);
        // SAFETY: a NULL block is only compared.
        unsafe { map2check_map_malloc(std::ptr::null(), i32::MIN + 0x0100_0000) };
        assert_violated(ViolatedProperty::Unknown, 0, "");
        for (quantity, size) in [(-1, 4), (2, -4)] {
            start(mode);
            // SAFETY: as above.
            unsafe { map2check_map_calloc(std::ptr::null(), quantity, size) };
            assert_violated(ViolatedProperty::Unknown, 0, "");
        }
    }
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
    map2check_set_mode(mode as i32);
    map2check_init(0);
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
        &|| unsafe {
            map2check_check_free(
                c"p".as_ptr(),
                addr(0x10),
                addr(0xdead),
                0,
                1,
                c"main".as_ptr(),
            )
        },
        &|| unsafe { map2check_check_free_resolved_address(addr(0xdead), 1, c"main".as_ptr(), 0) },
        &|| unsafe { map2check_binop_add_int(i32::MAX, 1, 1, 0, c"main".as_ptr()) },
        &|| unsafe { map2check_is_valid_assert(1, c"main".as_ptr(), 0) },
        &|| {
            // A leak still referenced by `p`, so it counts in every leak mode.
            // SAFETY: fake addresses are never dereferenced.
            unsafe {
                map2check_map_malloc(addr(0x3000), 8);
                map2check_map_store_pointer(
                    addr(0x10),
                    addr(0x3000),
                    0,
                    c"p".as_ptr(),
                    1,
                    c"main".as_ptr(),
                );
            }
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
    map2check_set_mode(AnalysisMode::None as i32);
    map2check_init(0);
    // SAFETY: C-string literal is valid; fake address is never dereferenced.
    unsafe { map2check_check_deref(addr(0xdead), 0, 1, c"main".as_ptr()) };
    assert_ok();
}

#[test]
fn mode_memtrack_reports_invalid_deref() {
    let _guard = fresh();
    map2check_set_mode(AnalysisMode::Memtrack as i32);
    map2check_init(0);
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
        &|| unsafe {
            map2check_check_free(
                c"p".as_ptr(),
                addr(0x10),
                addr(0xdead),
                0,
                1,
                c"main".as_ptr(),
            )
        },
        &|| unsafe { map2check_check_free_resolved_address(addr(0xdead), 1, c"main".as_ptr(), 0) },
        &|| unsafe { map2check_binop_add_int(i32::MAX, 1, 1, 0, c"main".as_ptr()) },
        &|| unsafe { map2check_is_valid_assert(1, c"main".as_ptr(), 0) },
        &|| {
            // A leak still referenced by `p`, so it counts in every leak mode.
            // SAFETY: fake addresses are never dereferenced.
            unsafe {
                map2check_map_malloc(addr(0x3000), 8);
                map2check_map_store_pointer(
                    addr(0x10),
                    addr(0x3000),
                    0,
                    c"p".as_ptr(),
                    1,
                    c"main".as_ptr(),
                );
            }
            map2check_check_mem_endprog();
        },
    ];
    for (slot, run) in out.iter_mut().zip(runs) {
        state::reset();
        map2check_init(0);
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
        map2check_set_mode(mode as i32);
        map2check_init(0);
        assert_eq!(state::config().mode, Some(mode));
        map2check_reset();
        assert_eq!(state::config().mode, Some(mode));
    }
}

#[test]
fn reset_keeps_selected_mode() {
    let _guard = fresh();
    map2check_set_mode(AnalysisMode::Overflow as i32);
    map2check_init(0);
    map2check_reset();
    assert_eq!(state::config().mode, Some(AnalysisMode::Overflow));
}

#[test]
fn reach_target_sets_target_reached() {
    let _guard = fresh();
    map2check_set_mode(AnalysisMode::Target as i32);
    map2check_init(0);
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
        set_false_result(ViolatedProperty::Overflow as i32, 3, c"f".as_ptr());
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
    unsafe { set_false_result(ViolatedProperty::Assert as i32, 4, c"main".as_ptr()) };
    assert_violated(ViolatedProperty::Assert, 4, "main");
    state::reset();
    // SAFETY: as above.
    unsafe { set_false_result(ViolatedProperty::Unknown as i32, 0, c"main".as_ptr()) };
    assert_violated(ViolatedProperty::Unknown, 0, "main");
}

// ── I-1: map2check_set_mode validates its raw value ────────────────────────

#[test]
fn set_mode_accepts_a_valid_raw_value() {
    let _guard = fresh();
    map2check_set_mode(2);
    assert_eq!(state::config().mode, Some(AnalysisMode::Memcleanup));
}

#[test]
fn set_mode_ignores_out_of_range_values() {
    let _guard = fresh();
    map2check_set_mode(AnalysisMode::Overflow as i32);
    for raw in [-1, 6, i32::MAX] {
        map2check_set_mode(raw);
        assert_eq!(
            state::config().mode,
            Some(AnalysisMode::Overflow),
            "raw {raw}"
        );
    }
}

#[test]
fn set_mode_out_of_range_before_any_mode_keeps_it_unset() {
    let _guard = fresh();
    map2check_set_mode(-1);
    assert_eq!(state::config().mode, None);
}

// ── I-2: memcleanup mode follows develop's last-leak + reference rule ──────

/// Stores `value` into the pointer variable at `var` (`var = value;`).
fn store(var: usize, value: usize) {
    // SAFETY: C-string literals are valid; fake addresses are never dereferenced.
    unsafe {
        map2check_map_store_pointer(
            addr(var),
            addr(value),
            0,
            c"p".as_ptr(),
            1,
            c"main".as_ptr(),
        )
    };
}

fn malloc_at(a: usize) {
    // SAFETY: fake address is never dereferenced.
    unsafe { map2check_map_malloc(addr(a), 8) };
}

fn memcleanup_endprog() -> ViolatedProperty {
    map2check_check_mem_endprog();
    snapshot(|s| s.result.property)
}

#[test]
fn memcleanup_mode_leak_still_pointed_to_is_memcleanup() {
    let _guard = fresh();
    start(AnalysisMode::Memcleanup);
    malloc_at(0x3000);
    store(0x10, 0x3000);
    map2check_check_mem_endprog();
    assert_violated(P::MemsafetyMemcleanup, 0, "end_of_program");
}

#[test]
fn memcleanup_mode_leak_whose_pointer_was_overwritten_has_no_verdict() {
    let _guard = fresh();
    start(AnalysisMode::Memcleanup);
    malloc_at(0x3000);
    store(0x10, 0x3000);
    store(0x10, 0);
    assert_eq!(memcleanup_endprog(), P::None);
}

#[test]
fn memcleanup_mode_leak_never_stored_has_no_verdict() {
    let _guard = fresh();
    start(AnalysisMode::Memcleanup);
    malloc_at(0x3000);
    assert_eq!(memcleanup_endprog(), P::None);
}

#[test]
fn memcleanup_mode_checks_only_the_last_leak() {
    // valid_allocation_log returns the last leaked address only
    // (AllocationLog.c:69-101): the referenced earlier leak is not checked.
    let _guard = fresh();
    start(AnalysisMode::Memcleanup);
    malloc_at(0x3000);
    malloc_at(0x4000);
    store(0x10, 0x3000);
    assert_eq!(memcleanup_endprog(), P::None);

    start(AnalysisMode::Memcleanup);
    malloc_at(0x3000);
    malloc_at(0x4000);
    store(0x10, 0x4000);
    assert_eq!(memcleanup_endprog(), P::MemsafetyMemcleanup);
}

#[test]
fn memcleanup_mode_another_pointer_keeps_the_leak_reachable() {
    let _guard = fresh();
    start(AnalysisMode::Memcleanup);
    malloc_at(0x3000);
    store(0x10, 0x3000);
    store(0x20, 0x3000);
    store(0x10, 0);
    assert_eq!(memcleanup_endprog(), P::MemsafetyMemcleanup);
}

#[test]
fn memcleanup_mode_freed_block_is_no_leak() {
    let _guard = fresh();
    start(AnalysisMode::Memcleanup);
    malloc_at(0x3000);
    store(0x10, 0x3000);
    // SAFETY: C-string literals are valid; fake address is never dereferenced.
    unsafe {
        map2check_map_free(
            c"p".as_ptr(),
            addr(0x10),
            addr(0x3000),
            0,
            2,
            c"main".as_ptr(),
        )
    };
    assert_eq!(memcleanup_endprog(), P::None);
}

#[test]
fn memcleanup_mode_free_of_an_old_target_re_points_the_variable_as_develop() {
    // update_reference_list_log (AnalysisModeMemcleanup.c:181-240) appends a
    // FREE copy of `p = A` when A is freed, so `p` reads as pointing to A
    // again and B (the last leak) is no longer referenced by it.
    let _guard = fresh();
    start(AnalysisMode::Memcleanup);
    malloc_at(0x3000);
    malloc_at(0x4000);
    store(0x10, 0x3000);
    store(0x10, 0x4000);
    // SAFETY: C-string literal is valid; fake address is never dereferenced.
    unsafe { map2check_check_free_resolved_address(addr(0x3000), 3, c"main".as_ptr(), 0) };
    assert_eq!(memcleanup_endprog(), P::None);
}

#[test]
fn memtrack_mode_reports_any_leak_reachable_or_not() {
    // AnalysisModeMemtrack.c:138-146: any address from valid_allocation_log.
    let _guard = fresh();
    start(AnalysisMode::Memtrack);
    malloc_at(0x3000);
    assert_eq!(memcleanup_endprog(), P::MemsafetyMemtrack);
    start(AnalysisMode::Memtrack);
    malloc_at(0x3000);
    store(0x10, 0x3000);
    store(0x10, 0);
    assert_eq!(memcleanup_endprog(), P::MemsafetyMemtrack);
}

// ── wasm2c runtime (feature `wasm`, Task 2.8) ───────────────────────────────
//
// The three `map2check_wasm_*` exports follow `AnalysisModeMemtrack.c:385-430`
// of Map2Check `develop`; the `wasm_rt_*` stubs follow `WasmRuntimeStubs.c`.

#[cfg(feature = "wasm")]
mod wasm {
    use super::*;
    use crate::wasm::{
        __m2c_rt_wasm_allocate_funcref_table, __m2c_rt_wasm_allocate_memory, __m2c_rt_wasm_free,
        __m2c_rt_wasm_free_funcref_table, __m2c_rt_wasm_free_memory, __m2c_rt_wasm_grow_memory,
        __m2c_rt_wasm_init, __m2c_rt_wasm_is_initialized, __m2c_rt_wasm_trap,
        map2check_wasm_check_access, map2check_wasm_free, map2check_wasm_malloc,
        wasm_rt_allocate_funcref_table, wasm_rt_allocate_memory, wasm_rt_free,
        wasm_rt_free_funcref_table, wasm_rt_free_memory, wasm_rt_funcref_table_t,
        wasm_rt_grow_memory, wasm_rt_init, wasm_rt_is_initialized, wasm_rt_memory_t,
    };

    fn started(mode: Option<AnalysisMode>) {
        map2check_reset();
        state::reset_config();
        if let Some(m) = mode {
            map2check_set_mode(m as i32);
        }
        map2check_init(0);
    }

    fn mem() -> wasm_rt_memory_t {
        // SAFETY: an all-zero memory descriptor is what wasm2c hands the
        // allocator (null pointers, zero counters).
        unsafe { std::mem::zeroed() }
    }

    // ── map2check_wasm_malloc ───────────────────────────────────────────────

    #[test]
    fn wasm_malloc_registers_a_block_whose_accesses_are_valid() {
        let _guard = fresh();
        started(Some(AnalysisMode::Memtrack));
        map2check_wasm_malloc(0x1000, 16);
        map2check_wasm_check_access(0x1000, 4);
        map2check_wasm_check_access(0x100c, 4);
        map2check_wasm_check_access(0x100f, 1);
        assert_ok();
    }

    #[test]
    fn wasm_malloc_ignores_null_and_failed_allocations() {
        // AnalysisModeMemtrack.c:386: offset 0 and (uint64_t)-1 are no block.
        let _guard = fresh();
        started(Some(AnalysisMode::Memtrack));
        map2check_wasm_malloc(0, 16);
        map2check_wasm_malloc(u64::MAX, 16);
        assert!(snapshot(|s| s.wasm_allocs.is_empty()));
    }

    #[test]
    fn wasm_malloc_of_a_known_offset_resizes_and_revives_it() {
        // AnalysisModeMemtrack.c:387-391: same offset -> size and is_free
        // updated in place, no second row.
        let _guard = fresh();
        started(Some(AnalysisMode::Memtrack));
        map2check_wasm_malloc(0x1000, 8);
        map2check_wasm_free(0x1000, 3);
        map2check_wasm_malloc(0x1000, 32);
        assert_eq!(snapshot(|s| s.wasm_allocs.len()), 1);
        map2check_wasm_check_access(0x101c, 4);
        assert_ok();
    }

    #[test]
    fn wasm_malloc_truncates_the_size_to_unsigned_as_develop() {
        // `row->size = (unsigned)size` (AnalysisModeMemtrack.c:389).
        let _guard = fresh();
        started(Some(AnalysisMode::Memtrack));
        map2check_wasm_malloc(0x1000, (1u64 << 32) | 8);
        assert_eq!(snapshot(|s| s.wasm_allocs[0].size), 8);
    }

    // ── map2check_wasm_free ─────────────────────────────────────────────────

    #[test]
    fn wasm_free_of_a_tracked_block_marks_it_free_with_size_zero() {
        let _guard = fresh();
        started(Some(AnalysisMode::Memtrack));
        map2check_wasm_malloc(0x1000, 16);
        map2check_wasm_free(0x1000, 7);
        assert_ok();
        snapshot(|s| {
            assert!(s.wasm_allocs[0].is_free);
            assert_eq!(s.wasm_allocs[0].size, 0);
        });
    }

    #[test]
    fn wasm_free_of_an_untracked_offset_is_a_false_free_at_the_line() {
        // AnalysisModeMemtrack.c:401: write_property(FALSE_FREE, line, "").
        let _guard = fresh();
        started(Some(AnalysisMode::Memtrack));
        map2check_wasm_free(0x2000, 41);
        assert_violated(ViolatedProperty::MemsafetyFree, 41, "");
    }

    #[test]
    fn wasm_double_free_is_not_reported_as_develop() {
        // develop only looks the row up; a freed row is still a row.
        let _guard = fresh();
        started(Some(AnalysisMode::Memtrack));
        map2check_wasm_malloc(0x1000, 16);
        map2check_wasm_free(0x1000, 7);
        map2check_wasm_free(0x1000, 8);
        assert_ok();
    }

    // ── map2check_wasm_check_access ─────────────────────────────────────────

    #[test]
    fn wasm_access_past_the_block_is_reported_as_develop_does() {
        // AnalysisModeMemtrack.c:420-423: FALSE_OVERFLOW, line 0, no function
        // (the report tag is OVERFLOW; see SD-wasm-access in semantic-deltas).
        let _guard = fresh();
        started(Some(AnalysisMode::Memtrack));
        map2check_wasm_malloc(0x1000, 16);
        map2check_wasm_check_access(0x1010, 4);
        assert_violated(ViolatedProperty::Overflow, 0, "");
    }

    #[test]
    fn wasm_access_straddling_the_end_is_invalid() {
        let _guard = fresh();
        started(Some(AnalysisMode::Memtrack));
        map2check_wasm_malloc(0x1000, 16);
        map2check_wasm_check_access(0x100d, 4);
        assert_violated(ViolatedProperty::Overflow, 0, "");
    }

    #[test]
    fn wasm_access_below_the_block_is_invalid() {
        let _guard = fresh();
        started(Some(AnalysisMode::Memtrack));
        map2check_wasm_malloc(0x1000, 16);
        map2check_wasm_check_access(0xfff, 1);
        assert_violated(ViolatedProperty::Overflow, 0, "");
    }

    #[test]
    fn wasm_access_after_free_is_invalid() {
        let _guard = fresh();
        started(Some(AnalysisMode::Memtrack));
        map2check_wasm_malloc(0x1000, 16);
        map2check_wasm_free(0x1000, 5);
        map2check_wasm_check_access(0x1000, 4);
        assert_violated(ViolatedProperty::Overflow, 0, "");
    }

    #[test]
    fn wasm_access_with_no_block_is_invalid() {
        let _guard = fresh();
        started(Some(AnalysisMode::Memtrack));
        map2check_wasm_check_access(0x1000, 1);
        assert_violated(ViolatedProperty::Overflow, 0, "");
    }

    #[test]
    fn wasm_access_inside_a_freed_inner_block_is_covered_by_the_older_block() {
        // A freed row keeps size 0, so its range
        // `[offset, offset + 0 - access + 1)` is empty and the scan goes on
        // to the older row that still covers the address
        // (AllocationLog.c:127-148). Develop's behaviour, kept as is.
        let _guard = fresh();
        started(Some(AnalysisMode::Memtrack));
        map2check_wasm_malloc(0x1000, 64);
        map2check_wasm_malloc(0x1010, 16);
        map2check_wasm_free(0x1010, 5);
        map2check_wasm_check_access(0x1014, 4);
        assert_ok();
    }

    #[test]
    fn wasm_first_violation_is_final() {
        let _guard = fresh();
        started(Some(AnalysisMode::Memtrack));
        map2check_wasm_free(0x2000, 41);
        map2check_wasm_check_access(0x1000, 1);
        assert_violated(ViolatedProperty::MemsafetyFree, 41, "");
    }

    // ── mode gating ─────────────────────────────────────────────────────────

    #[test]
    fn wasm_checks_are_active_with_the_mode_unset() {
        let _guard = fresh();
        started(None);
        map2check_wasm_check_access(0x1000, 1);
        assert_violated(ViolatedProperty::Overflow, 0, "");
    }

    #[test]
    fn wasm_checks_are_inactive_in_modes_without_memory_checks() {
        for mode in [
            AnalysisMode::None,
            AnalysisMode::Memcleanup,
            AnalysisMode::Overflow,
            AnalysisMode::Assert,
            AnalysisMode::Target,
        ] {
            let _guard = fresh();
            started(Some(mode));
            map2check_wasm_free(0x2000, 41);
            map2check_wasm_check_access(0x1000, 1);
            assert_ok();
        }
    }

    #[test]
    fn wasm_tracking_records_in_every_mode() {
        let _guard = fresh();
        started(Some(AnalysisMode::Memcleanup));
        map2check_wasm_malloc(0x1000, 16);
        assert_eq!(snapshot(|s| s.wasm_allocs.len()), 1);
    }

    #[test]
    fn wasm_table_is_cleared_by_reset_and_init() {
        let _guard = fresh();
        started(Some(AnalysisMode::Memtrack));
        map2check_wasm_malloc(0x1000, 16);
        map2check_init(0);
        assert!(snapshot(|s| s.wasm_allocs.is_empty()));
        map2check_wasm_malloc(0x1000, 16);
        map2check_reset();
        assert!(snapshot(|s| s.wasm_allocs.is_empty()));
    }

    // ── wasm_rt_* stubs (WasmRuntimeStubs.c) ────────────────────────────────

    #[test]
    fn rt_allocate_memory_zeroes_and_sets_every_field() {
        let mut m = mem();
        // SAFETY: `m` is a valid descriptor; freed below.
        unsafe { wasm_rt_allocate_memory(&mut m, 2, 5, false, 65536) };
        assert!(!m.data.is_null());
        assert_eq!(m.size, 2 * 65536);
        assert_eq!(m.pages, 2);
        assert_eq!(m.max_pages, 5);
        assert_eq!(m.page_size, 65536);
        // SAFETY: data_end points one past the allocation that data starts.
        assert_eq!(unsafe { m.data.add(m.size as usize) }, m.data_end);
        // SAFETY: the block is `size` bytes long and calloc'd.
        let all_zero = (0..m.size as usize).all(|i| unsafe { *m.data.add(i) } == 0);
        assert!(all_zero);
        // SAFETY: `m` was allocated above.
        unsafe { wasm_rt_free_memory(&mut m) };
        assert!(m.data.is_null());
        assert_eq!(m.size, 0);
    }

    #[test]
    fn rt_grow_memory_returns_old_pages_and_zero_fills() {
        let mut m = mem();
        // SAFETY: valid descriptor, freed below.
        unsafe {
            wasm_rt_allocate_memory(&mut m, 1, 3, false, 65536);
            *m.data = 0xAA;
            assert_eq!(wasm_rt_grow_memory(&mut m, 0), 1);
            assert_eq!(wasm_rt_grow_memory(&mut m, 1), 1);
        }
        assert_eq!(m.pages, 2);
        assert_eq!(m.size, 2 * 65536);
        // SAFETY: the block now has 2 pages.
        unsafe {
            assert_eq!(*m.data, 0xAA, "old contents are kept");
            assert_eq!(*m.data.add(65536), 0, "new pages are zeroed");
            assert_eq!(*m.data.add(2 * 65536 - 1), 0);
            assert_eq!(m.data.add(m.size as usize), m.data_end);
            wasm_rt_free_memory(&mut m);
        }
    }

    #[test]
    fn rt_grow_memory_past_the_maximum_fails_with_uint32_max() {
        let mut m = mem();
        // SAFETY: valid descriptor, freed below.
        unsafe {
            wasm_rt_allocate_memory(&mut m, 1, 2, false, 65536);
            assert_eq!(wasm_rt_grow_memory(&mut m, 2), u64::from(u32::MAX));
            assert_eq!(wasm_rt_grow_memory(&mut m, u64::MAX), u64::from(u32::MAX));
            wasm_rt_free_memory(&mut m);
        }
        assert_eq!(m.pages, 1);
    }

    #[test]
    fn rt_grow_memory_defaults_a_zero_page_size_to_64k() {
        let mut m = mem();
        // SAFETY: valid descriptor, freed below.
        unsafe {
            wasm_rt_allocate_memory(&mut m, 1, 4, false, 65536);
            m.page_size = 0;
            assert_eq!(wasm_rt_grow_memory(&mut m, 1), 1);
            assert_eq!(m.size, 2 * 65536);
            wasm_rt_free_memory(&mut m);
        }
    }

    #[test]
    fn rt_funcref_table_allocates_zeroed_elements() {
        // SAFETY: an all-zero table descriptor is valid.
        let mut t: wasm_rt_funcref_table_t = unsafe { std::mem::zeroed() };
        // SAFETY: valid descriptor, freed below.
        unsafe { wasm_rt_allocate_funcref_table(&mut t, 4, 10) };
        assert!(!t.data.is_null());
        assert_eq!(t.size, 4);
        // SAFETY: 4 funcref elements, calloc'd, so the last field of the last
        // one is addressable.
        unsafe {
            assert!((*t.data.add(3)).module_instance.is_null());
            wasm_rt_free_funcref_table(&mut t);
        }
        assert!(t.data.is_null());
    }

    #[test]
    fn rt_init_free_and_is_initialized_follow_the_stub() {
        // The stub is "always initialised for KLEE": true from the start,
        // false after wasm_rt_free, true again after wasm_rt_init.
        let _g = INIT_FLAG.lock().unwrap_or_else(|e| e.into_inner());
        wasm_rt_init();
        assert!(wasm_rt_is_initialized());
        wasm_rt_free();
        assert!(!wasm_rt_is_initialized());
        wasm_rt_init();
        assert!(wasm_rt_is_initialized());
    }

    // ── __m2c_rt_wasm_* (the core entry points of WasmRuntimeStubs.ll) ─────
    //
    // The IR module defines the C names `wasm_rt_*` and forwards each one to
    // `__m2c_rt_wasm_*`; the expectations are those of WasmRuntimeStubs.c
    // (line numbers of the develop copy cited per test). The descriptors
    // cross the C ABI as `void *`.

    fn p(m: &mut wasm_rt_memory_t) -> *mut std::os::raw::c_void {
        (m as *mut wasm_rt_memory_t).cast()
    }

    #[test]
    fn m2c_rt_wasm_allocate_memory_zeroes_and_sets_every_field() {
        // WasmRuntimeStubs.c:22-35: calloc(1, page_size * initial_pages); data_end,
        // page_size, size, pages and max_pages set; is64 untouched.
        let mut m = mem();
        m.is64 = true;
        // SAFETY: `m` is a valid descriptor; freed below.
        unsafe { __m2c_rt_wasm_allocate_memory(p(&mut m), 2, 5, false, 65536) };
        assert!(!m.data.is_null());
        assert_eq!(
            (m.size, m.pages, m.max_pages, m.page_size),
            (2 * 65536, 2, 5, 65536)
        );
        assert!(m.is64, "is64 is not written (WasmRuntimeStubs.c:34)");
        // SAFETY: data_end is one past the block that data starts.
        assert_eq!(unsafe { m.data.add(m.size as usize) }, m.data_end);
        // SAFETY: the block is `size` bytes long and calloc'd.
        assert!((0..m.size as usize).all(|i| unsafe { *m.data.add(i) } == 0));
        // SAFETY: allocated above.
        unsafe { __m2c_rt_wasm_free_memory(p(&mut m)) };
    }

    #[test]
    fn m2c_rt_wasm_grow_memory_returns_old_pages_zero_fills_and_fails_with_uint32_max() {
        // WasmRuntimeStubs.c:41-63.
        let mut m = mem();
        // SAFETY: valid descriptor, freed below.
        unsafe {
            __m2c_rt_wasm_allocate_memory(p(&mut m), 1, 3, false, 65536);
            *m.data = 0xAA;
            assert_eq!(__m2c_rt_wasm_grow_memory(p(&mut m), 0), 1, ":47-49");
            assert_eq!(__m2c_rt_wasm_grow_memory(p(&mut m), 1), 1, ":62");
            assert_eq!((m.pages, m.size), (2, 2 * 65536));
            assert_eq!(*m.data, 0xAA, "old contents kept (realloc)");
            assert_eq!(*m.data.add(65536), 0, "new pages zeroed (:57)");
            assert_eq!(m.data.add(m.size as usize), m.data_end, ":59");
            let fail = u64::from(u32::MAX);
            assert_eq!(
                __m2c_rt_wasm_grow_memory(p(&mut m), 2),
                fail,
                "past max_pages (:44-46)"
            );
            assert_eq!(
                __m2c_rt_wasm_grow_memory(p(&mut m), u64::MAX),
                fail,
                "wrap (:44)"
            );
            assert_eq!(m.pages, 2, "a failed grow changes nothing");
            m.page_size = 0;
            assert_eq!(__m2c_rt_wasm_grow_memory(p(&mut m), 1), 2);
            assert_eq!(m.size, 3 * 65536, "zero page_size defaults to 64 KiB (:50)");
            __m2c_rt_wasm_free_memory(p(&mut m));
        }
    }

    #[test]
    fn m2c_rt_wasm_free_memory_nulls_the_data_and_zeroes_the_size() {
        // WasmRuntimeStubs.c:66-70: pages and max_pages are left as they were.
        let mut m = mem();
        // SAFETY: valid descriptor.
        unsafe {
            __m2c_rt_wasm_allocate_memory(p(&mut m), 1, 3, false, 65536);
            __m2c_rt_wasm_free_memory(p(&mut m));
        }
        assert!(m.data.is_null());
        assert_eq!((m.size, m.pages, m.max_pages), (0, 1, 3));
    }

    #[test]
    fn m2c_rt_wasm_funcref_table_allocates_and_frees() {
        // WasmRuntimeStubs.c:73-84 (element size: SD-19).
        // SAFETY: an all-zero table descriptor is valid.
        let mut t: wasm_rt_funcref_table_t = unsafe { std::mem::zeroed() };
        let tp: *mut std::os::raw::c_void = (&mut t as *mut wasm_rt_funcref_table_t).cast();
        // SAFETY: valid descriptor, freed below.
        unsafe { __m2c_rt_wasm_allocate_funcref_table(tp, 4, 10) };
        assert!(!t.data.is_null());
        assert_eq!(
            (t.size, t.max_size),
            (4, 0),
            "max_size is not written (:77)"
        );
        // SAFETY: 4 calloc'd elements.
        unsafe {
            assert!((*t.data.add(3)).module_instance.is_null());
            __m2c_rt_wasm_free_funcref_table(tp);
        }
        assert!(t.data.is_null(), ":83");
        assert_eq!(t.size, 4, "size is not reset (:81-84)");
    }

    const TRAP_CHILD_ENV: &str = "M2C_WASM_TRAP_CHILD";

    /// Runs this test in a child process (the trap aborts) and returns its
    /// end signal and the files it wrote.
    fn trap_child(case: &str) -> (Option<i32>, Vec<String>, String) {
        use std::os::unix::process::ExitStatusExt;
        let dir = tempfile::tempdir().unwrap();
        let out = std::process::Command::new(std::env::current_exe().unwrap())
            .args(["--exact", "ffi::tests::wasm::m2c_rt_wasm_trap_aborts"])
            .args(["--nocapture", "--test-threads=1"])
            .env(TRAP_CHILD_ENV, case)
            .env(crate::output::termination::OUTPUT_DIR_ENV, dir.path())
            .output()
            .unwrap();
        let mut files: Vec<String> = std::fs::read_dir(dir.path())
            .unwrap()
            .map(|e| e.unwrap().file_name().into_string().unwrap())
            .collect();
        files.sort();
        let unknown = std::fs::read_to_string(dir.path().join("map2check_property__unknown"))
            .unwrap_or_default();
        (out.status.signal(), files, unknown)
    }

    #[test]
    fn m2c_rt_wasm_trap_aborts() {
        // WasmRuntimeStubs.c:110-116: map2check_error() aborts; it never
        // returns. SD-19: with a mode set the verdict is UNKNOWN (the file
        // develop's map2check_error leaves for the frontend).
        if let Some(case) = std::env::var_os(TRAP_CHILD_ENV) {
            started((case == "mode").then_some(AnalysisMode::Memtrack));
            __m2c_rt_wasm_trap(3);
            println!("returned");
            return;
        }
        let (signal, files, unknown) = trap_child("mode");
        assert_eq!(signal, Some(6));
        assert_eq!(files, ["map2check_property__unknown"]);
        assert_eq!(unknown, "UNKNOWN\n");
        let (signal, files, _) = trap_child("no-mode");
        assert_eq!(signal, Some(6), "aborts with no mode too");
        assert!(
            files.is_empty(),
            "nothing is written without a mode: {files:?}"
        );
    }

    /// The initialised flag is one process-wide static: the tests that flip it
    /// take this lock.
    static INIT_FLAG: std::sync::Mutex<()> = std::sync::Mutex::new(());

    #[test]
    fn m2c_rt_wasm_init_free_and_is_initialized_follow_the_stub() {
        // WasmRuntimeStubs.c:96-108: initialised from the start, false after
        // wasm_rt_free, true after wasm_rt_init, and init/free repeat freely.
        let _g = INIT_FLAG.lock().unwrap_or_else(|e| e.into_inner());
        __m2c_rt_wasm_init();
        __m2c_rt_wasm_free();
        __m2c_rt_wasm_free();
        assert!(!__m2c_rt_wasm_is_initialized());
        __m2c_rt_wasm_init();
        __m2c_rt_wasm_init();
        assert!(__m2c_rt_wasm_is_initialized());
    }
}

// ── Ported assertions of the legacy C runtime unit tests ───────────────────
//
// Port of `tests/unit/backend-library/{Container,AllocationLog,HeapLog,
// MemTrack}Test.cpp` (legacy/c-runtime-final). The C tests drove internal
// containers that have no export here, so each assertion goes through the
// export that feeds the same record. The C TEST -> Rust test table is in
// `docs/cutover/decisoes.md` (Task 5.2). `BTreeTest` is not ported (D3).

fn free_resolved(address: usize) {
    // SAFETY: C-string literal is valid; the address is never dereferenced.
    unsafe { map2check_check_free_resolved_address(addr(address), 7, c"main".as_ptr(), 0) };
}

fn malloc_of(address: usize, size: i32) {
    // SAFETY: fake address is never dereferenced.
    unsafe { map2check_map_malloc(addr(address), size) };
}

fn load_of(address: usize, size: i32) {
    // SAFETY: C-string literal is valid; the address is never dereferenced.
    unsafe { map2check_check_load(addr(address), 9, 0, size, c"main".as_ptr()) };
}

fn alloca_of(address: usize, size: i32, primitive: i32) {
    // SAFETY: C-string literal is valid; the address is never dereferenced.
    unsafe { map2check_map_alloca(c"var".as_ptr(), addr(address), size, primitive, 3, 1) };
}

// ContainerTest

#[test]
fn container_is_empty_initially() {
    let _guard = fresh();
    map2check_init(0);
    assert_eq!(snapshot(|s| s.memtrack.len()), 0);
}

#[test]
fn container_add_item_increases_size() {
    let _guard = fresh();
    map2check_init(0);
    malloc_of(0x1000, 4);
    assert_eq!(snapshot(|s| s.memtrack.len()), 1);
}

#[test]
fn container_added_item_is_set() {
    let _guard = fresh();
    map2check_init(0);
    malloc_of(42, 4);
    assert_eq!(only_memtrack().points_to, 42);
}

#[test]
fn container_multiple_items_added_do_not_break() {
    let _guard = fresh();
    map2check_init(0);
    let n = 10_000usize;
    for i in 0..n {
        malloc_of(n - i, 4);
    }
    snapshot(|s| {
        assert_eq!(s.memtrack.len(), n);
        for (i, entry) in s.memtrack.iter().enumerate() {
            assert_eq!(entry.points_to, n - i);
        }
    });
}

// AllocationLogTest

#[test]
fn allocation_log_mark_alloc_increases_size() {
    let _guard = fresh();
    malloc_of(42, 4);
    assert_eq!(snapshot(|s| s.memtrack.len()), 1);
}

#[test]
fn allocation_log_mark_dealloc_increases_size() {
    let _guard = fresh();
    // SAFETY: C-string literals are valid; fake addresses are never dereferenced.
    unsafe { map2check_map_free(c"p".as_ptr(), addr(0x10), addr(42), 0, 5, c"main".as_ptr()) };
    let entry = only_memtrack();
    assert!(entry.is_free);
    assert_eq!(entry.points_to, 42);
}

#[test]
fn allocation_log_address_status_dynamic() {
    let _guard = fresh();
    malloc_of(42, 4);
    free_resolved(42);
    assert_ok();
}

#[test]
fn allocation_log_address_status_free() {
    let _guard = fresh();
    // SAFETY: C-string literals are valid; fake addresses are never dereferenced.
    unsafe { map2check_map_free(c"p".as_ptr(), addr(0x10), addr(42), 0, 5, c"main".as_ptr()) };
    free_resolved(42);
    assert_violated(ViolatedProperty::MemsafetyFree, 7, "main");
}

// No export reads C's address status enum, so its STATIC value is
// observed through the SD-06 verdict: an address with no record is an
// invalid free.
#[test]
fn allocation_log_address_status_empty_is_static() {
    let _guard = fresh();
    free_resolved(72);
    assert_violated(ViolatedProperty::MemsafetyFree, 7, "main");
}

#[test]
fn allocation_log_address_status_static_when_another_address_is_tracked() {
    let _guard = fresh();
    malloc_of(42, 4);
    free_resolved(72);
    assert_violated(ViolatedProperty::MemsafetyFree, 7, "main");
}

#[test]
fn allocation_log_released_address_leaves_no_leak() {
    let _guard = fresh();
    malloc_of(42, 4);
    free_resolved(42);
    map2check_check_mem_endprog();
    assert_ok();
}

#[test]
fn allocation_log_unreleased_address_is_a_leak() {
    let _guard = fresh();
    malloc_of(0x1000, 4);
    map2check_check_mem_endprog();
    assert_violated(ViolatedProperty::MemsafetyMemtrack, 0, "end_of_program");
}

#[test]
fn allocation_log_address_is_in_allocation_log() {
    let _guard = fresh();
    malloc_of(0x1000, 4);
    load_of(0x1000, 4);
    assert_ok();
}

#[test]
fn allocation_log_address_is_not_in_allocation_log() {
    let _guard = fresh();
    malloc_of(0x1000, 4);
    load_of(0x1000, 8);
    assert_violated(ViolatedProperty::MemsafetyDeref, 9, "main");
}

// HeapLogTest

#[test]
fn heap_log_mark_heap_increases_size() {
    let _guard = fresh();
    alloca_of(0x2000, 4, 4);
    assert_eq!(snapshot(|s| s.memtrack.len()), 1);
}

#[test]
fn heap_log_valid_primitive() {
    let _guard = fresh();
    alloca_of(0x2000, 4, 4);
    load_of(0x2000, 4);
    assert_ok();
}

#[test]
fn heap_log_invalid_primitive() {
    let _guard = fresh();
    alloca_of(0x2000, 4, 4);
    load_of(0x3000, 4);
    assert_violated(ViolatedProperty::MemsafetyDeref, 9, "main");
}

#[test]
fn heap_log_valid_array() {
    let _guard = fresh();
    alloca_of(0x2000, 8, 4);
    load_of(0x2004, 4);
    assert_ok();
}

#[test]
fn heap_log_invalid_array() {
    let _guard = fresh();
    alloca_of(0x2000, 8, 4);
    load_of(0x2008, 4);
    assert_violated(ViolatedProperty::MemsafetyDeref, 9, "main");
}

// MemoryTrackTest (the C test analyses in the memtrack mode)

#[test]
fn memtrack_default_program_is_correct() {
    let _guard = fresh();
    start(AnalysisMode::Memtrack);
    map2check_check_mem_endprog();
    assert_ok();
}

#[test]
fn memtrack_malloc_generates_memleak() {
    let _guard = fresh();
    start(AnalysisMode::Memtrack);
    malloc_of(0x1000, 32);
    map2check_check_mem_endprog();
    assert_violated(ViolatedProperty::MemsafetyMemtrack, 0, "end_of_program");
}

#[test]
fn memtrack_calloc_generates_memleak() {
    let _guard = fresh();
    start(AnalysisMode::Memtrack);
    // SAFETY: fake address is never dereferenced.
    unsafe { map2check_map_calloc(addr(0x1000), 10, 32) };
    map2check_check_mem_endprog();
    assert_violated(ViolatedProperty::MemsafetyMemtrack, 0, "end_of_program");
}

#[test]
fn memtrack_release_after_malloc_leaves_no_leak() {
    let _guard = fresh();
    start(AnalysisMode::Memtrack);
    malloc_of(0x1000, 32);
    free_resolved(0x1000);
    map2check_check_mem_endprog();
    assert_ok();
}

#[test]
fn memtrack_release_after_calloc_leaves_no_leak() {
    let _guard = fresh();
    start(AnalysisMode::Memtrack);
    // SAFETY: fake address is never dereferenced.
    unsafe { map2check_map_calloc(addr(0x1000), 10, 32) };
    free_resolved(0x1000);
    map2check_check_mem_endprog();
    assert_ok();
}

// ── Map2CheckFunctions, TrackBBLog and PropertyGenerator (Task 2.1) ─────────
//
// The C ABI of `Map2CheckFunctions.c`, `TrackBBLog.c` and
// `PropertyGenerator.c` of Map2Check `develop`. Exports that end the run or
// write files with a mode set are pinned in `ffi_golden_tests.rs`, in a
// child process; these tests pin the effect on the analysis state.

#[test]
fn map2check_init_takes_the_c_sv_comp_argument_and_starts_clean() {
    let _guard = fresh();
    // `Map2CheckFunctions.c:29-40`: `isSvComp` only sets `sv_comp`, which
    // nothing reads; any value starts the same clean analysis.
    for is_sv_comp in [0, 1, -7] {
        // SAFETY: fake address is never dereferenced.
        unsafe { map2check_map_malloc(addr(0x1000), 8) };
        // SAFETY: C-string literal is valid and null-terminated.
        unsafe { map2check_track_bb(3, c"main".as_ptr()) };
        map2check_next_current_step();
        map2check_init(is_sv_comp);
        assert_ok();
        snapshot(|s| {
            assert!(s.memtrack.is_empty() && s.bbtrack.is_empty());
            assert_eq!(s.current_step(), 0);
        });
        assert_eq!(map2check_get_current_step(), 0);
    }
}

#[test]
fn map2check_get_current_step_is_the_c_step_counter() {
    let _guard = fresh();
    map2check_init(0);
    // `Map2CheckFunctions.c:30,42-43`: 0 after init, +1 per
    // `map2check_next_current_step`, and nothing else moves it.
    assert_eq!(map2check_get_current_step(), 0);
    // SAFETY: C-string literal is valid; fake address is never dereferenced.
    unsafe {
        map2check_track_bb(3, c"main".as_ptr());
        map2check_map_malloc(addr(0x1000), 8);
    }
    assert_eq!(map2check_get_current_step(), 0);
    map2check_next_current_step();
    map2check_next_current_step();
    assert_eq!(map2check_get_current_step(), 2);
    assert_eq!(map2check_get_current_step(), 2, "ler não avança");
    map2check_init(0);
    assert_eq!(map2check_get_current_step(), 0);
}

#[test]
fn map2check_next_current_step_wraps_like_c_unsigned() {
    let _guard = fresh();
    map2check_init(0);
    state::with_state(|s| {
        s.c_step = u32::MAX;
        Ok(())
    })
    .unwrap();
    map2check_next_current_step();
    assert_eq!(map2check_get_current_step(), 0);
}

#[test]
fn map2check_track_bb_appends_each_line_once() {
    let _guard = fresh();
    map2check_init(0);
    // `Map2CheckFunctions.c:49-55`: a row is appended only when
    // `is_in_tracked` finds no row of that line; the first name stays.
    // SAFETY: C-string literals are valid and null-terminated.
    unsafe {
        map2check_track_bb(3, c"main".as_ptr());
        map2check_track_bb(4, c"main".as_ptr());
        map2check_track_bb(3, c"other".as_ptr());
        map2check_track_bb(u32::MAX, c"f".as_ptr());
    }
    let rows = snapshot(|s| {
        s.bbtrack
            .iter()
            .map(|r| (r.line, r.function_name.clone()))
            .collect::<Vec<_>>()
    });
    assert_eq!(
        rows,
        [
            (3, "main".to_owned()),
            (4, "main".to_owned()),
            (u32::MAX, "f".to_owned())
        ]
    );
    assert_eq!(map2check_is_in_trackbb_container(4), 1);
    assert_ok();
}

#[test]
fn map2check_track_bb_accepts_null_function_name() {
    let _guard = fresh();
    map2check_init(0);
    // SAFETY: null is an accepted function_name (SD-09).
    unsafe { map2check_track_bb(9, std::ptr::null()) };
    assert_eq!(
        snapshot(|s| s
            .bbtrack
            .iter()
            .map(|r| r.function_name.clone())
            .collect::<Vec<_>>()),
        [String::new()]
    );
}

#[test]
fn map2check_target_function_records_target_reached() {
    let _guard = fresh();
    map2check_init(0);
    // `Map2CheckFunctions.c:61-65`: TARGET_REACHED at `line` in `func_name`;
    // `scope` is not used. Unset mode: recorded, the call returns (SD-15).
    // SAFETY: C-string literal is valid and null-terminated.
    unsafe { map2check_target_function(c"reach_error".as_ptr(), 3, 22) };
    assert_violated(ViolatedProperty::Reachability, 22, "reach_error");
    // SAFETY: as above; the first violation is final (SD-03).
    unsafe { map2check_target_function(c"other".as_ptr(), 0, 30) };
    assert_violated(ViolatedProperty::Reachability, 22, "reach_error");
}

#[test]
fn map2check_target_function_accepts_null_name() {
    let _guard = fresh();
    start(AnalysisMode::Target);
    // SAFETY: null is an accepted name (SD-09).
    unsafe { map2check_target_function(std::ptr::null(), 0, 5) };
    assert_violated(ViolatedProperty::Reachability, 5, "");
}

#[test]
fn map2check_destroy_releases_the_block_log_and_the_mode_containers_once() {
    let _guard = fresh();
    start(AnalysisMode::Memtrack);
    // SAFETY: C-string literal is valid; fake address is never dereferenced.
    unsafe {
        map2check_track_bb(3, c"main".as_ptr());
        map2check_map_malloc(addr(0x1000), 8);
    }
    // `Map2CheckFunctions.c:77-87`: frees the basic-block log, then
    // `analysis_destroy` (memtrack frees its logs), once.
    map2check_destroy();
    snapshot(|s| {
        assert!(s.bbtrack.is_empty());
        assert!(s.memtrack.is_empty());
        assert!(s.destroyed);
    });
    // SAFETY: as above.
    unsafe { map2check_track_bb(4, c"main".as_ptr()) };
    map2check_destroy();
    assert_eq!(
        snapshot(|s| s.bbtrack.len()),
        1,
        "a segunda chamada não faz nada"
    );
    assert_ok();
}

#[test]
fn map2check_destroy_keeps_records_of_modes_without_containers() {
    let _guard = fresh();
    start(AnalysisMode::Assert);
    // SAFETY: fake address is never dereferenced.
    unsafe { map2check_map_malloc(addr(0x1000), 8) };
    map2check_destroy();
    // AnalysisModeAssert.c:33-35: `analysis_destroy` does nothing.
    assert_eq!(snapshot(|s| s.memtrack.len()), 1);
}

#[test]
fn map2check_exit_without_mode_runs_the_verdict_and_returns() {
    let _guard = fresh();
    map2check_init(0);
    // SAFETY: fake address is never dereferenced.
    unsafe { map2check_map_malloc(addr(0x1000), 8) };
    // `Map2CheckFunctions.c:89-92`: with no error, the verdict of the mode
    // runs. Unset mode: recorded, no files, no abort (SD-03, SD-14).
    map2check_exit();
    assert_violated(ViolatedProperty::MemsafetyMemtrack, 0, "");
    assert!(snapshot(|s| s.destroyed), "map2check_destroy roda");
}

#[test]
fn map2check_exit_skips_the_verdict_after_an_error() {
    let _guard = fresh();
    map2check_init(0);
    // SAFETY: fake address is never dereferenced.
    unsafe { map2check_map_malloc(addr(0x1000), 8) };
    // `:90`: `analysis_is_program_correct` runs only when `gotError` is
    // FALSE; `map2check_error` sets it (`:72-75`).
    map2check_error();
    assert!(snapshot(|s| s.got_error));
    assert!(
        snapshot(|s| s.result.ok),
        "nenhuma propriedade é registrada"
    );
}

#[test]
fn map2check_error_without_mode_returns() {
    let _guard = fresh();
    map2check_init(0);
    map2check_error();
    snapshot(|s| assert!(s.got_error && s.destroyed));
    map2check_init(0);
    assert!(!snapshot(|s| s.got_error), "map2check_init recomeça");
}

#[test]
fn write_property_without_output_directory_changes_nothing() {
    let _guard = fresh();
    map2check_init(0);
    // A test build without `MAP2CHECK_TEST_OUTPUT_DIR` writes nowhere; the
    // export never touches the analysis state (`PropertyGenerator.c:50-106`
    // only writes files). Files: `ffi_golden_tests.rs`.
    // SAFETY: C-string literal is valid and null-terminated.
    unsafe { write_property(ViolatedProperty::MemsafetyFree as i32, 7, c"main".as_ptr()) };
    assert_ok();
}

#[test]
fn set_false_result_takes_the_c_enum_values() {
    let _guard = fresh();
    // `Map2CheckTypes.h:80-91`: UNKNOWN = 1, FALSE_OVERFLOW = 6.
    // SAFETY: C-string literal is valid and null-terminated.
    unsafe { set_false_result(1, 4, c"main".as_ptr()) };
    assert_violated(ViolatedProperty::Unknown, 4, "main");
    map2check_reset();
    // SAFETY: as above.
    unsafe { set_false_result(6, 5, c"main".as_ptr()) };
    assert_violated(ViolatedProperty::Overflow, 5, "main");
    map2check_reset();
    // SAFETY: as above. 10 is `Concurrency`, 11 is no value.
    unsafe { set_false_result(10, 6, c"main".as_ptr()) };
    assert_violated(ViolatedProperty::Concurrency, 6, "main");
    map2check_reset();
    // SAFETY: as above.
    unsafe { set_false_result(11, 6, c"main".as_ptr()) };
    assert_ok();
}

#[test]
fn non_utf8_function_name_is_kept_not_dropped() {
    let _guard = fresh();
    // develop prints the name with `%s`; an invalid UTF-8 byte once turned
    // the whole name into "". The valid parts are kept now, and the invalid
    // byte becomes U+FFFD.
    // SAFETY: C-string literal is valid and null-terminated.
    unsafe { set_false_result(7, 4, c"ma\xffin".as_ptr()) };
    assert_violated(ViolatedProperty::Assert, 4, "ma\u{FFFD}in");
}

#[test]
fn get_current_property_returns_the_c_enum_value() {
    let _guard = fresh();
    // SAFETY: C-string literal is valid and null-terminated.
    unsafe { set_false_result(3, 1, c"f".as_ptr()) };
    assert_eq!(get_current_property() as i32, 3, "FALSE_DEREF");
}

#[test]
fn m2c_rt_witness_entry_points_without_output_directory_change_nothing() {
    let _guard = fresh();
    map2check_init(0);
    // SAFETY: C-string literal is valid; a NULL log pointer is accepted (D7).
    unsafe {
        map2check_track_bb(3, c"main".as_ptr());
        __m2c_rt_witness_generate_aux_files(std::ptr::null_mut(), 1);
    }
    __m2c_rt_witness_generate_confirmation_file();
    assert_ok();
    assert_eq!(snapshot(|s| s.bbtrack.len()), 1);
}

// ── C runtime ABI: NonDetLog ────────────────────────────────────────────────
//
// `map2check_nondet_<t>` of develop's `NonDetLog.c`: each call appends a row
// that takes `map2check_get_current_step()` and then advances it
// (`:96-113`), and `nondet_log_to_file` writes `klee_log.csv` from the rows.

use crate::nondet::c_log::{self, CNondetCall};

fn c_nondet_rows() -> Vec<CNondetCall> {
    snapshot(|s| s.c_nondet.clone())
}

/// Calls `$export` with the extreme `$value` of its width and sign, reads the
/// row back and compares the stored bits, the type number and the CSV line
/// that `nondet_log_to_file` prints for it.
macro_rules! nondet_roundtrip {
    ($test:ident, $call:expr, $value:expr, $kind:expr, $bits:expr, $csv_value:expr) => {
        #[test]
        fn $test() {
            let _guard = fresh();
            map2check_init(0);
            // `$call` is a closure over the export under test.
            let call = $call;
            call($value, c"main".as_ptr());
            let rows = c_nondet_rows();
            assert_eq!(rows.len(), 1);
            let row = &rows[0];
            assert_eq!(row.kind, $kind);
            assert_eq!(row.value_bits(), $bits);
            assert_eq!((row.line, row.scope, row.step), (7, 3, 0));
            assert_eq!(row.function_name(), b"main");
            assert_eq!(map2check_get_current_step(), 1);
            assert_eq!(
                String::from_utf8(row.csv_row(0)).unwrap(),
                format!("0;7;3;main;0;{};{}\n", $csv_value, $kind)
            );
        }
    };
}

// `enum NONDET_TYPE` numbers: Map2CheckTypes.h:41-58.
nondet_roundtrip!(
    nondet_roundtrip_int,
    |v, n| // SAFETY: `n` is a valid C string.
        unsafe { map2check_nondet_int(7, 3, v, n) },
    i32::MIN,
    0,
    0x8000_0000,
    "-2147483648"
);
nondet_roundtrip!(
    nondet_roundtrip_char,
    |v, n| // SAFETY: `n` is a valid C string.
        unsafe { map2check_nondet_char(7, 3, v, n) },
    -128,
    1,
    0xffff_ff80,
    "-128"
);
nondet_roundtrip!(
    nondet_roundtrip_pointer,
    |v, n| // SAFETY: `n` is a valid C string.
        unsafe { map2check_nondet_pointer(7, 3, v, n) },
    i32::MIN,
    2,
    0x8000_0000,
    "-2147483648"
);
nondet_roundtrip!(
    nondet_roundtrip_ushort,
    |v, n| // SAFETY: `n` is a valid C string.
        unsafe { map2check_nondet_ushort(7, 3, v, n) },
    65535,
    3,
    65535,
    "65535"
);
nondet_roundtrip!(
    nondet_roundtrip_long,
    |v, n| // SAFETY: `n` is a valid C string.
        unsafe { map2check_nondet_long(7, 3, v, n) },
    i32::MIN,
    4,
    0x8000_0000,
    "-2147483648"
);
nondet_roundtrip!(
    nondet_roundtrip_unsigned,
    |v, n| // SAFETY: `n` is a valid C string.
        unsafe { map2check_nondet_unsigned(7, 3, v, n) },
    u32::MAX,
    5,
    0xffff_ffff,
    "4294967295"
);
nondet_roundtrip!(
    nondet_roundtrip_ulong,
    |v, n| // SAFETY: `n` is a valid C string.
        unsafe { map2check_nondet_ulong(7, 3, v, n) },
    -1,
    6,
    0xffff_ffff,
    "-1"
);
nondet_roundtrip!(
    nondet_roundtrip_bool,
    |v, n| // SAFETY: `n` is a valid C string.
        unsafe { map2check_nondet_bool(7, 3, v, n) },
    1,
    7,
    1,
    "1"
);
nondet_roundtrip!(
    nondet_roundtrip_uchar,
    |v, n| // SAFETY: `n` is a valid C string.
        unsafe { map2check_nondet_uchar(7, 3, v, n) },
    255,
    8,
    255,
    "255"
);
nondet_roundtrip!(
    nondet_roundtrip_pchar,
    |v, n| // SAFETY: `n` is a valid C string.
        unsafe { map2check_nondet_pchar(7, 3, v, n) },
    i32::MAX,
    9,
    0x7fff_ffff,
    "2147483647"
);
nondet_roundtrip!(
    nondet_roundtrip_size_t,
    |v, n| // SAFETY: `n` is a valid C string.
        unsafe { map2check_nondet_size_t(7, 3, v, n) },
    i32::MAX,
    10,
    0x7fff_ffff,
    "2147483647"
);
nondet_roundtrip!(
    nondet_roundtrip_loff_t,
    |v, n| // SAFETY: `n` is a valid C string.
        unsafe { map2check_nondet_loff_t(7, 3, v, n) },
    i32::MIN,
    11,
    0x8000_0000,
    "-2147483648"
);
nondet_roundtrip!(
    nondet_roundtrip_sector_t,
    |v, n| // SAFETY: `n` is a valid C string.
        unsafe { map2check_nondet_sector_t(7, 3, v, n) },
    i32::MAX,
    12,
    0x7fff_ffff,
    "2147483647"
);
nondet_roundtrip!(
    nondet_roundtrip_uint,
    |v, n| // SAFETY: `n` is a valid C string.
        unsafe { map2check_nondet_uint(7, 3, v, n) },
    -1,
    13,
    0xffff_ffff,
    "-1"
);
nondet_roundtrip!(
    nondet_roundtrip_short,
    |v, n| // SAFETY: `n` is a valid C string.
        unsafe { map2check_nondet_short(7, 3, v, n) },
    -32768,
    14,
    0xffff_8000,
    "-32768"
);
nondet_roundtrip!(
    nondet_roundtrip_double,
    |v, n| // SAFETY: `n` is a valid C string.
        unsafe { map2check_nondet_double(7, 3, v, n) },
    f64::MAX,
    15,
    f64::MAX.to_bits(),
    "179769313486231570814527423731704356798070567525844996598917476803157260780028538760589558632766878171540458953514382464234321326889464182768467546703537516986049910576551282076245490090389328944075868508455133942304583236903222948165808559332123348274797826204144723168738177180919299881250404026184124858368.000000"
);
nondet_roundtrip!(
    nondet_roundtrip_float,
    |v, n| // SAFETY: `n` is a valid C string.
        unsafe { map2check_nondet_float(7, 3, v, n) },
    f64::from(f32::MAX),
    16,
    f64::from(f32::MAX).to_bits(),
    "3.40282347e+38"
);
nondet_roundtrip!(
    nondet_roundtrip_longlong,
    |v, n| // SAFETY: `n` is a valid C string.
        unsafe { map2check_nondet_longlong(7, 3, v, n) },
    i64::MIN,
    17,
    1 << 63,
    "-9223372036854775808"
);
nondet_roundtrip!(
    nondet_roundtrip_ulonglong,
    |v, n| // SAFETY: `n` is a valid C string.
        unsafe { map2check_nondet_ulonglong(7, 3, v, n) },
    u64::MAX,
    18,
    u64::MAX,
    "18446744073709551615"
);
nondet_roundtrip!(
    nondet_roundtrip_u8,
    |v, n| // SAFETY: `n` is a valid C string.
        unsafe { map2check_nondet_u8(7, 3, v, n) },
    255,
    19,
    255,
    "255"
);
nondet_roundtrip!(
    nondet_roundtrip_u16,
    |v, n| // SAFETY: `n` is a valid C string.
        unsafe { map2check_nondet_u16(7, 3, v, n) },
    65535,
    20,
    65535,
    "65535"
);
// U32 prints through `as_unsigned` like UNSIGNED (NonDetLog.c:91).
nondet_roundtrip!(
    nondet_roundtrip_u32,
    |v, n| // SAFETY: `n` is a valid C string.
        unsafe { map2check_nondet_u32(7, 3, v, n) },
    -1,
    21,
    0xffff_ffff,
    "4294967295"
);
nondet_roundtrip!(
    nondet_roundtrip_memory_byte,
    |v, n| // SAFETY: `n` is a valid C string.
        unsafe { map2check_nondet_memory_byte(7, 3, v, n) },
    255,
    22,
    255,
    "255"
);

#[test]
fn nondet_calls_take_the_step_then_advance_it() {
    let _guard = fresh();
    map2check_init(0);
    // `NonDetLog.c:96-113`: the row takes `map2check_get_current_step()`, and
    // `helper_map2check_nondet_append_element` then advances it.
    // SAFETY: C-string literals are valid and null-terminated.
    unsafe {
        map2check_nondet_int(1, 0, 10, c"main".as_ptr());
        map2check_next_current_step();
        map2check_nondet_int(2, 0, 11, c"main".as_ptr());
    }
    let steps: Vec<u32> = c_nondet_rows().iter().map(|r| r.step).collect();
    assert_eq!(steps, [0, 2]);
    assert_eq!(map2check_get_current_step(), 3);
}

#[test]
fn nondet_function_name_is_cut_at_35_bytes_and_null_is_empty() {
    let _guard = fresh();
    map2check_init(0);
    let long = std::ffi::CString::new("f".repeat(40)).unwrap();
    // `strncpy(..., FUNCTION_MAX_LENGTH_NAME = 35)` and `put_string(..., 35)`
    // (`NonDetLog.c:78,120`, `Map2CheckTypes.h:20`).
    // SAFETY: the C string is valid; a null name is accepted.
    unsafe {
        map2check_nondet_int(1, 0, 1, long.as_ptr());
        map2check_nondet_int(1, 0, 1, std::ptr::null());
    }
    let rows = c_nondet_rows();
    assert_eq!(rows[0].function_name(), "f".repeat(35).as_bytes());
    assert_eq!(rows[1].function_name(), b"");
}

#[test]
fn nondet_log_init_and_destroy_empty_the_log_and_keep_the_step() {
    let _guard = fresh();
    map2check_init(0);
    // SAFETY: C-string literal is valid and null-terminated.
    unsafe { map2check_nondet_int(1, 0, 1, c"main".as_ptr()) };
    assert_eq!(c_nondet_rows().len(), 1);
    // `NonDetLog.c:150-152`: a new container, or a freed one.
    nondet_log_init();
    assert!(c_nondet_rows().is_empty());
    assert_eq!(map2check_get_current_step(), 1);
    // SAFETY: as above.
    unsafe { map2check_nondet_int(1, 0, 1, c"main".as_ptr()) };
    nondet_log_destroy();
    assert!(c_nondet_rows().is_empty());
    // `map2check_init` starts a new log too (`nondet_init`).
    // SAFETY: as above.
    unsafe { map2check_nondet_int(1, 0, 1, c"main".as_ptr()) };
    map2check_init(0);
    assert!(c_nondet_rows().is_empty());
}

#[test]
fn nondet_log_does_not_touch_the_json_report_state() {
    let _guard = fresh();
    map2check_init(0);
    // SAFETY: C-string literal is valid and null-terminated.
    unsafe { map2check_nondet_int(1, 0, 1, c"main".as_ptr()) };
    assert!(snapshot(
        |s| s.nondets.is_empty() && s.legacy_nondet_logs.is_empty()
    ));
    assert_eq!(snapshot(|s| s.current_step()), 0);
    assert_ok();
}

/// A row of every printing arm, in the text `nondet_log_to_file` writes.
fn sample_log() -> Vec<CNondetCall> {
    let rows = [
        (0, 3, 1, 5, "main", 0xffff_fffe_u64),
        (5, 17, 2, 9, "main", 5),
        (21, 4, 0, 10, "f", 0xffff_ffff),
        (15, 8, 1, 11, "g", 2.5_f64.to_bits()),
        (16, 9, 1, 12, "g", 0.1_f64.to_bits()),
        (17, 1, 0, 13, "h", i64::MIN as u64),
        (18, 1, 0, 14, "h", u64::MAX),
        (19, 2, 0, 15, "name_of_exactly_thirty_five_chars_xyz", 200),
    ];
    rows.iter()
        .map(|&(kind, line, scope, step, name, bits)| {
            CNondetCall::from_parts(kind, line, scope, step, name.as_bytes(), bits)
        })
        .collect()
}

#[test]
fn klee_log_csv_matches_c_format() {
    // `NonDetLog.c:68-112`: `index;line;scope;function;step;value;type\n`, the
    // numbers in decimal by hand (`:20-48`). INTEGER `%d` of the int (`:106`);
    // UNSIGNED and U32 `%u` (`:91-92`) and once, not twice (`:82-90`); DOUBLE
    // `%lf` (`:93-95`); FLOAT `%.9g` of the double narrowed to float (`:96-100`);
    // LONGLONG and ULONGLONG at 64 bits (`:101-105`); the name cut at 35.
    // Row 0 is INTEGER with the bits of -2 (`%d` prints -2); the name of row 7
    // has 37 characters and is cut at 35.
    let expected = "\
0;3;1;main;5;-2;0\n\
1;17;2;main;9;5;5\n\
2;4;0;f;10;4294967295;21\n\
3;8;1;g;11;2.500000;15\n\
4;9;1;g;12;0.100000001;16\n\
5;1;0;h;13;-9223372036854775808;17\n\
6;1;0;h;14;18446744073709551615;18\n\
7;2;0;name_of_exactly_thirty_five_chars_x;15;200;19\n";
    let dir = tempfile::tempdir().unwrap();
    assert!(c_log::nondet_log_to_file(&sample_log(), dir.path()));
    let written = std::fs::read(dir.path().join("klee_log.csv")).unwrap();
    assert_eq!(String::from_utf8(written).unwrap(), expected);
}

#[test]
fn nondet_log_to_file_writes_an_empty_file_for_an_empty_log_and_fails_without_a_directory() {
    let dir = tempfile::tempdir().unwrap();
    // `fopen("w")` creates the file even when there are no rows (`:55`).
    assert!(c_log::nondet_log_to_file(&[], dir.path()));
    assert_eq!(std::fs::read(dir.path().join("klee_log.csv")).unwrap(), b"");
    // `fopen` fails: FALSE (`:56-58`).
    assert!(!c_log::nondet_log_to_file(
        &[],
        &dir.path().join("does-not-exist")
    ));
}

#[test]
fn m2c_rt_nondet_log_to_file_writes_the_log_of_the_run() {
    let _guard = fresh();
    map2check_init(0);
    // SAFETY: C-string literals are valid and null-terminated.
    unsafe {
        map2check_nondet_int(3, 1, -7, c"main".as_ptr());
        map2check_nondet_unsigned(4, 1, 8, c"main".as_ptr());
    }
    let dir = tempfile::tempdir().unwrap();
    std::env::set_var(crate::output::termination::OUTPUT_DIR_ENV, dir.path());
    let ok = __m2c_rt_nondet_log_to_file();
    std::env::remove_var(crate::output::termination::OUTPUT_DIR_ENV);
    assert_eq!(ok, 1);
    assert_eq!(
        std::fs::read_to_string(dir.path().join("klee_log.csv")).unwrap(),
        "0;3;1;main;0;-7;0\n1;4;1;main;1;8;5\n"
    );
}

#[test]
fn float_g9_matches_printf() {
    // Each expected text is what glibc's `printf("%.9g", (float)d)` printed
    // for the same `d` (clang 21 on this host).
    let cases: [(f64, &str); 21] = [
        (f64::from(f32::MAX), "3.40282347e+38"),
        (1e-30_f32 as f64, "1e-30"),
        (0.5, "0.5"),
        (1.0, "1"),
        (100.0, "100"),
        (123_456_789.0, "123456792"),
        (1e9, "1e+09"),
        (999_999_999.0, "1e+09"),
        (0.0001_f32 as f64, "9.99999975e-05"),
        (0.00001_f32 as f64, "9.99999975e-06"),
        (-0.0, "-0"),
        (0.0, "0"),
        (f64::from(f32::MIN_POSITIVE), "1.17549435e-38"),
        (f64::from(1.4e-45_f32), "1.40129846e-45"),
        (16_777_216.0, "16777216"),
        (f64::from(0.1_f32), "0.100000001"),
        (-2.5, "-2.5"),
        (f64::INFINITY, "inf"),
        (f64::NEG_INFINITY, "-inf"),
        (f64::NAN, "nan"),
        (99_999.999_9, "100000"),
    ];
    for (value, text) in cases {
        assert_eq!(c_log::c_float_g9(value as f32), text, "{value}");
    }
    assert_eq!(c_log::c_float_g9(f32::from_bits(0xffc0_0000)), "-nan");
    assert_eq!(c_log::c_float_g9(1e8_f32), "100000000");
    assert_eq!(c_log::c_float_g9(123_456.79_f32), "123456.789");
}

#[test]
fn nondet_log_hooks_mirror_the_klee_concretization() {
    let _guard = fresh();
    map2check_init(0);
    assert_eq!(__m2c_rt_nondet_log_len(), 0);
    // SAFETY: C-string literals are valid and null-terminated.
    unsafe {
        map2check_nondet_int(1, 0, -2, c"main".as_ptr());
        map2check_nondet_double(2, 0, 1.5, c"main".as_ptr());
        map2check_nondet_longlong(3, 0, i64::MIN, c"main".as_ptr());
    }
    assert_eq!(__m2c_rt_nondet_log_len(), 3);
    // `memcpy(&symbolic, &call->value, 8)` (NonDetGeneratorKlee.c:39): the int
    // is zero-extended by new_nondet_call's memset, the others are bit patterns.
    assert_eq!(__m2c_rt_nondet_log_get_i64(0), 0xffff_fffe);
    assert_eq!(__m2c_rt_nondet_log_get_i64(1), 1.5_f64.to_bits() as i64);
    assert_eq!(__m2c_rt_nondet_log_get_i64(2), i64::MIN);
    assert_eq!(__m2c_rt_nondet_log_get_i64(3), 0, "out of range reads 0");
    // The write-back replaces all 8 bytes (`:42`), and the file shows it.
    __m2c_rt_nondet_log_set_i64(0, 5);
    __m2c_rt_nondet_log_set_i64(1, 2.5_f64.to_bits() as i64);
    __m2c_rt_nondet_log_set_i64(2, -1);
    __m2c_rt_nondet_log_set_i64(9, 7);
    assert_eq!(__m2c_rt_nondet_log_len(), 3);
    let dir = tempfile::tempdir().unwrap();
    assert!(c_log::nondet_log_to_file(&c_nondet_rows(), dir.path()));
    assert_eq!(
        std::fs::read_to_string(dir.path().join("klee_log.csv")).unwrap(),
        "0;1;0;main;0;5;0\n1;2;0;main;1;2.500000;15\n2;3;0;main;2;-1;17\n"
    );
}

#[test]
fn legacy_nondet_log_reaches_klee_log_csv_through_the_one_c_log_writer() {
    use crate::output::legacy_files::LegacyLogs;
    let _guard = fresh();
    map2check_init(0);
    let mut u: std::os::raw::c_uint = u32::MAX;
    let mut d: f64 = 2.5;
    let long_name = std::ffi::CString::new("n".repeat(40)).unwrap();
    // SAFETY: the pointers are valid for the calls.
    unsafe {
        map2check_save_nondet_log_unsigned(3, 1, 5, &mut u, c"main".as_ptr());
        map2check_save_nondet_log_double(4, 1, 15, &mut d, long_name.as_ptr());
    }
    let logs = snapshot(|s| LegacyLogs::replay(&s.memtrack, &s.nondets, None, false));
    // The file the witness path writes is exactly what `c_log` formats for
    // the rows of the legacy log: there is no second formatter.
    let dir = tempfile::tempdir().unwrap();
    logs.write_nondet_log(dir.path()).unwrap();
    let mut expected = Vec::new();
    for (i, call) in logs.nondet_calls().iter().enumerate() {
        expected.extend_from_slice(&call.csv_row(i));
    }
    assert_eq!(
        std::fs::read(dir.path().join("klee_log.csv")).unwrap(),
        expected
    );
    // `strncpy(..., 35)`: the C name cut now applies to the legacy API too.
    assert_eq!(
        String::from_utf8(expected).unwrap(),
        format!(
            "0;3;1;main;0;4294967295;5\n1;4;1;{};1;2.500000;15\n",
            "n".repeat(35)
        )
    );
}

// ── C runtime ABI: AnalysisModeOverflow (core entry points, D7) ─────────────
//
// `AnalysisModeOverflow.bc` is generated IR whose functions forward to these
// `__m2c_rt_overflow_*` entry points (scripts/runtime-ir/gen_ll.py). The C
// semantics are `AnalysisModeOverflow.c` of Map2Check `develop`; the files
// they write are pinned by the golden tests (`ffi_golden_tests.rs`).

/// `map2check_binop_{add,sub,mul,sdiv,srem}` of the C runtime
/// (bodies at `AnalysisModeOverflow.c:197-217`, `:234-243`, `:250-276`).
type RtSignedBinop = unsafe extern "C" fn(
    i64,
    i64,
    std::os::raw::c_uint,
    std::os::raw::c_uint,
    std::os::raw::c_uint,
    *const std::os::raw::c_char,
);

/// `map2check_binop_{add,sub,mul}_uint` (bodies at
/// `AnalysisModeOverflow.c:224-232`, `:245-248`).
type RtUnsignedBinop = unsafe extern "C" fn(
    u64,
    u64,
    std::os::raw::c_uint,
    std::os::raw::c_uint,
    std::os::raw::c_uint,
    *const std::os::raw::c_char,
);

const INT_MAX: i64 = i32::MAX as i64;
const INT_MIN: i64 = i32::MIN as i64;
const UINT_MAX: u64 = u32::MAX as u64;

/// Calls `op` on a fresh state as the pass does (width 32, scope 0) at
/// `line` in `main` and returns the recorded verdict.
fn rt_signed(op: RtSignedBinop, a: i64, b: i64, width: u32, line: u32) -> Option<P> {
    state::reset();
    // SAFETY: C-string literal is valid and null-terminated.
    unsafe { op(a, b, width, line, 0, c"main".as_ptr()) };
    let result = snapshot(|s| s.result.clone());
    if result.ok {
        return None;
    }
    assert_eq!(result.line, line);
    assert_eq!(result.function_name, "main");
    Some(result.property)
}

#[test]
fn overflow_rt_binops_report_the_c_tag_at_the_boundaries() {
    let _guard = fresh();
    let add: RtSignedBinop = __m2c_rt_overflow_map2check_binop_add;
    let sub: RtSignedBinop = __m2c_rt_overflow_map2check_binop_sub;
    let mul: RtSignedBinop = __m2c_rt_overflow_map2check_binop_mul;
    let sdiv: RtSignedBinop = __m2c_rt_overflow_map2check_binop_sdiv;
    let srem: RtSignedBinop = __m2c_rt_overflow_map2check_binop_srem;
    // overflowError (FALSE_OVERFLOW, `:185-188`) and divisionByZeroError
    // (FALSE_DIVBYZERO, `:192-195`) as the C binops call them (`:197-276`).
    let cases: [(&str, RtSignedBinop, i64, i64, Option<P>); 16] = [
        ("INT_MAX + 1", add, INT_MAX, 1, Some(P::Overflow)),
        ("INT_MAX + 0", add, INT_MAX, 0, None),
        ("INT_MIN - 1", sub, INT_MIN, 1, Some(P::Overflow)),
        ("INT_MIN - 0", sub, INT_MIN, 0, None),
        ("INT_MAX * 2", mul, INT_MAX, 2, Some(P::Overflow)),
        ("INT_MIN * -1", mul, INT_MIN, -1, Some(P::Overflow)),
        ("INT_MAX * -1", mul, INT_MAX, -1, None),
        ("INT_MIN / -1", sdiv, INT_MIN, -1, Some(P::Overflow)),
        ("INT_MIN / 1", sdiv, INT_MIN, 1, None),
        ("7 / 0", sdiv, 7, 0, Some(P::DivByZero)),
        ("0 / 0", sdiv, 0, 0, Some(P::DivByZero)),
        ("7 % 0", srem, 7, 0, Some(P::DivByZero)),
        ("INT_MIN % 0", srem, INT_MIN, 0, Some(P::DivByZero)),
        ("INT_MIN % -1", srem, INT_MIN, -1, Some(P::Overflow)),
        ("INT_MAX % -1", srem, INT_MAX, -1, None),
        ("-5 % 3", srem, -5, 3, None),
    ];
    for (name, op, a, b, expected) in cases {
        assert_eq!(rt_signed(op, a, b, 32, 20), expected, "{name}");
    }
}

#[test]
fn overflow_rt_binops_use_the_width_like_c() {
    let _guard = fresh();
    let add: RtSignedBinop = __m2c_rt_overflow_map2check_binop_add;
    let sub: RtSignedBinop = __m2c_rt_overflow_map2check_binop_sub;
    let mul: RtSignedBinop = __m2c_rt_overflow_map2check_binop_mul;
    let sdiv: RtSignedBinop = __m2c_rt_overflow_map2check_binop_sdiv;
    // fits_in_width (`:126-134`) after the 64-bit predicates (`:141-183`);
    // width 0 or >= 64 means 64 bits (`:111-124`).
    assert_eq!(rt_signed(add, 127, 1, 8, 3), Some(P::Overflow));
    assert_eq!(rt_signed(add, 126, 1, 8, 3), None);
    assert_eq!(rt_signed(sub, -32768, 1, 16, 3), Some(P::Overflow));
    assert_eq!(rt_signed(add, INT_MAX, 1, 64, 3), None);
    assert_eq!(rt_signed(add, i64::MAX, 1, 64, 3), Some(P::Overflow));
    assert_eq!(rt_signed(add, i64::MAX, 1, 0, 3), Some(P::Overflow));
    assert_eq!(rt_signed(mul, i64::MAX, 2, 8, 3), Some(P::Overflow));
    assert_eq!(rt_signed(sub, i64::MIN, 1, 64, 3), Some(P::Overflow));
    // Only the width's own minimum overflows the division (`:259`).
    assert_eq!(rt_signed(sdiv, INT_MIN, -1, 64, 3), None);
    assert_eq!(rt_signed(sdiv, i64::MIN, -1, 64, 3), Some(P::Overflow));
    assert_eq!(rt_signed(sdiv, -128, -1, 8, 3), Some(P::Overflow));
}

#[test]
fn overflow_rt_unsigned_binops_never_report_like_c() {
    let _guard = fresh();
    // "Unsigned wraparound is well-defined in C and is not an overflow under
    // SV-COMP's no-overflow property, so these remain deliberate no-ops"
    // (`AnalysisModeOverflow.c:219-248`).
    let ops: [(&str, RtUnsignedBinop); 3] = [
        ("add_uint", __m2c_rt_overflow_map2check_binop_add_uint),
        ("sub_uint", __m2c_rt_overflow_map2check_binop_sub_uint),
        ("mul_uint", __m2c_rt_overflow_map2check_binop_mul_uint),
    ];
    for (name, op) in ops {
        for (a, b) in [(UINT_MAX, 1), (0, 1), (UINT_MAX, 2), (u64::MAX, u64::MAX)] {
            state::reset();
            // SAFETY: C-string literal is valid and null-terminated.
            unsafe { op(a, b, 32, 20, 0, c"main".as_ptr()) };
            assert_ok();
            assert!(snapshot(|s| !s.got_error), "{name}({a}, {b})");
        }
        // A null name is accepted: the C body never reads it.
        // SAFETY: null is allowed.
        unsafe { op(UINT_MAX, 1, 32, 20, 0, std::ptr::null()) };
        assert_ok();
    }
}

#[test]
fn overflow_rt_overflow_error_records_false_overflow() {
    let _guard = fresh();
    // SAFETY: C-string literal is valid and null-terminated.
    unsafe { __m2c_rt_overflow_overflowError(12, c"f".as_ptr()) };
    assert_violated(ViolatedProperty::Overflow, 12, "f");
    state::reset();
    // SAFETY: null is allowed.
    unsafe { __m2c_rt_overflow_overflowError(13, std::ptr::null()) };
    assert_violated(ViolatedProperty::Overflow, 13, "");
}

#[test]
fn overflow_rt_first_violation_is_final() {
    let _guard = fresh();
    // SAFETY: C-string literals are valid and null-terminated.
    unsafe {
        __m2c_rt_overflow_map2check_binop_srem(1, 0, 32, 4, 0, c"f".as_ptr());
        __m2c_rt_overflow_map2check_binop_add(INT_MAX, 1, 32, 9, 0, c"g".as_ptr());
        __m2c_rt_overflow_overflowError(10, c"h".as_ptr());
    }
    assert_violated(ViolatedProperty::DivByZero, 4, "f");
}

#[test]
fn overflow_rt_binops_check_whatever_mode_is_set() {
    let _guard = fresh();
    // The C module has no mode test: being linked is what selects it
    // (`caller.cpp:575-612`), so the core entry points always check.
    for mode in MODES {
        state::reset();
        map2check_set_mode(mode as i32);
        map2check_init(0);
        // SAFETY: C-string literal is valid and null-terminated.
        unsafe { __m2c_rt_overflow_map2check_binop_add(INT_MAX, 1, 32, 4, 0, c"f".as_ptr()) };
        assert_violated(ViolatedProperty::Overflow, 4, "f");
    }
}

#[test]
fn overflow_rt_analysis_entry_points_match_c() {
    let _guard = fresh();
    map2check_init(0);
    // SAFETY: C-string literal is valid and null-terminated.
    unsafe { map2check_track_bb(3, c"main".as_ptr()) };
    // analysis_init (`:279`) is empty in C; linking the module is what picks
    // the overflow mode, so the core entry point selects it.
    __m2c_rt_overflow_analysis_init();
    assert_eq!(state::config().mode, Some(AnalysisMode::Overflow));
    // analysis_is_program_correct (`:283`): always TRUE (1).
    assert_eq!(__m2c_rt_overflow_analysis_is_program_correct(), 1);
    // analysis_destroy (`:281`), analysis_generate_aux_witness_files
    // (`:285`): empty.
    __m2c_rt_overflow_analysis_destroy();
    __m2c_rt_overflow_analysis_generate_aux_witness_files();
    assert_ok();
    assert_eq!(snapshot(|s| s.bbtrack.len()), 1);
    assert_eq!(__m2c_rt_overflow_analysis_is_program_correct(), 1);
    // Even after a violation: the C verdict function reads no state.
    // SAFETY: C-string literal is valid and null-terminated.
    unsafe { __m2c_rt_overflow_overflowError(1, c"f".as_ptr()) };
    assert_eq!(__m2c_rt_overflow_analysis_is_program_correct(), 1);
}

#[test]
fn overflow_rt_binops_called_as_the_ir_forwarders_do() {
    let _guard = fresh();
    let main = c"main".as_ptr();
    // Safe operations, each entry point called directly with the C
    // arguments the pass gives `map2check_binop_*` (operands, width, line,
    // scope, name).
    // SAFETY: C-string literal is valid and null-terminated.
    unsafe {
        __m2c_rt_overflow_map2check_binop_add(-5, 3, 32, 1, 0, main);
        __m2c_rt_overflow_map2check_binop_sub(-5, 3, 32, 1, 0, main);
        __m2c_rt_overflow_map2check_binop_mul(-5, 3, 32, 1, 0, main);
        __m2c_rt_overflow_map2check_binop_sdiv(-5, 3, 32, 1, 0, main);
        __m2c_rt_overflow_map2check_binop_srem(-5, 3, 32, 1, 0, main);
    }
    __m2c_rt_overflow_map2check_binop_add_uint(UINT_MAX, 1, 32, 1, 0, main);
    __m2c_rt_overflow_map2check_binop_sub_uint(0, 1, 32, 1, 0, main);
    __m2c_rt_overflow_map2check_binop_mul_uint(UINT_MAX, 2, 32, 1, 0, main);
    assert_ok();
    // SAFETY: as above.
    unsafe { __m2c_rt_overflow_map2check_binop_sub(INT_MIN, 1, 32, 2, 0, main) };
    assert_violated(ViolatedProperty::Overflow, 2, "main");
    state::reset();
    // SAFETY: as above.
    unsafe { __m2c_rt_overflow_map2check_binop_mul(INT_MAX, 2, 32, 3, 0, main) };
    assert_violated(ViolatedProperty::Overflow, 3, "main");
    state::reset();
    // SAFETY: as above.
    unsafe { __m2c_rt_overflow_map2check_binop_sdiv(INT_MIN, -1, 32, 4, 0, main) };
    assert_violated(ViolatedProperty::Overflow, 4, "main");
}

// ── C runtime ABI: AnalysisModeAssert and AnalysisModeNone (core entry points, D7) ──
//
// `AnalysisModeAssert.bc` and `AnalysisModeNone.bc` are generated IR
// (scripts/runtime-ir/gen_ll.py). Their `analysis_init` forwards to the
// `__m2c_rt_<mode>_analysis_init` below, which selects the mode; the files
// are pinned by the golden tests (`ffi_golden_tests.rs`).

#[test]
fn assert_rt_analysis_entry_points_match_c() {
    let _guard = fresh();
    map2check_init(0);
    // SAFETY: C-string literal is valid and null-terminated.
    unsafe { map2check_track_bb(3, c"main".as_ptr()) };
    // AnalysisModeAssert.c:29-31 analysis_init is empty; linking the module
    // picks the assert mode.
    __m2c_rt_assert_analysis_init();
    assert_eq!(state::config().mode, Some(AnalysisMode::Assert));
    // :37 analysis_is_program_correct is TRUE; :33-35 and :39-41 are empty.
    assert_eq!(__m2c_rt_assert_analysis_is_program_correct(), 1);
    __m2c_rt_assert_analysis_destroy();
    __m2c_rt_assert_analysis_generate_aux_witness_files();
    assert_ok();
    assert_eq!(snapshot(|s| s.bbtrack.len()), 1);
    // Even after a violation: the C verdict function reads no state.
    // SAFETY: as above.
    unsafe { __m2c_rt_assert_map2check_assert(0, 1, c"f".as_ptr()) };
    assert_eq!(__m2c_rt_assert_analysis_is_program_correct(), 1);
}

#[test]
fn assert_rt_map2check_assert_zero_records_assert_and_one_does_not() {
    let _guard = fresh();
    map2check_init(0);
    __m2c_rt_assert_analysis_init();
    // AnalysisModeAssert.c:18-23: only `!condition` is a violation.
    for condition in [1, 2, -1, i32::MAX] {
        // SAFETY: C-string literal is valid and null-terminated.
        unsafe { __m2c_rt_assert_map2check_assert(condition, 9, c"main".as_ptr()) };
        assert_ok();
    }
    // SAFETY: as above.
    unsafe { __m2c_rt_assert_map2check_assert(0, 21, c"main".as_ptr()) };
    assert_violated(ViolatedProperty::Assert, 21, "main");
    // A NULL name reads as "" (the C would crash in fprintf %s).
    state::reset();
    // SAFETY: NULL is accepted.
    unsafe { __m2c_rt_assert_map2check_assert(0, 22, std::ptr::null()) };
    assert_violated(ViolatedProperty::Assert, 22, "");
}

#[test]
fn none_rt_analysis_init_selects_the_none_mode_and_the_verdict_is_true() {
    let _guard = fresh();
    map2check_init(0);
    // AnalysisModeNone.c:11-13 is empty; REACHABILITY_MODE and
    // COVER_BRANCHES_MODE both link this module (caller.cpp:600-612).
    __m2c_rt_none_analysis_init();
    assert_eq!(state::config().mode, Some(AnalysisMode::None));
    // SAFETY: C-string literal is valid and null-terminated.
    unsafe { map2check_target_function(c"reach_error".as_ptr(), 0, 22) };
    assert_violated(ViolatedProperty::Reachability, 22, "reach_error");
    // :19 analysis_is_program_correct is TRUE, :15-17 and :21-23 are empty.
    assert_eq!(__m2c_rt_none_analysis_is_program_correct(), 1);
    __m2c_rt_none_analysis_destroy();
    __m2c_rt_none_analysis_generate_aux_witness_files();
}

// ── C runtime ABI: AnalysisModeMemtrack (core entry points, Task 2.5) ───────
//
// `AnalysisModeMemtrack.bc` forwards the C names to `__m2c_rt_memtrack_*`.
// Each test pins the C behaviour of `AnalysisModeMemtrack.c`,
// `AllocationLog.c`, `ListLog.c` and `HeapLog.c`: the verdict, the property
// recorded and the rows of the three logs, as the C formats them.

/// `map2check_init` (which in C calls `analysis_init`), then the module's
/// `analysis_init`, which selects the memtrack mode.
fn memtrack_rt() -> MutexGuard<'static, ()> {
    let guard = fresh();
    map2check_init(0);
    __m2c_rt_memtrack_analysis_init();
    guard
}

fn c_list_log() -> String {
    snapshot(|s| String::from_utf8(s.c_memory.list_log_bytes()).unwrap())
}

fn c_allocation_log() -> String {
    snapshot(|s| String::from_utf8(s.c_memory.allocation_log_bytes()).unwrap())
}

fn c_heap_log() -> String {
    snapshot(|s| String::from_utf8(s.c_memory.heap_log_bytes()).unwrap())
}

fn c_error_deref() -> bool {
    snapshot(|s| s.c_memory.error_deref())
}

/// `golden_memory()` of `tests/legacy_golden/drivers/golden.h` through the
/// core entry points: `int *p` at 0x1000 (8 bytes), `&main` at 0x1040,
/// `p = malloc(16)` at 0x1100.
fn rt_prelude() {
    // SAFETY: fake addresses are only stored and compared; names are C strings.
    unsafe {
        __m2c_rt_memtrack_map2check_alloca(c"p".as_ptr(), addr(0x1000), 8, 8, 10, 1);
        __m2c_rt_memtrack_map2check_function(c"main".as_ptr(), addr(0x1040));
        __m2c_rt_memtrack_map2check_malloc(addr(0x1100), 16);
        __m2c_rt_memtrack_map2check_add_store_pointer(
            addr(0x1000),
            addr(0x1100),
            1,
            c"p".as_ptr(),
            11,
            c"main".as_ptr(),
        );
    }
}

#[test]
fn memtrack_rt_analysis_init_selects_the_mode_and_starts_empty_logs() {
    let _guard = memtrack_rt();
    assert_eq!(state::config().mode, Some(AnalysisMode::Memtrack));
    rt_prelude();
    __m2c_rt_memtrack_map2check_load(addr(0x9000), 4);
    assert!(c_error_deref());
    // AnalysisModeMemtrack.c:125-130: new containers, ERROR_DEREF = FALSE.
    __m2c_rt_memtrack_analysis_init();
    assert_eq!(c_list_log(), "");
    assert_eq!(c_allocation_log(), "");
    assert_eq!(c_heap_log(), "");
    assert!(!c_error_deref());
}

#[test]
fn memtrack_rt_logs_have_the_c_rows_and_formats() {
    let _guard = memtrack_rt();
    rt_prelude();
    // HeapLog.c:54-66 `%p;%s;%d\n`; map2check_function is size 1 (:393-397).
    assert_eq!(c_heap_log(), "0x1000;p;8\n0x1040;main;1\n");
    // AllocationLog.c:161-174 `%p;%u;%d\n`.
    assert_eq!(c_allocation_log(), "0x1100;16;0\n");
    // ListLog.c:138-157: id (always 0), var, points to, scope, is_free,
    // is_dynamic, name, line, function, step (the C step counter, 0 here).
    assert_eq!(c_list_log(), "0;0x1000;0x1100;1;0;1;p;11;main;0\n");
    assert_eq!(map2check_get_current_step(), 1);
}

#[test]
fn memtrack_rt_list_rows_share_the_step_counter_with_the_nondet_log() {
    let _guard = memtrack_rt();
    // SAFETY: C-string literal is valid.
    unsafe { map2check_nondet_int(5, 0, 42, c"main".as_ptr()) };
    rt_prelude();
    assert_eq!(c_list_log(), "0;0x1000;0x1100;1;0;1;p;11;main;1\n");
}

#[test]
fn memtrack_rt_malloc_updates_the_row_of_a_known_address_in_place() {
    let _guard = memtrack_rt();
    __m2c_rt_memtrack_map2check_malloc(addr(0x2000), 8);
    __m2c_rt_memtrack_map2check_malloc(addr(0x3000), 4);
    __m2c_rt_memtrack_map2check_malloc(addr(0x2000), 32);
    // calloc is malloc of quantity * size (:347-349), as C int.
    __m2c_rt_memtrack_map2check_calloc(addr(0x4000), 3, 5);
    __m2c_rt_memtrack_map2check_calloc(addr(0x5000), 0x10000, 0x10001);
    assert_eq!(
        c_allocation_log(),
        "0x2000;32;0\n0x3000;4;0\n0x4000;15;0\n0x5000;65536;0\n"
    );
    assert_ok();
}

#[test]
fn memtrack_rt_malloc_of_null_is_unknown() {
    let _guard = memtrack_rt();
    __m2c_rt_memtrack_map2check_malloc(std::ptr::null(), 4);
    // :317-323: write_property_unknown + map2check_error, nothing recorded.
    assert_violated(ViolatedProperty::Unknown, 0, "");
    assert_eq!(c_allocation_log(), "");
    // `int addr = (long)ptr`: a block whose low 32 bits are zero is NULL too.
    state::reset();
    __m2c_rt_memtrack_map2check_calloc(addr(0x7_0000_0000), 1, 4);
    assert_violated(ViolatedProperty::Unknown, 0, "");
}

#[test]
fn memtrack_rt_non_static_alloca_multiplies_size_by_primitive() {
    let _guard = memtrack_rt();
    // SAFETY: fake address; C-string literal.
    unsafe {
        __m2c_rt_memtrack_map2check_non_static_alloca(c"vla".as_ptr(), addr(0x6000), 5, 4, 3, 1)
    };
    // :380-384: size * size_of_primitive bytes.
    assert_eq!(c_heap_log(), "0x6000;vla;20\n");
    __m2c_rt_memtrack_map2check_load(addr(0x6010), 4);
    assert!(!c_error_deref());
    __m2c_rt_memtrack_map2check_load(addr(0x6011), 4);
    assert!(c_error_deref());
}

#[test]
fn memtrack_rt_load_and_check_deref_follow_error_deref() {
    let _guard = memtrack_rt();
    rt_prelude();
    // SAFETY (all calls below): fake addresses; C-string literals.
    unsafe {
        // Inside the stack slot, the function and the heap block: valid.
        __m2c_rt_memtrack_map2check_load(addr(0x1000), 8);
        __m2c_rt_memtrack_map2check_load(addr(0x1040), 1);
        __m2c_rt_memtrack_map2check_load(addr(0x110c), 4);
        __m2c_rt_memtrack_map2check_check_deref(14, c"main".as_ptr());
    }
    assert!(!c_error_deref());
    assert_ok();
    // One byte past the block: map2check_load only sets ERROR_DEREF (:168-174).
    __m2c_rt_memtrack_map2check_load(addr(0x110d), 4);
    assert!(c_error_deref());
    assert_ok();
    // SAFETY: as above.
    unsafe {
        // ERROR_DEREF stays set; check_deref reports it (:309-315).
        __m2c_rt_memtrack_map2check_load(addr(0x1100), 4);
        __m2c_rt_memtrack_map2check_check_deref(14, c"main".as_ptr());
    }
    assert_violated(ViolatedProperty::MemsafetyDeref, 14, "main");
}

#[test]
fn memtrack_rt_load_of_a_freed_block_is_an_invalid_deref() {
    let _guard = memtrack_rt();
    rt_prelude();
    // SAFETY: fake addresses; C-string literals.
    unsafe {
        __m2c_rt_memtrack_map2check_free_resolved_address(addr(0x1100), 12, c"main".as_ptr(), 0);
        __m2c_rt_memtrack_map2check_load(addr(0x1100), 1);
        __m2c_rt_memtrack_map2check_check_deref(13, c"g".as_ptr());
    }
    assert_violated(ViolatedProperty::MemsafetyDeref, 13, "g");
}

#[test]
fn memtrack_rt_check_cstring_reads_up_to_the_terminator_inside_the_block() {
    let _guard = memtrack_rt();
    let inside: [u8; 4] = *b"ab\0x";
    let beyond: [u8; 4] = *b"abcd";
    let a = inside.as_ptr() as usize;
    let b = beyond.as_ptr() as usize;
    // SAFETY: the buffers are live; names are C strings.
    unsafe {
        __m2c_rt_memtrack_map2check_alloca(c"s".as_ptr(), addr(a), 4, 1, 1, 1);
        __m2c_rt_memtrack_map2check_alloca(c"t".as_ptr(), addr(b), 4, 1, 2, 1);
        __m2c_rt_memtrack_map2check_check_cstring(std::ptr::null());
        __m2c_rt_memtrack_map2check_check_cstring(inside.as_ptr().cast());
    }
    assert!(!c_error_deref());
    // No terminator inside the 4 bytes: the fifth byte is outside every
    // block, so ERROR_DEREF is set before it is read (:159-166).
    // SAFETY: only the 4 tracked bytes are read.
    unsafe { __m2c_rt_memtrack_map2check_check_cstring(beyond.as_ptr().cast()) };
    assert!(c_error_deref());
    // SAFETY: C-string literal.
    unsafe { __m2c_rt_memtrack_map2check_check_deref(30, c"puts".as_ptr()) };
    assert_violated(ViolatedProperty::MemsafetyDeref, 30, "puts");
}

/// A live pointer slot holding `value`, as `map2check_free` reads it.
fn slot(value: usize) -> Box<usize> {
    Box::new(value)
}

#[test]
fn memtrack_rt_free_releases_the_block_and_logs_the_free_row() {
    let _guard = memtrack_rt();
    let p = slot(0x1100);
    let p_addr = &*p as *const usize as usize;
    // SAFETY: `p` is live; the rest are fake addresses and C strings.
    unsafe {
        __m2c_rt_memtrack_map2check_alloca(c"p".as_ptr(), addr(p_addr), 8, 8, 10, 1);
        __m2c_rt_memtrack_map2check_malloc(addr(0x1100), 16);
        __m2c_rt_memtrack_map2check_add_store_pointer(
            addr(p_addr),
            addr(0x1100),
            1,
            c"p".as_ptr(),
            11,
            c"main".as_ptr(),
        );
        __m2c_rt_memtrack_map2check_free(c"p".as_ptr(), addr(p_addr), 1, 12, c"main".as_ptr());
    }
    assert_ok();
    // :351-378: a FREE row for the variable, then the row of the block is
    // freed with size 0.
    assert_eq!(
        c_list_log(),
        format!("0;{p_addr:#x};0x1100;1;0;1;p;11;main;0\n0;{p_addr:#x};0x1100;1;1;0;p;12;main;1\n")
    );
    assert_eq!(c_allocation_log(), "0x1100;0;1\n");
    assert_eq!(__m2c_rt_memtrack_analysis_is_program_correct(), 1);
}

#[test]
fn memtrack_rt_double_free_is_a_false_free_after_its_row_is_logged() {
    let _guard = memtrack_rt();
    let p = slot(0x1100);
    let p_addr = &*p as *const usize as usize;
    // SAFETY: `p` is live; the rest are fake addresses and C strings.
    unsafe {
        __m2c_rt_memtrack_map2check_malloc(addr(0x1100), 16);
        __m2c_rt_memtrack_map2check_add_store_pointer(
            addr(p_addr),
            addr(0x1100),
            1,
            c"p".as_ptr(),
            11,
            c"main".as_ptr(),
        );
        __m2c_rt_memtrack_map2check_free(c"p".as_ptr(), addr(p_addr), 1, 12, c"main".as_ptr());
        __m2c_rt_memtrack_map2check_free(c"p".as_ptr(), addr(p_addr), 1, 13, c"main".as_ptr());
    }
    assert_violated(ViolatedProperty::MemsafetyFree, 13, "main");
    // The failing free appended its FREE row before the check (:358-365).
    assert_eq!(c_list_log().lines().count(), 3);
    assert!(c_list_log().ends_with("0;p;13;main;2\n"));
}

#[test]
fn memtrack_rt_free_of_a_non_heap_address_is_a_false_free() {
    let _guard = memtrack_rt();
    let x = 7u64;
    let x_addr = &x as *const u64 as usize;
    let p = slot(x_addr);
    let p_addr = &*p as *const usize as usize;
    // SAFETY: `p` is live; names are C strings.
    unsafe {
        __m2c_rt_memtrack_map2check_alloca(c"x".as_ptr(), addr(x_addr), 8, 8, 3, 1);
        // `p = &x`: a STATIC row (check_address_allocation_log, AllocationLog.c:33-51).
        __m2c_rt_memtrack_map2check_add_store_pointer(
            addr(p_addr),
            addr(x_addr),
            1,
            c"p".as_ptr(),
            4,
            c"main".as_ptr(),
        );
        __m2c_rt_memtrack_map2check_free(c"p".as_ptr(), addr(p_addr), 1, 5, c"main".as_ptr());
    }
    // is_invalid_free: the newest row pointing to x is not dynamic (ListLog.c:95-118).
    assert_violated(ViolatedProperty::MemsafetyFree, 5, "main");
}

#[test]
fn memtrack_rt_free_of_a_null_pointer_does_nothing() {
    let _guard = memtrack_rt();
    let p = slot(0);
    // SAFETY: `p` is live; C strings.
    unsafe {
        __m2c_rt_memtrack_map2check_free(
            c"p".as_ptr(),
            (&*p as *const usize).cast(),
            1,
            5,
            c"main".as_ptr(),
        )
    };
    assert_ok();
    assert_eq!(c_list_log(), "");
}

#[test]
fn memtrack_rt_free_resolved_address_follows_is_invalid_free() {
    let _guard = memtrack_rt();
    // SAFETY (all calls below): fake addresses; C strings; NULL accepted.
    unsafe {
        // NULL with isNullValid returns at once (:179-181).
        __m2c_rt_memtrack_map2check_free_resolved_address(std::ptr::null(), 1, c"f".as_ptr(), 1);
        assert_ok();
        // A tracked, stored block is a valid free.
        rt_prelude();
        __m2c_rt_memtrack_map2check_free_resolved_address(addr(0x1100), 12, c"main".as_ptr(), 0);
    }
    assert_ok();
    // update_reference_list_log(FREE) re-points `p` at the freed block (:197-256).
    assert_eq!(
        c_list_log(),
        "0;0x1000;0x1100;1;0;1;p;11;main;0\n0;0x1000;0x1100;1;1;0;p;12;main;1\n"
    );
    assert_eq!(c_allocation_log(), "0x1100;0;1\n");
    // SAFETY: as above.
    unsafe {
        // Again: the newest row pointing to the block is free.
        __m2c_rt_memtrack_map2check_free_resolved_address(addr(0x1100), 13, c"main".as_ptr(), 0)
    };
    assert_violated(ViolatedProperty::MemsafetyFree, 13, "main");
}

#[test]
fn memtrack_rt_free_resolved_of_an_untracked_or_never_stored_block_is_a_false_free() {
    let _guard = memtrack_rt();
    // SAFETY: fake address; C string.
    unsafe {
        __m2c_rt_memtrack_map2check_free_resolved_address(addr(0x5000), 3, c"main".as_ptr(), 0)
    };
    assert_violated(ViolatedProperty::MemsafetyFree, 3, "main");
    // free(malloc(8)): no list row points to the block, so is_invalid_free
    // is TRUE (ListLog.c:117) — develop's verdict, unlike SD-13 of the legacy
    // `map2check_check_free_resolved_address`.
    state::reset();
    // SAFETY: as above.
    unsafe {
        __m2c_rt_memtrack_map2check_malloc(addr(0x6000), 8);
        __m2c_rt_memtrack_map2check_free_resolved_address(addr(0x6000), 4, c"main".as_ptr(), 0);
    }
    assert_violated(ViolatedProperty::MemsafetyFree, 4, "main");
}

#[test]
fn memtrack_rt_add_store_pointer_skips_redundant_rows_and_updates_references() {
    let _guard = memtrack_rt();
    // SAFETY (all calls below): fake addresses; C strings.
    unsafe {
        __m2c_rt_memtrack_map2check_malloc(addr(0xA0), 8);
        __m2c_rt_memtrack_map2check_add_store_pointer(
            addr(0x10),
            addr(0xA0),
            1,
            c"p".as_ptr(),
            1,
            c"f".as_ptr(),
        );
        // Same var, value and flags: redundant (:285-297), no row, no step.
        __m2c_rt_memtrack_map2check_add_store_pointer(
            addr(0x10),
            addr(0xA0),
            1,
            c"p".as_ptr(),
            2,
            c"f".as_ptr(),
        );
        __m2c_rt_memtrack_map2check_add_store_pointer(
            addr(0x20),
            addr(0xA0),
            2,
            c"q".as_ptr(),
            3,
            c"g".as_ptr(),
        );
        __m2c_rt_memtrack_map2check_free_resolved_address(addr(0xA0), 4, c"h".as_ptr(), 0);
        // After the free, storing the freed block again is a FREE row.
        __m2c_rt_memtrack_map2check_add_store_pointer(
            addr(0x30),
            addr(0xA0),
            1,
            c"r".as_ptr(),
            5,
            c"f".as_ptr(),
        );
    }
    assert_ok();
    assert_eq!(
        c_list_log(),
        "0;0x10;0xa0;1;0;1;p;1;f;0\n\
         0;0x20;0xa0;2;0;1;q;3;g;1\n\
         0;0x10;0xa0;1;1;0;p;4;f;2\n\
         0;0x20;0xa0;2;1;0;q;4;g;3\n\
         0;0x30;0xa0;1;1;0;r;5;f;4\n"
    );
}

#[test]
fn memtrack_rt_posix_reads_the_slot_and_logs_malloc_and_store() {
    let _guard = memtrack_rt();
    let q = slot(0x2200);
    let q_addr = &*q as *const usize as usize;
    // SAFETY: `q` is live and holds a `void *`.
    unsafe { __m2c_rt_memtrack_map2check_posix(addr(q_addr), 32) };
    // :340-345: map2check_malloc(*ptr) and the store with scope 1, line 1,
    // "pointer" and "cocoiso".
    assert_eq!(c_allocation_log(), "0x2200;32;0\n");
    assert_eq!(
        c_list_log(),
        format!("0;{q_addr:#x};0x2200;1;0;1;pointer;1;cocoiso;0\n")
    );
}

#[test]
fn memtrack_rt_names_are_cut_at_35_bytes_except_the_variable_name() {
    let _guard = memtrack_rt();
    let long = c"a_function_name_of_more_than_35_bytes_long";
    // SAFETY: fake addresses; C strings.
    unsafe {
        __m2c_rt_memtrack_map2check_alloca(long.as_ptr(), addr(0x100), 4, 4, 1, 1);
        __m2c_rt_memtrack_map2check_add_store_pointer(
            addr(0x10),
            addr(0x100),
            1,
            long.as_ptr(),
            2,
            long.as_ptr(),
        );
    }
    // new_heap_row and new_list_row strncpy FUNCTION_MAX_LENGTH_NAME (35)
    // bytes (HeapLog.c:25, ListLog.c:133); the list row keeps the pointer
    // to the variable name (:132).
    let cut = "a_function_name_of_more_than_35_byt";
    assert_eq!(c_heap_log(), format!("0x100;{cut};4\n"));
    assert_eq!(
        c_list_log(),
        format!("0;0x10;0x100;1;0;0;{};2;{cut};0\n", long.to_str().unwrap())
    );
}

#[test]
fn memtrack_rt_is_program_correct_reports_a_leak_and_releases_it() {
    let _guard = memtrack_rt();
    assert_eq!(__m2c_rt_memtrack_analysis_is_program_correct(), 1);
    rt_prelude();
    // AnalysisModeMemtrack.c:138-146: valid_allocation_log appends a freed
    // row for the leaked block (AllocationLog.c:69-101) and the verdict is
    // FALSE_MEMTRACK; the function does not record or end the run.
    assert_eq!(__m2c_rt_memtrack_analysis_is_program_correct(), 0);
    assert_ok();
    assert_eq!(c_allocation_log(), "0x1100;16;0\n0x1100;0;1\n");
    // The leak is now released: a second call is TRUE.
    assert_eq!(__m2c_rt_memtrack_analysis_is_program_correct(), 1);
    __m2c_rt_memtrack_analysis_generate_aux_witness_files();
}

#[test]
fn memtrack_rt_end_of_program_reports_the_leak_through_the_core() {
    let _guard = memtrack_rt();
    rt_prelude();
    map2check_check_mem_endprog();
    assert_violated(ViolatedProperty::MemsafetyMemtrack, 0, "end_of_program");
}

#[test]
fn memtrack_rt_destroy_releases_the_logs() {
    let _guard = memtrack_rt();
    rt_prelude();
    __m2c_rt_memtrack_analysis_destroy();
    assert_eq!(c_allocation_log(), "");
    assert_eq!(c_list_log(), "");
    assert_eq!(c_heap_log(), "");
}

#[test]
fn memtrack_rt_wasm_checks_use_the_allocation_log() {
    let _guard = memtrack_rt();
    __m2c_rt_memtrack_map2check_wasm_malloc(0, 8);
    __m2c_rt_memtrack_map2check_wasm_malloc(u64::MAX, 8);
    __m2c_rt_memtrack_map2check_wasm_malloc(0x400, 16);
    // AnalysisModeMemtrack.c:403-416: 0 and -1 are no block.
    assert_eq!(c_allocation_log(), "0x400;16;0\n");
    __m2c_rt_memtrack_map2check_wasm_check_access(0x40c, 4);
    assert_ok();
    // :430-436: FALSE_OVERFLOW at line 0, function "".
    __m2c_rt_memtrack_map2check_wasm_check_access(0x40d, 4);
    assert_violated(ViolatedProperty::Overflow, 0, "");
    state::reset();
    __m2c_rt_memtrack_map2check_wasm_malloc(0x400, 16);
    __m2c_rt_memtrack_map2check_wasm_free(0x400, 7);
    // A double free finds the row again (:418-428): no error.
    __m2c_rt_memtrack_map2check_wasm_free(0x400, 8);
    assert_ok();
    assert_eq!(c_allocation_log(), "0x400;0;1\n");
    __m2c_rt_memtrack_map2check_wasm_free(0x800, 9);
    assert_violated(ViolatedProperty::MemsafetyFree, 9, "");
}

#[test]
fn sd23_memtrack_rt_release_without_allocation_row_goes_on() {
    let _guard = memtrack_rt();
    // SAFETY: NULL is only compared; C strings.
    unsafe {
        __m2c_rt_memtrack_map2check_add_store_pointer(
            addr(0x10),
            std::ptr::null(),
            1,
            c"p".as_ptr(),
            1,
            c"main".as_ptr(),
        );
        __m2c_rt_memtrack_map2check_free_resolved_address(std::ptr::null(), 2, c"main".as_ptr(), 0);
    }
    // develop SIGSEGVs in find_row_with_address's NULL row; no verdict, no
    // row, no reference update here.
    assert_ok();
    assert_eq!(c_list_log(), "0;0x10;(nil);1;0;0;p;1;main;0\n");
    assert_eq!(c_allocation_log(), "");
}

#[test]
fn memtrack_rt_check_deref_keeps_a_negative_c_line() {
    let _guard = memtrack_rt();
    __m2c_rt_memtrack_map2check_load(addr(0x9000), 1);
    // SAFETY: C string.
    unsafe { __m2c_rt_memtrack_map2check_check_deref(-1, c"main".as_ptr()) };
    // The int is stored as its u32 bit pattern; the property files print
    // it back with %d (write_property_files: `line as i32`), so "-1".
    assert_violated(ViolatedProperty::MemsafetyDeref, u32::MAX, "main");
    assert_eq!(snapshot(|s| s.result.line as i32), -1);
}

// ── C runtime ABI: AnalysisModeMemcleanup (core entry points, Task 2.6) ─────
//
// `AnalysisModeMemcleanup.bc` forwards the C names to `__m2c_rt_memcleanup_*`,
// which share the memory rules of the memtrack entry points (`MemMode`).
// `diff AnalysisModeMemtrack.c AnalysisModeMemcleanup.c` shows five
// differences, one test each below:
//   :141-146  the verdict needs a pointer variable to the last leak
//   :158      map2check_load is empty (no ERROR_DEREF)
//   :159      map2check_check_cstring is empty
//   :168/:342 `Bool error = FALSE` in both release functions (no FALSE-FREE)
//   :294      map2check_check_deref is empty
// Everything else (rows, formats, UNKNOWN, posix, calloc) is the same code.

/// `map2check_init`, then the module's `analysis_init`, which selects the
/// memcleanup mode.
fn memcleanup_rt() -> MutexGuard<'static, ()> {
    let guard = fresh();
    map2check_init(0);
    __m2c_rt_memcleanup_analysis_init();
    guard
}

/// `golden_memory()` through the memcleanup entry points: `int *p` at 0x1000,
/// `&main` at 0x1040, `p = malloc(16)` at 0x1100.
fn memcleanup_prelude() {
    // SAFETY: fake addresses are only stored and compared; names are C strings.
    unsafe {
        __m2c_rt_memcleanup_map2check_alloca(c"p".as_ptr(), addr(0x1000), 8, 8, 10, 1);
        __m2c_rt_memcleanup_map2check_function(c"main".as_ptr(), addr(0x1040));
        __m2c_rt_memcleanup_map2check_malloc(addr(0x1100), 16);
        __m2c_rt_memcleanup_map2check_add_store_pointer(
            addr(0x1000),
            addr(0x1100),
            1,
            c"p".as_ptr(),
            11,
            c"main".as_ptr(),
        );
    }
}

#[test]
fn memcleanup_rt_analysis_init_selects_the_mode_and_starts_empty_logs() {
    let _guard = memcleanup_rt();
    assert_eq!(state::config().mode, Some(AnalysisMode::Memcleanup));
    memcleanup_prelude();
    // AnalysisModeMemcleanup.c:125-130: new containers, ERROR_DEREF = FALSE.
    __m2c_rt_memcleanup_analysis_init();
    assert_eq!(c_list_log(), "");
    assert_eq!(c_allocation_log(), "");
    assert_eq!(c_heap_log(), "");
    assert!(!c_error_deref());
    // :132-136 frees the logs.
    memcleanup_prelude();
    __m2c_rt_memcleanup_analysis_destroy();
    assert_eq!(c_allocation_log(), "");
}

#[test]
fn memcleanup_rt_shares_the_row_formats_and_rules_of_memtrack() {
    let _guard = memcleanup_rt();
    memcleanup_prelude();
    assert_eq!(c_heap_log(), "0x1000;p;8\n0x1040;main;1\n");
    assert_eq!(c_allocation_log(), "0x1100;16;0\n");
    assert_eq!(c_list_log(), "0;0x1000;0x1100;1;0;1;p;11;main;0\n");
    // :326-328 calloc is malloc of quantity * size; :296-314 revives a row.
    __m2c_rt_memcleanup_map2check_calloc(addr(0x2000), 3, 5);
    __m2c_rt_memcleanup_map2check_malloc(addr(0x2000), 32);
    // :359-363 non_static_alloca is alloca of size * primitive bytes.
    // SAFETY: fake address; C-string literal.
    unsafe {
        __m2c_rt_memcleanup_map2check_non_static_alloca(c"vla".as_ptr(), addr(0x6000), 5, 4, 3, 1)
    };
    assert_eq!(c_allocation_log(), "0x1100;16;0\n0x2000;32;0\n");
    assert_eq!(c_heap_log(), "0x1000;p;8\n0x1040;main;1\n0x6000;vla;20\n");
    assert_ok();
}

#[test]
fn memcleanup_rt_malloc_of_null_is_still_unknown() {
    let _guard = memcleanup_rt();
    // :296-302 is the memtrack code: write_property_unknown + map2check_error.
    __m2c_rt_memcleanup_map2check_malloc(std::ptr::null(), 4);
    assert_violated(ViolatedProperty::Unknown, 0, "");
    assert_eq!(c_allocation_log(), "");
}

#[test]
fn memcleanup_rt_posix_records_the_block_and_the_store() {
    let _guard = memcleanup_rt();
    let block = slot(0x3000);
    let p_addr = &*block as *const usize as usize;
    // SAFETY: `block` is live and holds the block address.
    unsafe { __m2c_rt_memcleanup_map2check_posix(addr(p_addr), 32) };
    // :319-324 map2check_malloc(*ptr, size) + the store of "pointer".
    assert_eq!(c_allocation_log(), "0x3000;32;0\n");
    assert_eq!(
        c_list_log(),
        format!("0;{p_addr:#x};0x3000;1;0;1;pointer;1;cocoiso;0\n")
    );
}

#[test]
fn memcleanup_rt_load_never_sets_error_deref() {
    let _guard = memcleanup_rt();
    memcleanup_prelude();
    // :158 `void map2check_load(void *ptr, int size) {}`: the access that
    // memtrack flags (memtrack_rt_load_and_check_deref_follow_error_deref)
    // leaves no trace.
    __m2c_rt_memcleanup_map2check_load(addr(0x9000), 4);
    __m2c_rt_memcleanup_map2check_load(addr(0x110d), 4);
    assert!(!c_error_deref());
}

#[test]
fn memcleanup_rt_check_deref_is_empty() {
    let _guard = memcleanup_rt();
    // :294 `void map2check_check_deref(int line, const char *function_name) {}`
    // even when the state would be an invalid dereference in memtrack mode.
    __m2c_rt_memcleanup_map2check_load(addr(0x9000), 4);
    // SAFETY: C-string literal.
    unsafe { __m2c_rt_memcleanup_map2check_check_deref(14, c"main".as_ptr()) };
    assert_ok();
}

#[test]
fn memcleanup_rt_check_cstring_is_empty() {
    let _guard = memcleanup_rt();
    let beyond: [u8; 4] = *b"abcd";
    // SAFETY: the buffer is live; names are C strings. Nothing is read.
    unsafe {
        __m2c_rt_memcleanup_map2check_alloca(
            c"t".as_ptr(),
            addr(beyond.as_ptr() as usize),
            4,
            1,
            2,
            1,
        );
        // :160 `void map2check_check_cstring(const char *string) {}`: memtrack
        // (memtrack_rt_check_cstring_reads_up_to_the_terminator_inside_the_block)
        // sets ERROR_DEREF at the fifth byte.
        __m2c_rt_memcleanup_map2check_check_cstring(beyond.as_ptr().cast());
        __m2c_rt_memcleanup_map2check_check_cstring(std::ptr::null());
        __m2c_rt_memcleanup_map2check_check_deref(30, c"puts".as_ptr());
    }
    assert!(!c_error_deref());
    assert_ok();
}

#[test]
fn memcleanup_rt_free_resolved_never_reports_false_free() {
    let _guard = memcleanup_rt();
    memcleanup_prelude();
    // SAFETY: fake addresses; C-string literals.
    unsafe {
        // :164-166 NULL with isNullValid returns.
        __m2c_rt_memcleanup_map2check_free_resolved_address(
            std::ptr::null(),
            11,
            c"main".as_ptr(),
            1,
        );
        // :168 `Bool error = FALSE`: the block is released ...
        __m2c_rt_memcleanup_map2check_free_resolved_address(addr(0x1100), 12, c"main".as_ptr(), 0);
        // ... and a second release is not FALSE-FREE (memtrack:
        // memtrack_rt_double_free_is_a_false_free_after_its_row_is_logged).
        __m2c_rt_memcleanup_map2check_free_resolved_address(addr(0x1100), 13, c"main".as_ptr(), 0);
    }
    assert_ok();
    assert_eq!(c_allocation_log(), "0x1100;0;1\n");
    // :179 update_reference_list_log: p gets a FREE row (line 12).
    assert_eq!(
        c_list_log(),
        "0;0x1000;0x1100;1;0;1;p;11;main;0\n0;0x1000;0x1100;1;1;0;p;12;main;1\n"
    );
}

#[test]
fn memcleanup_rt_free_never_reports_false_free() {
    let _guard = memcleanup_rt();
    let p = slot(0x1100);
    let p_addr = &*p as *const usize as usize;
    // SAFETY: `p` is live; the rest are fake addresses and C strings.
    unsafe {
        __m2c_rt_memcleanup_map2check_malloc(addr(0x1100), 16);
        __m2c_rt_memcleanup_map2check_add_store_pointer(
            addr(p_addr),
            addr(0x1100),
            1,
            c"p".as_ptr(),
            11,
            c"main".as_ptr(),
        );
        __m2c_rt_memcleanup_map2check_free(c"p".as_ptr(), addr(p_addr), 1, 12, c"main".as_ptr());
        // :342 `Bool error = FALSE`: the double free that memtrack reports
        // is a no-op here (the row is found again).
        __m2c_rt_memcleanup_map2check_free(c"p".as_ptr(), addr(p_addr), 1, 13, c"main".as_ptr());
    }
    assert_ok();
    assert_eq!(c_allocation_log(), "0x1100;0;1\n");
    assert_eq!(c_list_log().lines().count(), 3);
    assert!(c_list_log().ends_with("0;p;13;main;2\n"));
}

#[test]
fn memcleanup_rt_free_of_a_null_block_does_nothing() {
    let _guard = memcleanup_rt();
    let p = slot(0);
    let p_addr = &*p as *const usize as usize;
    // SAFETY: `p` is live; C-string literal.
    unsafe {
        __m2c_rt_memcleanup_map2check_free(c"p".as_ptr(), addr(p_addr), 1, 12, c"main".as_ptr())
    };
    // :334-336
    assert_eq!(c_list_log(), "");
    assert_ok();
}

#[test]
fn memcleanup_rt_verdict_needs_a_pointer_to_the_last_leak() {
    let _guard = memcleanup_rt();
    memcleanup_prelude();
    // :138-148: the block 0x1100 is leaked and p (0x1000) still points to it.
    assert_eq!(__m2c_rt_memcleanup_analysis_is_program_correct(), 0);
    // valid_allocation_log appended the freed row (AllocationLog.c:69-101),
    // so the verdict is TRUE the second time.
    assert_eq!(c_allocation_log(), "0x1100;16;0\n0x1100;0;1\n");
    assert_eq!(__m2c_rt_memcleanup_analysis_is_program_correct(), 1);
    // memtrack reports the same leak whatever points to it.
    state::reset();
    state::reset_config();
    map2check_init(0);
    __m2c_rt_memcleanup_analysis_init();
    __m2c_rt_memcleanup_map2check_malloc(addr(0x1100), 16);
    // :141: no pointer variable refers to it: TRUE (memtrack would be FALSE).
    assert_eq!(__m2c_rt_memcleanup_analysis_is_program_correct(), 1);
    assert_ok();
}

#[test]
fn memcleanup_rt_verdict_is_true_once_the_pointer_moves_away() {
    let _guard = memcleanup_rt();
    memcleanup_prelude();
    // SAFETY: fake addresses; C strings. p = NULL after the malloc.
    unsafe {
        __m2c_rt_memcleanup_map2check_add_store_pointer(
            addr(0x1000),
            std::ptr::null(),
            1,
            c"p".as_ptr(),
            12,
            c"main".as_ptr(),
        )
    };
    // ListLog.c:40-65: the newest row of p no longer points to the block.
    assert_eq!(__m2c_rt_memcleanup_analysis_is_program_correct(), 1);
}

#[test]
fn memcleanup_rt_verdict_writes_the_memcleanup_property_files() {
    let _guard = memcleanup_rt();
    let dir = tempfile::tempdir().unwrap();
    // The verdict writes into the output directory of the test build.
    std::env::set_var(crate::output::termination::OUTPUT_DIR_ENV, dir.path());
    memcleanup_prelude();
    assert_eq!(__m2c_rt_memcleanup_analysis_is_program_correct(), 0);
    std::env::remove_var(crate::output::termination::OUTPUT_DIR_ENV);
    // PropertyGenerator.c:36-40 and :77-80.
    assert_eq!(
        std::fs::read_to_string(dir.path().join("map2check_property")).unwrap(),
        "FALSE-MEMCLEANUP\n"
    );
    assert_eq!(
        std::fs::read_to_string(dir.path().join("map2check_property_memcleanup")).unwrap(),
        "FALSE-MEMCLEANUP\n"
    );
}

#[test]
fn memcleanup_rt_generate_aux_witness_files_writes_the_three_logs() {
    let _guard = memcleanup_rt();
    let dir = tempfile::tempdir().unwrap();
    std::env::set_var(crate::output::termination::OUTPUT_DIR_ENV, dir.path());
    memcleanup_prelude();
    __m2c_rt_memcleanup_analysis_generate_aux_witness_files();
    std::env::remove_var(crate::output::termination::OUTPUT_DIR_ENV);
    // :150-154 heap, allocation and list logs, in the C formats.
    let read = |n: &str| std::fs::read_to_string(dir.path().join(n)).unwrap();
    assert_eq!(read("heap_log.csv"), "0x1000;p;8\n0x1040;main;1\n");
    assert_eq!(read("allocation_log.csv"), "0x1100;16;0\n");
    assert_eq!(read("list_log.csv"), "0;0x1000;0x1100;1;0;1;p;11;main;0\n");
}

/// SD-23 in memcleanup mode: `error = FALSE` lets a release of an untracked
/// or stack address through (`AnalysisModeMemcleanup.c:168`, `:342`); develop
/// then writes `row->size` through the NULL row of `find_row_with_address`
/// (`:176-177`, `:353-354`) and gets SIGSEGV. The core goes on.
#[test]
fn sd23_memcleanup_rt_release_without_allocation_row_goes_on() {
    let _guard = memcleanup_rt();
    let x = 7u64;
    let x_addr = &x as *const u64 as usize;
    let p = slot(x_addr);
    let p_addr = &*p as *const usize as usize;
    // SAFETY: `p` is live; fake addresses; C strings. `int x; int *p = &x;
    // free(p);` by both release functions.
    unsafe {
        __m2c_rt_memcleanup_map2check_alloca(c"x".as_ptr(), addr(x_addr), 8, 8, 3, 1);
        __m2c_rt_memcleanup_map2check_add_store_pointer(
            addr(p_addr),
            addr(x_addr),
            1,
            c"p".as_ptr(),
            4,
            c"main".as_ptr(),
        );
        __m2c_rt_memcleanup_map2check_free(c"p".as_ptr(), addr(p_addr), 1, 50, c"main".as_ptr());
        __m2c_rt_memcleanup_map2check_free_resolved_address(addr(x_addr), 51, c"main".as_ptr(), 0);
        __m2c_rt_memcleanup_map2check_free_resolved_address(addr(0x7777), 52, c"main".as_ptr(), 0);
    }
    // No verdict, no allocation row; only the FREE row of the store that
    // map2check_free appends before it looks the block up (:337-345).
    assert_ok();
    assert_eq!(c_allocation_log(), "");
    assert_eq!(c_list_log().lines().count(), 2);
    assert!(c_list_log().ends_with(&format!("0;{p_addr:#x};{x_addr:#x};1;1;0;p;50;main;1\n")));
    assert_eq!(__m2c_rt_memcleanup_analysis_is_program_correct(), 1);
}

/// `__VERIFIER_error` of the C core does nothing (`Map2CheckFunctions.c:57-59`),
/// with a mode set and without: no violation, no step, the process goes on
/// (SD-08).
#[test]
fn core_verifier_error_does_nothing_as_in_c() {
    for mode in [None, Some(crate::analysismode::mode::AnalysisMode::None)] {
        let _g = fresh();
        state::update_config(|c| c.mode = mode);
        let seen = || snapshot(|s| (s.result.ok, s.result.property, s.result.step, s.c_step));
        let before = seen();
        __VERIFIER_error();
        assert_eq!(seen(), before, "mode {mode:?}");
        assert_ok();
    }
}

#[test]
fn output_set_atomic_selects_the_result_file_write_mode() {
    use crate::output::legacy_files::{atomic_writes, write_mode_test_lock};
    let _mode = write_mode_test_lock();
    __m2c_rt_output_set_atomic(0);
    assert!(!atomic_writes());
    __m2c_rt_output_set_atomic(7);
    assert!(atomic_writes());
    assert!(crate::output::legacy_files::never_downgrade());
    __m2c_rt_output_set_atomic(0);
    assert!(!crate::output::legacy_files::never_downgrade());
    __m2c_rt_output_set_atomic(1);
    assert!(atomic_writes(), "the default of every non-dropin build");
    assert!(crate::output::legacy_files::never_downgrade());
    crate::output::legacy_files::set_never_downgrade(false);
}
