// SPDX-License-Identifier: GPL-3.0-only
//
// The memory logs of Map2Check's C runtime, as the memory modes keep them
// (`AnalysisModeMemtrack.c`, `AnalysisModeMemcleanup.c`): the heap log
// (`HeapLog.c`), the allocation log (`AllocationLog.c`), the list log
// (`ListLog.c`) and the `ERROR_DEREF` flag. The `__m2c_rt_memtrack_*` core
// entry points (Task 2.5) run on these; the legacy `map2check_map_*` exports
// keep their own records (`AnalysisState::memtrack`).
//
// One container serves both container builds of develop (D3): the Array
// build links `ContainerRealloc.bc` and `--btree` links `ContainerBTree.bc`
// and `BTree.bc`; in the drop-in runtime all three are empty IR modules and
// both link this core, so the rows below are the only store.
//
// The rules are parameterised by [`MemMode`]: `AnalysisModeMemcleanup.c`
// shares the tracking of `AnalysisModeMemtrack.c` and differs only in the
// checks (no deref check, `error = FALSE` on free) and the end-of-program
// verdict, so Task 2.6 adds thin wrappers and no logic.
#![deny(unsafe_code)]

use std::fmt::Write as _;

use crate::caller::ViolatedProperty;
use crate::nondet::c_log::FUNCTION_MAX_LENGTH_NAME;
use crate::output::legacy_files::c_pointer;

/// Which memory module is linked: the checks and the verdict depend on it,
/// the tracking does not.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MemMode {
    /// `AnalysisModeMemtrack.c`.
    Memtrack,
    /// `AnalysisModeMemcleanup.c`.
    Memcleanup,
}

/// `enum MemoryAddressStatus` (`Map2CheckTypes.h:34-39`).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum AddressStatus {
    Static,
    Free,
    Dynamic,
}

impl AddressStatus {
    /// `(isDynamic, isFree)` of the `switch (status)` in
    /// `AnalysisModeMemtrack.c:229-242` and `:268-284`.
    fn flags(self) -> (bool, bool) {
        match self {
            AddressStatus::Static => (false, false),
            AddressStatus::Free => (false, true),
            AddressStatus::Dynamic => (true, false),
        }
    }
}

/// `char function_name[FUNCTION_MAX_LENGTH_NAME]` filled by `strncpy`
/// (`ListLog.c:133`, `HeapLog.c:25`): the name cut at 35 bytes. A name of 35
/// bytes or more has no terminator in C, and `%s` then reads past the array;
/// the cut name is what this library prints (as `c_log` does).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct CName {
    bytes: [u8; FUNCTION_MAX_LENGTH_NAME],
    len: u8,
}

impl CName {
    pub fn new(name: &[u8]) -> Self {
        let mut bytes = [0u8; FUNCTION_MAX_LENGTH_NAME];
        let mut len = 0u8;
        for (slot, &b) in bytes.iter_mut().zip(name) {
            if b == 0 {
                break;
            }
            *slot = b;
            len += 1;
        }
        Self { bytes, len }
    }

    pub fn as_bytes(&self) -> &[u8] {
        &self.bytes[..usize::from(self.len)]
    }
}

/// `LIST_LOG_ROW` (`Map2CheckTypes.h:97-118`). `id` is always 0
/// (`new_list_row`, `ListLog.c:125`). `var_name` is a pointer in C, so the
/// whole name is kept.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ListRow {
    pub memory_address: u64,
    pub memory_address_points_to: u64,
    pub scope: u32,
    pub is_dynamic: bool,
    pub is_free: bool,
    pub line_number: u32,
    pub var_name: Vec<u8>,
    pub function_name: CName,
    pub step_on_execution: u32,
}

impl ListRow {
    /// `get_type_from_list_log_row` (`ListLog.c:159-168`).
    fn status(&self) -> AddressStatus {
        if self.is_free && !self.is_dynamic {
            AddressStatus::Free
        } else if self.is_dynamic {
            AddressStatus::Dynamic
        } else {
            AddressStatus::Static
        }
    }
}

