// SPDX-License-Identifier: GPL-3.0-only
#![deny(unsafe_code)]

use crate::error::Map2CheckError;

pub mod assert;
pub mod memory;
pub mod mode;
pub mod overflow;

/// Context passed to every VCC checker — carries the source location.
///
/// The function name is borrowed: a context is built on every checked load
/// and store, and copying the name into the heap there was a measurable cost
/// under KLEE (Task 2.7b).
#[derive(Debug, Clone, Copy)]
pub struct VccContext<'a> {
    pub line: u32,
    pub scope: u32,
    pub function_name: &'a str,
}

impl<'a> VccContext<'a> {
    pub fn new(line: u32, scope: u32, function_name: &'a str) -> Self {
        Self {
            line,
            scope,
            function_name,
        }
    }
}

/// Result of a single verification condition check.
#[derive(Debug, PartialEq, Eq)]
pub enum VccOutcome {
    Safe,
    Violated {
        property: crate::caller::ViolatedProperty,
    },
}

/// Core trait that all analysis-mode checkers implement.
pub trait VccChecker: Send + Sync {
    fn check(&self, ctx: &VccContext) -> Result<VccOutcome, Map2CheckError>;
}
