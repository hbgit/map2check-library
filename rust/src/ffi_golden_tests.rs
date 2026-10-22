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
    let exe = std::env::current_exe().unwrap();
    let output = std::process::Command::new(exe)
        .args(["--exact", &format!("ffi::golden_tests::{name}")])
        .args(["--nocapture", "--test-threads=1"])
        .env(CHILD_ENV, "1")
        .env(crate::output::termination::OUTPUT_DIR_ENV, dir)
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
        map2check_save_basic_block_log(3, c"main".as_ptr());
        map2check_save_basic_block_log(4, c"main".as_ptr());
        map2check_save_basic_block_log(3, c"main".as_ptr());
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
    map2check_init();
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

/// A run with no violation: one nondet value, then success. Writes
/// `klee_log.csv` only when `MAP2CHECK_SEED_REPLAY` asks for it, as Map2Check
/// 9.0's seed exchange does when it replays a fuzzer queue entry.
fn no_violation_with_one_nondet(seed_replay: bool) {
    if seed_replay {
        std::env::set_var("MAP2CHECK_SEED_REPLAY", "1");
    }
    start(AnalysisMode::Assert);
    let mut value: i32 = 42;
    // SAFETY: `value` outlives the call; `f` is a C-string literal.
    unsafe { map2check_save_nondet_log_int(30, 1, 0, &mut value, c"f".as_ptr()) };
    map2check_success();
}

#[test]
fn seed_replay_child() {
    if is_child() {
        no_violation_with_one_nondet(true);
    }
}

#[test]
fn no_seed_replay_child() {
    if is_child() {
        no_violation_with_one_nondet(false);
    }
}

#[test]
fn seed_replay_writes_the_nondet_log_without_a_violation() {
    let dir = tempfile::tempdir().unwrap();
    run_child("seed_replay_child", dir.path());
    let log = std::fs::read_to_string(dir.path().join("klee_log.csv")).unwrap();
    // After the rows `tracking()` logs, the program's own value.
    assert!(log.ends_with(";30;1;f;5;42;0\n"), "{log}");

    let dir = tempfile::tempdir().unwrap();
    run_child("no_seed_replay_child", dir.path());
    assert!(!dir.path().join("klee_log.csv").exists());
}

// ── Without witness: property files only (WitnessGenerationNone.c) ──────────

#[test]
fn overflow_without_witness_child() {
    if is_child() {
        println!("{STARTED}");
        map2check_set_mode(AnalysisMode::Overflow as i32);
        map2check_init();
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
        map2check_init();
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

#[test]
fn init_with_mode_removes_stale_property_files_child() {
    if is_child() {
        println!("{STARTED}");
        map2check_set_mode(AnalysisMode::Assert as i32);
        map2check_init();
    }
}

#[test]
fn init_with_mode_removes_stale_property_files() {
    let dir = tempfile::tempdir().unwrap();
    for name in crate::output::legacy_files::PROPERTY_FILES {
        std::fs::write(dir.path().join(name), "stale\n").unwrap();
    }
    std::fs::write(dir.path().join("other"), "kept\n").unwrap();
    let output = run_child(
        "init_with_mode_removes_stale_property_files_child",
        dir.path(),
    );
    assert_eq!(output.status.code(), Some(0));
    assert_eq!(files_in(dir.path()), BTreeSet::from(["other".to_owned()]));
}

#[test]
fn unset_mode_records_without_files_or_abort_child() {
    if is_child() {
        println!("{STARTED}");
        map2check_enable_witness();
        map2check_init();
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
        map2check_init();
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
        map2check_init();
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
