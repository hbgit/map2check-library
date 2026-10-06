// SPDX-License-Identifier: GPL-3.0-only
#![deny(unsafe_code)]

use serde::Serialize;
use std::collections::HashSet;

/// Single memory tracking record — analogous to `memtrack_log_t` in C.
/// Addresses are `usize` (platform pointer width) instead of `long`.
#[derive(Debug, Clone, Serialize)]
pub struct MemTrackEntry {
    pub step: u64,
    pub line: u32,
    pub scope: u32,
    /// Address of the variable holding the pointer (cast from `*const T`).
    #[serde(rename = "var_mem_address")]
    pub var_addr: usize,
    /// Address the variable points to.
    #[serde(rename = "mem_address_points_to")]
    pub points_to: usize,
    pub is_dynamic: bool,
    pub is_free: bool,
    pub ptr_name: String,
    pub function_name: String,
    /// Total allocated size in bytes.
    pub size_destiny: usize,
    /// Size of the primitive element.
    pub size_primitive: usize,
    pub is_null_valid: bool,
}

impl MemTrackEntry {
    #[allow(clippy::too_many_arguments)]
    pub fn new(
        step: u64,
        line: u32,
        scope: u32,
        var_addr: usize,
        points_to: usize,
        is_dynamic: bool,
        is_free: bool,
        ptr_name: &str,
        function_name: &str,
        size_destiny: usize,
        size_primitive: usize,
        is_null_valid: bool,
    ) -> Self {
        Self {
            step,
            line,
            scope,
            var_addr,
            points_to,
            is_dynamic,
            is_free,
            ptr_name: ptr_name.to_owned(),
            function_name: function_name.to_owned(),
            size_destiny,
            size_primitive,
            is_null_valid,
        }
    }

    pub fn set_malloc(&mut self) {
        self.is_dynamic = true;
        self.is_free = false;
    }

    pub fn set_calloc(&mut self, quantity: usize) -> bool {
        let Some(size) = self.size_destiny.checked_mul(quantity) else {
            return false;
        };
        self.size_destiny = size;
        self.set_malloc();
        true
    }

    pub fn set_free(&mut self) {
        self.is_free = true;
        self.is_dynamic = false;
        self.size_destiny = 0;
    }

    /// Two entries refer to the same allocation slot when they share address,
    /// scope, dynamic flag, free status, and source line.
    pub fn same_slot(&self, other: &Self) -> bool {
        self.var_addr == other.var_addr
            && self.scope == other.scope
            && self.is_dynamic == other.is_dynamic
            && self.is_free == other.is_free
            && self.line == other.line
    }
}

// ── VCC checks (Verification Condition Checking) ─────────────────────────────

/// Checks whether freeing `address` is invalid (already freed).
/// Replaces `is_addr_a_invalid_free_in_cntr` — uses reverse iterator instead of TAILQ_FOREACH_REVERSE.
pub fn is_invalid_free(entries: &[MemTrackEntry], address: usize) -> bool {
    entries
        .iter()
        .rev()
        .find(|e| (e.is_dynamic || e.is_free) && (e.var_addr == address || e.points_to == address))
        .map(|e| e.is_free || !e.is_dynamic)
        .unwrap_or(true)
}

/// Checks whether dereferencing `address` is invalid (not allocated or already freed).
/// Replaces `is_addr_a_deref_error_in_cntr`.
pub fn is_deref_error(entries: &[MemTrackEntry], address: usize) -> bool {
    if let Some(entry) = entries
        .iter()
        .rev()
        .find(|e| (e.is_dynamic || e.is_free) && (e.var_addr == address || e.points_to == address))
    {
        return entry.is_free || !entry.is_dynamic;
    }

    !entries.iter().rev().any(|e| e.var_addr == address)
}

/// Checks whether there is a memory cleanup error (leaked allocation still referenced).
/// Replaces `has_a_memcleanup_error_in_cntr`.
pub fn has_memcleanup_error(entries: &[MemTrackEntry]) -> bool {
    let mut resolved = HashSet::new();
    entries.iter().rev().any(|entry| {
        if !entry.is_dynamic && !entry.is_free {
            return false;
        }
        if !resolved.insert(entry.points_to) {
            return false;
        }
        entry.is_dynamic && !entry.is_free
    })
}

/// Checks whether `address` is a valid allocation (within any live allocation's range).
/// Replaces `is_a_invalid_address_in_cntr`.
pub fn is_invalid_address(entries: &[MemTrackEntry], address: usize, size: usize) -> bool {
    let Some(address_end) = address.checked_add(size) else {
        return true;
    };
    !entries.iter().rev().any(|entry| {
        !entry.is_free
            && address >= entry.points_to
            && entry
                .points_to
                .checked_add(entry.size_destiny)
                .is_some_and(|allocation_end| address_end <= allocation_end)
    })
}

