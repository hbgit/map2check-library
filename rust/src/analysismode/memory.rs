// SPDX-License-Identifier: GPL-3.0-only
// Memory safety VCC checkers.
#![deny(unsafe_code)]
// Replaces analysis_memory.c — delegates to memtrack container functions.

use crate::{
    analysismode::{VccChecker, VccContext, VccOutcome},
    caller::ViolatedProperty,
    error::Map2CheckError,
    memtrack,
    state,
};

// ── Load / dereference check ──────────────────────────────────────────────────

/// Checks whether loading from `address` is valid.
/// Replaces `map2check_check_load` in analysis_memory.c.
pub struct LoadChecker {
    pub address: usize,
    pub size: usize,
    pub is_null_valid: bool,
}

impl VccChecker for LoadChecker {
    fn check(&self, _ctx: &VccContext) -> Result<VccOutcome, Map2CheckError> {
        if self.address == 0 && !self.is_null_valid {
            return Ok(VccOutcome::Violated {
                property: ViolatedProperty::MemsafetyDeref,
            });
        }
        state::with_state(|s| {
            if memtrack::is_invalid_address(&s.memtrack, self.address, self.size) {
                Ok(VccOutcome::Violated {
                    property: ViolatedProperty::MemsafetyDeref,
                })
            } else {
                Ok(VccOutcome::Safe)
            }
        })
    }
}

// ── Free check ────────────────────────────────────────────────────────────────

/// Checks whether freeing `address` is valid.
/// Replaces `map2check_check_free` in analysis_memory.c.
pub struct FreeChecker {
    pub address: usize,
}

impl VccChecker for FreeChecker {
    fn check(&self, _ctx: &VccContext) -> Result<VccOutcome, Map2CheckError> {
        if self.address == 0 {
            return Ok(VccOutcome::Safe);
        }
        state::with_state(|s| {
            if memtrack::is_invalid_free(&s.memtrack, self.address) {
                Ok(VccOutcome::Violated {
                    property: ViolatedProperty::MemsafetyFree,
                })
            } else {
                Ok(VccOutcome::Safe)
            }
        })
    }
}

// ── Deref check ───────────────────────────────────────────────────────────────

/// Checks whether dereferencing `address` is valid.
/// Replaces `map2check_check_deref`.
pub struct DerefChecker {
    pub address: usize,
}

impl VccChecker for DerefChecker {
    fn check(&self, _ctx: &VccContext) -> Result<VccOutcome, Map2CheckError> {
        if self.address == 0 {
            return Ok(VccOutcome::Violated {
                property: ViolatedProperty::MemsafetyDeref,
            });
        }
        state::with_state(|s| {
            if memtrack::is_deref_error(&s.memtrack, self.address) {
                Ok(VccOutcome::Violated {
                    property: ViolatedProperty::MemsafetyDeref,
                })
            } else {
                Ok(VccOutcome::Safe)
            }
        })
    }
}

// ── End-of-program memory cleanup check ──────────────────────────────────────

/// Checks for memory leaks at end of program.
/// Replaces `map2check_check_mem_endprog`.
pub struct MemCleanupChecker;

impl VccChecker for MemCleanupChecker {
    fn check(&self, _ctx: &VccContext) -> Result<VccOutcome, Map2CheckError> {
        state::with_state(|s| {
            if memtrack::has_memcleanup_error(&s.memtrack) {
                Ok(VccOutcome::Violated {
                    property: ViolatedProperty::MemsafetyMemcleanup,
                })
            } else {
                Ok(VccOutcome::Safe)
            }
        })
    }
}
