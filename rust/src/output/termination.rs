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

/// `map2check_init()` with a mode set: removes the property files of an
/// earlier run before this one writes its own.
pub(crate) fn on_init() {
    if let Some(dir) = channel(state::config()) {
        legacy_files::remove_stale_property_files(&dir);
    }
}

/// `generate_aux_files` (`WitnessGeneration.c:14-25`) when witness
/// generation is on: the basic-block log, the logs of the memory modes
/// (`analysis_generate_aux_witness_files`, `AnalysisModeMemtrack.c:148-152`)
/// and, on a violation, the nondet log.
fn write_aux_files(dir: &Path, config: Config, s: &AnalysisState, end_of_program: bool) {
    report(
        legacy_files::TRACKBB_LOG_FILE,
        legacy_files::write_trackbb_log(dir, &s.bbtrack),
    );
    let logs = LegacyLogs::replay(
        &s.memtrack,
        &s.nondets,
        s.failed_free.as_ref(),
        end_of_program,
    );
    if matches!(
        config.mode,
        Some(AnalysisMode::Memtrack | AnalysisMode::Memcleanup)
    ) {
        report(legacy_files::HEAP_LOG_FILE, logs.write_heap_log(dir));
        report(
            legacy_files::ALLOCATION_LOG_FILE,
            logs.write_allocation_log(dir),
        );
        report(legacy_files::LIST_LOG_FILE, logs.write_list_log(dir));
    }
    if !s.result.ok && nondet_log_fits(s) {
        report(legacy_files::NONDET_LOG_FILE, logs.write_nondet_log(dir));
    }
}

/// Under KLEE a log longer than `KLEE_LOG_MAX_ROWS` is not written (nor
/// concretised): the frontend falls back to the state's `.ktest`, as with
/// Map2Check 9.0 (issue #75). Elsewhere every log is written.
fn nondet_log_fits(s: &AnalysisState) -> bool {
    #[cfg(feature = "klee")]
    return s.nondets.len() <= crate::nondet::klee::KLEE_LOG_MAX_ROWS;
    #[cfg(not(feature = "klee"))]
    {
        let _ = s;
        true
    }
}

/// `map2check_exit` after the verdict is known: aux files, then
/// `analysis_destroy`, then, on a violation, the confirmation file and the
/// abort. Returns only when there is no violation.
fn exit(dir: &Path, config: Config, end_of_program: bool) {
    let failed = match state::with_state(|s| {
        if config.witness {
            super::prepare_for_output(s);
            write_aux_files(dir, config, s, end_of_program);
        }
        mode::analysis_destroy(config.mode, s);
        Ok(!s.result.ok)
    }) {
        Ok(failed) => failed,
        Err(e) => unknown_and_abort(dir, config, &e),
    };
    if failed {
        write_checked_error(dir, config);
        std::process::abort();
    }
}

fn write_checked_error(dir: &Path, config: Config) {
    if config.witness {
        report(
            legacy_files::CHECKED_ERROR_FILE,
            legacy_files::write_checked_error(dir),
        );
    }
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
    write_checked_error(dir, config);
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
/// files, ends the run and aborts. `end_of_program` is true when the
/// violation is the end-of-program verdict, whose check appends rows to
/// develop's allocation log. Without a mode, returns at once.
pub(crate) fn on_violation(end_of_program: bool) {
    let config = state::config();
    let Some(dir) = channel(config) else {
        return;
    };
    match state::with_state(|s| Ok(s.result.clone())) {
        Ok(result) => write_properties(&dir, &result),
        Err(e) => unknown_and_abort(&dir, config, &e),
    }
    exit(&dir, config, end_of_program);
    // `exit` returns only without a violation, which a recorded violation
    // rules out; abort anyway rather than let the program continue.
    std::process::abort();
}

/// `map2check_success` (`Map2CheckFunctions.c:67-70`, `:89-102`): with a
/// mode set, writes `NONE`, runs the end-of-program verdict, ends the run,
/// and returns when the program is correct. Returns whether the file
/// channel handled the call.
pub(crate) fn on_success() -> bool {
    let config = state::config();
    let Some(dir) = channel(config) else {
        return false;
    };
    write_properties(&dir, &AnalysisResult::default());
    let verdict = state::with_state(|s| {
        let end_of_program = s.result.ok;
        if end_of_program {
            if let Some(property) = mode::analysis_is_program_correct(config, s) {
                s.set_false(property, 0, "");
            }
        }
        Ok((end_of_program, s.result.clone()))
    });
    let end_of_program = match verdict {
        Ok((end_of_program, result)) => {
            if !result.ok {
                write_properties(&dir, &result);
            }
            end_of_program
        }
        Err(e) => unknown_and_abort(&dir, config, &e),
    };
    exit(&dir, config, end_of_program);
    true
}