/// `MEMORY_ALLOCATIONS_ROW` (`Map2CheckTypes.h:124-133`): `new_memory_row`
/// zeroes it (`AllocationLog.c:53-61`).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct AllocationRow {
    pub addr: u64,
    pub is_free: bool,
    pub size: u32,
}

/// `MEMORY_HEAP_ROW` (`Map2CheckTypes.h:191-203`). `new_heap_row` copies the
/// variable name into `function_name` (`HeapLog.c:22-32`).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct HeapRow {
    pub line: i32,
    pub scope: i32,
    pub value: u64,
    pub size: i32,
    pub size_of_primitive: i32,
    pub function_name: CName,
}

/// What a free found, for the caller to report (the report writes files
/// and may end the process, so it runs after the state lock is released).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum FreeOutcome {
    /// The release was recorded, or there was nothing to release.
    Released,
    /// `is_invalid_free` (`ListLog.c:95-118`): FALSE_FREE. The rows the C
    /// appends before it reports are already appended.
    InvalidFree,
}

/// `heap_log`, `allocation_log`, `list_log` and `ERROR_DEREF` of
/// `AnalysisModeMemtrack.c:120-123`.
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct CMemory {
    heap: Vec<HeapRow>,
    allocation: Vec<AllocationRow>,
    list: Vec<ListRow>,
    error_deref: bool,
}

impl CMemory {
    /// `analysis_init` (`AnalysisModeMemtrack.c:125-130`): new containers and
    /// `ERROR_DEREF = FALSE`. `analysis_destroy` (`:132-136`) frees the
    /// containers; both leave this state.
    pub fn clear(&mut self) {
        *self = Self::default();
    }

    /// Whether any row was logged (the drop-in memory entry points ran).
    pub fn has_rows(&self) -> bool {
        !(self.heap.is_empty() && self.allocation.is_empty() && self.list.is_empty())
    }

    pub fn error_deref(&self) -> bool {
        self.error_deref
    }

    // ── AllocationLog.c, HeapLog.c, ListLog.c ───────────────────────────────

    /// `check_address_allocation_log` (`AllocationLog.c:33-51`).
    fn check_address_allocation_log(&self, address: u64) -> AddressStatus {
        match self.allocation.iter().rev().find(|r| r.addr == address) {
            Some(r) if r.is_free => AddressStatus::Free,
            Some(_) => AddressStatus::Dynamic,
            None => AddressStatus::Static,
        }
    }

    /// `find_row_with_address` (`AllocationLog.c:103-118`): the newest row.
    fn find_row_with_address(&mut self, address: u64) -> Option<&mut AllocationRow> {
        self.allocation.iter_mut().rev().find(|r| r.addr == address)
    }

    /// `is_valid_allocation_address` (`AllocationLog.c:127-148`): the newest
    /// row whose `[addr, addr + size - size_to_destiny + 1)` holds `address`
    /// decides, valid only if not free. `unsigned long` arithmetic: the
    /// `int` size is sign-extended and the sum wraps.
    fn is_valid_allocation_address(&self, address: u64, size_to_destiny: i32) -> bool {
        let access = i64::from(size_to_destiny) as u64;
        for row in self.allocation.iter().rev() {
            let bottom = row.addr;
            let top = bottom
                .wrapping_add(u64::from(row.size))
                .wrapping_sub(access)
                .wrapping_add(1);
            if bottom <= address && address < top {
                return !row.is_free;
            }
        }
        false
    }

    /// `is_valid_heap_address` (`HeapLog.c:37-52`): any row whose range
    /// holds `address`, free or not; `long` arithmetic.
    fn is_valid_heap_address(&self, address: u64, size_to_load: i32) -> bool {
        let address = address as i64;
        self.heap.iter().rev().any(|row| {
            let bottom = row.value as i64;
            let top = bottom
                .wrapping_add(i64::from(row.size))
                .wrapping_sub(i64::from(size_to_load))
                .wrapping_add(1);
            bottom <= address && address < top
        })
    }

