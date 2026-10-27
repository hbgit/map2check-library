// SPDX-License-Identifier: GPL-3.0-only
// Runtime selection of the analysis mode (Task 2.3 of the cutover plan).
#![deny(unsafe_code)]
//
// In the C runtime of Map2Check `develop` the analysis mode is chosen at link
// time: the frontend links exactly one `AnalysisMode*.c` bitcode per run
// (`modules/frontend/caller.cpp:575-612`). Each of those files defines
// `analysis_init`, `analysis_destroy`, `analysis_is_program_correct` and the
// check functions of its mode. This library is a single artifact, so the mode
// is chosen at run time by `map2check_set_mode()` and every one of those
// functions becomes a `match` on the mode below.
//
// The mode is optional. When `map2check_set_mode()` was never called it is
// unset (`None` here) and the library behaves as it did before Task 2.3: every
// check is active and the end-of-program leak tag follows the memcleanup
// option.

use crate::{
    caller::ViolatedProperty,
    memtrack::{self, c_mode::MemMode},
    state::{AnalysisState, Config},
};

/// Analysis mode selected by the instrumented program before
/// `map2check_init()`. The numeric values are part of the ABI: the LLVM
/// passes emit them as constants.
///
/// Frontend mapping (`modules/frontend/caller.hpp:21-37`,
/// `caller.cpp:575-612`): `MEMTRACK_MODE` → `Memtrack`, `MEMCLEANUP_MODE` →
/// `Memcleanup`, `OVERFLOW_MODE` → `Overflow`, `ASSERT_MODE` → `Assert`,
/// `REACHABILITY_MODE` → `Target`, `COVER_BRANCHES_MODE` → `None`. Both
/// `REACHABILITY_MODE` and `COVER_BRANCHES_MODE` link `AnalysisModeNone.c`.
///
/// cbindgen:prefix-with-name
#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum AnalysisMode {
    None = 0,
    Memtrack = 1,
    Memcleanup = 2,
    Overflow = 3,
    Assert = 4,
    Target = 5,
}

/// A check whose activity depends on the analysis mode. Tracking calls
/// (`map2check_map_*`, nondet and basic-block logs) are not checks: they
/// record in every mode.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Check {
    /// `map2check_check_load`.
    Load,
    /// `map2check_check_deref`.
    Deref,
    /// `map2check_check_free`.
    Free,
    /// `map2check_check_free_resolved_address` (the check only; the release
    /// is recorded whenever the check is inactive or passes).
    FreeResolved,
    /// Every `map2check_binop_*` export.
    Overflow,
    /// `map2check_is_valid_assert`.
    Assert,
}

/// `analysis_init()`: starts a fresh analysis. Called by `map2check_init()`
/// (develop: `map2check_init` calls `analysis_init`,
/// `Map2CheckFunctions.c:29-40`).
///
/// Every arm clears the whole state. In develop only the memory modes have
/// containers to create; the other modes have none, and the step counter and
/// basic-block log are reset by `map2check_init` itself (`:30-32`). Clearing
/// everything in every mode gives the same observable start: empty containers,
/// step 0 and no verdict.
pub fn analysis_init(mode: Option<AnalysisMode>, state: &mut AnalysisState) {
    match mode {
        // Unset: the pre-Task-2.3 `map2check_init()`, which cleared everything.
        None => state.reset(),
        // AnalysisModeNone.c:11-13 — "DO NOTHING".
        Some(AnalysisMode::None) => state.reset(),
        // AnalysisModeMemtrack.c:125-130 — new heap/allocation/list logs,
        // ERROR_DEREF = FALSE.
        Some(AnalysisMode::Memtrack) => state.reset(),
        // AnalysisModeMemcleanup.c:125-130 — same as memtrack.
        Some(AnalysisMode::Memcleanup) => state.reset(),
        // AnalysisModeOverflow.c:279 — empty.
        Some(AnalysisMode::Overflow) => state.reset(),
        // AnalysisModeAssert.c:29-31 — "DO NOTHING".
        Some(AnalysisMode::Assert) => state.reset(),
        // REACHABILITY_MODE links AnalysisModeNone.c (caller.cpp:600-605).
        Some(AnalysisMode::Target) => state.reset(),
    }
}

