// SPDX-License-Identifier: GPL-3.0-only
#![deny(unsafe_code)]

use std::sync::{LazyLock, Mutex};

use crate::{
    bbtrack::BasicBlockEntry,
    caller::{AnalysisResult, ViolatedProperty},
    error::Map2CheckError,
    memtrack::MemTrackEntry,
    nondet::NonDetEntry,
};

static ANALYSIS_STATE: LazyLock<Mutex<AnalysisState>> =
    LazyLock::new(|| Mutex::new(AnalysisState::default()));

#[derive(Debug, Default)]
pub struct AnalysisState {
    pub result: AnalysisResult,
    pub nondets: Vec<NonDetEntry>,
    pub memtrack: Vec<MemTrackEntry>,
    pub bbtrack: Vec<BasicBlockEntry>,
    /// Set by `map2check_set_null_is_valid()`; read by `map2check_check_load`.
    pub null_is_valid: bool,
    /// Set by `map2check_set_memcleanup()`; read by `map2check_check_mem_endprog`.
    pub memcleanup_enabled: bool,
}

impl AnalysisState {
    pub fn reset(&mut self) {
        *self = Self::default();
    }

    pub fn set_false(&mut self, property: ViolatedProperty, line: u32, function_name: &str) {
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

pub fn init() {
    let _ = ensure_state();
}

pub fn reset() {
    let state = ensure_state();
    match state.lock() {
        Ok(mut guard) => guard.reset(),
        Err(poisoned) => {
            let mut guard = poisoned.into_inner();
            guard.reset();
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
    let mut guard = state.lock()?;
    f(&mut guard)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn reset_clears_global_state() {
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
}
