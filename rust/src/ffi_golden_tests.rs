// SPDX-License-Identifier: GPL-3.0-only
//
// Golden tests of the file channel (#19): each scenario makes, through the
// exports of this library, the calls that a driver in
// `tests/legacy_golden/drivers/` makes on the C runtime of Map2Check
// `develop`, and every file it writes must equal, byte for byte, the file
// that runtime wrote in `tests/legacy_golden/<TAG>/`.
//
// The scenarios end the process (abort on a violation, as develop does), so
// each one runs in a child process: the parent re-runs this test binary
// filtered to one `*_child` test, with `MAP2CHECK_TEST_OUTPUT_DIR` pointing to
// a fresh temporary directory, and then compares the files. Without that
// variable a test build writes no files and never aborts
// (`output::termination::output_dir`).

use std::collections::{BTreeMap, BTreeSet};
use std::os::raw::{c_char, c_long, c_void};
use std::os::unix::process::ExitStatusExt;
use std::path::Path;

use super::*;
use crate::analysismode::mode::AnalysisMode;

const CHILD_ENV: &str = "MAP2CHECK_GOLDEN_CHILD";
const STARTED: &str = "map2check-golden-child-started";
const RETURNED: &str = "map2check-golden-child-returned";

/// Fixed addresses of `tests/legacy_golden/drivers/golden.h`.
const ARENA: usize = 0x1000_0000;
const SLOT_P: usize = ARENA;
const FN_MAIN: usize = ARENA + 0x40;
const BLOCK: usize = ARENA + 0x100;
const WILD: usize = ARENA + 0x800;
const SLOT_Q: usize = ARENA + 0x8;
const BLOCK2: usize = ARENA + 0x200;
const ARENA_SIZE: usize = 4096;

extern "C" {
    fn mmap(addr: *mut c_void, len: usize, prot: i32, flags: i32, fd: i32, off: i64)
        -> *mut c_void;
}

/// `golden_arena()`: maps the arena at its fixed address, for the scenarios
/// whose export reads memory (`map2check_map_posix_memalign` reads the
/// `void *` slot, as develop's `map2check_posix` does).
fn map_arena() {
    const PROT_READ_WRITE: i32 = 0x1 | 0x2;
    const MAP_PRIVATE_ANONYMOUS_FIXED_NOREPLACE: i32 = 0x02 | 0x20 | 0x10_0000;
    // SAFETY: an anonymous private mapping at an address that must be free
    // (MAP_FIXED_NOREPLACE fails instead of replacing a mapping).
    let arena = unsafe {
        mmap(
            ARENA as *mut c_void,
            ARENA_SIZE,
            PROT_READ_WRITE,
            MAP_PRIVATE_ANONYMOUS_FIXED_NOREPLACE,
            -1,
            0,
        )
    };
    assert_eq!(arena as usize, ARENA, "não foi possível mapear a arena");
}

fn addr(a: usize) -> *const c_void {
    a as *const c_void
}

fn is_child() -> bool {
    std::env::var_os(CHILD_ENV).is_some()
}

/// Runs `ffi::golden_tests::<name>` in a child process whose output
/// directory is `dir`.
fn run_child(name: &str, dir: &Path) -> std::process::Output {
    run_child_with(name, dir, &[])
}

/// [`run_child`] with extra environment variables for the child.
fn run_child_with(name: &str, dir: &Path, envs: &[(&str, &str)]) -> std::process::Output {
    let exe = std::env::current_exe().unwrap();
    let output = std::process::Command::new(exe)
        .args(["--exact", &format!("ffi::golden_tests::{name}")])
        .args(["--nocapture", "--test-threads=1"])
        .env(CHILD_ENV, "1")
        .env(crate::output::termination::OUTPUT_DIR_ENV, dir)
        .envs(envs.iter().copied())
        .output()
        .unwrap();
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(
        stdout.contains(STARTED),
        "o processo filho não rodou `{name}`:\n{stdout}"
    );
    output
}

/// Names of the regular files in `dir`, without the `.exit_status` marker.
fn files_in(dir: &Path) -> BTreeSet<String> {
    std::fs::read_dir(dir)
        .unwrap()
        .map(|e| e.unwrap().file_name().into_string().unwrap())
        .filter(|name| name != ".exit_status")
        .collect()
}

/// With a mode set the library writes nothing to stdout (no JSON report):
/// after the start marker the child prints nothing until it aborts, or
/// until the `RETURNED` marker printed right after `map2check_success()`.
fn assert_quiet_stdout(stdout: &str, aborted: bool) {
    assert!(
        !stdout.contains("map2check_log"),
        "JSON no stdout:\n{stdout}"
    );
    let after = stdout
        .split_once(STARTED)
        .map(|(_, rest)| rest)
        .expect("marcador de início");
    let produced = if aborted {
        after
    } else {
        after
            .split_once(RETURNED)
            .map(|(before, _)| before)
            .expect("marcador de retorno")
    };
    assert_eq!(produced, "\n", "saída inesperada no stdout:\n{stdout}");
}

/// Runs the `<child>` scenario and compares its files and its end with
/// `tests/legacy_golden/<tag>/`.
fn assert_matches_golden(tag: &str, child: &str) {
    assert_matches_golden_except(tag, child, &[]);
}

/// [`assert_matches_golden`], except that the content of the files named in
/// `skip_content` is not compared (they must still exist).
fn assert_matches_golden_except(tag: &str, child: &str, skip_content: &[&str]) {
    let golden = Path::new(env!("CARGO_MANIFEST_DIR"))
        .join("tests/legacy_golden")
        .join(tag);
    let dir = tempfile::tempdir().unwrap();
    let output = run_child(child, dir.path());
    let stdout = String::from_utf8_lossy(&output.stdout);
    let stderr = String::from_utf8_lossy(&output.stderr);

    let status = std::fs::read_to_string(golden.join(".exit_status")).unwrap();
    match status.trim() {
        "134" => assert_eq!(
            output.status.signal(),
            Some(6),
            "{tag}: esperava SIGABRT\n{stdout}\n{stderr}"
        ),
        "0" => assert_eq!(
            output.status.code(),
            Some(0),
            "{tag}: esperava saída 0\n{stdout}\n{stderr}"
        ),
        other => panic!("{tag}: .exit_status inesperado `{other}`"),
    }

    assert_quiet_stdout(&stdout, status.trim() == "134");

    assert_eq!(
        files_in(dir.path()),
        files_in(&golden),
        "{tag}: conjunto de arquivos"
    );
    for name in files_in(&golden) {
        if skip_content.contains(&name.as_str()) {
            continue;
        }
        let expected = std::fs::read(golden.join(&name)).unwrap();
        let actual = std::fs::read(dir.path().join(&name)).unwrap();
        assert_eq!(
            String::from_utf8_lossy(&actual),
            String::from_utf8_lossy(&expected),
            "{tag}/{name}"
        );
        assert_eq!(actual, expected, "{tag}/{name} (bytes)");
    }
}

/// `golden_tracking()`: basic blocks (one repeated line) and one nondet value
/// of each kind.
fn tracking() {
    let mut int_value: i32 = 42;
    let mut uint_value: u32 = 4_000_000_000;
    let mut char_value: c_char = -3;
    let mut long_value: c_long = -7;
    let mut double_value: f64 = 2.5;
    // SAFETY: the values outlive the calls; the names are C-string literals.
    unsafe {
        map2check_track_bb(3, c"main".as_ptr());
        map2check_track_bb(4, c"main".as_ptr());
        map2check_track_bb(3, c"main".as_ptr());
        map2check_save_nondet_log_int(5, 0, 0, &mut int_value, c"main".as_ptr());
        map2check_save_nondet_log_uint(6, 0, 13, &mut uint_value, c"main".as_ptr());
        map2check_save_nondet_log_char(7, 0, 1, &mut char_value, c"main".as_ptr());
        map2check_save_nondet_log_long(8, 0, 4, &mut long_value, c"main".as_ptr());
        map2check_save_nondet_log_double(9, 0, 15, &mut double_value, c"main".as_ptr());
    }
}

/// `golden_memory()`: `int *p` (8-byte slot), `&main`, `p = malloc(16)`.
fn memory() {
    // SAFETY: fake addresses are never dereferenced; names are C strings.
    unsafe {
        map2check_map_alloca(c"p".as_ptr(), addr(SLOT_P), 8, 8, 10, 1);
        map2check_map_funct_address(c"main".as_ptr(), addr(FN_MAIN));
        map2check_map_malloc(addr(BLOCK), 16);
        map2check_map_store_pointer(
            addr(SLOT_P),
            addr(BLOCK),
            1,
            c"p".as_ptr(),
            11,
            c"main".as_ptr(),
        );
    }
}

/// `free(p)` at `line` as the pass emits it for a free of a load of `p`:
/// the check, then the release, both with the slot of `p` and the block.
fn free_p_at(line: u32) {
    // SAFETY: as in `memory`.
    unsafe {
        map2check_check_free(
            c"p".as_ptr(),
            addr(SLOT_P),
            addr(BLOCK),
            1,
            line,
            c"main".as_ptr(),
        );
        map2check_map_free(
            c"p".as_ptr(),
            addr(SLOT_P),
            addr(BLOCK),
            1,
            line,
            c"main".as_ptr(),
        );
    }
}

fn free_p() {
    free_p_at(12);
}

/// Starts the analysis as the instrumented witness binary does.
fn start(mode: AnalysisMode) {
    println!("{STARTED}");
    map2check_set_mode(mode as i32);
    map2check_enable_witness();
    map2check_init(0);
    tracking();
}

