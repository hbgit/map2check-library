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

/// Text of the verdict, as `write_property` prints it
/// (`PropertyGenerator.c:50-106`), and the extra per-property file the C
/// runtime writes next to `map2check_property`. `line` is printed with
/// `%d`, so it is shown as a C `int`.
fn property_text(result: &AnalysisResult) -> (Option<String>, Option<&'static str>) {
    let located = |tag: &str| {
        format!(
            "{tag}\nLine: {}\nFunction: {}\n",
            result.line as i32, result.function_name
        )
    };
    if result.ok {
        return (Some("NONE\n".to_owned()), None);
    }
    match result.property {
        ViolatedProperty::None => (Some("NONE\n".to_owned()), None),
        ViolatedProperty::MemsafetyFree => {
            (Some(located("FALSE-FREE")), Some("map2check_property_free"))
        }
        ViolatedProperty::MemsafetyDeref => (
            Some(located("FALSE-DEREF")),
            Some("map2check_property_deref"),
        ),
        ViolatedProperty::Overflow => (
            Some(located("OVERFLOW")),
            Some("map2check_property_overflow"),
        ),
        ViolatedProperty::Assert => (Some(located("ASSERT")), Some("map2check_property_assert")),
        ViolatedProperty::MemsafetyMemtrack => (
            Some("FALSE-MEMTRACK\n".to_owned()),
            Some("map2check_property_memtrack"),
        ),
        ViolatedProperty::MemsafetyMemcleanup => (
            Some("FALSE-MEMCLEANUP\n".to_owned()),
            Some("map2check_property_memcleanup"),
        ),
        ViolatedProperty::Reachability => (Some(located("TARGET-REACHED")), None),
        // `:98-102`: no per-property file.
        ViolatedProperty::DivByZero => (Some(located("FALSE-DIVBYZERO")), None),
        // The only UNKNOWN the C runtime reports is `write_property_unknown`
        // (NULL from malloc, AnalysisModeMemtrack.c:305-311): it writes
        // `map2check_property__unknown` and no `map2check_property`.
        // Concurrency has no develop counterpart and is reported the same way.
        ViolatedProperty::Unknown | ViolatedProperty::Concurrency => (None, None),
    }
}

/// Writes the property files of `result` into `dir`, as `write_property`
/// and the `write_property_*` helpers of `PropertyGenerator.c` do.
pub fn write_property_files(dir: &Path, result: &AnalysisResult) -> io::Result<()> {
    let (text, extra) = property_text(result);
    match text {
        Some(text) => {
            std::fs::write(dir.join(PROPERTY_FILE), &text)?;
            if let Some(extra) = extra {
                std::fs::write(dir.join(extra), &text)?;
            }
        }
        None => std::fs::write(dir.join(PROPERTY_FILE_UNKNOWN), "UNKNOWN\n")?,
    }
    Ok(())
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
    std::fs::write(dir.join(CHECKED_ERROR_FILE), "END OF TIME\n")
}

/// `trackbb_log_to_file` (`TrackBBLog.c:35-44`): `%u;%s\n` per row.
/// `map2check_track_bb` keeps only the first block of each line
/// (`Map2CheckFunctions.c:49-55`), so later rows of a line are skipped.
pub fn write_trackbb_log(dir: &Path, rows: &[BasicBlockEntry]) -> io::Result<()> {
    let mut seen = std::collections::HashSet::new();
    let mut out = String::new();
    for row in rows.iter().filter(|r| seen.insert(r.line)) {
        let _ = writeln!(out, "{};{}", row.line, row.function_name);
    }
    std::fs::write(dir.join(TRACKBB_LOG_FILE), out)
}

/// The value column and the `enum NONDET_TYPE` number
/// (`Map2CheckTypes.h:41-58`) of a nondet row, as `nondet_log_to_file`
/// prints them (`NonDetLog.c:45-54`). The `map2check_nondet_*` wrappers take
/// the value as a C `int` (`NonDetLog.c:105-113`), so every integer kind is
/// printed as its low 32 bits with `%d`; a double is printed with `%lf`.
/// `float` has no develop counterpart and is logged as a double.
pub fn nondet_value_and_type(value: &NonDetValue) -> (String, i32) {
    match *value {
        NonDetValue::Int(v) => (v.to_string(), 0),
        NonDetValue::Char(v) => ((v as i32).to_string(), 1),
        NonDetValue::Long(v) => ((v as i32).to_string(), 4),
        NonDetValue::UInt(v) => ((v as i32).to_string(), 13),
        NonDetValue::Float(v) => (c_double(f64::from(v)), 15),
        NonDetValue::Double(v) => (c_double(v), 15),
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
        std::fs::write(dir.join(LIST_LOG_FILE), out)
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
        std::fs::write(dir.join(ALLOCATION_LOG_FILE), out)
    }

    /// `heap_log_to_file` (`HeapLog.c:54-66`).
    pub fn write_heap_log(&self, dir: &Path) -> io::Result<()> {
        let mut out = String::new();
        for r in &self.heap {
            let _ = writeln!(out, "{};{};{}", c_pointer(r.addr), r.name, r.size);
        }
        std::fs::write(dir.join(HEAP_LOG_FILE), out)
    }

    /// `nondet_log_to_file` (`NonDetLog.c:17-60`):
    /// `index;line;scope;function;step;value;type`.
    pub fn write_nondet_log(&self, dir: &Path) -> io::Result<()> {
        let mut out = String::new();
        for (i, r) in self.nondet.iter().enumerate() {
            let (value, kind) = nondet_value_and_type(&r.value);
            let _ = writeln!(
                out,
                "{i};{};{};{};{};{value};{kind}",
                r.line, r.scope, r.function, r.step
            );
        }
        std::fs::write(dir.join(NONDET_LOG_FILE), out)
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
        use crate::nondet::NonDetValue as V;
        assert_eq!(nondet_value_and_type(&V::Int(-1)), ("-1".into(), 0));
        assert_eq!(nondet_value_and_type(&V::UInt(u32::MAX)), ("-1".into(), 13));
        assert_eq!(nondet_value_and_type(&V::Long(1 << 32)), ("0".into(), 4));
        assert_eq!(nondet_value_and_type(&V::Char(-3)), ("-3".into(), 1));
        assert_eq!(
            nondet_value_and_type(&V::Float(0.5)),
            ("0.500000".into(), 15)
        );
        assert_eq!(
            nondet_value_and_type(&V::Double(2.5)),
            ("2.500000".into(), 15)
        );
    }
}
