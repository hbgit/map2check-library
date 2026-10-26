// SPDX-License-Identifier: GPL-3.0-only
//
// Legacy result channel (#19): the files that the C runtime of Map2Check
// `develop` writes into the current directory and that the Map2Check
// frontend reads (`modules/frontend/utils/tools.cpp`, `caller.cpp`,
// `counter_example/`). Every writer reproduces the `fprintf` calls of the C
// runtime byte for byte; `tests/legacy_golden/` holds the files that runtime
// wrote, and `rust/src/ffi_golden_tests.rs` compares against them.
//
// | file                            | develop writer                         |
// |---------------------------------|----------------------------------------|
// | `map2check_property*`           | `PropertyGenerator.c`                  |
// | `map2check_checked_error`       | `WitnessGeneration.c:28-32`            |
// | `track_bb_log.st`               | `TrackBBLog.c:35-44`                   |
// | `klee_log.csv`                  | `NonDetLog.c:17-60`                    |
// | `list_log.csv`                  | `ListLog.c:138-157`                    |
// | `allocation_log.csv`            | `AllocationLog.c:161-174`              |
// | `heap_log.csv`                  | `HeapLog.c:54-66`                      |
//
// The C runtime keeps one log per kind of record and its own step counter,
// which only list-log rows and nondet calls advance. This library keeps one
// memory log and one step counter for every record, so `LegacyLogs::replay`
// rebuilds develop's logs and steps from the records, in order, with the
// rules of `AnalysisModeMemtrack.c` / `AnalysisModeMemcleanup.c`.
#![deny(unsafe_code)]

use std::fmt::Write as _;
use std::io;
use std::path::Path;

use crate::{
    bbtrack::BasicBlockEntry,
    caller::{AnalysisResult, ViolatedProperty},
    memtrack::{MemOrigin, MemTrackEntry},
    nondet::{NonDetEntry, NonDetValue},
};

/// `PropertyGenerator.c:15-22`. `map2check_property__unknown` keeps the
/// double underscore of the C runtime on purpose (SD-16).
pub const PROPERTY_FILE: &str = "map2check_property";
pub const PROPERTY_FILE_UNKNOWN: &str = "map2check_property__unknown";
pub const PROPERTY_FILES: [&str; 8] = [
    PROPERTY_FILE,
    PROPERTY_FILE_UNKNOWN,
    "map2check_property_memtrack",
    "map2check_property_memcleanup",
    "map2check_property_deref",
    "map2check_property_free",
    "map2check_property_overflow",
    "map2check_property_assert",
];
pub const CHECKED_ERROR_FILE: &str = "map2check_checked_error";
pub const TRACKBB_LOG_FILE: &str = "track_bb_log.st";
pub const NONDET_LOG_FILE: &str = "klee_log.csv";
pub const LIST_LOG_FILE: &str = "list_log.csv";
pub const ALLOCATION_LOG_FILE: &str = "allocation_log.csv";
pub const HEAP_LOG_FILE: &str = "heap_log.csv";

/// `%p` of glibc: `(nil)` for NULL, otherwise `0x` and lowercase hex.
pub fn c_pointer(address: usize) -> String {
    if address == 0 {
        "(nil)".to_owned()
    } else {
        format!("{address:#x}")
    }
}

/// `%lf` of glibc: six decimals, `inf`/`nan` with their sign.
pub fn c_double(value: f64) -> String {
    let sign = if value.is_sign_negative() { "-" } else { "" };
    if value.is_nan() {
        format!("{sign}nan")
    } else if value.is_infinite() {
        format!("{sign}inf")
    } else {
        format!("{value:.6}")
    }
}

/// Writes `contents` to `dir/name` atomically: the full text goes to a
/// temporary file of the same directory, which is then renamed over the
/// target. `std::fs::write` truncates the target and writes in separate
/// calls; under KLEE (`--external-calls=all`) the forked states share the
/// real file system and one state can truncate the file after another wrote
/// its violation, leaving it empty when KLEE halts on the abort. A reader of
/// the target sees the old file or the new one, never an empty or partial
/// one.
///
/// The temporary name has the pid and a counter. KLEE states
/// share the pid and each has a copy of the counter, so the file is created
/// with `create_new` and a name that already exists is skipped.
pub fn write_atomic(dir: &Path, name: &str, contents: &str) -> io::Result<()> {
    write_atomic_bytes(dir, name, contents.as_bytes())
}

/// [`write_atomic`] for contents that need not be UTF-8 (a function name is
/// a C byte string).
pub fn write_atomic_bytes(dir: &Path, name: &str, contents: &[u8]) -> io::Result<()> {
    use std::io::Write as _;
    use std::sync::atomic::{AtomicU64, Ordering};
    static COUNTER: AtomicU64 = AtomicU64::new(0);

    let pid = std::process::id();
    let mut attempts = 0u32;
    let (tmp, mut file) = loop {
        let n = COUNTER.fetch_add(1, Ordering::Relaxed);
        let tmp = dir.join(format!(".{name}.{pid}.{n}.tmp"));
        match std::fs::OpenOptions::new()
            .write(true)
            .create_new(true)
            .open(&tmp)
        {
            Ok(file) => break (tmp, file),
            Err(e) if e.kind() == io::ErrorKind::AlreadyExists && attempts < 10_000 => {
                attempts += 1;
            }
            Err(e) => return Err(e),
        }
    };
    let result = file.write_all(contents).and_then(|()| {
        drop(file);
        std::fs::rename(&tmp, dir.join(name))
    });
    if result.is_err() {
        let _ = std::fs::remove_file(&tmp);
    }
    result
}

