// SPDX-License-Identifier: GPL-3.0-only
// JSON output serialization.
#![deny(unsafe_code)]
// Replaces lib/json-maker.c and lib/to_string/ftoa.c entirely.
// serde_json handles JSON construction and float formatting safely.

pub mod legacy_files;
pub(crate) mod termination;

// The JSON channel is host-only: the drop-in core has none (see
// `print_report_unless_mode_set` below) and is built without serde.
#[cfg(not(feature = "dropin"))]
use serde::Serialize;

#[cfg(not(feature = "dropin"))]
use crate::{caller::ViolatedProperty, error::Map2CheckError, state::AnalysisState};

/// Top-level JSON output structure.
/// Schema matches what Map2Check tool expects from the library.
#[cfg(not(feature = "dropin"))]
#[derive(Serialize)]
struct Map2CheckLog<'a> {
    map2check_log: LogBody<'a>,
}

#[cfg(not(feature = "dropin"))]
#[derive(Serialize)]
struct LogBody<'a> {
    result: &'static str,
    step: u64,
    #[serde(skip_serializing_if = "Option::is_none")]
    property: Option<&'static str>,
    #[serde(skip_serializing_if = "Option::is_none")]
    line_number: Option<u32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    function_name: Option<&'a str>,
    #[serde(rename = "Container_TrackBBLog")]
    bbtrack: &'a [crate::bbtrack::BasicBlockEntry],
    #[serde(rename = "Container_NonDetLog")]
    nondets: &'a [crate::nondet::NonDetEntry],
    #[serde(
        rename = "Container_AllocationLog",
        skip_serializing_if = "Option::is_none"
    )]
    memtrack: Option<&'a [crate::memtrack::MemTrackEntry]>,
}

/// Serialize the complete analysis state to a JSON string.
/// Replaces `print_all_containers_as_json()` in caller_lib_result.c.
#[cfg(not(feature = "dropin"))]
pub fn to_json(state: &AnalysisState) -> Result<String, Map2CheckError> {
    let result = &state.result;
    let is_mem_violation = matches!(
        result.property,
        ViolatedProperty::MemsafetyFree
            | ViolatedProperty::MemsafetyDeref
            | ViolatedProperty::MemsafetyMemtrack
            | ViolatedProperty::MemsafetyMemcleanup
    );

    let log = Map2CheckLog {
        map2check_log: LogBody {
            result: if result.ok { "TRUE" } else { "FALSE" },
            step: result.step,
            property: if result.ok {
                None
            } else {
                Some(result.property.as_str())
            },
            line_number: if result.ok { None } else { Some(result.line) },
            function_name: if result.ok || result.function_name.is_empty() {
                None
            } else {
                Some(&result.function_name)
            },
            bbtrack: &state.bbtrack,
            nondets: &state.nondets,
            memtrack: if is_mem_violation {
                Some(&state.memtrack)
            } else {
                None
            },
        },
    };

    serde_json::to_string_pretty(&log).map_err(Map2CheckError::from)
}

/// Print the JSON report to stdout, as the C library did. A failed write
/// (closed stdout, EPIPE) is reported on stderr instead of panicking.
#[cfg(not(feature = "dropin"))]
pub fn print_json(state: &AnalysisState) -> Result<(), Map2CheckError> {
    write_report(&to_json(state)?);
    Ok(())
}

#[cfg(not(feature = "dropin"))]
fn write_report(json: &str) {
    use std::io::Write as _;
    if let Err(e) = writeln!(std::io::stdout().lock(), "{json}") {
        eprintln!("[map2check] cannot print the JSON report: {e}");
    }
}

/// The JSON report channel of the exports (#14). Prints only when no
/// analysis mode is set: a Map2Check run reports through the result files
/// and keeps the analysed program's stdout clean, as develop does. The
/// report is serialised under the state lock and written after the lock is
/// released, so stdout can never affect the state or the verdict.
#[cfg(not(feature = "dropin"))]
pub fn print_report_unless_mode_set() {
    if crate::state::config().mode.is_some() {
        return;
    }
    match crate::state::with_state(|s| to_json(s)) {
        Ok(json) => write_report(&json),
        Err(e) => eprintln!("[map2check] error: {e}"),
    }
}

