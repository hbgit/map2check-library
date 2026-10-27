// SPDX-License-Identifier: GPL-3.0-only
//
// End of a Map2Check run (#19): the files the frontend reads and the abort
// that tells it a violation was found. Mirrors `map2check_success`,
// `map2check_error`, `map2check_exit` and `map2check_destroy` of the C
// runtime of Map2Check `develop` (`Map2CheckFunctions.c:67-102`).
//
// Only a Map2Check-instrumented program selects an analysis mode
// (`map2check_set_mode`), so the mode decides: with a mode set, the first
// violation writes the files and aborts, and `map2check_success` writes the
// files and returns; with the mode unset (direct API users, the C harness,
// unit tests) nothing is written and nothing ends the process.
#![deny(unsafe_code)]

use std::path::{Path, PathBuf};

use super::legacy_files::{self, LegacyLogs};
use crate::{
    analysismode::mode::{self, AnalysisMode},
    caller::AnalysisResult,
    state::{self, AnalysisState, Config},
};

/// Test builds write into this directory, and only when it is set; the
/// golden tests set it for a child process (`rust/src/ffi_golden_tests.rs`).
#[cfg(test)]
pub(crate) const OUTPUT_DIR_ENV: &str = "MAP2CHECK_TEST_OUTPUT_DIR";

/// Where the result files go: the current directory, as in develop. In test
/// builds, the directory named by [`OUTPUT_DIR_ENV`], or nowhere, so that a
/// unit test with a mode set records the violation and keeps running.
pub(crate) fn output_dir() -> Option<PathBuf> {
    #[cfg(not(test))]
    {
        Some(PathBuf::from("."))
    }
    #[cfg(test)]
    {
        std::env::var_os(OUTPUT_DIR_ENV).map(PathBuf::from)
    }
}

/// The directory to write into, when this run uses the file channel: a mode
/// is set and there is an output directory.
fn channel(config: Config) -> Option<PathBuf> {
    config.mode.and(output_dir())
}

fn report(what: &str, result: std::io::Result<()>) {
    if let Err(e) = result {
        eprintln!("[map2check] cannot write {what}: {e}");
    }
}

/// Set by the seed exchange of the Map2Check frontend when it replays a
/// non-violating fuzzer input to learn its nondet values
/// (`WitnessGeneration.c:23-28`).
const SEED_REPLAY_ENV: &str = "MAP2CHECK_SEED_REPLAY";

/// `generate_aux_files` (`WitnessGeneration.c:15-29`): the basic-block log,
/// the logs of the memory modes (`analysis_generate_aux_witness_files`,
/// `AnalysisModeMemtrack.c:148-152`) and, on a violation or when
/// `MAP2CHECK_SEED_REPLAY` is set, the nondet log.
pub(crate) fn generate_aux_files(
    dir: &Path,
    config: Config,
    s: &mut AnalysisState,
    violation: bool,
) {
    report(
        legacy_files::TRACKBB_LOG_FILE,
        legacy_files::write_trackbb_log(dir, &s.bbtrack),
    );
    let logs = LegacyLogs::replay(
        &s.memtrack,
        &s.nondets,
        s.failed_free.as_ref(),
        s.end_of_program,
    );
    if matches!(
        config.mode,
        Some(AnalysisMode::Memtrack | AnalysisMode::Memcleanup)
    ) {
        // The drop-in entry points keep develop's logs themselves
        // (`__m2c_rt_memtrack_*`, Task 2.5); the Rust-only 1.x API is replayed.
        if s.c_memory.has_rows() {
            write_c_memory_logs(dir, &s.c_memory);
        } else {
            report(legacy_files::HEAP_LOG_FILE, logs.write_heap_log(dir));
            report(
                legacy_files::ALLOCATION_LOG_FILE,
                logs.write_allocation_log(dir),
            );
            report(legacy_files::LIST_LOG_FILE, logs.write_list_log(dir));
        }
    }
    if violation || std::env::var_os(SEED_REPLAY_ENV).is_some() {
        report(legacy_files::NONDET_LOG_FILE, logs.write_nondet_log(dir));
    }
}