/// `"<tag>\nLine: %d\nFunction: %s\n"`, the three `fprintf` calls of the
/// located properties of `PropertyGenerator.c`.
fn located(tag: &str, line: i32, function_name: &str) -> String {
    format!("{tag}\nLine: {line}\nFunction: {function_name}\n")
}

/// `write_property_unknown` (`PropertyGenerator.c:24-28`). The double
/// underscore of the file name is kept on purpose (SD-16). Like the other
/// `write_property_<x>` helpers it is private to the Rust core (SD-22).
pub(crate) fn write_property_unknown(dir: &Path) -> io::Result<()> {
    write_atomic(dir, PROPERTY_FILE_UNKNOWN, "UNKNOWN\n")
}

/// `write_property_memtrack` (`PropertyGenerator.c:30-34`).
pub(crate) fn write_property_memtrack(dir: &Path) -> io::Result<()> {
    write_atomic(dir, "map2check_property_memtrack", "FALSE-MEMTRACK\n")
}

/// `write_property_memcleanup` (`PropertyGenerator.c:36-40`).
pub(crate) fn write_property_memcleanup(dir: &Path) -> io::Result<()> {
    write_atomic(dir, "map2check_property_memcleanup", "FALSE-MEMCLEANUP\n")
}

/// `write_property_deref` (`PropertyGenerator.c:42-48`).
pub(crate) fn write_property_deref(dir: &Path, line: i32, function_name: &str) -> io::Result<()> {
    write_atomic(
        dir,
        "map2check_property_deref",
        &located("FALSE-DEREF", line, function_name),
    )
}

/// `write_property_free` (`PropertyGenerator.c:108-114`).
pub(crate) fn write_property_free(dir: &Path, line: i32, function_name: &str) -> io::Result<()> {
    write_atomic(
        dir,
        "map2check_property_free",
        &located("FALSE-FREE", line, function_name),
    )
}

/// `write_property_overflow` (`PropertyGenerator.c:116-122`).
pub(crate) fn write_property_overflow(
    dir: &Path,
    line: i32,
    function_name: &str,
) -> io::Result<()> {
    write_atomic(
        dir,
        "map2check_property_overflow",
        &located("OVERFLOW", line, function_name),
    )
}

/// `write_property_assert` (`PropertyGenerator.c:124-130`).
pub(crate) fn write_property_assert(dir: &Path, line: i32, function_name: &str) -> io::Result<()> {
    write_atomic(
        dir,
        "map2check_property_assert",
        &located("ASSERT", line, function_name),
    )
}

/// `write_property` (`PropertyGenerator.c:50-106`): `map2check_property`
/// with the text of `violated` and, for the properties that have one, the
/// file of its `write_property_<x>` helper, written before
/// `map2check_property` is complete, as the C function calls the helper
/// before its own `fclose`. `Concurrency`, which has no case in the C
/// switch, leaves `map2check_property` empty. Each file is replaced
/// atomically (SD-20).
pub fn write_property(
    dir: &Path,
    violated: ViolatedProperty,
    line: i32,
    function_name: &str,
) -> io::Result<()> {
    let text = match violated {
        ViolatedProperty::None => "NONE\n".to_owned(),
        ViolatedProperty::Unknown => "UNKNOWN\n".to_owned(),
        ViolatedProperty::MemsafetyFree => {
            write_property_free(dir, line, function_name)?;
            located("FALSE-FREE", line, function_name)
        }
        ViolatedProperty::MemsafetyDeref => {
            write_property_deref(dir, line, function_name)?;
            located("FALSE-DEREF", line, function_name)
        }
        ViolatedProperty::MemsafetyMemtrack => {
            write_property_memtrack(dir)?;
            "FALSE-MEMTRACK\n".to_owned()
        }
        ViolatedProperty::MemsafetyMemcleanup => {
            write_property_memcleanup(dir)?;
            "FALSE-MEMCLEANUP\n".to_owned()
        }
        ViolatedProperty::Reachability => located("TARGET-REACHED", line, function_name),
        ViolatedProperty::Overflow => {
            write_property_overflow(dir, line, function_name)?;
            located("OVERFLOW", line, function_name)
        }
        ViolatedProperty::Assert => {
            write_property_assert(dir, line, function_name)?;
            located("ASSERT", line, function_name)
        }
        // `:98-102`: no per-property file.
        ViolatedProperty::DivByZero => located("FALSE-DIVBYZERO", line, function_name),
        ViolatedProperty::Concurrency => String::new(),
    };
    write_atomic(dir, PROPERTY_FILE, &text)
}

/// Writes the property files of `result` into `dir`, as the C runtime does
/// on the path that records it: `write_property(NONE, 0, "")` for a correct
/// run (`map2check_success`, `Map2CheckFunctions.c:67-70`), and
/// `write_property` of the property otherwise. `line` is printed with `%d`,
/// so it is shown as a C `int`. The only UNKNOWN the C runtime reports is
/// `write_property_unknown` (NULL from malloc, `AnalysisModeMemtrack.c:305-311`),
/// which writes no `map2check_property`; `Concurrency`, which has no develop
/// counterpart, is reported the same way.
pub fn write_property_files(dir: &Path, result: &AnalysisResult) -> io::Result<()> {
    if result.ok {
        return write_property(dir, ViolatedProperty::None, 0, "");
    }
    match result.property {
        ViolatedProperty::Unknown | ViolatedProperty::Concurrency => write_property_unknown(dir),
        property => write_property(dir, property, result.line as i32, &result.function_name),
    }
}

