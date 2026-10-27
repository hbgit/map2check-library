// SPDX-License-Identifier: GPL-3.0-only
#![deny(unsafe_code)]

pub mod c_mode;

use std::collections::{hash_map::DefaultHasher, HashSet};
use std::hash::BuildHasherDefault;

/// A `HashSet` with fixed SipHash keys instead of `RandomState`.
///
/// `RandomState::new()` seeds itself from the OS (`getrandom`, reached
/// through a weak symbol), which under KLEE is an invalid function pointer
/// and kills the path (D1 route A'). These sets only answer membership
/// questions, so the hash seed changes nothing in their results.
pub(crate) type FixedHashSet<T> = HashSet<T, BuildHasherDefault<DefaultHasher>>;

/// One row of develop's allocation log as the wasm2c runtime uses it
/// (`MEMORY_ALLOCATIONS_ROW`, `Map2CheckTypes.h:113-121`): the linear-memory
/// offset the lifted `malloc` returned, the block size and whether it was
/// freed. Offsets are wasm linear-memory offsets, not host addresses.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct WasmAlloc {
    pub offset: u64,
    /// `unsigned` in develop: the size is truncated to 32 bits.
    pub size: u32,
    pub is_free: bool,
}

/// `map2check_wasm_malloc` (`AnalysisModeMemtrack.c:385-397`): offset 0 and
/// `(uint64_t)-1` are no block; a known offset (newest row first,
/// `find_row_with_address`, `AllocationLog.c:103-118`) is resized and revived
/// in place; any other offset gets a new row.
pub fn wasm_register_malloc(table: &mut Vec<WasmAlloc>, offset: u64, size: u64) {
    if offset == 0 || offset == u64::MAX {
        return;
    }
    let size = size as u32;
    match table.iter_mut().rev().find(|row| row.offset == offset) {
        Some(row) => {
            row.size = size;
            row.is_free = false;
        }
        None => table.push(WasmAlloc {
            offset,
            size,
            is_free: false,
        }),
    }
}

/// `map2check_wasm_free` (`AnalysisModeMemtrack.c:399-407`): marks the block
/// at `offset` free with size 0 and returns true; false when no row has that
/// offset. A row that is already free is found again, so a double free is not
/// an error, as in develop.
pub fn wasm_register_free(table: &mut [WasmAlloc], offset: u64) -> bool {
    match table.iter_mut().rev().find(|row| row.offset == offset) {
        Some(row) => {
            row.is_free = true;
            row.size = 0;
            true
        }
        None => false,
    }
}

/// `is_valid_allocation_address` (`AllocationLog.c:127-148`) for
/// `map2check_wasm_check_access`: the newest row whose range
/// `[offset, offset + size - access + 1)` holds `offset` decides, and it is
/// valid only if the block is live. The arithmetic is develop's: the access
/// size is cut to `int` (`(int)access_size`) and sign-extended, and the sum
/// wraps at 64 bits.
pub fn wasm_is_valid_access(table: &[WasmAlloc], address: u64, access_size: u64) -> bool {
    let access = i64::from(access_size as i32) as u64;
    for row in table.iter().rev() {
        let top = row
            .offset
            .wrapping_add(u64::from(row.size))
            .wrapping_sub(access)
            .wrapping_add(1);
        if row.offset <= address && address < top {
            return !row.is_free;
        }
    }
    false
}

/// Single memory tracking record — analogous to `memtrack_log_t` in C.
/// Addresses are `usize` (platform pointer width) instead of `long`.
#[derive(Debug, Clone)]
#[cfg_attr(not(feature = "dropin"), derive(serde::Serialize))]
pub struct MemTrackEntry {
    pub step: u64,
    pub line: u32,
    pub scope: u32,
    /// Address of the variable holding the pointer (cast from `*const T`).
    #[cfg_attr(not(feature = "dropin"), serde(rename = "var_mem_address"))]
    pub var_addr: usize,
    /// Address the variable points to.
    #[cfg_attr(not(feature = "dropin"), serde(rename = "mem_address_points_to"))]
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
    /// The export that recorded the entry. Only the legacy log files read it
    /// (`output::legacy_files`); the JSON report does not carry it.
    #[cfg_attr(not(feature = "dropin"), serde(skip))]
    pub origin: MemOrigin,
}