    /// `is_invalid_free` (`ListLog.c:95-118`): NULL is valid; the newest list
    /// row pointing to `address` decides (invalid if freed or not dynamic);
    /// no row is invalid.
    fn is_invalid_free(&self, address: u64) -> bool {
        if address == 0 {
            return false;
        }
        self.list
            .iter()
            .rev()
            .find(|r| r.memory_address_points_to == address)
            .map_or(true, |r| r.is_free || !r.is_dynamic)
    }

    /// `is_memcleanup_error` (`ListLog.c:40-65`): some pointer whose newest
    /// row still points to `address`.
    fn is_memcleanup_error(&self, address: u64) -> bool {
        let list = &self.list;
        (0..list.len()).rev().any(|i| {
            if list[i].memory_address_points_to != address {
                return false;
            }
            let pointer = list[i].memory_address;
            list[i + 1..]
                .iter()
                .rev()
                .find(|r| r.memory_address == pointer)
                .map_or(true, |r| r.memory_address_points_to == address)
        })
    }

    /// `valid_allocation_log` (`AllocationLog.c:69-101`): every live row with
    /// no later freed row of its address gets a freed row (size 0)
    /// appended; returns the last such address, 0 when none. The rows it
    /// appends are visited too (the loop reads the growing size) and are
    /// free. develop also calls `free()` on the leaked block (`:91`); the
    /// process ends right after, so the core does not.
    pub fn valid_allocation_log(&mut self) -> u64 {
        let mut error = 0;
        let mut i = 0;
        while i < self.allocation.len() {
            let row = self.allocation[i];
            if !row.is_free {
                let released = self.allocation[i + 1..]
                    .iter()
                    .any(|r| r.addr == row.addr && r.is_free);
                if !released {
                    self.allocation.push(AllocationRow {
                        addr: row.addr,
                        is_free: true,
                        size: 0,
                    });
                    error = row.addr;
                }
            }
            i += 1;
        }
        error
    }

    /// `new_list_row` with the current step, then
    /// `map2check_next_current_step` and `append_element`.
    #[allow(clippy::too_many_arguments)]
    fn append_list_row(
        &mut self,
        step: &mut u32,
        var: u64,
        points_to: u64,
        scope: u32,
        is_dynamic: bool,
        is_free: bool,
        line: u32,
        name: &[u8],
        function_name: CName,
    ) {
        self.list.push(ListRow {
            memory_address: var,
            memory_address_points_to: points_to,
            scope,
            is_dynamic,
            is_free,
            line_number: line,
            var_name: name.to_vec(),
            function_name,
            step_on_execution: *step,
        });
        *step = step.wrapping_add(1);
    }

    /// `update_reference_list_log` (`AnalysisModeMemtrack.c:197-256`): for
    /// each row of the first `currentSize` that points to `address` with
    /// another status, the newest row at or after it of the same variable
    /// that points to `address` gets a copy with `status` appended, unless
    /// it already has that status.
    fn update_reference_list_log(
        &mut self,
        step: &mut u32,
        address: u64,
        status: AddressStatus,
        line: u32,
    ) {
        let current_size = self.list.len();
        for i in 0..current_size {
            let (points_to, var, i_status) = {
                let r = &self.list[i];
                (r.memory_address_points_to, r.memory_address, r.status())
            };
            if points_to != address || status == i_status {
                continue;
            }
            let Some(j_row) = self.list[i..current_size]
                .iter()
                .rev()
                .find(|r| r.memory_address_points_to == address && r.memory_address == var)
                .cloned()
            else {
                continue;
            };
            if j_row.status() != status {
                let (is_dynamic, is_free) = status.flags();
                self.append_list_row(
                    step,
                    j_row.memory_address,
                    j_row.memory_address_points_to,
                    j_row.scope,
                    is_dynamic,
                    is_free,
                    line,
                    &j_row.var_name,
                    j_row.function_name,
                );
            }
        }
    }

