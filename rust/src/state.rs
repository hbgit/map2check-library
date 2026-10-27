// SPDX-License-Identifier: GPL-3.0-only
#![deny(unsafe_code)]

use std::sync::Mutex;

use crate::{
    analysismode::mode::AnalysisMode,
    bbtrack::BasicBlockEntry,
    caller::{AnalysisResult, ViolatedProperty},
    error::Map2CheckError,
    memtrack::MemTrackEntry,
    nondet::NonDetEntry,
};

// Built at compile time (`AnalysisState::new` is const): no `OnceLock` and
// no `LazyLock` (unstable in rustc 1.72, which builds the drop-in core, D1
// condition 5), so the core carries no once-initialisation code (Task 3.3).
static ANALYSIS_STATE: Mutex<AnalysisState> = Mutex::new(AnalysisState::new());

static CONFIG: Mutex<Config> = Mutex::new(Config::new());

/// Run configuration, kept apart from the analysis state: it changes only
/// through its setters, so `map2check_init()` and `map2check_reset()` never
/// clear it.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Config {
    /// Set by the `__m2c_rt_<mode>_analysis_init` of the linked mode module
    /// (and by the Rust-only `map2check_set_mode()` of the tests). `None`
    /// means unset: every check is active and the leak tag follows
    /// `memcleanup`, as before Task 2.3.
    pub mode: Option<AnalysisMode>,
    /// Set by `map2check_set_memcleanup()`: a leak at exit is reported as
    /// `MemsafetyMemcleanup` instead of `MemsafetyMemtrack`.
    pub memcleanup: bool,
    /// Set by `map2check_set_null_is_valid()`: a NULL load is safe.
    pub null_is_valid: bool,
    /// Set by `map2check_enable_witness()`: the end of a Map2Check run also
    /// writes the witness files (`track_bb_log.st`, the memory logs,
    /// `klee_log.csv` and `map2check_checked_error`), as a develop binary
    /// linked with `WitnessGeneration.c` does.
    pub witness: bool,
}

impl Config {
    pub const fn new() -> Self {
        Self {
            mode: None,
            memcleanup: false,
            null_is_valid: false,
            witness: false,
        }
    }
}

impl Default for Config {
    fn default() -> Self {
        Self::new()
    }
}

/// Returns a copy of the current configuration.
pub fn config() -> Config {
    *CONFIG
        .lock()
        .unwrap_or_else(std::sync::PoisonError::into_inner)
}

/// Changes the configuration. Only the option setters call this.
pub fn update_config(f: impl FnOnce(&mut Config)) {
    f(&mut CONFIG
        .lock()
        .unwrap_or_else(std::sync::PoisonError::into_inner));
}

/// Restores the default configuration (tests only; the library never does).
#[cfg(test)]
pub(crate) fn reset_config() {
    update_config(|c| *c = Config::new());
}

