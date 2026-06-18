// SPDX-License-Identifier: GPL-3.0-only
#![deny(unsafe_code)]

use std::sync::Arc;

use crate::error::Map2CheckError;

pub mod assert;
pub mod memory;
pub mod overflow;

/// Context passed to every VCC checker — carries the source location.
#[derive(Debug, Clone)]
pub struct VccContext {
    pub line: u32,
    pub scope: u32,
    pub function_name: Arc<str>,
}

impl VccContext {
    pub fn new(line: u32, scope: u32, function_name: &str) -> Self {
        Self {
            line,
            scope,
            function_name: Arc::from(function_name),
        }
    }
}

/// Result of a single verification condition check.
#[derive(Debug, PartialEq, Eq)]
pub enum VccOutcome {
    Safe,
    Violated { property: crate::caller::ViolatedProperty },
}

/// Core trait that all analysis-mode checkers implement.
pub trait VccChecker: Send + Sync {
    fn check(&self, ctx: &VccContext) -> Result<VccOutcome, Map2CheckError>;
}