/// `analysis_destroy()`: releases the containers of the mode. The verdict,
/// the step counter and the nondet/basic-block logs are kept (develop frees
/// the basic-block log in `map2check_destroy` itself,
/// `Map2CheckFunctions.c:77-87`). Ending the run is Task 2.4, which calls
/// this after the end-of-program verdict.
pub fn analysis_destroy(mode: Option<AnalysisMode>, state: &mut AnalysisState) {
    match mode {
        // Unset: every check is active, so the memory log is in use.
        None => {
            state.memtrack.clear();
            state.c_memory.clear();
        }
        // AnalysisModeMemtrack.c:132-136 — frees heap, list and allocation
        // logs (the drop-in ones too).
        Some(AnalysisMode::Memtrack) => {
            state.memtrack.clear();
            state.c_memory.clear();
        }
        // AnalysisModeMemcleanup.c:132-136 — same as memtrack.
        Some(AnalysisMode::Memcleanup) => {
            state.memtrack.clear();
            state.c_memory.clear();
        }
        // AnalysisModeNone.c:15-17 — "DO NOTHING".
        Some(AnalysisMode::None) => {}
        // AnalysisModeOverflow.c:281 — empty.
        Some(AnalysisMode::Overflow) => {}
        // AnalysisModeAssert.c:33-35 — "DO NOTHING".
        Some(AnalysisMode::Assert) => {}
        // REACHABILITY_MODE links AnalysisModeNone.c (caller.cpp:600-605).
        Some(AnalysisMode::Target) => {}
    }
}

/// `analysis_is_program_correct()`: the end-of-program verdict. Returns the
/// violated property, or `None` when the program is correct. Develop calls it
/// from `map2check_exit` when no error was recorded
/// (`Map2CheckFunctions.c:89-92`); here `map2check_check_mem_endprog()` does.
///
/// The memcleanup option is an alias of the memcleanup mode for the leak tag:
/// in every mode that checks leaks it selects `MemsafetyMemcleanup`.
///
/// In memtrack mode the drop-in logs of the `__m2c_rt_memtrack_*` entry
/// points (`AnalysisState::c_memory`) are checked first, with develop's rule
/// (`valid_allocation_log`, which appends the freed rows the witness logs
/// show); that is why the state is mutable.
pub fn analysis_is_program_correct(
    config: Config,
    state: &mut AnalysisState,
) -> Option<ViolatedProperty> {
    let leak = |property| old_api_leak(&state.memtrack).then_some(property);
    let memtrack_tag = if config.memcleanup {
        ViolatedProperty::MemsafetyMemcleanup
    } else {
        ViolatedProperty::MemsafetyMemtrack
    };
    match config.mode {
        // Unset: the pre-Task-2.3 leak check, tagged by the option (SD-04).
        None => leak(memtrack_tag),
        // AnalysisModeMemtrack.c:138-146 — FALSE_MEMTRACK when
        // valid_allocation_log returns non-zero, i.e. any heap block is still
        // live; no reachability rule. `has_memcleanup_error` is that test.
        Some(AnalysisMode::Memtrack) => state
            .c_memory
            .is_program_correct(MemMode::Memtrack)
            .or_else(|| leak(memtrack_tag)),
        // AnalysisModeMemcleanup.c:138-148 — FALSE_MEMCLEANUP only when the
        // last leaked address (valid_allocation_log, AllocationLog.c:69-101)
        // is still referenced by a pointer variable (is_memcleanup_error,
        // ListLog.c:40-65). An unreachable leak gives no verdict. The drop-in
        // logs are checked first with that rule, as in memtrack.
        Some(AnalysisMode::Memcleanup) => state
            .c_memory
            .is_program_correct(MemMode::Memcleanup)
            .or_else(|| {
                old_api_develop_memcleanup_error(&state.memtrack)
                    .then_some(ViolatedProperty::MemsafetyMemcleanup)
            }),
        // AnalysisModeNone.c:19 — TRUE.
        Some(AnalysisMode::None) => None,
        // AnalysisModeOverflow.c:283 — TRUE.
        Some(AnalysisMode::Overflow) => None,
        // AnalysisModeAssert.c:37 — TRUE.
        Some(AnalysisMode::Assert) => None,
        // REACHABILITY_MODE links AnalysisModeNone.c: TRUE.
        Some(AnalysisMode::Target) => None,
    }
}

