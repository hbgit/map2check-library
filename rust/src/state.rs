// SPDX-License-Identifier: GPL-3.0-only
#![deny(unsafe_code)]

use std::sync::{Arc, Mutex, OnceLock};

use crate::{
    bbtrack::BasicBlockEntry,
    caller::{AnalysisResult, ViolatedProperty},
    error::Map2CheckError,
    memtrack::MemTrackEntry,
    nondet::NonDetEntry,
};

static ANALYSIS_STATE: OnceLock<Arc<Mutex<AnalysisState>>> = OnceLock::new();

#[derive(Debug, Default)]
pub struct AnalysisState {
    pub result: AnalysisResult,
    pub nondets: Vec<NonDetEntry>,
    pub memtrack: Vec<MemTrackEntry>,
    pub bbtrack: Vec<BasicBlockEntry>,
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

pub fn init() {
    ANALYSIS_STATE.get_or_init(|| Arc::new(Mutex::new(AnalysisState::default())));
}

pub fn get() -> Result<Arc<Mutex<AnalysisState>>, Map2CheckError> {
    ANALYSIS_STATE
        .get()
        .cloned()
        .ok_or(Map2CheckError::NotInitialized)
}

/// Convenience: lock the global state and apply a closure.
pub fn with_state<F, R>(f: F) -> Result<R, Map2CheckError>
where
    F: FnOnce(&mut AnalysisState) -> Result<R, Map2CheckError>,
{
    let arc = get()?;
    let mut guard = arc.lock()?;
    f(&mut guard)
}