#[test]
fn false_free_child() {
    if is_child() {
        start(AnalysisMode::Memtrack);
        memory();
        free_p();
        // The second free fails in the check, after which develop's
        // `map2check_free` has already appended its FREE row.
        free_p_at(13);
        map2check_success();
    }
}

#[test]
fn false_free_matches_c_runtime() {
    assert_matches_golden("FALSE-FREE", "false_free_child");
}

#[test]
fn false_free_resolved_child() {
    if is_child() {
        start(AnalysisMode::Memtrack);
        memory();
        free_p();
        // SAFETY: as in `memory`.
        unsafe { map2check_check_free_resolved_address(addr(BLOCK), 13, c"main".as_ptr(), 0) };
        map2check_success();
    }
}

#[test]
fn false_free_resolved_matches_c_runtime() {
    assert_matches_golden("FALSE-FREE-RESOLVED", "false_free_resolved_child");
}

#[test]
fn false_deref_child() {
    if is_child() {
        start(AnalysisMode::Memtrack);
        memory();
        // SAFETY: as in `memory`.
        unsafe { map2check_check_load(addr(WILD), 14, 0, 4, c"main".as_ptr()) };
        map2check_success();
    }
}

#[test]
fn false_deref_matches_c_runtime() {
    assert_matches_golden("FALSE-DEREF", "false_deref_child");
}

#[test]
fn false_memtrack_child() {
    if is_child() {
        start(AnalysisMode::Memtrack);
        memory();
        map2check_success();
    }
}

#[test]
fn false_memtrack_matches_c_runtime() {
    assert_matches_golden("FALSE-MEMTRACK", "false_memtrack_child");
}

#[test]
fn false_memcleanup_child() {
    if is_child() {
        start(AnalysisMode::Memcleanup);
        memory();
        map2check_success();
    }
}

#[test]
fn false_memcleanup_matches_c_runtime() {
    assert_matches_golden("FALSE-MEMCLEANUP", "false_memcleanup_child");
}

#[test]
fn none_child() {
    if is_child() {
        start(AnalysisMode::Memtrack);
        memory();
        free_p();
        map2check_success();
        println!("{RETURNED}");
    }
}

#[test]
fn none_matches_c_runtime() {
    assert_matches_golden("NONE", "none_child");
}

#[test]
fn unknown_child() {
    if is_child() {
        start(AnalysisMode::Memtrack);
        memory();
        // SAFETY: a NULL block is only compared, never dereferenced.
        unsafe { map2check_map_malloc(std::ptr::null(), 4) };
        map2check_success();
    }
}

#[test]
fn unknown_matches_c_runtime() {
    assert_matches_golden("UNKNOWN", "unknown_child");
}

#[test]
fn overflow_child() {
    if is_child() {
        start(AnalysisMode::Overflow);
        // SAFETY: C-string literal is valid.
        unsafe { map2check_binop_add_int(i32::MAX, 1, 20, 0, c"main".as_ptr()) };
        map2check_success();
    }
}

#[test]
fn overflow_matches_c_runtime() {
    assert_matches_golden("OVERFLOW", "overflow_child");
}

#[test]
fn div_by_zero_child() {
    if is_child() {
        start(AnalysisMode::Overflow);
        // SAFETY: C-string literal is valid.
        unsafe { map2check_binop_div_signed(7, 0, 32, 23, c"main".as_ptr()) };
        map2check_success();
    }
}

#[test]
fn div_by_zero_matches_c_runtime() {
    assert_matches_golden("DIVBYZERO", "div_by_zero_child");
}

#[test]
fn posix_memalign_child() {
    if is_child() {
        map_arena();
        start(AnalysisMode::Memtrack);
        memory();
        // SAFETY: SLOT_Q lies in the mapped arena; the names are C strings.
        unsafe {
            map2check_map_alloca(c"q".as_ptr(), addr(SLOT_Q), 8, 8, 15, 1);
            (SLOT_Q as *mut usize).write(BLOCK2);
            map2check_map_posix_memalign(addr(SLOT_Q), 32);
        }
        map2check_success();
    }
}

#[test]
fn posix_memalign_matches_c_runtime() {
    assert_matches_golden("POSIX-MEMALIGN", "posix_memalign_child");
}

#[test]
fn assert_child() {
    if is_child() {
        start(AnalysisMode::Assert);
        // SAFETY: C-string literal is valid.
        unsafe { map2check_is_valid_assert(21, c"main".as_ptr(), 0) };
        map2check_success();
    }
}

#[test]
fn assert_matches_c_runtime() {
    assert_matches_golden("ASSERT", "assert_child");
}

#[test]
fn target_reached_child() {
    if is_child() {
        start(AnalysisMode::Target);
        // SAFETY: C-string literal is valid.
        unsafe { map2check_reach_target(c"reach_error".as_ptr(), 0, 22) };
        map2check_success();
    }
}

#[test]
fn target_reached_matches_c_runtime() {
    assert_matches_golden("TARGET-REACHED", "target_reached_child");
}

/// `drivers/NONDET-TYPES.c`: one nondet value of every develop type, each
/// handed to its `map2check_save_nondet_log_<t>` in its own C type, then a
/// failed assert, so the witness writes `klee_log.csv`.
#[test]
fn nondet_types_child() {
    if is_child() {
        start(AnalysisMode::Assert);
        let f = c"f".as_ptr();
        let mut int_v: i32 = -5;
        let mut unsigned_v: u32 = 4_000_000_000;
        let mut char_v: c_char = -3;
        let mut pointer_v: *mut c_void = 0x1_2345_6789_usize as *mut c_void;
        let mut long_v: c_long = -7;
        let mut ushort_v: u16 = 65535;
        let mut short_v: i16 = -2;
        let mut ulong_v: std::os::raw::c_ulong = 0xFFFF_FFFF_8000_0000;
        let mut bool_v: i32 = 1;
        let mut uchar_v: u8 = 200;
        let mut pchar_v: *mut c_char = 0x7fff_1234_5678_usize as *mut c_char;
        let mut size_t_v: usize = 5_000_000_000;
        let mut loff_t_v: i64 = -1;
        let mut sector_t_v: std::os::raw::c_ulong = 0x1_0000_0009;
        let mut uint_v: u32 = 4_000_000_000;
        let mut double_v: f64 = -0.125;
        // SAFETY: every value outlives its call; the pointers are only
        // recorded, never dereferenced; `f` is a C-string literal.
        unsafe {
            map2check_save_nondet_log_int(30, 1, 0, &mut int_v, f);
            map2check_save_nondet_log_unsigned(31, 1, 5, &mut unsigned_v, f);
            map2check_save_nondet_log_char(32, 1, 1, &mut char_v, f);
            map2check_save_nondet_log_pointer(33, 1, 2, &mut pointer_v, f);
            map2check_save_nondet_log_long(34, 1, 4, &mut long_v, f);
            map2check_save_nondet_log_ushort(35, 1, 3, &mut ushort_v, f);
            map2check_save_nondet_log_short(36, 1, 14, &mut short_v, f);
            map2check_save_nondet_log_ulong(37, 1, 6, &mut ulong_v, f);
            map2check_save_nondet_log_bool(38, 1, 7, &mut bool_v, f);
            map2check_save_nondet_log_uchar(39, 1, 8, &mut uchar_v, f);
            map2check_save_nondet_log_pchar(40, 1, 9, &mut pchar_v, f);
            map2check_save_nondet_log_size_t(41, 1, 10, &mut size_t_v, f);
            map2check_save_nondet_log_loff_t(42, 1, 11, &mut loff_t_v, f);
            map2check_save_nondet_log_sector_t(43, 1, 12, &mut sector_t_v, f);
            map2check_save_nondet_log_uint(44, 1, 13, &mut uint_v, f);
            map2check_save_nondet_log_double(45, 1, 15, &mut double_v, f);
            map2check_is_valid_assert(46, f, 0);
        }
        map2check_success();
    }
}

#[test]
fn nondet_types_match_c_runtime() {
    assert_matches_golden("NONDET-TYPES", "nondet_types_child");
}

// ── Without witness: property files only (WitnessGenerationNone.c) ──────────

#[test]
fn overflow_without_witness_child() {
    if is_child() {
        println!("{STARTED}");
        map2check_set_mode(AnalysisMode::Overflow as i32);
        map2check_init(0);
        tracking();
        // SAFETY: C-string literal is valid.
        unsafe { map2check_binop_add_int(i32::MAX, 1, 20, 0, c"main".as_ptr()) };
        println!("map2check-golden-child-survived");
    }
}

#[test]
fn without_witness_a_violation_writes_only_property_files_and_aborts() {
    let dir = tempfile::tempdir().unwrap();
    let output = run_child("overflow_without_witness_child", dir.path());
    assert_eq!(output.status.signal(), Some(6));
    assert!(!String::from_utf8_lossy(&output.stdout).contains("survived"));
    assert_eq!(
        files_in(dir.path()),
        BTreeSet::from([
            "map2check_property".to_owned(),
            "map2check_property_overflow".to_owned()
        ])
    );
}

#[test]
fn success_without_witness_child() {
    if is_child() {
        println!("{STARTED}");
        map2check_set_mode(AnalysisMode::Memtrack as i32);
        map2check_init(0);
        tracking();
        memory();
        free_p();
        map2check_success();
        println!("{RETURNED}");
    }
}