/// Search for the most recent entry with the given `address` as `var_addr`.
/// Returns `None` instead of the C version's UB (returning pointer to last element).
pub fn find_by_address(entries: &[MemTrackEntry], address: usize) -> Option<&MemTrackEntry> {
    entries.iter().rev().find(|e| e.var_addr == address)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn make_entry(
        var_addr: usize,
        points_to: usize,
        is_dynamic: bool,
        is_free: bool,
        size: usize,
    ) -> MemTrackEntry {
        MemTrackEntry::new(
            1, 10, 0, var_addr, points_to, is_dynamic, is_free, "ptr", "main", size, 4, false,
        )
    }

    #[test]
    fn invalid_free_detected_when_already_freed() {
        let entries = vec![make_entry(0x100, 0x200, true, true, 8)];
        assert!(is_invalid_free(&entries, 0x100));
    }

    #[test]
    fn valid_free_not_flagged() {
        let entries = vec![make_entry(0x100, 0x200, true, false, 8)];
        assert!(!is_invalid_free(&entries, 0x100));
    }

    #[test]
    fn deref_error_on_freed_address() {
        let entries = vec![make_entry(0x100, 0x200, true, true, 8)];
        assert!(is_deref_error(&entries, 0x100));
    }

    #[test]
    fn deref_ok_on_live_address() {
        let entries = vec![make_entry(0x100, 0x200, false, false, 8)];
        assert!(!is_deref_error(&entries, 0x100));
    }

    #[test]
    fn invalid_address_outside_allocation() {
        let entries = vec![make_entry(0x100, 0x200, true, false, 8)];
        assert!(is_invalid_address(&entries, 0x300, 4));
    }

    #[test]
    fn valid_address_inside_allocation() {
        let entries = vec![make_entry(0x100, 0x200, true, false, 16)];
        assert!(!is_invalid_address(&entries, 0x200, 4));
    }

    #[test]
    fn find_by_address_returns_none_when_not_found() {
        let entries: Vec<MemTrackEntry> = vec![];
        assert!(find_by_address(&entries, 0xDEAD).is_none());
    }

    #[test]
    fn set_malloc_marks_dynamic() {
        let mut e = make_entry(0x100, 0x200, false, false, 8);
        e.set_malloc();
        assert!(e.is_dynamic);
        assert!(!e.is_free);
    }

    #[test]
    fn set_free_marks_freed_and_clears_size() {
        let mut e = make_entry(0x100, 0x200, true, false, 8);
        e.set_free();
        assert!(e.is_free);
        assert!(!e.is_dynamic);
        assert_eq!(e.size_destiny, 0);
    }

    #[test]
    fn set_calloc_multiplies_size() {
        let mut e = make_entry(0x100, 0x200, false, false, 4);
        assert!(e.set_calloc(3));
        assert_eq!(e.size_destiny, 12);
        assert!(e.is_dynamic);
    }

    #[test]
    fn calloc_size_multiplication_is_checked() {
        let mut e = make_entry(0x100, 0x200, false, false, usize::MAX);
        assert!(!e.set_calloc(2));
        assert_eq!(e.size_destiny, usize::MAX);
        assert!(!e.is_dynamic);
    }

    #[test]
    fn unknown_free_is_invalid() {
        assert!(is_invalid_free(&[], 0xdead));
    }

    #[test]
    fn cleanup_detects_live_allocation_and_ignores_freed_allocation() {
        let live = vec![make_entry(0x100, 0x200, true, false, 8)];
        assert!(has_memcleanup_error(&live));

        let mut freed = make_entry(0x100, 0x200, true, false, 8);
        freed.set_free();
        assert!(!has_memcleanup_error(&[live[0].clone(), freed]));
    }

    #[test]
    fn deref_resolves_allocation_through_stored_pointer() {
        let entries = vec![
            make_entry(0x100, 0x200, true, false, 8),
            make_entry(0x300, 0x200, false, false, 0),
        ];
        assert!(!is_deref_error(&entries, 0x200));
    }

    #[test]
    fn invalid_address_rejects_wrapping_ranges() {
        let entries = vec![make_entry(0x100, usize::MAX - 3, true, false, 16)];
        assert!(is_invalid_address(&entries, usize::MAX - 1, 8));
        assert!(is_invalid_address(&entries, usize::MAX - 1, 4));
    }
}
