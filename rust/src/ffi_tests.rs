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
        assert!(!s.memcleanup_enabled);
        assert!(!s.null_is_valid);
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
    assert!(!snapshot(|s| s.memcleanup_enabled));
    map2check_set_memcleanup();
    assert!(snapshot(|s| s.memcleanup_enabled));
}

#[test]
fn set_null_is_valid_sets_the_flag() {
    let _guard = fresh();
    assert!(!snapshot(|s| s.null_is_valid));
    map2check_set_null_is_valid();
    assert!(snapshot(|s| s.null_is_valid));
}
