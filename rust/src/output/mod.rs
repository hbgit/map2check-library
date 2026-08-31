// SPDX-License-Identifier: GPL-3.0-only
// JSON output serialization.
#![deny(unsafe_code)]
// Replaces lib/json-maker.c and lib/to_string/ftoa.c entirely.
// serde_json handles JSON construction and float formatting safely.

use serde::Serialize;

use crate::{caller::ViolatedProperty, error::Map2CheckError, state::AnalysisState};

/// Top-level JSON output structure.
/// Schema matches what Map2Check tool expects from the library.
#[derive(Serialize)]
struct Map2CheckLog<'a> {
    map2check_log: LogBody<'a>,
}

#[derive(Serialize)]
struct LogBody<'a> {
    result: &'static str,
    #[serde(skip_serializing_if = "Option::is_none")]
    property: Option<&'static str>,
    #[serde(skip_serializing_if = "Option::is_none")]
    line_number: Option<u32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    function_name: Option<&'a str>,
    #[serde(rename = "Container_BasicBlockLog")]
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

/// Print the JSON report to stdout, as the C library did.
pub fn print_json(state: &AnalysisState) -> Result<(), Map2CheckError> {
    let json = to_json(state)?;
    println!("{json}");
    Ok(())
}

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
        }
    }

    #[test]
    fn ok_result_serializes_true() {
        let state = state_ok();
        let json = to_json(&state).unwrap();
        assert!(json.contains("\"TRUE\""));
        assert!(!json.contains("\"FALSE\""));
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
        let json_mem = to_json(&state).unwrap();
        assert!(json_mem.contains("Container_AllocationLog"));
    }

    #[test]
    fn output_is_valid_json() {
        let state = state_ok();
        let json = to_json(&state).unwrap();
        let parsed: serde_json::Value = serde_json::from_str(&json).unwrap();
        assert!(parsed["map2check_log"].is_object());
    }
}