/// The leak test of the records of the old API (`map2check_map_*`,
/// `AnalysisState::memtrack`). The drop-in core has no such records (only
/// the `__m2c_rt_*` entry points record, into `c_memory`), so there it is
/// always false and the code is not compiled (Task 3.3).
fn old_api_leak(records: &[memtrack::MemTrackEntry]) -> bool {
    #[cfg(not(feature = "dropin"))]
    {
        memtrack::has_memcleanup_error(records)
    }
    #[cfg(feature = "dropin")]
    {
        debug_assert!(records.is_empty());
        false
    }
}

/// develop's memcleanup verdict on the records of the old API
/// ([`old_api_leak`]).
fn old_api_develop_memcleanup_error(records: &[memtrack::MemTrackEntry]) -> bool {
    #[cfg(not(feature = "dropin"))]
    {
        memtrack::has_develop_memcleanup_error(records)
    }
    #[cfg(feature = "dropin")]
    {
        debug_assert!(records.is_empty());
        false
    }
}

/// Whether `check` reports violations in `mode`. An inactive check records
/// nothing, as when develop links a mode whose file has no such check (the
/// pass of another mode never emits the call) or whose check never fails.
pub fn check_enabled(mode: Option<AnalysisMode>, check: Check) -> bool {
    match mode {
        // Unset: every check is active, as before Task 2.3.
        None => true,
        // AnalysisModeNone.c defines no check.
        Some(AnalysisMode::None) => false,
        // AnalysisModeMemtrack.c: map2check_load (:156-162), check_deref
        // (:297-303), map2check_free (:339-366), free_resolved_address
        // (:164-183). No overflow or assert check is linked.
        Some(AnalysisMode::Memtrack) => matches!(
            check,
            Check::Load | Check::Deref | Check::Free | Check::FreeResolved
        ),
        // AnalysisModeMemcleanup.c: map2check_load is empty (:158),
        // check_deref is empty (:293), map2check_free and
        // free_resolved_address use `error = FALSE` (:343, :166). Only the
        // end-of-program leak is checked.
        Some(AnalysisMode::Memcleanup) => false,
        // AnalysisModeOverflow.c:185-276 — the binop checks only.
        Some(AnalysisMode::Overflow) => check == Check::Overflow,
        // AnalysisModeAssert.c:18-23 — map2check_assert only.
        Some(AnalysisMode::Assert) => check == Check::Assert,
        // REACHABILITY_MODE links AnalysisModeNone.c; the target call is
        // map2check_target_function, outside the mode (Map2CheckFunctions.c:61).
        Some(AnalysisMode::Target) => false,
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::memtrack::MemTrackEntry;

    const ALL_CHECKS: [Check; 6] = [
        Check::Load,
        Check::Deref,
        Check::Free,
        Check::FreeResolved,
        Check::Overflow,
        Check::Assert,
    ];

    fn malloc(addr: usize) -> MemTrackEntry {
        let mut e = MemTrackEntry::new(1, 0, 0, addr, addr, false, false, "", "", 16, 1, false);
        e.set_malloc();
        e
    }

    /// A state with one leaked heap block, a recorded violation and a step.
    fn dirty_state() -> AnalysisState {
        let mut s = AnalysisState::default();
        s.memtrack.push(malloc(0x1000));
        s.set_false(ViolatedProperty::Overflow, 3, "f");
        s.next_step();
        s
    }

    fn leaked_state() -> AnalysisState {
        let mut s = AnalysisState::default();
        s.memtrack.push(malloc(0x1000));
        s
    }

    fn config(mode: Option<AnalysisMode>, memcleanup: bool) -> Config {
        Config {
            mode,
            memcleanup,
            ..Config::new()
        }
    }

    fn enabled(mode: Option<AnalysisMode>) -> Vec<Check> {
        ALL_CHECKS
            .into_iter()
            .filter(|c| check_enabled(mode, *c))
            .collect()
    }

    fn assert_fresh(s: &AnalysisState) {
        assert!(s.result.ok);
        assert_eq!(s.result.property, ViolatedProperty::None);
        assert_eq!(s.current_step(), 0);
        assert!(s.memtrack.is_empty() && s.nondets.is_empty() && s.bbtrack.is_empty());
    }

    // ── AnalysisMode ABI ────────────────────────────────────────────────────

    #[test]
    fn analysis_mode_discriminants_are_the_abi_values() {
        assert_eq!(AnalysisMode::None as i32, 0);
        assert_eq!(AnalysisMode::Memtrack as i32, 1);
        assert_eq!(AnalysisMode::Memcleanup as i32, 2);
        assert_eq!(AnalysisMode::Overflow as i32, 3);
        assert_eq!(AnalysisMode::Assert as i32, 4);
        assert_eq!(AnalysisMode::Target as i32, 5);
    }

    // ── analysis_init: one test per arm ─────────────────────────────────────

    #[test]
    fn init_unset_starts_fresh() {
        let mut s = dirty_state();
        analysis_init(None, &mut s);
        assert_fresh(&s);
    }

    #[test]
    fn init_none_starts_fresh() {
        let mut s = dirty_state();
        analysis_init(Some(AnalysisMode::None), &mut s);
        assert_fresh(&s);
    }

    #[test]
    fn init_memtrack_starts_fresh() {
        let mut s = dirty_state();
        analysis_init(Some(AnalysisMode::Memtrack), &mut s);
        assert_fresh(&s);
    }

    #[test]
    fn init_memcleanup_starts_fresh() {
        let mut s = dirty_state();
        analysis_init(Some(AnalysisMode::Memcleanup), &mut s);
        assert_fresh(&s);
    }

    #[test]
    fn init_overflow_starts_fresh() {
        let mut s = dirty_state();
        analysis_init(Some(AnalysisMode::Overflow), &mut s);
        assert_fresh(&s);
    }

    #[test]
    fn init_assert_starts_fresh() {
        let mut s = dirty_state();
        analysis_init(Some(AnalysisMode::Assert), &mut s);
        assert_fresh(&s);
    }

    #[test]
    fn init_target_starts_fresh() {
        let mut s = dirty_state();
        analysis_init(Some(AnalysisMode::Target), &mut s);
        assert_fresh(&s);
    }

    // ── analysis_destroy: one test per arm ──────────────────────────────────

    #[test]
    fn destroy_unset_releases_memory_containers() {
        let mut s = dirty_state();
        analysis_destroy(None, &mut s);
        assert!(s.memtrack.is_empty());
        assert!(!s.result.ok, "destroy keeps the verdict");
    }

    #[test]
    fn destroy_none_keeps_everything() {
        let mut s = dirty_state();
        analysis_destroy(Some(AnalysisMode::None), &mut s);
        assert_eq!(s.memtrack.len(), 1);
        assert!(!s.result.ok);
    }

    #[test]
    fn destroy_memtrack_releases_memory_containers() {
        let mut s = dirty_state();
        analysis_destroy(Some(AnalysisMode::Memtrack), &mut s);
        assert!(s.memtrack.is_empty());
        assert!(!s.result.ok);
    }

    #[test]
    fn destroy_memcleanup_releases_memory_containers() {
        let mut s = dirty_state();
        analysis_destroy(Some(AnalysisMode::Memcleanup), &mut s);
        assert!(s.memtrack.is_empty());
        assert!(!s.result.ok);
    }

    #[test]
    fn destroy_overflow_keeps_everything() {
        let mut s = dirty_state();
        analysis_destroy(Some(AnalysisMode::Overflow), &mut s);
        assert_eq!(s.memtrack.len(), 1);
    }

    #[test]
    fn destroy_assert_keeps_everything() {
        let mut s = dirty_state();
        analysis_destroy(Some(AnalysisMode::Assert), &mut s);
        assert_eq!(s.memtrack.len(), 1);
    }

    #[test]
    fn destroy_target_keeps_everything() {
        let mut s = dirty_state();
        analysis_destroy(Some(AnalysisMode::Target), &mut s);
        assert_eq!(s.memtrack.len(), 1);
    }

    // ── analysis_is_program_correct: one test per arm ───────────────────────

    #[test]
    fn program_correct_unset_reports_leak_by_option() {
        let mut s = leaked_state();
        assert_eq!(
            analysis_is_program_correct(config(None, false), &mut s),
            Some(ViolatedProperty::MemsafetyMemtrack)
        );
        assert_eq!(
            analysis_is_program_correct(config(None, true), &mut s),
            Some(ViolatedProperty::MemsafetyMemcleanup)
        );
        assert_eq!(
            analysis_is_program_correct(config(None, false), &mut AnalysisState::default()),
            None
        );
    }

    #[test]
    fn program_correct_none_ignores_leak() {
        let mut s = leaked_state();
        for memcleanup in [false, true] {
            let c = config(Some(AnalysisMode::None), memcleanup);
            assert_eq!(analysis_is_program_correct(c, &mut s), None);
        }
    }

    #[test]
    fn program_correct_memtrack_reports_leak_as_memtrack() {
        let mut s = leaked_state();
        let c = config(Some(AnalysisMode::Memtrack), false);
        assert_eq!(
            analysis_is_program_correct(c, &mut s),
            Some(ViolatedProperty::MemsafetyMemtrack)
        );
        assert_eq!(
            analysis_is_program_correct(c, &mut AnalysisState::default()),
            None
        );
    }

    #[test]
    fn program_correct_memtrack_with_memcleanup_option_reports_memcleanup() {
        // The option is an alias of the memcleanup mode for the leak tag.
        let c = config(Some(AnalysisMode::Memtrack), true);
        assert_eq!(
            analysis_is_program_correct(c, &mut leaked_state()),
            Some(ViolatedProperty::MemsafetyMemcleanup)
        );
    }

    #[test]
    fn program_correct_memcleanup_reports_leak_as_memcleanup() {
        // Develop reports only a leak still referenced by a pointer
        // (AnalysisModeMemcleanup.c:138-148, ListLog.c:40-65).
        assert_eq!(
            analysis_is_program_correct(
                config(Some(AnalysisMode::Memcleanup), false),
                &mut leaked_state()
            ),
            None,
            "an unreferenced leak is no memcleanup error"
        );
        let mut s = leaked_state();
        s.memtrack.push(MemTrackEntry::new(
            2, 1, 0, 0x10, 0x1000, false, false, "p", "main", 0, 1, false,
        ));
        let c = config(Some(AnalysisMode::Memcleanup), false);
        assert_eq!(
            analysis_is_program_correct(c, &mut s),
            Some(ViolatedProperty::MemsafetyMemcleanup)
        );
        assert_eq!(
            analysis_is_program_correct(c, &mut AnalysisState::default()),
            None
        );
    }

    #[test]
    fn program_correct_overflow_ignores_leak() {
        let c = config(Some(AnalysisMode::Overflow), true);
        assert_eq!(analysis_is_program_correct(c, &mut leaked_state()), None);
    }

    #[test]
    fn program_correct_assert_ignores_leak() {
        let c = config(Some(AnalysisMode::Assert), true);
        assert_eq!(analysis_is_program_correct(c, &mut leaked_state()), None);
    }

    #[test]
    fn program_correct_target_ignores_leak() {
        let c = config(Some(AnalysisMode::Target), true);
        assert_eq!(analysis_is_program_correct(c, &mut leaked_state()), None);
    }

    #[test]
    fn program_correct_memcleanup_checks_the_drop_in_logs_with_the_c_rule() {
        // AnalysisModeMemcleanup.c:138-148 over the drop-in logs: only a
        // leak still referenced by a pointer is FALSE_MEMCLEANUP.
        let c = config(Some(AnalysisMode::Memcleanup), false);
        let mut s = AnalysisState::default();
        assert!(s.c_memory.malloc(0x1000, 8));
        assert_eq!(analysis_is_program_correct(c, &mut s), None);
        let mut s = AnalysisState::default();
        let mut step = 0;
        assert!(s.c_memory.malloc(0x1000, 8));
        s.c_memory
            .add_store_pointer(&mut step, 0x10, 0x1000, 1, b"p", 1, b"main");
        assert_eq!(
            analysis_is_program_correct(c, &mut s),
            Some(ViolatedProperty::MemsafetyMemcleanup)
        );
    }

    #[test]
    fn program_correct_memtrack_checks_the_drop_in_logs_with_the_c_rule() {
        // AnalysisModeMemtrack.c:138-146 over the logs of the
        // __m2c_rt_memtrack_* entry points: valid_allocation_log appends a
        // freed row for the leak, so the next verdict is TRUE.
        let mut s = AnalysisState::default();
        assert!(s.c_memory.malloc(0x1000, 8));
        let c = config(Some(AnalysisMode::Memtrack), false);
        assert_eq!(
            analysis_is_program_correct(c, &mut s),
            Some(ViolatedProperty::MemsafetyMemtrack)
        );
        assert_eq!(
            s.c_memory.allocation_log_bytes(),
            b"0x1000;8;0\n0x1000;0;1\n"
        );
        assert_eq!(analysis_is_program_correct(c, &mut s), None);
        // Other modes do not read them.
        let mut s = AnalysisState::default();
        assert!(s.c_memory.malloc(0x1000, 8));
        let c = config(Some(AnalysisMode::Overflow), false);
        assert_eq!(analysis_is_program_correct(c, &mut s), None);
    }

    #[test]
    fn destroy_of_the_memory_modes_frees_the_drop_in_logs() {
        for mode in [
            None,
            Some(AnalysisMode::Memtrack),
            Some(AnalysisMode::Memcleanup),
        ] {
            let mut s = AnalysisState::default();
            assert!(s.c_memory.malloc(0x1000, 8));
            analysis_destroy(mode, &mut s);
            assert!(!s.c_memory.has_rows(), "{mode:?}");
        }
    }

    // ── check_enabled: one test per arm ─────────────────────────────────────

    #[test]
    fn checks_unset_all_active() {
        assert_eq!(enabled(None), ALL_CHECKS.to_vec());
    }

    #[test]
    fn checks_none_all_inactive() {
        assert_eq!(enabled(Some(AnalysisMode::None)), vec![]);
    }

    #[test]
    fn checks_memtrack_memory_only() {
        assert_eq!(
            enabled(Some(AnalysisMode::Memtrack)),
            vec![Check::Load, Check::Deref, Check::Free, Check::FreeResolved]
        );
    }

    #[test]
    fn checks_memcleanup_none_active() {
        assert_eq!(enabled(Some(AnalysisMode::Memcleanup)), vec![]);
    }

    #[test]
    fn checks_overflow_overflow_only() {
        assert_eq!(enabled(Some(AnalysisMode::Overflow)), vec![Check::Overflow]);
    }

    #[test]
    fn checks_assert_assert_only() {
        assert_eq!(enabled(Some(AnalysisMode::Assert)), vec![Check::Assert]);
    }

    #[test]
    fn checks_target_all_inactive() {
        assert_eq!(enabled(Some(AnalysisMode::Target)), vec![]);
    }
}
