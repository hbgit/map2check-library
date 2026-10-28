// SPDX-License-Identifier: GPL-3.0-only
//! The gate divergences that SD-20 and SD-24 to SD-26 accept
//! (docs/cutover/gate-2026-10-27.md). Each SD names exact corpus keys; the
//! comparator only lets a divergence through with a row of
//! docs/cutover/deltas-aceitos.tsv, so these tests pin that every named key
//! has its row, with the values the gate measured. SD-24 also pins the IR
//! property behind it: the generated KLEE `main` is not `optnone`.

mod common;

use std::path::Path;
use std::process::Command;

use common::read;

/// Rows of deltas-aceitos.tsv: task prp gen field c_value rust_value sd_ref.
fn delta_rows() -> Vec<Vec<String>> {
    let text = read("docs/cutover/deltas-aceitos.tsv");
    let mut lines = text.lines().filter(|l| !l.trim().is_empty());
    assert_eq!(
        lines.next(),
        Some("task\tprp\tgen\tfield\tc_value\trust_value\tsd_ref")
    );
    lines
        .map(|l| l.split('\t').map(str::to_string).collect())
        .collect()
}

fn assert_rows(sd: &str, want: &[[&str; 6]]) {
    let rows = delta_rows();
    for w in want {
        let mut row: Vec<String> = w.iter().map(|s| s.to_string()).collect();
        row.push(sd.to_string());
        assert!(rows.contains(&row), "deltas-aceitos.tsv lacks {row:?}");
    }
    let n = rows
        .iter()
        .filter(|r| r.last().map(String::as_str) == Some(sd))
        .count();
    assert_eq!(n, want.len(), "{sd}: unexpected extra rows");
}

#[test]
fn sd20_gate_rows_name_the_property_race_keys() {
    assert_rows(
        "SD-20",
        &[
            [
                "list-ext-properties/simple-ext",
                "unreach-call",
                "symex",
                "verdict",
                "UNKNOWN",
                "FAILED",
            ],
            [
                "map2check-assert/ex01_false",
                "unreach-call",
                "symex",
                "verdict",
                "UNKNOWN",
                "FAILED",
            ],
            [
                "list-ext-properties/list-ext",
                "unreach-call",
                "symex",
                "verdict",
                "UNKNOWN",
                "FAILED",
            ],
            [
                "list-ext-properties/960521-1_1-1",
                "valid-memsafety",
                "symex",
                "line",
                "0",
                "533",
            ],
            [
                "list-ext-properties/960521-1_1-1",
                "valid-memsafety",
                "symex",
                "function",
                "",
                "main",
            ],
        ],
    );
}

#[test]
fn sd24_gate_rows_name_the_void_main_keys() {
    let mut want = Vec::new();
    for task in [
        "ldv-memsafety/memleaks_test10-2",
        "ldv-memsafety/memleaks_test3-2",
    ] {
        for gen in ["hybrid", "symex"] {
            want.push([
                task,
                "valid-memsafety",
                gen,
                "verdict",
                "UNKNOWN",
                "SUCCEEDED",
            ]);
        }
    }
    assert_rows("SD-24", &want);
}

#[test]
fn sd24_klee_generator_main_is_not_optnone() {
    let root = Path::new(env!("CARGO_MANIFEST_DIR"));
    let out = tempfile::tempdir().expect("tempdir");
    let status = Command::new("python3")
        .arg("-I")
        .arg(root.join("scripts/runtime-ir/gen_ll.py"))
        .args(["--module", "NonDetGeneratorKlee"])
        .arg(root.join("docs/runtime-abi/inventory.tsv"))
        .arg(out.path())
        .status()
        .expect("python3 runs gen_ll.py");
    assert!(status.success(), "gen_ll.py failed");
    let ll = std::fs::read_to_string(out.path().join("NonDetGeneratorKlee.ll")).expect("module");
    // No attribute group on main: KLEE's --optimize may fold a call whose
    // return type the program's `void main` does not match (SD-24).
    assert!(
        ll.contains(
            "define i32 @main(i32 %a0, ptr %a1) {\n  %r = call i32 @__map2check_main__(i32 %a0, ptr %a1)\n"
        ),
        "{ll}"
    );
    assert!(!ll.contains("optnone"), "{ll}");
}

#[test]
fn sd25_gate_rows_name_the_keys_klee_completes() {
    assert_rows(
        "SD-25",
        &[
            [
                "ldv-memsafety/ArraysOfVariableLength",
                "valid-memsafety",
                "hybrid",
                "verdict",
                "UNKNOWN",
                "SUCCEEDED",
            ],
            [
                "ldv-memsafety/ArraysOfVariableLength",
                "valid-memsafety",
                "symex",
                "verdict",
                "UNKNOWN",
                "SUCCEEDED",
            ],
            [
                "memsafety/960521-1-2",
                "valid-memsafety",
                "symex",
                "verdict",
                "UNKNOWN",
                "SUCCEEDED",
            ],
            [
                "list-ext-properties/960521-1_1-2",
                "valid-memsafety",
                "hybrid",
                "verdict",
                "UNKNOWN",
                "SUCCEEDED",
            ],
        ],
    );
}

#[test]
fn sd26_gate_row_names_the_uninitialised_read_key() {
    assert_rows(
        "SD-26",
        &[[
            "list-ext-properties/list-ext",
            "valid-memsafety",
            "afl",
            "verdict",
            "UNKNOWN",
            "FAILED",
        ]],
    );
}