/// Removes every property file left in `dir` by an earlier run. A missing
/// file is not an error; other errors are reported on stderr.
pub fn remove_stale_property_files(dir: &Path) {
    for name in PROPERTY_FILES {
        match std::fs::remove_file(dir.join(name)) {
            Ok(()) => {}
            Err(e) if e.kind() == io::ErrorKind::NotFound => {}
            Err(e) => eprintln!("[map2check] cannot remove stale {name}: {e}"),
        }
    }
}

/// `generate_confirmation_file` (`WitnessGeneration.c:28-32`).
pub fn write_checked_error(dir: &Path) -> io::Result<()> {
    write_atomic(dir, CHECKED_ERROR_FILE, "END OF TIME\n")
}

/// `trackbb_log_to_file` (`TrackBBLog.c:35-44`), private to the Rust core
/// (SD-22): `"%u;"` then `"%s\n"` per row (`:40-41`), in order.
pub(crate) fn trackbb_log_to_file(dir: &Path, rows: &[BasicBlockEntry]) -> io::Result<()> {
    let mut out = String::new();
    for row in rows {
        let _ = writeln!(out, "{};{}", row.line, row.function_name);
    }
    write_atomic(dir, TRACKBB_LOG_FILE, &out)
}

/// The basic-block log of the run: `map2check_track_bb` keeps only the
/// first block of each line (`Map2CheckFunctions.c:49-55`), and the rows of
/// `map2check_save_basic_block_log`, which records every block, are reduced
/// the same way before [`trackbb_log_to_file`].
pub fn write_trackbb_log(dir: &Path, rows: &[BasicBlockEntry]) -> io::Result<()> {
    let mut seen = crate::memtrack::FixedHashSet::default();
    let first: Vec<BasicBlockEntry> = rows
        .iter()
        .filter(|r| seen.insert(r.line))
        .cloned()
        .collect();
    trackbb_log_to_file(dir, &first)
}

/// The `enum NONDET_TYPE` number and the union bits of a nondet row, as
/// develop stores it, so that [`crate::nondet::c_log`] is the only code that
/// formats `klee_log.csv`.
///
/// `NonDetPass.cpp` hands each value to its `map2check_nondet_<t>` wrapper as
/// a C `int` (`NonDetLog.c:105-150`): `int`, `unsigned`, `uint` as they are
/// (`NONDET_IMPL_HELPER`, `:260-280`); the other integer kinds through
/// `CreateIntegerCast(v, i32, isSigned = false)` (`:240-258`, `:281-290`),
/// which zero-extends the narrow ones (`char` -3 arrives as 253) and
/// truncates the wide ones to their low 32 bits; `pointer` and `pchar`
/// through `CreatePtrToInt(v, i32)` (`:224-238`, `:291-292`), the low 32
/// bits of the address. `float` has no develop counterpart and is logged as
/// a double.
pub fn nondet_kind_and_bits(value: &NonDetValue) -> (i32, u64) {
    use crate::nondet::c_log::kind as k;
    /// `trunc` to `i32`, as `CreateIntegerCast` narrows a wide integer.
    fn low32(v: u64) -> u64 {
        u64::from(v as u32)
    }
    match *value {
        NonDetValue::Int(v) => (k::INTEGER, low32(v as u32 as u64)),
        NonDetValue::Char(v) => (k::CHAR, u64::from(v as u8)),
        NonDetValue::Pointer(v) => (k::POINTER, low32(v as u64)),
        NonDetValue::UShort(v) => (k::USHORT, u64::from(v)),
        NonDetValue::Long(v) => (k::LONG, low32(v as u64)),
        NonDetValue::Unsigned(v) => (k::UNSIGNED, u64::from(v)),
        NonDetValue::ULong(v) => (k::ULONG, low32(v)),
        NonDetValue::Bool(v) => (k::BOOL, low32(v as u32 as u64)),
        NonDetValue::UChar(v) => (k::UCHAR, u64::from(v)),
        NonDetValue::PChar(v) => (k::PCHAR, low32(v as u64)),
        NonDetValue::SizeT(v) => (k::SIZE_T, low32(v as u64)),
        NonDetValue::LoffT(v) => (k::LOFF_T, low32(v as u64)),
        NonDetValue::SectorT(v) => (k::SECTOR_T, low32(v)),
        NonDetValue::UInt(v) => (k::UINT, u64::from(v)),
        NonDetValue::Short(v) => (k::SHORT, u64::from(v as u16)),
        NonDetValue::Float(v) => (k::DOUBLE, f64::from(v).to_bits()),
        NonDetValue::Double(v) => (k::DOUBLE, v.to_bits()),
    }
}

/// `enum MemoryAddressStatus` (`Map2CheckTypes.h:34`).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum Status {
    Static,
    Free,
    Dynamic,
}