    /// Marks the newest row of `address` free with size 0
    /// (`AnalysisModeMemtrack.c:190-192`, `:372-375`) and returns true.
    /// develop dereferences the row without a NULL test, so an address with
    /// no row crashes there, before `update_reference_list_log` (only
    /// reachable when the free was not found invalid: NULL with
    /// `isNullValid` 0, or memcleanup mode). The core stops there instead and
    /// returns false.
    fn release_row(&mut self, address: u64) -> bool {
        match self.find_row_with_address(address) {
            Some(row) => {
                row.size = 0;
                row.is_free = true;
                true
            }
            None => false,
        }
    }

    // ── AnalysisModeMemtrack.c ──────────────────────────────────────────────

    /// `analysis_is_program_correct` (`AnalysisModeMemtrack.c:138-146`;
    /// `AnalysisModeMemcleanup.c:138-148`): the property of the leak, or
    /// `None`. It runs `valid_allocation_log`, which appends rows.
    pub fn is_program_correct(&mut self, mode: MemMode) -> Option<ViolatedProperty> {
        let addr = self.valid_allocation_log();
        if addr == 0 {
            return None;
        }
        match mode {
            MemMode::Memtrack => Some(ViolatedProperty::MemsafetyMemtrack),
            MemMode::Memcleanup => self
                .is_memcleanup_error(addr)
                .then_some(ViolatedProperty::MemsafetyMemcleanup),
        }
    }

    /// `map2check_load` (`AnalysisModeMemtrack.c:168-174`): sets
    /// `ERROR_DEREF` when no heap-log row and no live allocation covers the
    /// `size` bytes at `ptr`. Empty in memcleanup (`AnalysisModeMemcleanup.c:158`).
    pub fn load(&mut self, mode: MemMode, ptr: u64, size: i32) {
        if mode == MemMode::Memcleanup {
            return;
        }
        if !self.is_valid_heap_address(ptr, size) && !self.is_valid_allocation_address(ptr, size) {
            self.error_deref = true;
        }
    }

    /// `map2check_check_cstring` (`AnalysisModeMemtrack.c:159-166`): each
    /// byte up to the terminator must be covered (`map2check_load(s + i, 1)`);
    /// stops at the first invalid byte, before reading it, or at the
    /// terminator. `read` reads the byte at an address. Empty in memcleanup
    /// (`AnalysisModeMemcleanup.c:159`).
    pub fn check_cstring(&mut self, mode: MemMode, string: u64, mut read: impl FnMut(u64) -> u8) {
        if mode == MemMode::Memcleanup || string == 0 {
            return;
        }
        let mut i: u64 = 0;
        loop {
            let at = string.wrapping_add(i);
            self.load(mode, at, 1);
            if self.error_deref || read(at) == 0 {
                return;
            }
            i = i.wrapping_add(1);
        }
    }

    /// `map2check_check_deref` (`AnalysisModeMemtrack.c:309-315`): whether
    /// to report FALSE_DEREF. Empty in memcleanup (`:294`).
    pub fn check_deref(&self, mode: MemMode) -> bool {
        mode == MemMode::Memtrack && self.error_deref
    }

    /// `map2check_free_resolved_address` (`AnalysisModeMemtrack.c:176-195`).
    /// Memcleanup never finds the free invalid (`AnalysisModeMemcleanup.c:168`).
    pub fn free_resolved_address(
        &mut self,
        mode: MemMode,
        step: &mut u32,
        ptr: u64,
        line: u32,
        is_null_valid: i16,
    ) -> FreeOutcome {
        if ptr == 0 && is_null_valid != 0 {
            return FreeOutcome::Released;
        }
        if mode == MemMode::Memtrack && self.is_invalid_free(ptr) {
            return FreeOutcome::InvalidFree;
        }
        if self.release_row(ptr) {
            self.update_reference_list_log(step, ptr, AddressStatus::Free, line);
        }
        FreeOutcome::Released
    }