#[derive(Debug)]
pub struct AnalysisState {
    pub result: AnalysisResult,
    pub nondets: Vec<NonDetEntry>,
    /// The rows of develop's `nondet_log` (`NonDetLog.c:144`), appended by
    /// the `map2check_nondet_<t>` exports and written to `klee_log.csv` by
    /// `__m2c_rt_nondet_log_to_file`.
    pub c_nondet: Vec<crate::nondet::c_log::CNondetCall>,
    pub memtrack: Vec<MemTrackEntry>,
    /// The offset-keyed allocation table of the wasm2c runtime
    /// (`map2check_wasm_*`, Task 2.8).
    pub wasm_allocs: Vec<crate::memtrack::WasmAlloc>,
    /// develop's `heap_log`, `allocation_log`, `list_log` and `ERROR_DEREF`
    /// (`AnalysisModeMemtrack.c:120-123`), kept by the `__m2c_rt_memtrack_*`
    /// core entry points (Task 2.5). Its list rows take `c_step`.
    pub c_memory: crate::memtrack::c_mode::CMemory,
    pub bbtrack: Vec<BasicBlockEntry>,
    pub legacy_nondet_logs: Vec<Box<crate::ffi::non_det_log_t>>,
    pub legacy_bbtrack_logs: Vec<Box<crate::ffi::bbtrack_log_t>>,
    /// The free that `map2check_check_free` found invalid, when it is the
    /// first violation. Develop's `map2check_free` appends its FREE row to
    /// the list log before it checks (`AnalysisModeMemtrack.c:346-358`), so
    /// the legacy logs keep it; it is not a release and no check reads it.
    pub failed_free: Option<MemTrackEntry>,
    /// develop's `Map2CheckCurrentStep` (`Map2CheckFunctions.c:19`): 0 after
    /// `map2check_init`, read by `map2check_get_current_step` and advanced
    /// only by `map2check_next_current_step`, with C `unsigned` wrap-around.
    /// It is not `result.step`, which every record of this library advances.
    pub c_step: u32,
    /// develop's `gotError` (`Map2CheckFunctions.c:27`): set by
    /// `map2check_error`, so `map2check_exit` skips the end-of-program
    /// verdict and ends the run as a violation even with no property recorded.
    pub got_error: bool,
    /// The end-of-program verdict (`analysis_is_program_correct`) ran in this
    /// run; develop's allocation log then has the rows `valid_allocation_log`
    /// appends (`AllocationLog.c:69-101`), which the witness logs replay.
    pub end_of_program: bool,
    /// `map2check_destroy` already ran (develop's function-static
    /// `alreadyReleased`, `Map2CheckFunctions.c:80-83`). Here it belongs to
    /// the run and `map2check_init` clears it; develop never clears it, which
    /// only changes what a second run in the same process frees.
    pub destroyed: bool,
}

impl Default for AnalysisState {
    fn default() -> Self {
        Self::new()
    }
}

impl AnalysisState {
    /// The state before any record.
    pub const fn new() -> Self {
        Self {
            result: AnalysisResult::new(),
            nondets: Vec::new(),
            c_nondet: Vec::new(),
            memtrack: Vec::new(),
            wasm_allocs: Vec::new(),
            c_memory: crate::memtrack::c_mode::CMemory::new(),
            bbtrack: Vec::new(),
            legacy_nondet_logs: Vec::new(),
            legacy_bbtrack_logs: Vec::new(),
            failed_free: None,
            c_step: 0,
            got_error: false,
            end_of_program: false,
            destroyed: false,
        }
    }

    pub fn reset(&mut self) {
        *self = Self::new();
    }

    /// Records a violation unless one is already recorded (#36, SD-03).
    ///
    /// The first violation is final: in the C runtime of Map2Check every
    /// violation ends the process through `map2check_error()`, so nothing can
    /// replace it. This library keeps running instead, so a later violation is
    /// ignored rather than overwriting the first.
    pub fn set_false(&mut self, property: ViolatedProperty, line: u32, function_name: &str) {
        if !self.result.ok {
            return;
        }
        self.result.ok = false;
        self.result.property = property;
        self.result.line = line;
        self.result.function_name = function_name.to_owned();
    }

    pub fn next_step(&mut self) -> u64 {
        self.result.step += 1;
        self.result.step
    }

    pub fn current_step(&self) -> u64 {
        self.result.step
    }
}

fn ensure_state() -> &'static Mutex<AnalysisState> {
    &ANALYSIS_STATE
}

/// Starts a fresh analysis: forces the singleton into existence and runs the
/// `analysis_init` of the selected mode, which clears every counter,
/// container, result and flag, so a second `map2check_init()` in the same
/// process never sees data from an earlier analysis. The configuration,
/// including the mode, is kept.
pub fn init() {
    let mode = config().mode;
    with_state_recovering(|s| crate::analysismode::mode::analysis_init(mode, s));
}