/// `analysis_generate_aux_witness_files` of the memory modes
/// (`AnalysisModeMemtrack.c:148-152`): `heap_log.csv`, `allocation_log.csv`
/// and `list_log.csv`, in that order, from develop's logs.
pub(crate) fn write_c_memory_logs(dir: &Path, memory: &crate::memtrack::c_mode::CMemory) {
    for (name, bytes) in [
        (legacy_files::HEAP_LOG_FILE, memory.heap_log_bytes()),
        (
            legacy_files::ALLOCATION_LOG_FILE,
            memory.allocation_log_bytes(),
        ),
        (legacy_files::LIST_LOG_FILE, memory.list_log_bytes()),
    ] {
        report(name, legacy_files::write_atomic_bytes(dir, name, &bytes));
    }
}

/// `generate_confirmation_file` (`WitnessGeneration.c:32-36`).
pub(crate) fn generate_confirmation_file(dir: &Path) {
    report(
        legacy_files::CHECKED_ERROR_FILE,
        legacy_files::write_checked_error(dir),
    );
}

/// `__m2c_rt_witness_generate_aux_files`: [`generate_aux_files`] on the
/// state of the run, into the output directory, whatever the mode and the
/// witness option (the IR module `WitnessGeneration.bc` is linked only into
/// witness builds, D7).
pub(crate) fn rt_generate_aux_files(violation: bool) {
    let Some(dir) = output_dir() else {
        return;
    };
    let config = state::config();
    if let Err(e) = state::with_state(|s| {
        generate_aux_files(&dir, config, s, violation);
        Ok(())
    }) {
        eprintln!("[map2check] error: {e}");
    }
}

/// `__m2c_rt_witness_generate_confirmation_file`:
/// [`generate_confirmation_file`] into the output directory.
pub(crate) fn rt_generate_confirmation_file() {
    if let Some(dir) = output_dir() {
        generate_confirmation_file(&dir);
    }
}

/// `write_property` into the output directory (`PropertyGenerator.c:50-106`),
/// whatever the mode.
pub(crate) fn write_property(
    violated: crate::caller::ViolatedProperty,
    line: i32,
    function_name: &str,
) {
    if let Some(dir) = output_dir() {
        report(
            legacy_files::PROPERTY_FILE,
            legacy_files::write_property(&dir, violated, line, function_name),
        );
    }
}

/// `map2check_destroy` (`Map2CheckFunctions.c:77-87`): releases the
/// basic-block log and runs `analysis_destroy` of the mode, once per run.
/// The nondet log belongs to the generator (`nondet_destroy`) and stays.
pub(crate) fn destroy(config: Config, s: &mut AnalysisState) {
    if s.destroyed {
        return;
    }
    s.destroyed = true;
    s.bbtrack.clear();
    mode::analysis_destroy(config.mode, s);
}

/// The end of `map2check_exit` (`Map2CheckFunctions.c:94-101`), once the
/// verdict is known: the aux files (witness on), `map2check_destroy`, and on
/// an error the confirmation file (witness on) and the abort. With no `dir`
/// (no mode) nothing is written and nothing aborts. Returns only without an
/// error, or without `dir`.
fn finish(dir: Option<&Path>, config: Config) {
    let failed = match state::with_state(|s| {
        let failed = s.got_error || !s.result.ok;
        if let (Some(dir), true) = (dir, config.witness) {
            generate_aux_files(dir, config, s, failed);
        }
        destroy(config, s);
        Ok(failed)
    }) {
        Ok(failed) => failed,
        Err(e) => match dir {
            Some(dir) => unknown_and_abort(dir, config, &e),
            None => {
                eprintln!("[map2check] error: {e}");
                return;
            }
        },
    };
    if let (true, Some(dir)) = (failed, dir) {
        if config.witness {
            generate_confirmation_file(dir);
        }
        std::process::abort();
    }
}