    /// `map2check_add_store_pointer` (`AnalysisModeMemtrack.c:258-307`): the
    /// status of `value` in the allocation log; a row unless the variable's
    /// newest row already has this value and these flags; then the references
    /// to `value` are updated.
    #[allow(clippy::too_many_arguments)]
    pub fn add_store_pointer(
        &mut self,
        step: &mut u32,
        var: u64,
        value: u64,
        scope: u32,
        name: &[u8],
        line: i32,
        function_name: &[u8],
    ) {
        let status = self.check_address_allocation_log(value);
        let (is_dynamic, is_free) = status.flags();
        let redundant = self
            .list
            .iter()
            .rev()
            .find(|r| r.memory_address == var)
            .is_some_and(|r| {
                r.memory_address_points_to == value
                    && r.is_free == is_free
                    && r.is_dynamic == is_dynamic
            });
        if redundant {
            return;
        }
        // `new_list_row` takes `unsigned line_number`.
        let line = line as u32;
        self.append_list_row(
            step,
            var,
            value,
            scope,
            is_dynamic,
            is_free,
            line,
            name,
            CName::new(function_name),
        );
        self.update_reference_list_log(step, value, status, line);
    }

    /// `map2check_malloc` (`AnalysisModeMemtrack.c:317-335`). Returns false
    /// for develop's NULL test, `int addr = (long)ptr; addr == 0` (the low 32
    /// bits), which writes UNKNOWN and ends the run before any row.
    /// Otherwise the newest row of `ptr` is revived with the new size, or a
    /// row is appended. `size` is an `int` stored in an `unsigned`.
    pub fn malloc(&mut self, ptr: u64, size: i32) -> bool {
        if ptr as u32 == 0 {
            return false;
        }
        self.track_allocation(ptr, size as u32);
        true
    }

    fn track_allocation(&mut self, addr: u64, size: u32) {
        match self.find_row_with_address(addr) {
            Some(row) => {
                row.size = size;
                row.is_free = false;
            }
            None => self.allocation.push(AllocationRow {
                addr,
                is_free: false,
                size,
            }),
        }
    }

    /// `map2check_calloc` (`AnalysisModeMemtrack.c:347-349`):
    /// `map2check_malloc(ptr, quantity * size)`, an `int` product (it wraps).
    pub fn calloc(&mut self, ptr: u64, quantity: i32, size: i32) -> bool {
        self.malloc(ptr, quantity.wrapping_mul(size))
    }

    /// `map2check_free` (`AnalysisModeMemtrack.c:351-378`) after the slot was
    /// read (`points_to = *(long *)ptr`): nothing for NULL; a FREE row for the
    /// variable `var` (appended before the check, `:358-365`); FALSE_FREE when
    /// `is_invalid_free` (memtrack only, memcleanup has `error = FALSE`);
    /// else the block is released and the references updated.
    #[allow(clippy::too_many_arguments)]
    pub fn free(
        &mut self,
        mode: MemMode,
        step: &mut u32,
        name: &[u8],
        var: u64,
        points_to: u64,
        scope: u32,
        line: u32,
        function_name: &[u8],
    ) -> FreeOutcome {
        if points_to == 0 {
            return FreeOutcome::Released;
        }
        let row_step = *step;
        *step = step.wrapping_add(1);
        let error = mode == MemMode::Memtrack && self.is_invalid_free(points_to);
        self.list.push(ListRow {
            memory_address: var,
            memory_address_points_to: points_to,
            scope,
            is_dynamic: false,
            is_free: true,
            line_number: line,
            var_name: name.to_vec(),
            function_name: CName::new(function_name),
            step_on_execution: row_step,
        });
        if error {
            return FreeOutcome::InvalidFree;
        }
        if self.release_row(points_to) {
            self.update_reference_list_log(step, points_to, AddressStatus::Free, line);
        }
        FreeOutcome::Released
    }