#[test]
fn without_witness_success_writes_none_and_returns() {
    let dir = tempfile::tempdir().unwrap();
    let output = run_child("success_without_witness_child", dir.path());
    assert_eq!(output.status.code(), Some(0));
    assert!(String::from_utf8_lossy(&output.stdout).contains(RETURNED));
    assert_eq!(
        files_in(dir.path()),
        BTreeSet::from(["map2check_property".to_owned()])
    );
    assert_eq!(
        std::fs::read(dir.path().join("map2check_property")).unwrap(),
        b"NONE\n"
    );
}

// ── Stale property files and the unset mode ─────────────────────────────────

/// develop's `map2check_init` touches no file (`Map2CheckFunctions.c:29-40`)
/// and `write_property` truncates only the files of the property it writes
/// (`PropertyGenerator.c:50-106`): property files of an earlier run in the
/// same directory stay, and `map2check_property` is replaced.
#[test]
fn property_files_of_an_earlier_run_are_kept_as_c_does_child() {
    if is_child() {
        println!("{STARTED}");
        map2check_set_mode(AnalysisMode::Assert as i32);
        map2check_init(0);
        map2check_success();
        println!("{RETURNED}");
    }
}

#[test]
fn property_files_of_an_earlier_run_are_kept_as_c_does() {
    let dir = tempfile::tempdir().unwrap();
    for name in crate::output::legacy_files::PROPERTY_FILES {
        std::fs::write(dir.path().join(name), "stale\n").unwrap();
    }
    let output = run_child(
        "property_files_of_an_earlier_run_are_kept_as_c_does_child",
        dir.path(),
    );
    assert_eq!(output.status.code(), Some(0));
    for name in crate::output::legacy_files::PROPERTY_FILES {
        let expected: &[u8] = if name == "map2check_property" {
            b"NONE\n"
        } else {
            b"stale\n"
        };
        assert_eq!(
            std::fs::read(dir.path().join(name)).unwrap(),
            expected,
            "{name}"
        );
    }
}

#[test]
fn unset_mode_records_without_files_or_abort_child() {
    if is_child() {
        println!("{STARTED}");
        map2check_enable_witness();
        map2check_init(0);
        // SAFETY: C-string literal is valid.
        unsafe { map2check_binop_add_int(i32::MAX, 1, 20, 0, c"main".as_ptr()) };
        assert_eq!(
            get_current_property(),
            crate::caller::ViolatedProperty::Overflow
        );
        map2check_success();
        println!("{RETURNED}");
    }
}

#[test]
fn unset_mode_records_without_files_or_abort() {
    let dir = tempfile::tempdir().unwrap();
    std::fs::write(dir.path().join("map2check_property_free"), "stale\n").unwrap();
    let output = run_child(
        "unset_mode_records_without_files_or_abort_child",
        dir.path(),
    );
    assert_eq!(output.status.code(), Some(0));
    assert!(String::from_utf8_lossy(&output.stdout).contains(RETURNED));
    assert_eq!(
        files_in(dir.path()),
        BTreeSet::from(["map2check_property_free".to_owned()])
    );
}

// ── No JSON on stdout with a mode set; a poisoned state is UNKNOWN ─────────

#[test]
fn assert_violation_without_witness_child() {
    if is_child() {
        println!("{STARTED}");
        map2check_set_mode(AnalysisMode::Assert as i32);
        map2check_init(0);
        print_all_containers_as_json();
        // SAFETY: C-string literal is valid.
        unsafe { map2check_is_valid_assert(21, c"main".as_ptr(), 0) };
        println!("map2check-golden-child-survived");
    }
}

#[test]
fn assert_violation_with_mode_set_writes_files_aborts_and_prints_no_json() {
    let dir = tempfile::tempdir().unwrap();
    let output = run_child("assert_violation_without_witness_child", dir.path());
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(output.status.signal(), Some(6), "{stdout}");
    assert_quiet_stdout(&stdout, true);
    assert_eq!(
        files_in(dir.path()),
        BTreeSet::from([
            "map2check_property".to_owned(),
            "map2check_property_assert".to_owned()
        ])
    );
    assert_eq!(
        std::fs::read(dir.path().join("map2check_property_assert")).unwrap(),
        b"ASSERT\nLine: 21\nFunction: main\n"
    );
}

#[test]
fn poisoned_state_at_success_child() {
    if is_child() {
        println!("{STARTED}");
        map2check_set_mode(AnalysisMode::Memtrack as i32);
        map2check_enable_witness();
        map2check_init(0);
        let _ = std::thread::spawn(|| {
            let _held = crate::state::get().unwrap().lock().unwrap();
            panic!("poison the analysis state on purpose");
        })
        .join();
        map2check_success();
        println!("map2check-golden-child-survived");
    }
}

#[test]
fn poisoned_state_at_success_reports_unknown_and_aborts() {
    let dir = tempfile::tempdir().unwrap();
    let output = run_child("poisoned_state_at_success_child", dir.path());
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(output.status.signal(), Some(6), "{stdout}");
    assert!(!stdout.contains("survived"), "{stdout}");
    // No NONE left behind: develop's UNKNOWN (SD-16) plus the confirmation.
    assert_eq!(
        files_in(dir.path()),
        BTreeSet::from([
            "map2check_property__unknown".to_owned(),
            "map2check_checked_error".to_owned()
        ])
    );
}

// ── C ABI of Map2CheckFunctions, TrackBBLog, PropertyGenerator and the
//    witness (Task 2.1) ─────────────────────────────────────────────────────

/// `drivers/TARGET-REACHED.c` with the C entry point the target pass emits,
/// `map2check_target_function` (`Map2CheckFunctions.c:61-65`).
#[test]
fn target_function_child() {
    if is_child() {
        start(AnalysisMode::Target);
        // SAFETY: C-string literal is valid.
        unsafe { map2check_target_function(c"reach_error".as_ptr(), 0, 22) };
        map2check_success();
    }
}

#[test]
fn target_function_matches_c_runtime() {
    assert_matches_golden("TARGET-REACHED", "target_function_child");
}

/// `drivers/FALSE-MEMTRACK.c` ending with `map2check_exit` instead of
/// `map2check_success`: with no error the verdict runs (`:89-92`), and
/// memtrack's `analysis_is_program_correct` writes FALSE-MEMTRACK
/// (`AnalysisModeMemtrack.c:138-146`). `map2check_success` only writes
/// `NONE` first, which that verdict replaces, so the files are the golden's.
#[test]
fn map2check_exit_child() {
    if is_child() {
        start(AnalysisMode::Memtrack);
        memory();
        map2check_exit();
    }
}

#[test]
fn map2check_exit_matches_c_runtime() {
    assert_matches_golden("FALSE-MEMTRACK", "map2check_exit_child");
}

/// `map2check_exit` of a correct run writes no property file (only
/// `map2check_success` writes `NONE`), writes the aux files and returns.
#[test]
fn map2check_exit_without_error_returns_child() {
    if is_child() {
        start(AnalysisMode::Assert);
        map2check_exit();
        println!("{RETURNED}");
    }
}

#[test]
fn map2check_exit_without_error_returns() {
    let dir = tempfile::tempdir().unwrap();
    let output = run_child("map2check_exit_without_error_returns_child", dir.path());
    assert_eq!(output.status.code(), Some(0));
    assert_quiet_stdout(&String::from_utf8_lossy(&output.stdout), false);
    assert_eq!(
        files_in(dir.path()),
        BTreeSet::from(["track_bb_log.st".to_owned()])
    );
}

/// `map2check_error` (`:72-75`): `gotError`, then `map2check_exit` skips the
/// verdict, writes the aux files with the nondet log (a violation), the
/// confirmation file, and aborts. No property file: the caller writes it.
#[test]
fn map2check_error_child() {
    if is_child() {
        start(AnalysisMode::Assert);
        map2check_error();
        println!("map2check-golden-child-survived");
    }
}

#[test]
fn map2check_error_writes_the_witness_files_and_aborts() {
    let golden = Path::new(env!("CARGO_MANIFEST_DIR")).join("tests/legacy_golden/ASSERT");
    let dir = tempfile::tempdir().unwrap();
    let output = run_child("map2check_error_child", dir.path());
    assert_eq!(output.status.signal(), Some(6), "esperava SIGABRT");
    assert_quiet_stdout(&String::from_utf8_lossy(&output.stdout), true);
    assert_eq!(
        files_in(dir.path()),
        BTreeSet::from([
            "klee_log.csv".to_owned(),
            "map2check_checked_error".to_owned(),
            "track_bb_log.st".to_owned(),
        ])
    );
    for name in files_in(dir.path()) {
        assert_eq!(
            std::fs::read(dir.path().join(&name)).unwrap(),
            std::fs::read(golden.join(&name)).unwrap(),
            "{name}"
        );
    }
}

/// The values `write_property` takes, by the number the parent passes in
/// `M2C_PROPERTY` (the C value of `enum ViolatedProperty`).
fn property_by_c_value(value: i32) -> crate::caller::ViolatedProperty {
    use crate::caller::ViolatedProperty as P;
    [
        P::None,
        P::Unknown,
        P::MemsafetyFree,
        P::MemsafetyDeref,
        P::MemsafetyMemtrack,
        P::Reachability,
        P::Overflow,
        P::Assert,
        P::MemsafetyMemcleanup,
        P::DivByZero,
        P::Concurrency,
    ]
    .into_iter()
    .find(|p| *p as i32 == value)
    .unwrap()
}

