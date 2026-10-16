// SPDX-License-Identifier: GPL-3.0-only
//! Issue #8: every `#[no_mangle]` export must run its body inside
//! `ffi_guard`, so a panic is recovered at the FFI boundary (on unwinding
//! profiles) instead of unwinding into C.

mod common;

use common::read;

const SOURCES: &[&str] = &["rust/src/ffi.rs", "rust/src/nondet/libfuzzer.rs"];

/// Drops comments and string/char-literal contents so braces inside them do
/// not confuse the body matcher.
fn strip(src: &str) -> String {
    let c: Vec<char> = src.chars().collect();
    let mut out = String::new();
    let mut i = 0;
    while i < c.len() {
        if c[i] == '/' && c.get(i + 1) == Some(&'/') {
            while i < c.len() && c[i] != '\n' {
                i += 1;
            }
        } else if c[i] == '"' {
            i += 1;
            while i < c.len() && c[i] != '"' {
                i += if c[i] == '\\' { 2 } else { 1 };
            }
            i += 1;
            out.push_str("\"\"");
        } else if c[i] == '\'' && c.get(i + 2) == Some(&'\'') {
            i += 3;
        } else {
            out.push(c[i]);
            i += 1;
        }
    }
    out
}

/// Returns `(name, body)` for each `#[no_mangle]` function that is not
/// test-only.
fn exports(src: &str) -> Vec<(String, String)> {
    let mut found = Vec::new();
    let mut rest = src;
    while let Some(pos) = rest.find("#[no_mangle]") {
        let before = &rest[..pos];
        let after = &rest[pos + "#[no_mangle]".len()..];
        rest = after;
        // `#[cfg(test)]` directly above the attribute marks a test double.
        if before.trim_end().ends_with("#[cfg(test)]") {
            continue;
        }
        let fn_at = after.find("fn ").expect("fn after #[no_mangle]") + 3;
        let name: String = after[fn_at..]
            .chars()
            .take_while(|ch| ch.is_alphanumeric() || *ch == '_' || *ch == '$')
            .collect();
        let open = after.find('{').expect("function body");
        let mut depth = 0;
        let mut end = open;
        for (off, ch) in after[open..].char_indices() {
            match ch {
                '{' => depth += 1,
                '}' => {
                    depth -= 1;
                    if depth == 0 {
                        end = open + off;
                        break;
                    }
                }
                _ => {}
            }
        }
        found.push((name, after[open + 1..end].to_owned()));
    }
    found
}

#[test]
fn every_no_mangle_export_body_is_wrapped_in_ffi_guard() {
    let mut total = 0;
    for file in SOURCES {
        let src = strip(&read(file));
        // Only production code: drop the in-file test module.
        let prod = src.split("#[cfg(test)]\nmod tests").next().unwrap();
        for (name, body) in exports(prod) {
            total += 1;
            let trimmed = body.trim();
            assert!(
                trimmed.starts_with("ffi_guard(") || trimmed.contains("ffi_guard("),
                "{file}: export `{name}` is not wrapped in ffi_guard"
            );
        }
    }
    assert!(
        total > 40,
        "scanner found only {total} exports; is it broken?"
    );
}

#[test]
fn scanner_detects_an_unguarded_export() {
    let src = "#[no_mangle]\npub extern \"C\" fn bad() { panic!(); }\n";
    let found = exports(&strip(src));
    assert_eq!(found.len(), 1);
    assert!(!found[0].1.contains("ffi_guard("));
}