impl Status {
    /// `(is_dynamic, is_free)` of a list row with this status
    /// (`AnalysisModeMemtrack.c:217-230`, `:256-272`).
    fn flags(self) -> (bool, bool) {
        match self {
            Status::Static => (false, false),
            Status::Free => (false, true),
            Status::Dynamic => (true, false),
        }
    }
}

#[derive(Debug, Clone)]
struct ListRow {
    var: usize,
    points_to: usize,
    scope: u32,
    is_dynamic: bool,
    is_free: bool,
    line: u32,
    name: String,
    function: String,
    step: u32,
}

impl ListRow {
    /// `get_type_from_list_log_row` (`ListLog.c:159-168`).
    fn status(&self) -> Status {
        if self.is_free && !self.is_dynamic {
            Status::Free
        } else if self.is_dynamic {
            Status::Dynamic
        } else {
            Status::Static
        }
    }
}

#[derive(Debug, Clone)]
struct AllocationRow {
    addr: usize,
    size: u32,
    is_free: bool,
}

#[derive(Debug, Clone)]
struct HeapRow {
    addr: usize,
    name: String,
    size: i32,
}

#[derive(Debug, Clone)]
struct NondetRow {
    line: u32,
    scope: u32,
    function: String,
    step: u32,
    value: NonDetValue,
}

/// develop's heap, allocation, list and nondet logs, rebuilt from the
/// records of this library.
#[derive(Debug, Default)]
pub struct LegacyLogs {
    list: Vec<ListRow>,
    allocation: Vec<AllocationRow>,
    heap: Vec<HeapRow>,
    nondet: Vec<NondetRow>,
    /// `Map2CheckCurrentStep` (`Map2CheckFunctions.c:19`).
    step: u32,
}