/// Which export recorded a [`MemTrackEntry`]. The legacy log files of the
/// Map2Check `develop` runtime keep one log per kind of call (heap log,
/// allocation log, list log), so the replay that rebuilds them needs it.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum MemOrigin {
    /// Built without an export (unit tests); the replay infers the kind
    /// from the flags and the size.
    #[default]
    Unspecified,
    /// `map2check_map_alloca` and `map2check_map_non_static_alloca`.
    Alloca,
    /// `map2check_map_funct_address`.
    Function,
    /// `map2check_map_malloc` and `map2check_map_calloc`.
    Malloc,
    /// `map2check_map_store_pointer`.
    StorePointer,
    /// `map2check_map_free`, with the address of the pointer variable that
    /// was freed (develop's `map2check_free` argument). The entry itself is
    /// keyed on the block, so the memory checks never see the variable;
    /// only the legacy list log names it.
    Free { var_address: usize },
    /// The release recorded by `map2check_check_free_resolved_address`.
    FreeResolved,
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
            origin: MemOrigin::Unspecified,
        }
    }

    /// Sets the export that recorded the entry.
    pub fn with_origin(mut self, origin: MemOrigin) -> Self {
        self.origin = origin;
        self
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

/// Checks whether freeing the already-resolved heap `address` is invalid.
/// Unlike [`is_invalid_free`], which matches on the pointer *variable's* own
/// slot (`var_addr`), this matches on the target heap address (`points_to`) —
/// the value obtained after following one level of indirection. Used by
/// `map2check_check_free_resolved_address`, which receives the resolved
/// pointer value directly instead of the address of the pointer variable.
///
/// Follows `is_invalid_free` of the Map2Check `develop` C runtime
/// (`ListLog.c:95-118`): the most recent heap record (allocation or free) for
/// `address` decides, a freed block is invalid, and an address with no heap
/// record — untracked, or only a stack slot — is an invalid free (#37).
pub fn is_invalid_free_resolved(entries: &[MemTrackEntry], address: usize) -> bool {
    entries
        .iter()
        .rev()
        .find(|e| (e.is_dynamic || e.is_free) && e.points_to == address)
        // `map_or(true, ..)`, not `is_none_or`: the KLEE runtime builds this
        // file with rustc 1.72 (D1 condition 5).
        .map_or(true, |e| e.is_free)
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
    let mut resolved = FixedHashSet::default();
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

// ── develop's memcleanup verdict ─────────────────────────────────────────────
//
// Memcleanup mode of the Map2Check `develop` C runtime decides the
// end-of-program verdict on two logs that this crate does not keep: the
// allocation log (one row per heap address, updated in place) and the list
// log (pointer-variable rows). `DevelopLogs::replay` rebuilds both from the
// memtrack entries, in order, with the same rules as
// `AnalysisModeMemcleanup.c`, so the verdict can be computed exactly.

/// `enum MemoryAddressStatus` (`Map2CheckTypes.h:34`).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum AddressStatus {
    Static,
    Free,
    Dynamic,
}

/// A list-log row: `memory_address`, `memory_address_points_to` and the
/// status that `get_type_from_list_log_row` reads (`ListLog.c:159-168`).
#[derive(Debug, Clone, Copy)]
struct ListRow {
    var: usize,
    points_to: usize,
    status: AddressStatus,
}

#[derive(Debug, Default)]
struct DevelopLogs {
    /// `(addr, is_free)`, one row per address in first-allocation order.
    allocation: Vec<(usize, bool)>,
    list: Vec<ListRow>,
}

impl DevelopLogs {
    fn replay(entries: &[MemTrackEntry]) -> Self {
        let mut logs = Self::default();
        for e in entries {
            if e.is_dynamic && !e.is_free {
                logs.malloc(e.points_to);
            } else if e.is_free {
                if let MemOrigin::Free { var_address } = e.origin {
                    logs.free_row(var_address, e.points_to);
                }
                logs.free(e.points_to);
            } else if e.size_destiny == 0 {
                logs.store_pointer(e.var_addr, e.points_to);
            }
            // Stack slots and function addresses go to develop's heap log,
            // which the verdict does not read.
        }
        logs
    }

    /// `map2check_malloc` (`AnalysisModeMemcleanup.c:295-313`): updates the
    /// row of the address in place or appends one. A NULL result ends the
    /// develop run with UNKNOWN (`:297-300`), so it adds no row here.
    fn malloc(&mut self, addr: usize) {
        if addr == 0 {
            return;
        }
        match self.allocation.iter_mut().rev().find(|(a, _)| *a == addr) {
            Some(row) => row.1 = false,
            None => self.allocation.push((addr, false)),
        }
    }

    /// The FREE row `map2check_free` appends for the pointer variable before
    /// it releases the block (`:336-343`). A NULL block returns before it.
    fn free_row(&mut self, var: usize, addr: usize) {
        if addr != 0 {
            self.list.push(ListRow {
                var,
                points_to: addr,
                status: AddressStatus::Free,
            });
        }
    }

    /// The free paths, `map2check_free` (`:329-356`, after [`Self::free_row`])
    /// and `map2check_free_resolved_address` (`:160-179`): mark the row free
    /// and run `update_reference_list_log(addr, FREE)`.
    fn free(&mut self, addr: usize) {
        if addr == 0 {
            return;
        }
        if let Some(row) = self.allocation.iter_mut().rev().find(|(a, _)| *a == addr) {
            row.1 = true;
        }
        self.update_reference(addr, AddressStatus::Free);
    }

    /// `check_address_allocation_log` (`AllocationLog.c:34-51`).
    fn status_of(&self, addr: usize) -> AddressStatus {
        match self.allocation.iter().rev().find(|(a, _)| *a == addr) {
            Some((_, true)) => AddressStatus::Free,
            Some((_, false)) => AddressStatus::Dynamic,
            None => AddressStatus::Static,
        }
    }

    /// `map2check_add_store_pointer` (`AnalysisModeMemcleanup.c:242-291`).
    fn store_pointer(&mut self, var: usize, value: usize) {
        let status = self.status_of(value);
        let redundant = self
            .list
            .iter()
            .rev()
            .find(|r| r.var == var)
            .is_some_and(|r| r.points_to == value && r.status == status);
        if !redundant {
            self.list.push(ListRow {
                var,
                points_to: value,
                status,
            });
            self.update_reference(value, status);
        }
    }

    /// `update_reference_list_log` (`AnalysisModeMemcleanup.c:181-240`): for
    /// each row that points to `address` with another status, the newest row
    /// of the same variable that points to `address` gets a copy with the new
    /// status appended. Rows appended here are not revisited.
    fn update_reference(&mut self, address: usize, status: AddressStatus) {
        let current_size = self.list.len();
        for i in 0..current_size {
            let i_row = self.list[i];
            if i_row.points_to != address || i_row.status == status {
                continue;
            }
            if let Some(j_row) = self.list[i..current_size]
                .iter()
                .rev()
                .find(|r| r.points_to == address && r.var == i_row.var)
                .copied()
            {
                if j_row.status != status {
                    self.list.push(ListRow { status, ..j_row });
                }
            }
        }
    }

    /// `valid_allocation_log` (`AllocationLog.c:69-101`): the LAST address,
    /// in allocation-log order, that is not free. Rows are unique per
    /// address, so "no later freed row" reduces to the row's own flag.
    fn last_leaked_address(&self) -> Option<usize> {
        self.allocation
            .iter()
            .filter(|(_, is_free)| !is_free)
            .map(|(addr, _)| *addr)
            .next_back()
    }

    /// `is_memcleanup_error` (`ListLog.c:40-65`).
    fn is_memcleanup_error(&self, address: usize) -> bool {
        let list = &self.list;
        (0..list.len()).rev().any(|i| {
            if list[i].points_to != address {
                return false;
            }
            let pointer = list[i].var;
            list[i + 1..]
                .iter()
                .rev()
                .find(|r| r.var == pointer)
                .map_or(true, |r| r.points_to == address)
        })
    }
}

/// The address `valid_allocation_log` of the Map2Check `develop` C runtime
/// returns for these entries: the last leaked heap address, or `None`.
pub fn last_leaked_address(entries: &[MemTrackEntry]) -> Option<usize> {
    DevelopLogs::replay(entries).last_leaked_address()
}

/// `is_memcleanup_error(address, &list_log)` of the Map2Check `develop` C
/// runtime over these entries: some pointer variable's latest stored value
/// still points to `address`.
pub fn is_memcleanup_error(entries: &[MemTrackEntry], address: usize) -> bool {
    DevelopLogs::replay(entries).is_memcleanup_error(address)
}

/// The memcleanup-mode verdict of the Map2Check `develop` C runtime
/// (`AnalysisModeMemcleanup.c:138-148`): the last leaked address is still
/// referenced by a pointer variable.
pub fn has_develop_memcleanup_error(entries: &[MemTrackEntry]) -> bool {
    let logs = DevelopLogs::replay(entries);
    logs.last_leaked_address()
        .is_some_and(|addr| logs.is_memcleanup_error(addr))
}

/// Checks whether the `size` bytes at `address` lie outside every valid block.
/// Replaces `is_a_invalid_address_in_cntr`.
///
/// Follows `map2check_load` of the Map2Check `develop` C runtime
/// (`AnalysisModeMemtrack.c:156-162`), which accepts the access when a stack
/// slot covers it (`is_valid_heap_address`, `HeapLog.c:37-52`) or a live heap
/// block does (`is_valid_allocation_address`, `AllocationLog.c:127-148`):
///
/// - a stack slot (`map2check_map_alloca`, `_non_static_alloca`,
///   `_funct_address`: neither dynamic nor freed, non-zero size) stays valid;
/// - for heap blocks, only the latest alloc/free event per block address
///   counts (#11): `develop` keeps one row per address and updates it in place
///   on malloc and free (`AnalysisModeMemtrack.c:313-317`, `:360-363`), so a
///   free invalidates the block and a later malloc at the same address makes
///   it valid again, with the new size;
/// - pointer stores (`map2check_map_store_pointer`, size 0) are not events.
pub fn is_invalid_address(entries: &[MemTrackEntry], address: usize, size: usize) -> bool {
    let Some(address_end) = address.checked_add(size) else {
        return true;
    };
    let covers = |entry: &MemTrackEntry| {
        address >= entry.points_to
            && entry
                .points_to
                .checked_add(entry.size_destiny)
                .is_some_and(|allocation_end| address_end <= allocation_end)
    };
    let is_heap_event = |entry: &MemTrackEntry| entry.is_dynamic || entry.is_free;
    // No hash set and no allocation: this runs on every load, and under KLEE
    // a set built per call cost about 95% of the runtime's instructions
    // (Task 2.7b). An older event of a block is skipped when that block's
    // latest event was already looked up; remembering the last such block
    // is enough for the common case (one block freed and reallocated in a
    // loop) and only saves work, so it cannot change the result.
    let mut last_looked_up: Option<usize> = None;
    for (i, entry) in entries.iter().enumerate().rev() {
        if is_heap_event(entry) {
            // A freed block (size 0) never validates the access.
            if entry.is_free || !covers(entry) || last_looked_up == Some(entry.points_to) {
                continue;
            }
            last_looked_up = Some(entry.points_to);
            let is_latest = !entries[i + 1..]
                .iter()
                .any(|newer| is_heap_event(newer) && newer.points_to == entry.points_to);
            if is_latest {
                return false;
            }
        } else if entry.size_destiny > 0 && covers(entry) {
            return false;
        }
    }
    true
}

/// Search for the most recent entry with the given `address` as `var_addr`.
/// Returns `None` instead of the C version's UB (returning pointer to last element).
pub fn find_by_address(entries: &[MemTrackEntry], address: usize) -> Option<&MemTrackEntry> {
    entries.iter().rev().find(|e| e.var_addr == address)
}

#[cfg(test)]
mod tests {
    use super::*;

    // ── develop's memcleanup rule (AllocationLog.c:69-101, ListLog.c:40-65) ──

    fn alloc(a: usize) -> MemTrackEntry {
        make_entry(a, a, true, false, 8)
    }

    fn free(a: usize) -> MemTrackEntry {
        let mut e = make_entry(a, a, false, false, 0);
        e.set_free();
        e
    }

    fn store(var: usize, value: usize) -> MemTrackEntry {
        MemTrackEntry::new(1, 1, 0, var, value, false, false, "p", "main", 0, 1, false)
    }

    #[test]
    fn map_free_row_names_its_variable_in_the_memcleanup_verdict() {
        // develop's map2check_free appends a FREE row for the variable it
        // received (AnalysisModeMemcleanup.c:336-343), even when no store
        // of that variable was tracked; the row still points to the block,
        // so a block reallocated at the same address counts as referenced.
        let freed_through_p = free(0x3000).with_origin(MemOrigin::Free { var_address: 0x10 });
        let entries = vec![alloc(0x3000), freed_through_p, alloc(0x3000)];
        assert!(has_develop_memcleanup_error(&entries));
        // A release without a variable (free_resolved) appends no row.
        let entries = vec![alloc(0x3000), free(0x3000), alloc(0x3000)];
        assert!(!has_develop_memcleanup_error(&entries));
    }

    #[test]
    fn last_leaked_address_is_the_last_live_block_in_allocation_order() {
        assert_eq!(last_leaked_address(&[]), None);
        assert_eq!(last_leaked_address(&[alloc(0xA0), free(0xA0)]), None);
        assert_eq!(last_leaked_address(&[alloc(0xA0), alloc(0xB0)]), Some(0xB0));
        assert_eq!(
            last_leaked_address(&[alloc(0xA0), alloc(0xB0), free(0xB0)]),
            Some(0xA0)
        );
        // develop updates the row of a reused address in place, so the order
        // is that of the first allocation of each address.
        assert_eq!(
            last_leaked_address(&[alloc(0xA0), alloc(0xB0), free(0xA0), alloc(0xA0)]),
            Some(0xB0)
        );
        // Pointer stores and stack slots are not allocations.
        assert_eq!(last_leaked_address(&[store(0x10, 0xA0)]), None);
    }

    #[test]
    fn memcleanup_error_needs_a_pointer_whose_latest_value_is_the_block() {
        let e = [alloc(0xA0), store(0x10, 0xA0)];
        assert!(is_memcleanup_error(&e, 0xA0));
        let e = [alloc(0xA0), store(0x10, 0xA0), store(0x10, 0xB0)];
        assert!(!is_memcleanup_error(&e, 0xA0));
        let e = [alloc(0xA0)];
        assert!(!is_memcleanup_error(&e, 0xA0));
        let e = [
            alloc(0xA0),
            store(0x10, 0xA0),
            store(0x20, 0xA0),
            store(0x10, 0),
        ];
        assert!(is_memcleanup_error(&e, 0xA0));
    }

    #[test]
    fn memcleanup_redundant_store_is_not_logged_again() {
        // add_store_pointer skips a store equal to the variable's latest row
        // (AnalysisModeMemcleanup.c:272-283); the verdict is unchanged.
        let e = [alloc(0xA0), store(0x10, 0xA0), store(0x10, 0xA0)];
        assert!(is_memcleanup_error(&e, 0xA0));
    }

    #[test]
    fn memcleanup_free_re_points_variables_as_update_reference_list_log() {
        // AnalysisModeMemcleanup.c:181-240: freeing A appends a FREE copy of
        // the latest `p = A` row, which makes `p` point to A again.
        let e = [
            alloc(0xA0),
            alloc(0xB0),
            store(0x10, 0xA0),
            store(0x10, 0xB0),
            free(0xA0),
        ];
        assert!(!is_memcleanup_error(&e, 0xB0));
        assert!(is_memcleanup_error(&e[..4], 0xB0));
    }

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
    fn invalid_free_resolved_detected_when_already_freed() {
        let entries = vec![make_entry(0x100, 0x200, true, true, 8)];
        assert!(is_invalid_free_resolved(&entries, 0x200));
    }

    #[test]
    fn valid_free_resolved_not_flagged() {
        let entries = vec![make_entry(0x100, 0x200, true, false, 8)];
        assert!(!is_invalid_free_resolved(&entries, 0x200));
    }

    #[test]
    fn free_resolved_unknown_address_is_invalid() {
        let entries = vec![make_entry(0x100, 0x200, true, false, 8)];
        assert!(is_invalid_free_resolved(&entries, 0xDEAD));
    }

    #[test]
    fn free_resolved_stack_slot_is_invalid() {
        let entries = vec![make_entry(0x300, 0x300, false, false, 8)];
        assert!(is_invalid_free_resolved(&entries, 0x300));
    }

    #[test]
    fn free_resolved_ignores_pointer_stores_to_the_block() {
        // A later `store_pointer` record (`p = block`) is not an allocation
        // event and must not hide the live allocation.
        let entries = vec![
            make_entry(0x200, 0x200, true, false, 8),
            make_entry(0x500, 0x200, false, false, 0),
        ];
        assert!(!is_invalid_free_resolved(&entries, 0x200));
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
    fn invalid_address_uses_latest_event_per_block() {
        let malloc = make_entry(0x200, 0x200, true, false, 16);
        let mut free = make_entry(0x200, 0x200, true, false, 16);
        free.set_free();
        assert!(is_invalid_address(
            &[malloc.clone(), free.clone()],
            0x204,
            4
        ));
        let realloc = make_entry(0x200, 0x200, true, false, 8);
        let live = [malloc, free, realloc];
        assert!(!is_invalid_address(&live, 0x204, 4));
        assert!(is_invalid_address(&live, 0x208, 4));
    }

    /// The set-based `is_invalid_address` before Task 2.7b, kept as the
    /// reference the rewrite must agree with.
    fn is_invalid_address_reference(
        entries: &[MemTrackEntry],
        address: usize,
        size: usize,
    ) -> bool {
        let Some(address_end) = address.checked_add(size) else {
            return true;
        };
        let covers = |entry: &MemTrackEntry| {
            address >= entry.points_to
                && entry
                    .points_to
                    .checked_add(entry.size_destiny)
                    .is_some_and(|allocation_end| address_end <= allocation_end)
        };
        let mut decided = FixedHashSet::default();
        !entries.iter().rev().any(|entry| {
            if entry.is_dynamic || entry.is_free {
                decided.insert(entry.points_to) && !entry.is_free && covers(entry)
            } else {
                entry.size_destiny > 0 && covers(entry)
            }
        })
    }

    #[test]
    fn invalid_address_matches_the_set_based_reference() {
        // Random histories over a few block addresses, so blocks are freed,
        // reallocated with other sizes and overlap: every kind of entry the
        // exports push (malloc, free, stack slot, pointer store).
        let mut seed: u64 = 0x2545_F491_4F6C_DD1D;
        let mut next = |bound: u64| {
            seed ^= seed << 13;
            seed ^= seed >> 7;
            seed ^= seed << 17;
            (seed % bound) as usize
        };
        for _ in 0..3000 {
            let mut entries = Vec::new();
            for _ in 0..next(24) {
                let addr = 0x100 + 8 * next(6);
                let size = 4 * next(5);
                let entry = match next(4) {
                    0 => make_entry(addr, addr, true, false, size),
                    1 => {
                        let mut e = make_entry(addr, addr, true, false, size);
                        e.set_free();
                        e
                    }
                    2 => make_entry(addr, addr, false, false, size),
                    _ => make_entry(0x900 + addr, addr, false, false, 0),
                };
                entries.push(entry);
            }
            for _ in 0..8 {
                let address = 0xF8 + next(64);
                let size = next(10);
                assert_eq!(
                    is_invalid_address(&entries, address, size),
                    is_invalid_address_reference(&entries, address, size),
                    "address {address:#x} size {size} entries {entries:?}"
                );
            }
        }
    }

    #[test]
    fn invalid_address_keeps_stack_slots_valid() {
        let entries = vec![make_entry(0x300, 0x300, false, false, 8)];
        assert!(!is_invalid_address(&entries, 0x304, 4));
        assert!(is_invalid_address(&entries, 0x306, 4));
    }

    #[test]
    fn invalid_address_rejects_wrapping_ranges() {
        let entries = vec![make_entry(0x100, usize::MAX - 3, true, false, 16)];
        assert!(is_invalid_address(&entries, usize::MAX - 1, 8));
        assert!(is_invalid_address(&entries, usize::MAX - 1, 4));
    }

    #[test]
    fn same_slot_compares_address_scope_flags_and_line() {
        let a = make_entry(0x100, 0x200, true, false, 8);
        let mut b = make_entry(0x100, 0x300, true, false, 16);
        assert!(a.same_slot(&b)); // points_to and size do not matter
        b.line = 11;
        assert!(!a.same_slot(&b));
        let c = make_entry(0x100, 0x200, true, true, 8);
        assert!(!a.same_slot(&c));
        let d = make_entry(0x104, 0x200, true, false, 8);
        assert!(!a.same_slot(&d));
    }

    #[test]
    fn cleanup_ignores_stack_entries() {
        let entries = vec![make_entry(0x100, 0x100, false, false, 4)];
        assert!(!has_memcleanup_error(&entries));
    }
}
