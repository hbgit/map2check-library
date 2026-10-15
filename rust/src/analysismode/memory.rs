// SPDX-License-Identifier: GPL-3.0-only
// Memory safety VCC checkers.
#![deny(unsafe_code)]
// Replaces analysis_memory.c — delegates to memtrack container functions.

use crate::{
    analysismode::{VccChecker, VccContext, VccOutcome},
    caller::ViolatedProperty,
    error::Map2CheckError,
    memtrack, state,
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
        if self.address == 0 {
            return if self.is_null_valid {
                Ok(VccOutcome::Safe)
            } else {
                Ok(VccOutcome::Violated {
                    property: ViolatedProperty::MemsafetyDeref,
                })
            };
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

// ── Free check (resolved address) ───────────────────────────────────────────────

/// Checks whether freeing an already-resolved heap `address` is valid.
/// Replaces `map2check_check_free_resolved_address` — unlike [`FreeChecker`],
/// which is keyed on the pointer variable's own slot, this is keyed on the
/// target heap address itself (post-indirection).
pub struct FreeResolvedChecker {
    pub address: usize,
}

impl VccChecker for FreeResolvedChecker {
    fn check(&self, _ctx: &VccContext) -> Result<VccOutcome, Map2CheckError> {
        if self.address == 0 {
            return Ok(VccOutcome::Safe);
        }
        state::with_state(|s| {
            if memtrack::is_invalid_free_resolved(&s.memtrack, self.address) {
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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn null_load_obeys_null_valid_flag() {
        let ctx = VccContext::new(1, 0, "test");
        assert_eq!(
            LoadChecker {
                address: 0,
                size: 0,
                is_null_valid: true,
            }
            .check(&ctx)
            .unwrap(),
            VccOutcome::Safe
        );
        assert_eq!(
            LoadChecker {
                address: 0,
                size: 0,
                is_null_valid: false,
            }
            .check(&ctx)
            .unwrap(),
            VccOutcome::Violated {
                property: ViolatedProperty::MemsafetyDeref,
            }
        );
    }

    use crate::memtrack::MemTrackEntry;

    fn ctx() -> VccContext {
        VccContext::new(1, 0, "test")
    }

    /// Takes the global-state test lock, resets the state and installs `entries`.
    /// Keep the returned guard alive for the whole test.
    fn with_entries(entries: Vec<MemTrackEntry>) -> std::sync::MutexGuard<'static, ()> {
        let guard = state::test_lock();
        state::reset();
        state::with_state(|s| {
            s.memtrack = entries;
            Ok(())
        })
        .unwrap();
        guard
    }

    /// Heap allocation held by pointer variable `var_addr`; `is_free` models a freed block.
    fn heap(var_addr: usize, points_to: usize, size: usize, is_free: bool) -> MemTrackEntry {
        MemTrackEntry::new(
            1, 10, 0, var_addr, points_to, !is_free, is_free, "p", "main", size, 4, false,
        )
    }

    /// Stack variable (`alloca`): neither dynamic nor freed.
    fn stack(var_addr: usize) -> MemTrackEntry {
        MemTrackEntry::new(
            1, 10, 0, var_addr, var_addr, false, false, "x", "main", 4, 4, false,
        )
    }

    fn violated(property: ViolatedProperty) -> VccOutcome {
        VccOutcome::Violated { property }
    }

    #[test]
    fn load_inside_live_allocation_is_safe() {
        let _g = with_entries(vec![heap(0x10, 0x1000, 16, false)]);
        let load = LoadChecker {
            address: 0x1004,
            size: 4,
            is_null_valid: false,
        };
        assert_eq!(load.check(&ctx()).unwrap(), VccOutcome::Safe);
    }

    #[test]
    fn load_past_allocation_end_is_deref_violation() {
        let _g = with_entries(vec![heap(0x10, 0x1000, 16, false)]);
        let load = LoadChecker {
            address: 0x100c,
            size: 8,
            is_null_valid: false,
        };
        assert_eq!(
            load.check(&ctx()).unwrap(),
            violated(ViolatedProperty::MemsafetyDeref)
        );
    }

    #[test]
    fn load_from_freed_block_is_deref_violation() {
        let _g = with_entries(vec![heap(0x10, 0x1000, 16, true)]);
        let load = LoadChecker {
            address: 0x1000,
            size: 4,
            is_null_valid: false,
        };
        assert_eq!(
            load.check(&ctx()).unwrap(),
            violated(ViolatedProperty::MemsafetyDeref)
        );
    }

    #[test]
    fn free_checker_outcomes() {
        let _g = with_entries(vec![
            heap(0x10, 0x1000, 16, false),
            heap(0x20, 0x2000, 8, true),
        ]);
        assert_eq!(
            FreeChecker { address: 0 }.check(&ctx()).unwrap(),
            VccOutcome::Safe
        );
        assert_eq!(
            FreeChecker { address: 0x10 }.check(&ctx()).unwrap(),
            VccOutcome::Safe
        );
        assert_eq!(
            FreeChecker { address: 0x20 }.check(&ctx()).unwrap(),
            violated(ViolatedProperty::MemsafetyFree)
        );
        assert_eq!(
            FreeChecker { address: 0x99 }.check(&ctx()).unwrap(),
            violated(ViolatedProperty::MemsafetyFree)
        );
    }

    #[test]
    fn free_resolved_checker_outcomes() {
        let _g = with_entries(vec![
            heap(0x10, 0x1000, 16, false),
            heap(0x20, 0x2000, 8, true),
        ]);
        assert_eq!(
            FreeResolvedChecker { address: 0 }.check(&ctx()).unwrap(),
            VccOutcome::Safe
        );
        assert_eq!(
            FreeResolvedChecker { address: 0x1000 }
                .check(&ctx())
                .unwrap(),
            VccOutcome::Safe
        );
        assert_eq!(
            FreeResolvedChecker { address: 0x2000 }
                .check(&ctx())
                .unwrap(),
            violated(ViolatedProperty::MemsafetyFree)
        );
        assert_eq!(
            FreeResolvedChecker { address: 0x9999 }
                .check(&ctx())
                .unwrap(),
            VccOutcome::Safe
        );
    }

    #[test]
    fn deref_checker_outcomes() {
        let _g = with_entries(vec![
            heap(0x10, 0x1000, 16, false),
            heap(0x20, 0x2000, 8, true),
            stack(0x30),
        ]);
        assert_eq!(
            DerefChecker { address: 0 }.check(&ctx()).unwrap(),
            violated(ViolatedProperty::MemsafetyDeref)
        );
        assert_eq!(
            DerefChecker { address: 0x1000 }.check(&ctx()).unwrap(),
            VccOutcome::Safe
        );
        assert_eq!(
            DerefChecker { address: 0x2000 }.check(&ctx()).unwrap(),
            violated(ViolatedProperty::MemsafetyDeref)
        );
        assert_eq!(
            DerefChecker { address: 0x30 }.check(&ctx()).unwrap(),
            VccOutcome::Safe
        );
        assert_eq!(
            DerefChecker { address: 0x5555 }.check(&ctx()).unwrap(),
            violated(ViolatedProperty::MemsafetyDeref)
        );
    }

    #[test]
    fn mem_cleanup_flags_leaked_allocation() {
        let _g = with_entries(vec![stack(0x30), heap(0x10, 0x1000, 16, false)]);
        assert_eq!(
            MemCleanupChecker.check(&ctx()).unwrap(),
            violated(ViolatedProperty::MemsafetyMemcleanup)
        );
    }

    #[test]
    fn mem_cleanup_accepts_freed_allocation_and_stack_vars() {
        let _g = with_entries(vec![
            stack(0x30),
            heap(0x10, 0x1000, 16, false),
            heap(0x10, 0x1000, 16, true),
        ]);
        assert_eq!(MemCleanupChecker.check(&ctx()).unwrap(), VccOutcome::Safe);
    }
}