pub fn reset() {
    with_state_recovering(AnalysisState::reset);
}

/// Applies `f` to the state, recovering the lock if an earlier panic
/// poisoned it.
fn with_state_recovering(f: impl FnOnce(&mut AnalysisState)) {
    let state = ensure_state();
    match state.lock() {
        Ok(mut guard) => f(&mut guard),
        Err(poisoned) => {
            let mut guard = poisoned.into_inner();
            f(&mut guard);
            // `Mutex::clear_poison` is unstable in rustc 1.72, which builds
            // the drop-in core (klee/Cargo.toml). That build has
            // `panic = "abort"`, so no caught panic can poison the lock there
            // (D1, "Custo do pin").
            #[cfg(not(feature = "dropin"))]
            state.clear_poison();
        }
    }
}

pub fn get() -> Result<&'static Mutex<AnalysisState>, Map2CheckError> {
    Ok(ensure_state())
}

/// Locks the process-wide analysis state and applies a closure.
///
/// This function is intentionally non-reentrant: it serializes access to the
/// singleton state via a global mutex and should not be called from a path that
/// can re-enter the same FFI boundary while the lock is held. Code that needs to
/// mutate the state should do so within a single closure and avoid nested calls
/// into other exported `extern "C"` functions.
pub fn with_state<F, R>(f: F) -> Result<R, Map2CheckError>
where
    F: FnOnce(&mut AnalysisState) -> Result<R, Map2CheckError>,
{
    let state = get()?;
    // The drop-in core is built with `panic = "abort"`: no panic can poison
    // its lock, so there is no error to report (and no `PoisonError` text
    // to format).
    #[cfg(feature = "dropin")]
    let mut guard = state
        .lock()
        .unwrap_or_else(std::sync::PoisonError::into_inner);
    #[cfg(not(feature = "dropin"))]
    let mut guard = state.lock()?;
    f(&mut guard)
}

/// Serializes unit tests that touch process-wide state (the analysis state and
/// the LibFuzzer input atomics). `cargo test` runs tests in parallel threads,
/// so without this a `reset()` in one test can wipe another test's setup.
#[cfg(test)]
pub(crate) fn test_lock() -> std::sync::MutexGuard<'static, ()> {
    static TEST_LOCK: Mutex<()> = Mutex::new(());
    TEST_LOCK
        .lock()
        .unwrap_or_else(std::sync::PoisonError::into_inner)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn reset_clears_global_state() {
        let _guard = test_lock();
        init();
        with_state(|s| {
            s.set_false(ViolatedProperty::MemsafetyDeref, 42, "test_fn");
            s.nondets.push(NonDetEntry::new(
                1,
                42,
                0,
                "test_fn",
                crate::nondet::NonDetValue::Int(7),
            ));
            Ok(())
        })
        .unwrap();

        reset();

        let state = ensure_state();
        let guard = state.lock().unwrap();
        assert!(guard.result.function_name.is_empty());
        assert!(guard.nondets.is_empty());
        assert!(guard.memtrack.is_empty());
        assert!(guard.bbtrack.is_empty());
    }

    #[test]
    fn next_step_increments_and_current_step_reads_it() {
        let mut s = AnalysisState::default();
        assert_eq!(s.current_step(), 0);
        assert_eq!(s.next_step(), 1);
        assert_eq!(s.next_step(), 2);
        assert_eq!(s.current_step(), 2);
    }

    #[test]
    fn reset_recovers_from_poisoned_lock() {
        let _guard = test_lock();
        let _ = std::thread::spawn(|| {
            let _held = ensure_state().lock().unwrap();
            panic!("poison the analysis state on purpose");
        })
        .join();
        assert!(ensure_state().is_poisoned());

        reset();

        assert!(!ensure_state().is_poisoned());
        assert!(with_state(|s| Ok(s.result.ok)).unwrap());
    }
}