/// One record, memory or nondet, in the order the program made it.
enum Event<'a> {
    Memory(&'a MemTrackEntry),
    Nondet(&'a NonDetEntry),
}

impl LegacyLogs {
    /// Replays the memory and nondet records in the order the program made
    /// them (both carry this library's step). `failed_free`, the free that
    /// ended the run, adds the FREE row develop's `map2check_free` appends
    /// before it fails (`AnalysisModeMemtrack.c:346-358`). `end_of_program`
    /// adds what `valid_allocation_log` appends when the end-of-program
    /// verdict runs (`AllocationLog.c:69-101`).
    pub fn replay(
        memtrack: &[MemTrackEntry],
        nondets: &[NonDetEntry],
        failed_free: Option<&MemTrackEntry>,
        end_of_program: bool,
    ) -> Self {
        let mut events: Vec<(u64, Event<'_>)> = memtrack
            .iter()
            .map(|e| (e.step, Event::Memory(e)))
            .chain(nondets.iter().map(|e| (e.step, Event::Nondet(e))))
            .collect();
        events.sort_by_key(|(step, _)| *step);

        let mut logs = Self::default();
        for (_, event) in events {
            match event {
                Event::Memory(e) => logs.memory(e),
                Event::Nondet(e) => logs.nondet(e),
            }
        }
        if let Some(e) = failed_free {
            logs.free_row(e);
        }
        if end_of_program {
            logs.valid_allocation_log();
        }
        logs
    }

    fn next_step(&mut self) -> u32 {
        let step = self.step;
        self.step = self.step.wrapping_add(1);
        step
    }

    fn memory(&mut self, e: &MemTrackEntry) {
        let origin = match e.origin {
            MemOrigin::Unspecified if e.is_free => MemOrigin::FreeResolved,
            MemOrigin::Unspecified if e.is_dynamic => MemOrigin::Malloc,
            MemOrigin::Unspecified if e.size_destiny == 0 => MemOrigin::StorePointer,
            MemOrigin::Unspecified => MemOrigin::Alloca,
            origin => origin,
        };
        match origin {
            // map2check_alloca (AnalysisModeMemtrack.c:374-379).
            MemOrigin::Alloca => self.heap.push(HeapRow {
                addr: e.var_addr,
                name: e.ptr_name.clone(),
                size: e.size_destiny as i32,
            }),
            // map2check_function (:381-385): size 1.
            MemOrigin::Function => self.heap.push(HeapRow {
                addr: e.var_addr,
                name: e.ptr_name.clone(),
                size: 1,
            }),
            MemOrigin::Malloc => self.malloc(e.points_to, e.size_destiny as u32),
            MemOrigin::StorePointer => self.store_pointer(e),
            MemOrigin::Free { .. } => self.free(e),
            MemOrigin::FreeResolved => self.free_resolved(e.points_to, e.line),
            MemOrigin::Unspecified => {}
        }
    }

    /// `map2check_nondet_*` (`NonDetLog.c:96-113`): the row takes the
    /// current step, then the step advances.
    fn nondet(&mut self, e: &NonDetEntry) {
        let step = self.next_step();
        self.nondet.push(NondetRow {
            line: e.line,
            scope: e.scope,
            function: e.function_name.clone(),
            step,
            value: e.value.clone(),
        });
    }

    /// `map2check_malloc` (`AnalysisModeMemtrack.c:305-323`). A NULL block
    /// ends the develop run before any row (UNKNOWN).
    fn malloc(&mut self, addr: usize, size: u32) {
        if addr == 0 {
            return;
        }
        match self.allocation.iter_mut().rev().find(|r| r.addr == addr) {
            Some(row) => {
                row.size = size;
                row.is_free = false;
            }
            None => self.allocation.push(AllocationRow {
                addr,
                size,
                is_free: false,
            }),
        }
    }

    /// `check_address_allocation_log` (`AllocationLog.c:34-51`).
    fn status_of(&self, addr: usize) -> Status {
        match self.allocation.iter().rev().find(|r| r.addr == addr) {
            Some(r) if r.is_free => Status::Free,
            Some(_) => Status::Dynamic,
            None => Status::Static,
        }
    }

    /// `map2check_add_store_pointer` (`AnalysisModeMemtrack.c:246-295`).
    fn store_pointer(&mut self, e: &MemTrackEntry) {
        let status = self.status_of(e.points_to);
        let (is_dynamic, is_free) = status.flags();
        let redundant = self
            .list
            .iter()
            .rev()
            .find(|r| r.var == e.var_addr)
            .is_some_and(|r| {
                r.points_to == e.points_to && r.is_free == is_free && r.is_dynamic == is_dynamic
            });
        if redundant {
            return;
        }
        let step = self.next_step();
        self.list.push(ListRow {
            var: e.var_addr,
            points_to: e.points_to,
            scope: e.scope,
            is_dynamic,
            is_free,
            line: e.line,
            name: e.ptr_name.clone(),
            function: e.function_name.clone(),
            step,
        });
        self.update_reference(e.points_to, status, e.line);
    }

    /// `map2check_free` (`AnalysisModeMemtrack.c:339-366`): a FREE row for
    /// the pointer variable, then the block is released.
    fn free(&mut self, e: &MemTrackEntry) {
        if self.free_row(e) {
            self.release(e.points_to, e.line);
        }
    }

    /// The FREE row `map2check_free` appends for the pointer variable whose
    /// slot it received (`:339-347`); returns false for a NULL block, where
    /// develop returns first (`:342-344`). A record without the variable
    /// (built outside `map2check_map_free`) names the block, as before.
    fn free_row(&mut self, e: &MemTrackEntry) -> bool {
        let addr = e.points_to;
        if addr == 0 {
            return false;
        }
        let var = match e.origin {
            MemOrigin::Free { var_address } => var_address,
            _ => addr,
        };
        let step = self.next_step();
        self.list.push(ListRow {
            var,
            points_to: addr,
            scope: e.scope,
            is_dynamic: false,
            is_free: true,
            line: e.line,
            name: e.ptr_name.clone(),
            function: e.function_name.clone(),
            step,
        });
        true
    }

    /// `map2check_free_resolved_address` (`AnalysisModeMemtrack.c:164-183`).
    fn free_resolved(&mut self, addr: usize, line: u32) {
        if addr == 0 {
            return;
        }
        self.release(addr, line);
    }

    /// The allocation row becomes free with size 0 and every pointer to the
    /// block gets a FREE row.
    fn release(&mut self, addr: usize, line: u32) {
        if let Some(row) = self.allocation.iter_mut().rev().find(|r| r.addr == addr) {
            row.size = 0;
            row.is_free = true;
        }
        self.update_reference(addr, Status::Free, line);
    }

    /// `update_reference_list_log` (`AnalysisModeMemtrack.c:185-244`).
    fn update_reference(&mut self, address: usize, status: Status, line: u32) {
        let current_size = self.list.len();
        for i in 0..current_size {
            let (i_var, i_points_to, i_status) = {
                let r = &self.list[i];
                (r.var, r.points_to, r.status())
            };
            if i_points_to != address || i_status == status {
                continue;
            }
            let Some(j_row) = self.list[i..current_size]
                .iter()
                .rev()
                .find(|r| r.points_to == address && r.var == i_var)
                .cloned()
            else {
                continue;
            };
            if j_row.status() != status {
                let (is_dynamic, is_free) = status.flags();
                let step = self.next_step();
                self.list.push(ListRow {
                    is_dynamic,
                    is_free,
                    line,
                    step,
                    ..j_row
                });
            }
        }
    }

    /// `valid_allocation_log` (`AllocationLog.c:69-101`): every block with
    /// no later freed row gets a freed row of size 0 appended.
    fn valid_allocation_log(&mut self) {
        let mut i = 0;
        while i < self.allocation.len() {
            let row = &self.allocation[i];
            if !row.is_free {
                let addr = row.addr;
                let released = self.allocation[i + 1..]
                    .iter()
                    .any(|r| r.addr == addr && r.is_free);
                if !released {
                    self.allocation.push(AllocationRow {
                        addr,
                        size: 0,
                        is_free: true,
                    });
                }
            }
            i += 1;
        }
    }

    /// `list_log_to_file` (`ListLog.c:138-157`). The id column is always 0
    /// (`new_list_row`, `ListLog.c:125`).
    pub fn write_list_log(&self, dir: &Path) -> io::Result<()> {
        let mut out = String::new();
        for r in &self.list {
            let _ = writeln!(
                out,
                "0;{};{};{};{};{};{};{};{};{}",
                c_pointer(r.var),
                c_pointer(r.points_to),
                r.scope,
                i32::from(r.is_free),
                i32::from(r.is_dynamic),
                r.name,
                r.line,
                r.function,
                r.step
            );
        }
        write_atomic(dir, LIST_LOG_FILE, &out)
    }

    /// `allocation_log_to_file` (`AllocationLog.c:161-174`).
    pub fn write_allocation_log(&self, dir: &Path) -> io::Result<()> {
        let mut out = String::new();
        for r in &self.allocation {
            let _ = writeln!(
                out,
                "{};{};{}",
                c_pointer(r.addr),
                r.size,
                i32::from(r.is_free)
            );
        }
        write_atomic(dir, ALLOCATION_LOG_FILE, &out)
    }

    /// `heap_log_to_file` (`HeapLog.c:54-66`).
    pub fn write_heap_log(&self, dir: &Path) -> io::Result<()> {
        let mut out = String::new();
        for r in &self.heap {
            let _ = writeln!(out, "{};{};{}", c_pointer(r.addr), r.name, r.size);
        }
        write_atomic(dir, HEAP_LOG_FILE, &out)
    }

    /// The rows of the nondet log in the shape of `NONDET_CALL`.
    pub fn nondet_calls(&self) -> Vec<crate::nondet::c_log::CNondetCall> {
        self.nondet
            .iter()
            .map(|r| {
                let (kind, bits) = nondet_kind_and_bits(&r.value);
                crate::nondet::c_log::CNondetCall::from_parts(
                    kind,
                    r.line,
                    r.scope,
                    r.step,
                    r.function.as_bytes(),
                    bits,
                )
            })
            .collect()
    }

    /// `nondet_log_to_file` (`NonDetLog.c:50-125`) through the one writer,
    /// [`crate::nondet::c_log::nondet_log_to_file`].
    pub fn write_nondet_log(&self, dir: &Path) -> io::Result<()> {
        if crate::nondet::c_log::nondet_log_to_file(&self.nondet_calls(), dir) {
            Ok(())
        } else {
            Err(io::Error::new(
                io::ErrorKind::Other,
                "cannot write klee_log.csv",
            ))
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::caller::{AnalysisResult, ViolatedProperty};

    fn golden(tag: &str, file: &str) -> Vec<u8> {
        std::fs::read(format!(
            "{}/tests/legacy_golden/{tag}/{file}",
            env!("CARGO_MANIFEST_DIR")
        ))
        .unwrap()
    }

    fn violated(property: ViolatedProperty, line: u32, function_name: &str) -> AnalysisResult {
        AnalysisResult {
            ok: false,
            property,
            line,
            function_name: function_name.into(),
            ..Default::default()
        }
    }

    #[test]
    fn property_files_match_c_runtime_for_every_tag() {
        let cases = [
            (
                "FALSE-FREE",
                violated(ViolatedProperty::MemsafetyFree, 13, "main"),
                "map2check_property_free",
            ),
            (
                "FALSE-DEREF",
                violated(ViolatedProperty::MemsafetyDeref, 14, "main"),
                "map2check_property_deref",
            ),
            (
                "FALSE-MEMTRACK",
                violated(ViolatedProperty::MemsafetyMemtrack, 0, ""),
                "map2check_property_memtrack",
            ),
            (
                "FALSE-MEMCLEANUP",
                violated(ViolatedProperty::MemsafetyMemcleanup, 0, ""),
                "map2check_property_memcleanup",
            ),
            (
                "OVERFLOW",
                violated(ViolatedProperty::Overflow, 20, "main"),
                "map2check_property_overflow",
            ),
            (
                "ASSERT",
                violated(ViolatedProperty::Assert, 21, "main"),
                "map2check_property_assert",
            ),
        ];
        for (tag, result, extra) in cases {
            let dir = tempfile::tempdir().unwrap();
            write_property_files(dir.path(), &result).unwrap();
            for file in ["map2check_property", extra] {
                assert_eq!(
                    std::fs::read(dir.path().join(file)).unwrap(),
                    golden(tag, file),
                    "{tag}/{file}"
                );
            }
            assert_eq!(std::fs::read_dir(dir.path()).unwrap().count(), 2, "{tag}");
        }
    }

    #[test]
    fn target_reached_and_none_write_only_map2check_property() {
        for (tag, result) in [
            (
                "TARGET-REACHED",
                violated(ViolatedProperty::Reachability, 22, "reach_error"),
            ),
            ("NONE", AnalysisResult::default()),
        ] {
            let dir = tempfile::tempdir().unwrap();
            write_property_files(dir.path(), &result).unwrap();
            assert_eq!(
                std::fs::read(dir.path().join("map2check_property")).unwrap(),
                golden(tag, "map2check_property"),
                "{tag}"
            );
            assert_eq!(std::fs::read_dir(dir.path()).unwrap().count(), 1, "{tag}");
        }
    }

    fn bb_rows(count: u32, function: &str) -> Vec<BasicBlockEntry> {
        (1..=count)
            .map(|line| BasicBlockEntry::new(u64::from(line), line, function))
            .collect()
    }

    /// Race test (the list-ext defect): a reader that polls the target while
    /// the writer rewrites it must see the old file or the new one in full,
    /// never an empty or partial file. The files are large, so the window
    /// between truncating and writing, which `std::fs::write` leaves open, is
    /// wide; with the old code this fails on every run seen.
    #[test]
    fn concurrent_reader_never_sees_empty_or_partial_file() {
        use std::sync::atomic::{AtomicBool, Ordering};
        let dir = tempfile::tempdir().unwrap();
        let old = bb_rows(400_000, "old");
        let new = bb_rows(500_000, "newer");
        write_trackbb_log(dir.path(), &old).unwrap();
        let target = dir.path().join(TRACKBB_LOG_FILE);
        let old_len = std::fs::metadata(&target).unwrap().len();
        let done = AtomicBool::new(false);
        let mut seen = Vec::new();
        std::thread::scope(|s| {
            s.spawn(|| {
                for _ in 0..20 {
                    write_trackbb_log(dir.path(), &new).unwrap();
                    write_trackbb_log(dir.path(), &old).unwrap();
                }
                done.store(true, Ordering::SeqCst);
            });
            while !done.load(Ordering::SeqCst) {
                if let Ok(m) = std::fs::read(&target) {
                    seen.push(m.len() as u64);
                }
            }
        });
        let new_len = {
            write_trackbb_log(dir.path(), &new).unwrap();
            std::fs::metadata(&target).unwrap().len()
        };
        assert!(!seen.is_empty());
        for len in seen {
            assert!(
                len == old_len || len == new_len,
                "a reader saw {len} bytes, expected {old_len} or {new_len}"
            );
        }
    }

    /// Structural check, deterministic: the target is replaced by a rename
    /// (its inode changes), and no temporary file is left behind.
    #[test]
    fn write_goes_through_a_temp_file_and_rename() {
        use std::os::unix::fs::MetadataExt as _;
        let dir = tempfile::tempdir().unwrap();
        let target = dir.path().join(PROPERTY_FILE);
        write_property_files(dir.path(), &violated(ViolatedProperty::Assert, 5, "main")).unwrap();
        let first = std::fs::metadata(&target).unwrap().ino();
        // An open handle on the old file keeps its inode alive, so a new
        // file cannot reuse the number.
        let _held = std::fs::File::open(&target).unwrap();
        write_property_files(dir.path(), &violated(ViolatedProperty::Assert, 5, "main")).unwrap();
        assert_ne!(first, std::fs::metadata(&target).unwrap().ino());
        let mut names: Vec<String> = std::fs::read_dir(dir.path())
            .unwrap()
            .map(|e| e.unwrap().file_name().into_string().unwrap())
            .collect();
        names.sort();
        assert_eq!(names, ["map2check_property", "map2check_property_assert"]);
    }

    #[test]
    fn temp_name_collisions_are_skipped() {
        let dir = tempfile::tempdir().unwrap();
        for _ in 0..50 {
            write_atomic(dir.path(), "f", "x\n").unwrap();
        }
        assert_eq!(std::fs::read(dir.path().join("f")).unwrap(), b"x\n");
        assert_eq!(std::fs::read_dir(dir.path()).unwrap().count(), 1);
    }

    #[test]
    fn div_by_zero_writes_only_map2check_property() {
        // PropertyGenerator.c:98-102: no per-property file for FALSE_DIVBYZERO.
        let dir = tempfile::tempdir().unwrap();
        write_property_files(
            dir.path(),
            &violated(ViolatedProperty::DivByZero, 23, "main"),
        )
        .unwrap();
        assert_eq!(
            std::fs::read(dir.path().join("map2check_property")).unwrap(),
            golden("DIVBYZERO", "map2check_property")
        );
        assert_eq!(std::fs::read_dir(dir.path()).unwrap().count(), 1);
    }

    #[test]
    fn unknown_uses_legacy_double_underscore_name() {
        // PropertyGenerator.c:16; SD-16.
        let dir = tempfile::tempdir().unwrap();
        write_property_files(dir.path(), &violated(ViolatedProperty::Unknown, 0, "")).unwrap();
        assert_eq!(
            std::fs::read(dir.path().join("map2check_property__unknown")).unwrap(),
            golden("UNKNOWN", "map2check_property__unknown")
        );
        assert!(!dir.path().join("map2check_property_unknown").exists());
        assert!(!dir.path().join("map2check_property").exists());
    }

    #[test]
    fn stale_property_files_are_removed() {
        let dir = tempfile::tempdir().unwrap();
        for name in PROPERTY_FILES {
            std::fs::write(dir.path().join(name), "stale\n").unwrap();
        }
        std::fs::write(dir.path().join("track_bb_log.st"), "3;main\n").unwrap();
        remove_stale_property_files(dir.path());
        let left: Vec<_> = std::fs::read_dir(dir.path())
            .unwrap()
            .map(|e| e.unwrap().file_name())
            .collect();
        assert_eq!(left, ["track_bb_log.st"]);
        // Nothing to remove is not an error.
        remove_stale_property_files(dir.path());
    }

    #[test]
    fn checked_error_matches_c_runtime() {
        let dir = tempfile::tempdir().unwrap();
        write_checked_error(dir.path()).unwrap();
        assert_eq!(
            std::fs::read(dir.path().join("map2check_checked_error")).unwrap(),
            golden("ASSERT", "map2check_checked_error")
        );
    }

    #[test]
    fn trackbb_log_keeps_the_first_row_of_each_line() {
        use crate::bbtrack::BasicBlockEntry;
        let dir = tempfile::tempdir().unwrap();
        let rows = [
            BasicBlockEntry::new(1, 3, "main"),
            BasicBlockEntry::new(2, 4, "main"),
            BasicBlockEntry::new(3, 3, "other"),
        ];
        write_trackbb_log(dir.path(), &rows).unwrap();
        assert_eq!(
            std::fs::read(dir.path().join("track_bb_log.st")).unwrap(),
            golden("ASSERT", "track_bb_log.st")
        );
    }

    #[test]
    fn c_formats_match_glibc() {
        assert_eq!(c_pointer(0), "(nil)");
        assert_eq!(c_pointer(0x1000_0100), "0x10000100");
        assert_eq!(c_double(2.5), "2.500000");
        assert_eq!(c_double(-0.0), "-0.000000");
        assert_eq!(c_double(f64::INFINITY), "inf");
        assert_eq!(c_double(f64::NEG_INFINITY), "-inf");
        assert_eq!(c_double(f64::NAN), "nan");
        assert_eq!(c_double(-f64::NAN), "-nan");
    }

    #[test]
    fn nondet_rows_use_develop_types_and_value_formats() {
        use crate::nondet::c_log::CNondetCall as C;
        use crate::nondet::NonDetValue as V;
        let row = |v: &V| {
            let (kind, bits) = nondet_kind_and_bits(v);
            String::from_utf8(C::from_parts(kind, 0, 0, 0, b"", bits).csv_row(0)).unwrap()
        };
        assert_eq!(row(&V::Int(-1)), "0;0;0;;0;-1;0\n");
        assert_eq!(row(&V::UInt(u32::MAX)), "0;0;0;;0;-1;13\n");
        assert_eq!(row(&V::Long(1 << 32)), "0;0;0;;0;0;4\n");
        assert_eq!(row(&V::Char(-3)), "0;0;0;;0;253;1\n");
        assert_eq!(row(&V::Short(-2)), "0;0;0;;0;65534;14\n");
        assert_eq!(row(&V::Unsigned(u32::MAX)), "0;0;0;;0;4294967295;5\n");
        assert_eq!(row(&V::Pointer(0x1_2345_6789)), "0;0;0;;0;591751049;2\n");
        assert_eq!(row(&V::Float(0.5)), "0;0;0;;0;0.500000;15\n");
        assert_eq!(row(&V::Double(2.5)), "0;0;0;;0;2.500000;15\n");
    }

    /// The `write_property_<x>` helpers of `PropertyGenerator.c`, which the
    /// Rust core keeps private (SD-22): each writes its own file with the
    /// format strings of the C function.
    #[test]
    fn write_property_helpers_match_c_format() {
        let dir = tempfile::tempdir().unwrap();
        let d = dir.path();
        write_property_unknown(d).unwrap(); // :24-28
        write_property_memtrack(d).unwrap(); // :30-34
        write_property_memcleanup(d).unwrap(); // :36-40
        write_property_deref(d, 7, "f").unwrap(); // :42-48
        write_property_free(d, -2, "g").unwrap(); // :108-114
        write_property_overflow(d, 0, "").unwrap(); // :116-122
        write_property_assert(d, i32::MAX, "main").unwrap(); // :124-130
        let read = |name: &str| std::fs::read_to_string(d.join(name)).unwrap();
        assert_eq!(read("map2check_property__unknown"), "UNKNOWN\n");
        assert_eq!(read("map2check_property_memtrack"), "FALSE-MEMTRACK\n");
        assert_eq!(read("map2check_property_memcleanup"), "FALSE-MEMCLEANUP\n");
        assert_eq!(
            read("map2check_property_deref"),
            "FALSE-DEREF\nLine: 7\nFunction: f\n"
        );
        assert_eq!(
            read("map2check_property_free"),
            "FALSE-FREE\nLine: -2\nFunction: g\n"
        );
        assert_eq!(
            read("map2check_property_overflow"),
            "OVERFLOW\nLine: 0\nFunction: \n"
        );
        assert_eq!(
            read("map2check_property_assert"),
            "ASSERT\nLine: 2147483647\nFunction: main\n"
        );
        assert!(
            !d.join(PROPERTY_FILE).exists(),
            "nenhum escreve map2check_property"
        );
    }

    /// `write_property` replaces `map2check_property` and the file of its
    /// own property and leaves every other file alone
    /// (`PropertyGenerator.c:50-106`).
    #[test]
    fn write_property_truncates_only_its_own_files() {
        let dir = tempfile::tempdir().unwrap();
        for name in PROPERTY_FILES {
            std::fs::write(dir.path().join(name), "stale\n").unwrap();
        }
        write_property(dir.path(), ViolatedProperty::Overflow, 3, "main").unwrap();
        for name in PROPERTY_FILES {
            let text = std::fs::read_to_string(dir.path().join(name)).unwrap();
            if name == PROPERTY_FILE || name == "map2check_property_overflow" {
                assert_eq!(text, "OVERFLOW\nLine: 3\nFunction: main\n", "{name}");
            } else {
                assert_eq!(text, "stale\n", "{name}");
            }
        }
    }

    /// `trackbb_log_to_file` (`TrackBBLog.c:35-44`), private in the Rust
    /// core (SD-22): `"%u;" "%s\n"` per row, in order.
    #[test]
    fn trackbb_log_to_file_matches_c_format() {
        use crate::bbtrack::BasicBlockEntry;
        let dir = tempfile::tempdir().unwrap();
        let rows = [
            BasicBlockEntry::new(1, 0, "main"),
            BasicBlockEntry::new(2, u32::MAX, ""),
        ];
        trackbb_log_to_file(dir.path(), &rows).unwrap();
        assert_eq!(
            std::fs::read(dir.path().join(TRACKBB_LOG_FILE)).unwrap(),
            b"0;main\n4294967295;\n"
        );
    }
}