    /// `map2check_alloca` (`AnalysisModeMemtrack.c:386-391`).
    pub fn alloca(
        &mut self,
        name: &[u8],
        ptr: u64,
        size: i32,
        size_of_primitive: i32,
        line: i32,
        scope: i32,
    ) {
        self.heap.push(HeapRow {
            line,
            scope,
            value: ptr,
            size,
            size_of_primitive,
            function_name: CName::new(name),
        });
    }

    /// `map2check_non_static_alloca` (`AnalysisModeMemtrack.c:380-384`):
    /// `size * size_of_primitive` bytes, an `int` product (it wraps).
    pub fn non_static_alloca(
        &mut self,
        name: &[u8],
        ptr: u64,
        size: i32,
        size_of_primitive: i32,
        line: i32,
        scope: i32,
    ) {
        self.alloca(
            name,
            ptr,
            size.wrapping_mul(size_of_primitive),
            size_of_primitive,
            line,
            scope,
        );
    }

    /// `map2check_function` (`AnalysisModeMemtrack.c:393-397`): line, scope,
    /// size and primitive size 1.
    pub fn function(&mut self, name: &[u8], ptr: u64) {
        self.alloca(name, ptr, 1, 1, 1, 1);
    }

    /// `map2check_wasm_malloc` (`AnalysisModeMemtrack.c:403-416`): offsets 0
    /// and `(uint64_t)-1` are no block; the size is cut to `unsigned`.
    pub fn wasm_malloc(&mut self, offset: u64, size: u64) {
        if offset == 0 || offset == u64::MAX {
            return;
        }
        self.track_allocation(offset, size as u32);
    }

    /// `map2check_wasm_free` (`AnalysisModeMemtrack.c:418-428`): false when
    /// no row has `offset` (FALSE_FREE); a freed row is found again, so a
    /// double free is not an error.
    pub fn wasm_free(&mut self, offset: u64) -> bool {
        match self.find_row_with_address(offset) {
            Some(row) => {
                row.is_free = true;
                row.size = 0;
                true
            }
            None => false,
        }
    }

    /// `map2check_wasm_check_access` (`AnalysisModeMemtrack.c:430-436`):
    /// whether the access is valid; `(int)access_size`.
    pub fn wasm_check_access(&self, offset: u64, access_size: u64) -> bool {
        self.is_valid_allocation_address(offset, access_size as i32)
    }

    // ── *_log_to_file ───────────────────────────────────────────────────────

    /// `list_log_to_file` (`ListLog.c:138-157`).
    pub fn list_log_bytes(&self) -> Vec<u8> {
        let mut out = Vec::new();
        for r in &self.list {
            list_log_row(
                &mut out,
                r.memory_address,
                r.memory_address_points_to,
                r.scope,
                r.is_free,
                r.is_dynamic,
                &r.var_name,
                r.line_number,
                r.function_name.as_bytes(),
                r.step_on_execution,
            );
        }
        out
    }

    /// `allocation_log_to_file` (`AllocationLog.c:161-174`).
    pub fn allocation_log_bytes(&self) -> Vec<u8> {
        let mut out = Vec::new();
        for r in &self.allocation {
            allocation_log_row(&mut out, r.addr, r.size, r.is_free);
        }
        out
    }

    /// `heap_log_to_file` (`HeapLog.c:54-66`).
    pub fn heap_log_bytes(&self) -> Vec<u8> {
        let mut out = Vec::new();
        for r in &self.heap {
            heap_log_row(&mut out, r.value, r.function_name.as_bytes(), r.size);
        }
        out
    }
}

