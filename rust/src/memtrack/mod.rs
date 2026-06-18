// SPDX-License-Identifier: GPL-3.0-only
#![deny(unsafe_code)]

use serde::Serialize;

/// Single memory tracking record — analogous to `memtrack_log_t` in C.
/// Addresses are `usize` (platform pointer width) instead of `long`.
#[derive(Debug, Clone, Serialize)]
pub struct MemTrackEntry {
    pub step: u64,
    pub line: u32,
    pub scope: u32,
    /// Address of the variable holding the pointer (cast from `*const T`).
    pub var_addr: usize,
    /// Address the variable points to.
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

    pub fn set_calloc(&mut self, quantity: usize) {
        self.size_destiny *= quantity;
        self.set_malloc();
    }

    pub fn set_free(&mut self) {
        self.is_free = true;
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
        .find(|e| e.var_addr == address)
        .map(|e| e.is_free)
        .unwrap_or(false)
}

/// Checks whether dereferencing `address` is invalid (not allocated or already freed).
/// Replaces `is_addr_a_deref_error_in_cntr`.
pub fn is_deref_error(entries: &[MemTrackEntry], address: usize) -> bool {
    match entries.iter().rev().find(|e| e.var_addr == address) {
        None => true,
        Some(e) => e.is_free,
    }
}

/// Checks whether there is a memory cleanup error (leaked allocation still referenced).
/// Replaces `has_a_memcleanup_error_in_cntr`.
pub fn has_memcleanup_error(entries: &[MemTrackEntry]) -> bool {
    entries.iter().rev().any(|e| e.is_dynamic && !e.is_free && {
        // Check if any later entry still holds a pointer to this allocation
        let leaked_addr = e.points_to;
        entries
            .iter()
            .rev()
            .take_while(|later| !std::ptr::eq(*later, e))
            .any(|later| later.points_to == leaked_addr)
    })
}

/// Checks whether `address` is a valid allocation (within any live allocation's range).
/// Replaces `is_a_invalid_address_in_cntr`.
pub fn is_invalid_address(entries: &[MemTrackEntry], address: usize, size: usize) -> bool {
    !entries.iter().rev().any(|e| {
        !e.is_free
            && address >= e.points_to
            && address + size <= e.points_to + e.size_destiny
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

    fn make_entry(var_addr: usize, points_to: usize, is_dynamic: bool, is_free: bool, size: usize) -> MemTrackEntry {
        MemTrackEntry::new(1, 10, 0, var_addr, points_to, is_dynamic, is_free, "ptr", "main", size, 4, false)
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
        assert_eq!(e.size_destiny, 0);
    }

    #[test]
    fn set_calloc_multiplies_size() {
        let mut e = make_entry(0x100, 0x200, false, false, 4);
        e.set_calloc(3);
        assert_eq!(e.size_destiny, 12);
        assert!(e.is_dynamic);
    }
}
