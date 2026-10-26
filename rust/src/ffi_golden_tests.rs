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

use std::collections::BTreeSet;
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