/// One row of `list_log.csv`, the `fprintf` calls of `ListLog.c:145-154`:
/// `"%u;"` id (always 0, `new_list_row` `:125`), `"%p;"` memory address,
/// `"%p;"` points to, `"%u;"` scope, `"%d;"` is_free, `"%d;"` is_dynamic,
/// `"%s;"` var name, `"%u;"` line, `"%s;"` function name, `"%u\n"` step.
#[allow(clippy::too_many_arguments)]
pub fn list_log_row(
    out: &mut Vec<u8>,
    memory_address: u64,
    points_to: u64,
    scope: u32,
    is_free: bool,
    is_dynamic: bool,
    var_name: &[u8],
    line: u32,
    function_name: &[u8],
    step: u32,
) {
    let mut head = String::new();
    let _ = write!(
        head,
        "0;{};{};{scope};{};{};",
        c_pointer(memory_address as usize),
        c_pointer(points_to as usize),
        i32::from(is_free),
        i32::from(is_dynamic)
    );
    out.extend_from_slice(head.as_bytes());
    out.extend_from_slice(var_name);
    out.extend_from_slice(format!(";{line};").as_bytes());
    out.extend_from_slice(function_name);
    out.extend_from_slice(format!(";{step}\n").as_bytes());
}

/// One row of `allocation_log.csv`, `AllocationLog.c:169-171`:
/// `"%p;"` address, `"%u;"` size, `"%d\n"` is_free.
pub fn allocation_log_row(out: &mut Vec<u8>, addr: u64, size: u32, is_free: bool) {
    out.extend_from_slice(
        format!(
            "{};{size};{}\n",
            c_pointer(addr as usize),
            i32::from(is_free)
        )
        .as_bytes(),
    );
}

/// One row of `heap_log.csv`, `HeapLog.c:61-63`: `"%p;"` address, `"%s;"`
/// name, `"%d\n"` size.
pub fn heap_log_row(out: &mut Vec<u8>, addr: u64, name: &[u8], size: i32) {
    out.extend_from_slice(format!("{};", c_pointer(addr as usize)).as_bytes());
    out.extend_from_slice(name);
    out.extend_from_slice(format!(";{size}\n").as_bytes());
}

#[cfg(test)]
mod tests {
    use super::*;

    fn text(bytes: Vec<u8>) -> String {
        String::from_utf8(bytes).unwrap()
    }

    #[test]
    fn row_formats_are_those_of_the_c_fprintf_calls() {
        let mut out = Vec::new();
        list_log_row(&mut out, 0x10, 0, 3, true, false, b"p", 7, b"main", 9);
        assert_eq!(text(out), "0;0x10;(nil);3;1;0;p;7;main;9\n");
        let mut out = Vec::new();
        allocation_log_row(&mut out, 0xA0, u32::MAX, false);
        assert_eq!(text(out), "0xa0;4294967295;0\n");
        let mut out = Vec::new();
        heap_log_row(&mut out, 0, b"x", -4);
        assert_eq!(text(out), "(nil);x;-4\n");
    }

    #[test]
    fn valid_allocation_log_appends_a_freed_row_per_leak_and_returns_the_last() {
        let mut m = CMemory::default();
        assert_eq!(m.valid_allocation_log(), 0);
        assert!(m.malloc(0xA0, 4));
        assert!(m.malloc(0xB0, 8));
        assert!(m.wasm_free(0xB0));
        assert!(m.malloc(0xC0, 2));
        assert_eq!(m.valid_allocation_log(), 0xC0);
        assert_eq!(
            text(m.allocation_log_bytes()),
            "0xa0;4;0\n0xb0;0;1\n0xc0;2;0\n0xa0;0;1\n0xc0;0;1\n"
        );
        assert_eq!(m.valid_allocation_log(), 0);
    }