/// The drop-in core (feature `dropin`) has no JSON channel, as the C runtime
/// has none: there `map2check_init` runs the `analysis_init` of the linked
/// mode module, which always selects a mode, so the channel above could
/// never print. Compiled out, the JSON serialiser is not in
/// `Map2CheckFunctions.bc`; its float formatting carried a `freeze`, which
/// KLEE 3.1 cannot execute (scripts/runtime-ir/check_no_freeze.py).
#[cfg(feature = "dropin")]
pub fn print_report_unless_mode_set() {}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::{
        bbtrack::BasicBlockEntry,
        caller::{AnalysisResult, ViolatedProperty},
        nondet::{NonDetEntry, NonDetValue},
        state::AnalysisState,
    };

    fn state_ok() -> AnalysisState {
        AnalysisState {
            result: AnalysisResult::default(),
            nondets: vec![NonDetEntry::new(1, 10, 0, "main", NonDetValue::Int(42))],
            memtrack: vec![],
            bbtrack: vec![BasicBlockEntry::new(1, 5, "main")],
            ..AnalysisState::default()
        }
    }

    #[test]
    fn ok_result_serializes_true() {
        let mut state = state_ok();
        state.result.step = 42;
        let json = to_json(&state).unwrap();
        assert!(json.contains("\"TRUE\""));
        assert!(!json.contains("\"FALSE\""));
        assert!(json.contains("\"Container_TrackBBLog\""));
        assert!(json.contains("\"step\": 42"));
    }

    #[test]
    fn false_result_includes_property_and_line() {
        let mut state = state_ok();
        state.result.ok = false;
        state.result.property = ViolatedProperty::Reachability;
        state.result.line = 42;
        state.result.function_name = "foo".to_owned();

        let json = to_json(&state).unwrap();
        assert!(json.contains("\"FALSE\""));
        assert!(json.contains("REACHABILITY"));
        assert!(json.contains("42"));
        assert!(json.contains("foo"));
    }

    #[test]
    fn memtrack_included_only_for_memory_violations() {
        let mut state = state_ok();
        state.result.ok = false;
        state.result.property = ViolatedProperty::Overflow;
        let json_overflow = to_json(&state).unwrap();
        assert!(!json_overflow.contains("Container_AllocationLog"));

        state.result.property = ViolatedProperty::MemsafetyFree;
        state.memtrack.push(crate::memtrack::MemTrackEntry::new(
            1, 10, 0, 0x100, 0x200, true, false, "ptr", "main", 8, 1, false,
        ));
        let json_mem = to_json(&state).unwrap();
        assert!(json_mem.contains("Container_AllocationLog"));
        assert!(json_mem.contains("var_mem_address"));
        assert!(json_mem.contains("mem_address_points_to"));
    }

    #[test]
    fn output_is_valid_json() {
        let state = state_ok();
        let json = to_json(&state).unwrap();
        let parsed: serde_json::Value = serde_json::from_str(&json).unwrap();
        assert!(parsed["map2check_log"].is_object());
    }

    /// Snapshot of the whole report (#14): the JSON is an additional channel
    /// with its own schema (SD-01); Map2Check reads the files of
    /// `legacy_files`. A change to this text is a schema change.
    #[test]
    fn json_report_snapshot() {
        let mut state = state_ok();
        state.result.ok = false;
        state.result.step = 3;
        state.result.property = ViolatedProperty::MemsafetyFree;
        state.result.line = 12;
        state.result.function_name = "main".to_owned();
        state.memtrack.push(crate::memtrack::MemTrackEntry::new(
            2, 12, 1, 0x100, 0x200, true, false, "p", "main", 16, 4, false,
        ));
        let snapshot = std::fs::read_to_string(concat!(
            env!("CARGO_MANIFEST_DIR"),
            "/rust/src/output/json_report.snap"
        ))
        .unwrap();
        assert_eq!(to_json(&state).unwrap() + "\n", snapshot);
    }

    #[test]
    fn print_json_succeeds_for_valid_state() {
        assert!(print_json(&state_ok()).is_ok());
    }
}