#[test]
fn property_file_child() {
    if is_child() {
        println!("{STARTED}");
        let value: i32 = std::env::var("M2C_PROPERTY").unwrap().parse().unwrap();
        let line: i32 = std::env::var("M2C_LINE").unwrap().parse().unwrap();
        // No mode, no init: `write_property` writes whatever the state.
        // SAFETY: C-string literal is valid.
        unsafe { write_property(property_by_c_value(value), line, c"main".as_ptr()) };
        println!("{RETURNED}");
    }
}

/// The files a scenario must leave, by name, with their contents.
type ExpectedFiles = Vec<(&'static str, String)>;

/// `write_property(prp, line, "main")` writes exactly what
/// `PropertyGenerator.c` writes for the same call, byte for byte: the
/// `fprintf` format strings of `:50-106` for `map2check_property` and of the
/// `write_property_<x>` helper each case calls (`:24-48`, `:108-130`) for
/// `map2check_property_<prp>`, with `Line: %d` and `Function: %s`. A value
/// outside the C switch (`Concurrency`, 10) leaves `map2check_property`
/// opened with `"w"` and closed: an empty file.
#[test]
fn property_file_matches_c_format() {
    let located = |tag: &str, line: i32| format!("{tag}\nLine: {line}\nFunction: main\n");
    let cases: Vec<(i32, i32, ExpectedFiles)> = vec![
        // :55-57
        (0, 42, vec![("map2check_property", "NONE\n".into())]),
        // :58-60
        (1, 42, vec![("map2check_property", "UNKNOWN\n".into())]),
        // :61-66 and write_property_free :108-114
        (
            2,
            42,
            vec![
                ("map2check_property", located("FALSE-FREE", 42)),
                ("map2check_property_free", located("FALSE-FREE", 42)),
            ],
        ),
        // :67-72 and write_property_deref :42-48
        (
            3,
            -1,
            vec![
                ("map2check_property", located("FALSE-DEREF", -1)),
                ("map2check_property_deref", located("FALSE-DEREF", -1)),
            ],
        ),
        // :73-76 and write_property_memtrack :30-34
        (
            4,
            42,
            vec![
                ("map2check_property", "FALSE-MEMTRACK\n".into()),
                ("map2check_property_memtrack", "FALSE-MEMTRACK\n".into()),
            ],
        ),
        // :81-85
        (
            5,
            42,
            vec![("map2check_property", located("TARGET-REACHED", 42))],
        ),
        // :86-91 and write_property_overflow :116-122
        (
            6,
            42,
            vec![
                ("map2check_property", located("OVERFLOW", 42)),
                ("map2check_property_overflow", located("OVERFLOW", 42)),
            ],
        ),
        // :92-97 and write_property_assert :124-130
        (
            7,
            42,
            vec![
                ("map2check_property", located("ASSERT", 42)),
                ("map2check_property_assert", located("ASSERT", 42)),
            ],
        ),
        // :77-80 and write_property_memcleanup :36-40
        (
            8,
            42,
            vec![
                ("map2check_property", "FALSE-MEMCLEANUP\n".into()),
                ("map2check_property_memcleanup", "FALSE-MEMCLEANUP\n".into()),
            ],
        ),
        // :98-102
        (
            9,
            42,
            vec![("map2check_property", located("FALSE-DIVBYZERO", 42))],
        ),
        // no case of the switch
        (10, 42, vec![("map2check_property", String::new())]),
    ];
    for (value, line, expected) in cases {
        let dir = tempfile::tempdir().unwrap();
        let (value_s, line_s) = (value.to_string(), line.to_string());
        let output = run_child_with(
            "property_file_child",
            dir.path(),
            &[("M2C_PROPERTY", &value_s), ("M2C_LINE", &line_s)],
        );
        assert_eq!(output.status.code(), Some(0), "valor {value}");
        assert_eq!(
            files_in(dir.path()),
            expected
                .iter()
                .map(|(n, _)| (*n).to_owned())
                .collect::<BTreeSet<_>>(),
            "valor {value}"
        );
        for (name, text) in expected {
            assert_eq!(
                std::fs::read(dir.path().join(name)).unwrap(),
                text.as_bytes(),
                "valor {value}: {name}"
            );
        }
    }
}

#[test]
fn track_bb_log_child() {
    if is_child() {
        println!("{STARTED}");
        map2check_init(0);
        // SAFETY: C-string literals are valid; a NULL log pointer is
        // accepted (D7: the core reads its own log).
        unsafe {
            map2check_track_bb(3, c"main".as_ptr());
            map2check_track_bb(4, c"main".as_ptr());
            map2check_track_bb(3, c"other".as_ptr());
            map2check_track_bb(u32::MAX, c"f".as_ptr());
            __m2c_rt_witness_generate_aux_files(std::ptr::null_mut(), 0);
        }
        println!("{RETURNED}");
    }
}

/// `track_bb_log.st` as `trackbb_log_to_file` writes it
/// (`TrackBBLog.c:35-44`): one row per tracked line, in order, printed with
/// `"%u;"` then `"%s\n"` (`:40-41`); `map2check_track_bb` tracks a line once
/// (`Map2CheckFunctions.c:49-55`, `is_in_tracked` `TrackBBLog.c:23-33`).
#[test]
fn track_bb_log_matches_c_format() {
    let dir = tempfile::tempdir().unwrap();
    let output = run_child("track_bb_log_child", dir.path());
    assert_eq!(output.status.code(), Some(0));
    // No mode: no memory logs; no violation: no nondet log
    // (`WitnessGeneration.c:15-29`).
    assert_eq!(
        files_in(dir.path()),
        BTreeSet::from(["track_bb_log.st".to_owned()])
    );
    assert_eq!(
        std::fs::read(dir.path().join("track_bb_log.st")).unwrap(),
        b"3;main\n4;main\n4294967295;f\n"
    );
}

#[test]
fn generate_aux_files_child() {
    if is_child() {
        println!("{STARTED}");
        map2check_set_mode(AnalysisMode::Memtrack as i32);
        map2check_init(0);
        tracking();
        memory();
        let violation: i8 = std::env::var("M2C_VIOLATION").unwrap().parse().unwrap();
        // SAFETY: a NULL log pointer is accepted (D7).
        unsafe { __m2c_rt_witness_generate_aux_files(std::ptr::null_mut(), violation) };
        println!("{RETURNED}");
    }
}

/// Extra environment variables of a child.
type Envs = &'static [(&'static str, &'static str)];

/// `generate_aux_files` (`WitnessGeneration.c:15-29`): the block log, the
/// logs of the mode (memtrack: `AnalysisModeMemtrack.c:148-152`) and the
/// nondet log only for a violation or when `MAP2CHECK_SEED_REPLAY` is set.
/// It writes whether or not `map2check_enable_witness` was called: the
/// IR module `WitnessGeneration.bc` calls it only in witness builds (D7).
#[test]
fn generate_aux_files_writes_the_nondet_log_on_violation_or_seed_replay() {
    let base = [
        "allocation_log.csv",
        "heap_log.csv",
        "list_log.csv",
        "track_bb_log.st",
    ];
    let cases: [(&str, Envs, bool); 3] = [
        ("0", &[], false),
        ("1", &[], true),
        ("0", &[("MAP2CHECK_SEED_REPLAY", "")], true),
    ];
    for (violation, extra, nondet) in cases {
        let dir = tempfile::tempdir().unwrap();
        let mut envs = vec![("M2C_VIOLATION", violation)];
        envs.extend_from_slice(extra);
        let output = run_child_with("generate_aux_files_child", dir.path(), &envs);
        assert_eq!(output.status.code(), Some(0));
        let mut expected: BTreeSet<String> = base.iter().map(|n| (*n).to_owned()).collect();
        if nondet {
            expected.insert("klee_log.csv".to_owned());
        }
        assert_eq!(files_in(dir.path()), expected, "{violation} {extra:?}");
    }
    // The bytes are develop's: the logs of `drivers/FALSE-MEMTRACK.c` (the
    // same calls) before its end-of-program verdict, which only appends the
    // release row `0x10000100;0;1` to the allocation log
    // (`AllocationLog.c:69-101`); `allocation_log_to_file` prints
    // `"%p;" "%u;" "%d\n"` (`:169-171`).
    let dir = tempfile::tempdir().unwrap();
    run_child_with(
        "generate_aux_files_child",
        dir.path(),
        &[("M2C_VIOLATION", "0")],
    );
    let golden = Path::new(env!("CARGO_MANIFEST_DIR")).join("tests/legacy_golden/FALSE-MEMTRACK");
    for name in ["heap_log.csv", "list_log.csv", "track_bb_log.st"] {
        assert_eq!(
            std::fs::read(dir.path().join(name)).unwrap(),
            std::fs::read(golden.join(name)).unwrap(),
            "{name}"
        );
    }
    assert_eq!(
        std::fs::read(dir.path().join("allocation_log.csv")).unwrap(),
        b"0x10000100;16;0\n"
    );
}

#[test]
fn generate_confirmation_file_child() {
    if is_child() {
        println!("{STARTED}");
        __m2c_rt_witness_generate_confirmation_file();
        println!("{RETURNED}");
    }
}

/// `generate_confirmation_file` (`WitnessGeneration.c:32-36`).
#[test]
fn generate_confirmation_file_matches_c_format() {
    let dir = tempfile::tempdir().unwrap();
    let output = run_child("generate_confirmation_file_child", dir.path());
    assert_eq!(output.status.code(), Some(0));
    assert_eq!(
        files_in(dir.path()),
        BTreeSet::from(["map2check_checked_error".to_owned()])
    );
    assert_eq!(
        std::fs::read(dir.path().join("map2check_checked_error")).unwrap(),
        b"END OF TIME\n"
    );
}

// ── AnalysisModeOverflow through the core entry points (Task 2.3, D7) ───────
//
// The IR module `AnalysisModeOverflow.bc` forwards the C names to these
// entry points. The C drivers `drivers/OVERFLOW.c` and `drivers/DIVBYZERO.c`
// call develop's `map2check_binop_add` / `map2check_binop_sdiv` with exactly
// these arguments, so the C goldens apply unchanged.

/// Starts a run as the drop-in runtime does: `map2check_init` (which in C
/// calls `analysis_init`, `Map2CheckFunctions.c:29-40`), then the overflow
/// module's `analysis_init`, which selects the mode.
fn start_overflow_rt(witness: bool) {
    println!("{STARTED}");
    if witness {
        map2check_enable_witness();
    }
    map2check_init(0);
    __m2c_rt_overflow_analysis_init();
}

#[test]
fn overflow_rt_child() {
    if is_child() {
        start_overflow_rt(true);
        tracking();
        // SAFETY: C-string literal is valid.
        unsafe {
            __m2c_rt_overflow_map2check_binop_add(
                i64::from(i32::MAX),
                1,
                32,
                20,
                0,
                c"main".as_ptr(),
            )
        };
        map2check_success();
    }
}

#[test]
fn overflow_rt_matches_c_runtime() {
    assert_matches_golden("OVERFLOW", "overflow_rt_child");
}

#[test]
fn div_by_zero_rt_child() {
    if is_child() {
        start_overflow_rt(true);
        tracking();
        // SAFETY: C-string literal is valid.
        unsafe { __m2c_rt_overflow_map2check_binop_sdiv(7, 0, 32, 23, 0, c"main".as_ptr()) };
        map2check_success();
    }
}

#[test]
fn div_by_zero_rt_matches_c_runtime() {
    assert_matches_golden("DIVBYZERO", "div_by_zero_rt_child");
}

/// One boundary operation per child, without witness. `OVERFLOW_RT_CASE`
/// selects it.
#[test]
fn overflow_rt_boundary_child() {
    if is_child() {
        start_overflow_rt(false);
        let case = std::env::var("OVERFLOW_RT_CASE").unwrap();
        let main = c"main".as_ptr();
        // SAFETY: C-string literals are valid.
        unsafe {
            match case.as_str() {
                "INT_MAX + 1" => {
                    __m2c_rt_overflow_map2check_binop_add(i64::from(i32::MAX), 1, 32, 30, 0, main)
                }
                "INT_MIN - 1" => {
                    __m2c_rt_overflow_map2check_binop_sub(i64::from(i32::MIN), 1, 32, 31, 0, main)
                }
                "INT_MIN / -1" => {
                    __m2c_rt_overflow_map2check_binop_sdiv(i64::from(i32::MIN), -1, 32, 32, 0, main)
                }
                "INT_MIN % -1" => {
                    __m2c_rt_overflow_map2check_binop_srem(i64::from(i32::MIN), -1, 32, 33, 0, main)
                }
                "x % 0" => __m2c_rt_overflow_map2check_binop_srem(5, 0, 32, 34, 0, main),
                "INT_MAX * 2" => {
                    __m2c_rt_overflow_map2check_binop_mul(i64::from(i32::MAX), 2, 32, 35, 0, main)
                }
                "overflowError" => __m2c_rt_overflow_overflowError(36, c"f".as_ptr()),
                "UINT_MAX + 1" => __m2c_rt_overflow_map2check_binop_add_uint(
                    u64::from(u32::MAX),
                    1,
                    32,
                    37,
                    0,
                    main,
                ),
                "0 - 1u" => __m2c_rt_overflow_map2check_binop_sub_uint(0, 1, 32, 38, 0, main),
                "UINT_MAX * 2" => __m2c_rt_overflow_map2check_binop_mul_uint(
                    u64::from(u32::MAX),
                    2,
                    32,
                    39,
                    0,
                    main,
                ),
                other => panic!("caso desconhecido {other}"),
            }
        }
        println!("map2check-golden-child-survived");
        map2check_success();
        println!("{RETURNED}");
    }
}

/// The property text of the C runtime for `prp` at `line` in `function`:
/// `write_property` (`PropertyGenerator.c:86-91` for FALSE_OVERFLOW,
/// `:98-102` for FALSE_DIVBYZERO) and `write_property_overflow` (`:116-122`).
fn c_property_text(tag: &str, line: u32, function: &str) -> String {
    format!("{tag}\nLine: {line}\nFunction: {function}\n")
}

#[test]
fn overflow_rt_boundaries_write_the_c_property_text_and_abort() {
    let overflow = |line, function| {
        let text = c_property_text("OVERFLOW", line, function);
        BTreeMap::from([
            ("map2check_property".to_owned(), text.clone()),
            ("map2check_property_overflow".to_owned(), text),
        ])
    };
    let cases = [
        ("INT_MAX + 1", overflow(30, "main")),
        ("INT_MIN - 1", overflow(31, "main")),
        ("INT_MIN / -1", overflow(32, "main")),
        ("INT_MIN % -1", overflow(33, "main")),
        (
            "x % 0",
            // FALSE_DIVBYZERO writes only map2check_property (:98-102).
            BTreeMap::from([(
                "map2check_property".to_owned(),
                c_property_text("FALSE-DIVBYZERO", 34, "main"),
            )]),
        ),
        ("INT_MAX * 2", overflow(35, "main")),
        ("overflowError", overflow(36, "f")),
    ];
    for (case, expected) in cases {
        let dir = tempfile::tempdir().unwrap();
        let output = run_child_with(
            "overflow_rt_boundary_child",
            dir.path(),
            &[("OVERFLOW_RT_CASE", case)],
        );
        let stdout = String::from_utf8_lossy(&output.stdout);
        // map2check_error -> map2check_exit -> abort (Map2CheckFunctions.c:72-102).
        assert_eq!(output.status.signal(), Some(6), "{case}: SIGABRT\n{stdout}");
        assert!(!stdout.contains("survived"), "{case}: o processo continuou");
        let actual: BTreeMap<String, String> = files_in(dir.path())
            .into_iter()
            .map(|name| {
                let text = std::fs::read_to_string(dir.path().join(&name)).unwrap();
                (name, text)
            })
            .collect();
        assert_eq!(actual, expected, "{case}");
    }
}

#[test]
fn overflow_rt_unsigned_wraparound_is_not_reported_like_c() {
    // AnalysisModeOverflow.c:219-248: the _uint binops are no-ops, so the
    // run goes on to map2check_success, which writes NONE and returns.
    for case in ["UINT_MAX + 1", "0 - 1u", "UINT_MAX * 2"] {
        let dir = tempfile::tempdir().unwrap();
        let output = run_child_with(
            "overflow_rt_boundary_child",
            dir.path(),
            &[("OVERFLOW_RT_CASE", case)],
        );
        let stdout = String::from_utf8_lossy(&output.stdout);
        assert_eq!(output.status.code(), Some(0), "{case}\n{stdout}");
        assert!(stdout.contains(RETURNED), "{case}");
        assert_eq!(
            files_in(dir.path()),
            BTreeSet::from(["map2check_property".to_owned()]),
            "{case}"
        );
        assert_eq!(
            std::fs::read(dir.path().join("map2check_property")).unwrap(),
            b"NONE\n",
            "{case}"
        );
    }
}

// ── AnalysisModeAssert and AnalysisModeNone through the core entry points
//    (Task 2.4, D7) ─────────────────────────────────────────────────────────
//
// `AnalysisModeAssert.bc` / `AnalysisModeNone.bc` forward the C names to
// `__m2c_rt_assert_*` / `__m2c_rt_none_*`. The C drivers `drivers/ASSERT.c`
// and `drivers/TARGET-REACHED.c` call `map2check_assert` and
// `map2check_target_function`, so the C goldens apply unchanged.

/// As [`start_overflow_rt`], with the init of the module under test.
fn start_rt(init: extern "C" fn(), witness: bool) {
    println!("{STARTED}");
    if witness {
        map2check_enable_witness();
    }
    map2check_init(0);
    init();
}

#[test]
fn assert_rt_child() {
    if is_child() {
        start_rt(__m2c_rt_assert_analysis_init, true);
        tracking();
        // SAFETY: C-string literal is valid.
        unsafe { __m2c_rt_assert_map2check_assert(0, 21, c"main".as_ptr()) };
        map2check_success();
    }
}

#[test]
fn assert_rt_matches_c_runtime() {
    assert_matches_golden("ASSERT", "assert_rt_child");
}

#[test]
fn none_rt_child() {
    if is_child() {
        start_rt(__m2c_rt_none_analysis_init, true);
        tracking();
        // SAFETY: C-string literal is valid.
        unsafe { map2check_target_function(c"reach_error".as_ptr(), 0, 22) };
        map2check_success();
    }
}

#[test]
fn none_rt_target_function_matches_c_runtime() {
    assert_matches_golden("TARGET-REACHED", "none_rt_child");
}

/// One `map2check_assert` call per child, without witness. `ASSERT_RT_CASE`
/// selects the condition.
#[test]
fn assert_rt_boundary_child() {
    if is_child() {
        start_rt(__m2c_rt_assert_analysis_init, false);
        let condition: i32 = std::env::var("ASSERT_RT_CASE").unwrap().parse().unwrap();
        // SAFETY: C-string literal is valid.
        unsafe { __m2c_rt_assert_map2check_assert(condition, 40, c"f".as_ptr()) };
        println!("map2check-golden-child-survived");
        map2check_success();
        println!("{RETURNED}");
    }
}

#[test]
fn assert_rt_zero_writes_the_c_property_text_and_aborts() {
    let dir = tempfile::tempdir().unwrap();
    let output = run_child_with(
        "assert_rt_boundary_child",
        dir.path(),
        &[("ASSERT_RT_CASE", "0")],
    );
    let stdout = String::from_utf8_lossy(&output.stdout);
    // map2check_error -> map2check_exit -> abort (Map2CheckFunctions.c:72-102).
    assert_eq!(output.status.signal(), Some(6), "{stdout}");
    assert!(!stdout.contains("survived"));
    // write_property(ASSERT) (PropertyGenerator.c:92-96) writes
    // map2check_property_assert (write_property_assert, :124-130) and then
    // map2check_property, with the same text.
    let text = c_property_text("ASSERT", 40, "f");
    let actual: BTreeMap<String, String> = files_in(dir.path())
        .into_iter()
        .map(|name| {
            let t = std::fs::read_to_string(dir.path().join(&name)).unwrap();
            (name, t)
        })
        .collect();
    assert_eq!(
        actual,
        BTreeMap::from([
            ("map2check_property".to_owned(), text.clone()),
            ("map2check_property_assert".to_owned(), text),
        ])
    );
}

#[test]
fn assert_rt_nonzero_does_not_report_like_c() {
    for case in ["1", "-7"] {
        let dir = tempfile::tempdir().unwrap();
        let output = run_child_with(
            "assert_rt_boundary_child",
            dir.path(),
            &[("ASSERT_RT_CASE", case)],
        );
        let stdout = String::from_utf8_lossy(&output.stdout);
        assert_eq!(output.status.code(), Some(0), "{case}\n{stdout}");
        assert!(stdout.contains(RETURNED), "{case}");
        assert_eq!(
            std::fs::read(dir.path().join("map2check_property")).unwrap(),
            b"NONE\n"
        );
        assert_eq!(
            files_in(dir.path()),
            BTreeSet::from(["map2check_property".to_owned()])
        );
    }
}

/// `map2check_target_function` in mode none (`PropertyGenerator.c:81-85`,
/// TARGET_REACHED): only `map2check_property`, byte for byte, then abort.
#[test]
fn none_rt_target_function_writes_the_c_reachability_property_and_aborts() {
    let dir = tempfile::tempdir().unwrap();
    let output = run_child_with("none_rt_boundary_child", dir.path(), &[]);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(output.status.signal(), Some(6), "{stdout}");
    assert!(!stdout.contains("survived"));
    assert_eq!(
        files_in(dir.path()),
        BTreeSet::from(["map2check_property".to_owned()])
    );
    assert_eq!(
        std::fs::read(dir.path().join("map2check_property")).unwrap(),
        b"TARGET-REACHED\nLine: 41\nFunction: reach_error\n"
    );
}

#[test]
fn none_rt_boundary_child() {
    if is_child() {
        start_rt(__m2c_rt_none_analysis_init, false);
        // SAFETY: C-string literal is valid.
        unsafe { map2check_target_function(c"reach_error".as_ptr(), 0, 41) };
        println!("map2check-golden-child-survived");
    }
}

// ── AnalysisModeMemtrack through the core entry points (Task 2.5, D7) ───────
//
// `AnalysisModeMemtrack.bc` forwards the C names to `__m2c_rt_memtrack_*`.
// The children make the calls of `tests/legacy_golden/drivers/<TAG>.c` with
// the C ABI (`map2check_track_bb`, `map2check_nondet_<t>`, the memory entry
// points), so the C goldens apply: property files, `list_log.csv`,
// `allocation_log.csv`, `heap_log.csv`, `track_bb_log.st` and the end of the
// process. `klee_log.csv` is compared elsewhere: the witness writes it from
// the generator's log, which Task 3.1 wires (the drop-in nondet rows are
// `__m2c_rt_nondet_log_to_file`'s, Task 2.2); here only its presence is.

const KLEE_LOG: &[&str] = &["klee_log.csv"];

/// `golden_tracking()` through the C ABI: the same basic blocks and nondet
/// values as the driver, so the list rows get the same C steps (5 on).
fn c_tracking() {
    // SAFETY: C-string literals are valid.
    unsafe {
        map2check_track_bb(3, c"main".as_ptr());
        map2check_track_bb(4, c"main".as_ptr());
        map2check_track_bb(3, c"main".as_ptr());
        map2check_nondet_int(5, 0, 42, c"main".as_ptr());
        map2check_nondet_uint(6, 0, 4_000_000_000u32 as i32, c"main".as_ptr());
        map2check_nondet_char(7, 0, 253, c"main".as_ptr());
        map2check_nondet_long(8, 0, -7, c"main".as_ptr());
        map2check_nondet_double(9, 0, 2.5, c"main".as_ptr());
    }
}

/// `golden_memory()` through `__m2c_rt_memtrack_*`, with the arena mapped
/// and `p = BLOCK` written in its slot (`map2check_free` reads it).
fn rt_memory() {
    map_arena();
    // SAFETY: SLOT_P lies in the mapped arena; the other addresses are only
    // stored; names are C strings.
    unsafe {
        __m2c_rt_memtrack_map2check_alloca(c"p".as_ptr(), addr(SLOT_P), 8, 8, 10, 1);
        __m2c_rt_memtrack_map2check_function(c"main".as_ptr(), addr(FN_MAIN));
        __m2c_rt_memtrack_map2check_malloc(addr(BLOCK), 16);
        (SLOT_P as *mut usize).write(BLOCK);
        __m2c_rt_memtrack_map2check_add_store_pointer(
            addr(SLOT_P),
            addr(BLOCK),
            1,
            c"p".as_ptr(),
            11,
            c"main".as_ptr(),
        );
    }
}

/// `map2check_free("p", SLOT_P, 1, line, "main")`.
fn rt_free_p(line: u32) {
    // SAFETY: SLOT_P is mapped and holds BLOCK; C strings.
    unsafe {
        __m2c_rt_memtrack_map2check_free(c"p".as_ptr(), addr(SLOT_P), 1, line, c"main".as_ptr())
    };
}

fn start_memtrack_rt() {
    start_rt(__m2c_rt_memtrack_analysis_init, true);
    c_tracking();
    rt_memory();
}

#[test]
fn memtrack_rt_false_deref_child() {
    if is_child() {
        start_memtrack_rt();
        // SAFETY: WILD is only compared; C string.
        unsafe {
            __m2c_rt_memtrack_map2check_load(addr(WILD), 4);
            __m2c_rt_memtrack_map2check_check_deref(14, c"main".as_ptr());
        }
        map2check_success();
    }
}

#[test]
fn memtrack_rt_false_deref_matches_c_runtime() {
    assert_matches_golden_except("FALSE-DEREF", "memtrack_rt_false_deref_child", KLEE_LOG);
}

#[test]
fn memtrack_rt_false_free_child() {
    if is_child() {
        start_memtrack_rt();
        rt_free_p(12);
        rt_free_p(13);
        map2check_success();
    }
}

#[test]
fn memtrack_rt_double_free_matches_c_runtime() {
    assert_matches_golden_except("FALSE-FREE", "memtrack_rt_false_free_child", KLEE_LOG);
}

#[test]
fn memtrack_rt_false_free_resolved_child() {
    if is_child() {
        start_memtrack_rt();
        rt_free_p(12);
        // SAFETY: BLOCK is only compared; C string.
        unsafe {
            __m2c_rt_memtrack_map2check_free_resolved_address(addr(BLOCK), 13, c"main".as_ptr(), 0)
        };
        map2check_success();
    }
}

#[test]
fn memtrack_rt_false_free_resolved_matches_c_runtime() {
    assert_matches_golden_except(
        "FALSE-FREE-RESOLVED",
        "memtrack_rt_false_free_resolved_child",
        KLEE_LOG,
    );
}

#[test]
fn memtrack_rt_false_memtrack_child() {
    if is_child() {
        start_memtrack_rt();
        map2check_success();
    }
}

#[test]
fn memtrack_rt_false_memtrack_matches_c_runtime() {
    assert_matches_golden_except(
        "FALSE-MEMTRACK",
        "memtrack_rt_false_memtrack_child",
        KLEE_LOG,
    );
}

#[test]
fn memtrack_rt_none_child() {
    if is_child() {
        start_memtrack_rt();
        rt_free_p(12);
        map2check_success();
        println!("{RETURNED}");
    }
}

#[test]
fn memtrack_rt_valid_run_matches_c_runtime() {
    assert_matches_golden("NONE", "memtrack_rt_none_child");
}

#[test]
fn memtrack_rt_unknown_child() {
    if is_child() {
        start_memtrack_rt();
        __m2c_rt_memtrack_map2check_malloc(std::ptr::null(), 4);
        map2check_success();
    }
}

#[test]
fn memtrack_rt_unknown_matches_c_runtime() {
    assert_matches_golden_except("UNKNOWN", "memtrack_rt_unknown_child", KLEE_LOG);
}

#[test]
fn memtrack_rt_posix_child() {
    if is_child() {
        start_memtrack_rt();
        // SAFETY: SLOT_Q lies in the mapped arena; names are C strings.
        unsafe {
            __m2c_rt_memtrack_map2check_alloca(c"q".as_ptr(), addr(SLOT_Q), 8, 8, 15, 1);
            (SLOT_Q as *mut usize).write(BLOCK2);
            __m2c_rt_memtrack_map2check_posix(addr(SLOT_Q), 32);
        }
        map2check_success();
    }
}

#[test]
fn memtrack_rt_posix_matches_c_runtime() {
    assert_matches_golden_except("POSIX-MEMALIGN", "memtrack_rt_posix_child", KLEE_LOG);
}

/// One violation per child, without witness: `MEMTRACK_RT_CASE` selects it.
#[test]
fn memtrack_rt_boundary_child() {
    if is_child() {
        start_rt(__m2c_rt_memtrack_analysis_init, false);
        map_arena();
        let case = std::env::var("MEMTRACK_RT_CASE").unwrap();
        let main = c"main".as_ptr();
        // SAFETY: every address read lies in the mapped arena; the others
        // are only compared; names are C strings.
        unsafe {
            match case.as_str() {
                "non-heap free" => {
                    // int x; int *p = &x; free(p);
                    __m2c_rt_memtrack_map2check_alloca(c"x".as_ptr(), addr(BLOCK), 4, 4, 3, 1);
                    (SLOT_P as *mut usize).write(BLOCK);
                    __m2c_rt_memtrack_map2check_add_store_pointer(
                        addr(SLOT_P),
                        addr(BLOCK),
                        1,
                        c"p".as_ptr(),
                        4,
                        main,
                    );
                    __m2c_rt_memtrack_map2check_free(c"p".as_ptr(), addr(SLOT_P), 1, 50, main);
                }
                "cstring beyond the block" => {
                    // char *s = malloc(4); memcpy(s, "abcd", 4); puts(s);
                    let s = BLOCK as *mut u8;
                    s.copy_from_nonoverlapping(b"abcd".as_ptr(), 4);
                    __m2c_rt_memtrack_map2check_malloc(addr(BLOCK), 4);
                    __m2c_rt_memtrack_map2check_check_cstring(s.cast_const().cast());
                    __m2c_rt_memtrack_map2check_check_deref(51, c"puts_caller".as_ptr());
                }
                "cstring inside the block" => {
                    let s = BLOCK as *mut u8;
                    s.copy_from_nonoverlapping(b"abc\0".as_ptr(), 4);
                    __m2c_rt_memtrack_map2check_malloc(addr(BLOCK), 4);
                    __m2c_rt_memtrack_map2check_check_cstring(s.cast_const().cast());
                    __m2c_rt_memtrack_map2check_check_deref(52, main);
                    __m2c_rt_memtrack_map2check_free_resolved_address(addr(BLOCK), 53, main, 0);
                }
                "free of a literal NULL" => {
                    // free(0): not a LoadInst, so the pass emits the resolved
                    // free with isNullValid 0 (MemoryTrackPass.cpp:428-436).
                    __m2c_rt_memtrack_map2check_free_resolved_address(
                        std::ptr::null(),
                        54,
                        main,
                        0,
                    );
                }
                "wasm leak" => {
                    // A lifted malloc never freed: develop free()s the
                    // linear-memory offset (AllocationLog.c:91) and glibc
                    // aborts before FALSE_MEMTRACK is written (SD-19).
                    __m2c_rt_memtrack_map2check_wasm_malloc(0x400, 16);
                }
                other => panic!("caso desconhecido {other}"),
            }
        }
        println!("map2check-golden-child-survived");
        map2check_success();
        println!("{RETURNED}");
    }
}

/// SD-23: develop's `find_row_with_address(NULL)` returns NULL and the
/// release writes through it (SIGSEGV, no property file); the core goes on
/// and the run ends correct.
#[test]
fn sd23_free_of_a_literal_null_goes_on_where_develop_crashes() {
    let (output, files) = memtrack_rt_case("free of a literal NULL");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(output.status.code(), Some(0), "{stdout}");
    assert!(stdout.contains(RETURNED));
    assert_eq!(
        files,
        BTreeMap::from([("map2check_property".to_owned(), "NONE\n".to_owned())])
    );
}

/// SD-19: a leaked wasm block is FALSE-MEMTRACK; the core does not free()
/// the offset as develop does.
#[test]
fn sd19_wasm_leak_is_false_memtrack_without_freeing_the_offset() {
    let (output, files) = memtrack_rt_case("wasm leak");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(output.status.signal(), Some(6), "{stdout}");
    assert_eq!(
        files,
        BTreeMap::from([
            (
                "map2check_property".to_owned(),
                "FALSE-MEMTRACK\n".to_owned()
            ),
            (
                "map2check_property_memtrack".to_owned(),
                "FALSE-MEMTRACK\n".to_owned()
            ),
        ])
    );
}

// ── AnalysisModeMemcleanup through __m2c_rt_memcleanup_* (Task 2.6) ─────────

/// `golden_memory()` through `__m2c_rt_memcleanup_*`, as `rt_memory` does for
/// memtrack.
fn rt_memcleanup_memory() {
    map_arena();
    // SAFETY: SLOT_P lies in the mapped arena; the other addresses are only
    // stored; names are C strings.
    unsafe {
        __m2c_rt_memcleanup_map2check_alloca(c"p".as_ptr(), addr(SLOT_P), 8, 8, 10, 1);
        __m2c_rt_memcleanup_map2check_function(c"main".as_ptr(), addr(FN_MAIN));
        __m2c_rt_memcleanup_map2check_malloc(addr(BLOCK), 16);
        (SLOT_P as *mut usize).write(BLOCK);
        __m2c_rt_memcleanup_map2check_add_store_pointer(
            addr(SLOT_P),
            addr(BLOCK),
            1,
            c"p".as_ptr(),
            11,
            c"main".as_ptr(),
        );
    }
}

fn start_memcleanup_rt() {
    start_rt(__m2c_rt_memcleanup_analysis_init, true);
    c_tracking();
    rt_memcleanup_memory();
}

/// `exit(0)` of a program with a reachable block still allocated: the pass
/// ends the program with `map2check_success`, whose `map2check_exit` runs
/// `analysis_is_program_correct` (`AnalysisModeMemcleanup.c:138-148`;
/// `Map2CheckFunctions.c:89-102`). `p` still points to the block.
#[test]
fn memcleanup_reports_leak_at_exit_child() {
    if is_child() {
        start_memcleanup_rt();
        map2check_success();
    }
}

#[test]
fn memcleanup_reports_leak_at_exit() {
    assert_matches_golden_except(
        "FALSE-MEMCLEANUP",
        "memcleanup_reports_leak_at_exit_child",
        KLEE_LOG,
    );
    // The golden's property text, from PropertyGenerator.c:36-40 and :77-80.
    let dir = tempfile::tempdir().unwrap();
    let output = run_child("memcleanup_reports_leak_at_exit_child", dir.path());
    assert_eq!(output.status.signal(), Some(6));
    assert_eq!(
        std::fs::read_to_string(dir.path().join("map2check_property")).unwrap(),
        "FALSE-MEMCLEANUP\n"
    );
    assert_eq!(
        std::fs::read_to_string(dir.path().join("map2check_property_memcleanup")).unwrap(),
        "FALSE-MEMCLEANUP\n"
    );
}

/// Memtrack reports the leak of an unreferenced block; memcleanup does not
/// (`AnalysisModeMemcleanup.c:141`, `ListLog.c:40-65`): `p` is reassigned to
/// NULL, the run ends `NONE`.
#[test]
fn memcleanup_unreferenced_leak_is_none_child() {
    if is_child() {
        start_memcleanup_rt();
        // SAFETY: C strings.
        unsafe {
            __m2c_rt_memcleanup_map2check_add_store_pointer(
                addr(SLOT_P),
                std::ptr::null(),
                1,
                c"p".as_ptr(),
                12,
                c"main".as_ptr(),
            );
        }
        map2check_success();
        println!("{RETURNED}");
    }
}

#[test]
fn memcleanup_unreferenced_leak_is_none() {
    let dir = tempfile::tempdir().unwrap();
    let output = run_child("memcleanup_unreferenced_leak_is_none_child", dir.path());
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(output.status.code(), Some(0), "{stdout}");
    assert!(stdout.contains(RETURNED));
    assert_eq!(
        std::fs::read_to_string(dir.path().join("map2check_property")).unwrap(),
        "NONE\n"
    );
    assert!(!dir.path().join("map2check_property_memcleanup").exists());
}

/// A freed block ends the run `NONE` (`tests/legacy_golden/NONE`).
#[test]
fn memcleanup_valid_run_child() {
    if is_child() {
        start_memcleanup_rt();
        // SAFETY: SLOT_P holds BLOCK; C strings.
        unsafe {
            __m2c_rt_memcleanup_map2check_free(c"p".as_ptr(), addr(SLOT_P), 1, 12, c"main".as_ptr())
        };
        map2check_success();
        println!("{RETURNED}");
    }
}

#[test]
fn memcleanup_valid_run_matches_c_runtime() {
    assert_matches_golden("NONE", "memcleanup_valid_run_child");
}

/// Memtrack's FALSE-FREE cases are not violations here (`:168`, `:342`): a
/// double free runs to the end, `NONE`.
#[test]
fn memcleanup_double_free_child() {
    if is_child() {
        start_memcleanup_rt();
        // SAFETY: SLOT_P holds BLOCK; C strings.
        unsafe {
            __m2c_rt_memcleanup_map2check_free(
                c"p".as_ptr(),
                addr(SLOT_P),
                1,
                12,
                c"main".as_ptr(),
            );
            __m2c_rt_memcleanup_map2check_free(
                c"p".as_ptr(),
                addr(SLOT_P),
                1,
                13,
                c"main".as_ptr(),
            );
        }
        map2check_success();
        println!("{RETURNED}");
    }
}

#[test]
fn memcleanup_double_free_is_not_false_free() {
    let dir = tempfile::tempdir().unwrap();
    let output = run_child("memcleanup_double_free_child", dir.path());
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(output.status.code(), Some(0), "{stdout}");
    assert!(stdout.contains(RETURNED));
    assert_eq!(
        std::fs::read_to_string(dir.path().join("map2check_property")).unwrap(),
        "NONE\n"
    );
    assert!(!dir.path().join("map2check_property_free").exists());
}

/// `map2check_malloc(NULL)` is UNKNOWN in both modes (`:296-302`).
#[test]
fn memcleanup_unknown_child() {
    if is_child() {
        start_memcleanup_rt();
        __m2c_rt_memcleanup_map2check_malloc(std::ptr::null(), 4);
        map2check_success();
    }
}

#[test]
fn memcleanup_unknown_matches_c_runtime() {
    assert_matches_golden_except("UNKNOWN", "memcleanup_unknown_child", KLEE_LOG);
}

/// `drivers/POSIX-MEMALIGN.c` in memcleanup mode: the block is stored in
/// `q`, which still points to it: the same files, ending FALSE-MEMCLEANUP
/// rather than the memtrack golden's FALSE-MEMTRACK.
#[test]
fn memcleanup_posix_child() {
    if is_child() {
        start_memcleanup_rt();
        // SAFETY: SLOT_Q lies in the mapped arena; names are C strings.
        unsafe {
            __m2c_rt_memcleanup_map2check_alloca(c"q".as_ptr(), addr(SLOT_Q), 8, 8, 15, 1);
            (SLOT_Q as *mut usize).write(BLOCK2);
            __m2c_rt_memcleanup_map2check_posix(addr(SLOT_Q), 32);
        }
        map2check_success();
    }
}

#[test]
fn memcleanup_posix_leaves_the_memtrack_golden_logs() {
    let golden =
        std::path::Path::new(env!("CARGO_MANIFEST_DIR")).join("tests/legacy_golden/POSIX-MEMALIGN");
    let dir = tempfile::tempdir().unwrap();
    let output = run_child("memcleanup_posix_child", dir.path());
    assert_eq!(output.status.signal(), Some(6));
    for f in ["allocation_log.csv", "list_log.csv", "heap_log.csv"] {
        assert_eq!(
            std::fs::read(dir.path().join(f)).unwrap(),
            std::fs::read(golden.join(f)).unwrap(),
            "{f}"
        );
    }
    assert_eq!(
        std::fs::read_to_string(dir.path().join("map2check_property")).unwrap(),
        "FALSE-MEMCLEANUP\n"
    );
}

/// One case per child, without witness: `MEMCLEANUP_RT_CASE` selects it.
#[test]
fn memcleanup_rt_boundary_child() {
    if is_child() {
        start_rt(__m2c_rt_memcleanup_analysis_init, false);
        map_arena();
        let case = std::env::var("MEMCLEANUP_RT_CASE").unwrap();
        let main = c"main".as_ptr();
        // SAFETY: every address read lies in the mapped arena; the others
        // are only compared; names are C strings.
        unsafe {
            match case.as_str() {
                "stack free" => {
                    // int x; int *p = &x; free(p);
                    __m2c_rt_memcleanup_map2check_alloca(c"x".as_ptr(), addr(BLOCK), 4, 4, 3, 1);
                    (SLOT_P as *mut usize).write(BLOCK);
                    __m2c_rt_memcleanup_map2check_add_store_pointer(
                        addr(SLOT_P),
                        addr(BLOCK),
                        1,
                        c"p".as_ptr(),
                        4,
                        main,
                    );
                    __m2c_rt_memcleanup_map2check_free(c"p".as_ptr(), addr(SLOT_P), 1, 50, main);
                }
                "untracked resolved free" => {
                    // free(q) of an address no allocation ever recorded.
                    __m2c_rt_memcleanup_map2check_free_resolved_address(addr(WILD), 51, main, 0);
                }
                "free of a literal NULL" => {
                    __m2c_rt_memcleanup_map2check_free_resolved_address(
                        std::ptr::null(),
                        54,
                        main,
                        0,
                    );
                }
                "invalid deref" => {
                    __m2c_rt_memcleanup_map2check_load(addr(WILD), 4);
                    __m2c_rt_memcleanup_map2check_check_deref(14, main);
                }
                other => panic!("caso desconhecido {other}"),
            }
        }
        println!("map2check-golden-child-survived");
        map2check_success();
        println!("{RETURNED}");
    }
}

fn memcleanup_rt_case(case: &str) -> (std::process::Output, BTreeMap<String, String>) {
    let dir = tempfile::tempdir().unwrap();
    let output = run_child_with(
        "memcleanup_rt_boundary_child",
        dir.path(),
        &[("MEMCLEANUP_RT_CASE", case)],
    );
    let files = files_in(dir.path())
        .into_iter()
        .map(|name| {
            let text = std::fs::read_to_string(dir.path().join(&name)).unwrap();
            (name, text)
        })
        .collect();
    (output, files)
}

/// SD-23: develop's `AnalysisModeMemcleanup.c` lets every free through
/// (`error = FALSE`, `:168`, `:342`) and writes through the NULL row of
/// `find_row_with_address` (`:176-177`, `:353-354`): SIGSEGV, no property
/// file. The core goes on and the run ends `NONE`.
#[test]
fn sd23_memcleanup_release_without_allocation_row_goes_on_where_develop_crashes() {
    for case in [
        "stack free",
        "untracked resolved free",
        "free of a literal NULL",
    ] {
        let (output, files) = memcleanup_rt_case(case);
        let stdout = String::from_utf8_lossy(&output.stdout);
        assert_eq!(output.status.code(), Some(0), "{case}: {stdout}");
        assert!(stdout.contains(RETURNED), "{case}");
        assert_eq!(
            files,
            BTreeMap::from([("map2check_property".to_owned(), "NONE\n".to_owned())]),
            "{case}"
        );
    }
}

/// `map2check_load` and `map2check_check_deref` are empty (`:158`, `:294`):
/// the access memtrack reports as FALSE-DEREF goes unnoticed.
#[test]
fn memcleanup_invalid_deref_is_not_reported() {
    let (output, files) = memcleanup_rt_case("invalid deref");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(output.status.code(), Some(0), "{stdout}");
    assert_eq!(
        files,
        BTreeMap::from([("map2check_property".to_owned(), "NONE\n".to_owned())])
    );
}

/// The files `memtrack_rt_boundary_child` leaves for `case`.
fn memtrack_rt_case(case: &str) -> (std::process::Output, BTreeMap<String, String>) {
    let dir = tempfile::tempdir().unwrap();
    let output = run_child_with(
        "memtrack_rt_boundary_child",
        dir.path(),
        &[("MEMTRACK_RT_CASE", case)],
    );
    let files = files_in(dir.path())
        .into_iter()
        .map(|name| {
            let text = std::fs::read_to_string(dir.path().join(&name)).unwrap();
            (name, text)
        })
        .collect();
    (output, files)
}

#[test]
fn memtrack_rt_free_of_a_non_heap_address_writes_false_free_and_aborts() {
    let (output, files) = memtrack_rt_case("non-heap free");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(output.status.signal(), Some(6), "{stdout}");
    assert!(!stdout.contains("survived"));
    // AnalysisModeMemtrack.c:367-370: write_property(FALSE_FREE)
    // (PropertyGenerator.c:61-66, which writes map2check_property_free first).
    let text = c_property_text("FALSE-FREE", 50, "main");
    assert_eq!(
        files,
        BTreeMap::from([
            ("map2check_property".to_owned(), text.clone()),
            ("map2check_property_free".to_owned(), text),
        ])
    );
}

#[test]
fn memtrack_rt_check_cstring_beyond_the_block_writes_false_deref_and_aborts() {
    let (output, files) = memtrack_rt_case("cstring beyond the block");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(output.status.signal(), Some(6), "{stdout}");
    assert!(!stdout.contains("survived"));
    // :159-166 sets ERROR_DEREF at the fifth byte; :309-315 writes
    // FALSE_DEREF (PropertyGenerator.c:67-72, :42-48).
    let text = c_property_text("FALSE-DEREF", 51, "puts_caller");
    assert_eq!(
        files,
        BTreeMap::from([
            ("map2check_property".to_owned(), text.clone()),
            ("map2check_property_deref".to_owned(), text),
        ])
    );
}

#[test]
fn memtrack_rt_check_cstring_inside_the_block_is_not_reported() {
    let (output, files) = memtrack_rt_case("cstring inside the block");
    let stdout = String::from_utf8_lossy(&output.stdout);
    // free(malloc(4)) with no tracked store: is_invalid_free (ListLog.c:117)
    // is TRUE in develop, so the resolved free is FALSE-FREE.
    assert_eq!(output.status.signal(), Some(6), "{stdout}");
    let text = c_property_text("FALSE-FREE", 53, "main");
    assert_eq!(
        files,
        BTreeMap::from([
            ("map2check_property".to_owned(), text.clone()),
            ("map2check_property_free".to_owned(), text),
        ])
    );
}