    #[test]
    fn allocation_range_wraps_as_unsigned_long() {
        let mut m = CMemory::default();
        m.wasm_malloc(0x100, 4);
        assert!(m.wasm_check_access(0x100, 4));
        assert!(!m.wasm_check_access(0x101, 4));
        // (int)access_size: 2^32 + 1 is 1.
        assert!(m.wasm_check_access(0x103, (1 << 32) + 1));
        // A negative int access widens the range.
        assert!(m.wasm_check_access(0x104, u64::from(u32::MAX)));
    }

    #[test]
    fn memcleanup_mode_tracks_but_never_reports_deref_or_free() {
        let mut m = CMemory::default();
        let mut step = 0;
        m.load(MemMode::Memcleanup, 0x9000, 4);
        assert!(!m.error_deref());
        m.check_cstring(MemMode::Memcleanup, 0x9000, |_| unreachable!());
        assert!(!m.check_deref(MemMode::Memcleanup));
        assert_eq!(
            m.free_resolved_address(MemMode::Memcleanup, &mut step, 0x5000, 1, 0),
            FreeOutcome::Released
        );
        assert!(m.malloc(0xA0, 8));
        assert_eq!(
            m.free(MemMode::Memcleanup, &mut step, b"p", 0x10, 0xA0, 1, 2, b"f"),
            FreeOutcome::Released
        );
        assert_eq!(text(m.allocation_log_bytes()), "0xa0;0;1\n");
        assert_eq!(text(m.list_log_bytes()), "0;0x10;0xa0;1;1;0;p;2;f;0\n");
    }

    #[test]
    fn memcleanup_verdict_needs_a_pointer_to_the_last_leak() {
        let mut step = 0;
        let mut m = CMemory::default();
        assert!(m.malloc(0xA0, 8));
        assert_eq!(
            m.clone().is_program_correct(MemMode::Memtrack),
            Some(ViolatedProperty::MemsafetyMemtrack)
        );
        assert_eq!(m.clone().is_program_correct(MemMode::Memcleanup), None);
        m.add_store_pointer(&mut step, 0x10, 0xA0, 1, b"p", 1, b"f");
        assert_eq!(
            m.clone().is_program_correct(MemMode::Memcleanup),
            Some(ViolatedProperty::MemsafetyMemcleanup)
        );
        m.add_store_pointer(&mut step, 0x10, 0, 1, b"p", 2, b"f");
        assert_eq!(m.is_program_correct(MemMode::Memcleanup), None);
    }

    #[test]
    fn a_release_without_allocation_row_stops_where_develop_crashes() {
        // free_resolved_address(NULL, .., isNullValid = 0): is_invalid_free
        // is FALSE for NULL and find_row_with_address finds no row; develop
        // writes through NULL there. No row and no reference update here.
        let mut m = CMemory::default();
        let mut step = 0;
        m.add_store_pointer(&mut step, 0x10, 0, 1, b"p", 1, b"f");
        assert_eq!(
            m.free_resolved_address(MemMode::Memtrack, &mut step, 0, 2, 0),
            FreeOutcome::Released
        );
        assert_eq!(text(m.list_log_bytes()), "0;0x10;(nil);1;0;0;p;1;f;0\n");
        assert_eq!(step, 1);
    }

    #[test]
    fn heap_range_is_signed_long() {
        let mut m = CMemory::default();
        m.alloca(b"x", 0x100, 8, 8, 1, 1);
        m.load(MemMode::Memtrack, 0x104, 4);
        assert!(!m.error_deref());
        // A size larger than the slot leaves an empty range.
        m.load(MemMode::Memtrack, 0x100, 9);
        assert!(m.error_deref());
    }

    #[test]
    fn cname_cuts_at_35_bytes_and_at_the_first_nul() {
        assert_eq!(CName::new(b"ab\0cd").as_bytes(), b"ab");
        assert_eq!(CName::new(&[b'x'; 40]).as_bytes(), &[b'x'; 35][..]);
    }
}