/// `map2check_exit` (`Map2CheckFunctions.c:89-102`): with no error
/// (`gotError` FALSE, no recorded violation) the end-of-program verdict of
/// the mode runs, and a violation it finds writes its property files, as
/// `analysis_is_program_correct` of the memory modes does
/// (`AnalysisModeMemtrack.c:138-146`); then [`finish`]. Without a mode the
/// verdict is only recorded (SD-03, SD-14).
pub(crate) fn map2check_exit() {
    let config = state::config();
    let dir = channel(config);
    let verdict = state::with_state(|s| {
        if s.got_error || !s.result.ok {
            return Ok(None);
        }
        s.end_of_program = true;
        Ok(
            mode::analysis_is_program_correct(config, s).map(|property| {
                s.set_false(property, 0, "");
                s.result.clone()
            }),
        )
    });
    match verdict {
        Ok(Some(result)) => {
            if let Some(dir) = &dir {
                write_properties(dir, &result);
            }
        }
        Ok(None) => {}
        Err(e) => match &dir {
            Some(dir) => unknown_and_abort(dir, config, &e),
            None => eprintln!("[map2check] error: {e}"),
        },
    }
    finish(dir.as_deref(), config);
}

/// `map2check_error` (`Map2CheckFunctions.c:72-75`): sets `gotError` and
/// runs [`map2check_exit`], which then skips the verdict and, with a mode
/// set, aborts.
pub(crate) fn map2check_error() {
    if let Err(e) = state::with_state(|s| {
        s.got_error = true;
        Ok(())
    }) {
        eprintln!("[map2check] error: {e}");
    }
    map2check_exit();
}

/// The analysis state cannot be read (its lock was poisoned by an earlier
/// panic), so the verdict is not known. Ends the run the way develop ends
/// an undecided one, `write_property_unknown` + `map2check_error`
/// (`AnalysisModeMemtrack.c:305-311`): any property file already written
/// (`NONE` from `map2check_success`) is removed, `map2check_property__unknown`
/// is written, then `map2check_checked_error` with witness on, and the
/// process aborts. The frontend reads UNKNOWN because `map2check_property`
/// is missing (`tools.cpp:98-103`). No log files: their data is unreadable.
fn unknown_and_abort(dir: &Path, config: Config, error: &crate::error::Map2CheckError) -> ! {
    eprintln!("[map2check] error: {error}; the verdict is UNKNOWN");
    legacy_files::remove_stale_property_files(dir);
    let unknown = AnalysisResult {
        ok: false,
        property: crate::caller::ViolatedProperty::Unknown,
        ..AnalysisResult::default()
    };
    write_properties(dir, &unknown);
    if config.witness {
        generate_confirmation_file(dir);
    }
    std::process::abort();
}

fn write_properties(dir: &Path, result: &AnalysisResult) {
    report(
        "the property files",
        legacy_files::write_property_files(dir, result),
    );
}

/// The first violation was just recorded (`map2check_error`,
/// `Map2CheckFunctions.c:72-75`): with a mode set, writes the property
/// files, ends the run and aborts. Without a mode, returns at once.
pub(crate) fn on_violation() {
    let config = state::config();
    let Some(dir) = channel(config) else {
        return;
    };
    match state::with_state(|s| Ok(s.result.clone())) {
        Ok(result) => write_properties(&dir, &result),
        Err(e) => unknown_and_abort(&dir, config, &e),
    }
    finish(Some(&dir), config);
    // `finish` returns only without a violation, which a recorded violation
    // rules out; abort anyway rather than let the program continue.
    std::process::abort();
}

/// `map2check_success` (`Map2CheckFunctions.c:67-70`): with a mode set,
/// `write_property(NONE, 0, "")` and [`map2check_exit`], which returns when
/// the program is correct. Returns whether the file channel handled the call.
pub(crate) fn on_success() -> bool {
    let config = state::config();
    let Some(dir) = channel(config) else {
        return false;
    };
    write_properties(&dir, &AnalysisResult::default());
    map2check_exit();
    true
}
