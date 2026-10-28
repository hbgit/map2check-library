// SPDX-License-Identifier: GPL-3.0-only
#![deny(unsafe_code)]

/// Single basic-block execution record — analogous to `bbtrack_log_t` in C.
#[derive(Debug, Clone)]
#[cfg_attr(not(feature = "dropin"), derive(serde::Serialize))]
pub struct BasicBlockEntry {
    pub step: u64,
    pub line: u32,
    pub function_name: String,
}

impl BasicBlockEntry {
    pub fn new(step: u64, line: u32, function_name: &str) -> Self {
        Self {
            step,
            line,
            function_name: function_name.to_owned(),
        }
    }
}

/// `trackbb_new_row` (`TrackBBLog.c:15-21`), private to the Rust core
/// (SD-22): a row with `line` and a copy of `function_name`. develop copies
/// the name into `char[35]`; this library keeps the whole name (SD-17).
pub(crate) fn trackbb_new_row(step: u64, line: u32, function_name: &str) -> BasicBlockEntry {
    BasicBlockEntry::new(step, line, function_name)
}

/// `is_in_tracked` (`TrackBBLog.c:23-33`), private to the Rust core
/// (SD-22): whether a row of `line` exists, searched from the last row.
pub(crate) fn is_in_tracked(line: u32, log: &[BasicBlockEntry]) -> bool {
    log.iter().rev().any(|e| e.line == line)
}

/// Returns `true` if any tracked basic block is at `line`.
/// Replaces `map2check_is_in_trackbb_container` (0/1 int) with a proper bool.
pub fn contains_line(entries: &[BasicBlockEntry], line: u32) -> bool {
    entries.iter().any(|e| e.line == line)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn basic_block_entry_created_correctly() {
        let e = BasicBlockEntry::new(1, 42, "main");
        assert_eq!(e.line, 42);
        assert_eq!(e.function_name, "main");
        assert_eq!(e.step, 1);
    }

    #[test]
    fn contains_line_finds_existing() {
        let entries = vec![
            BasicBlockEntry::new(1, 10, "foo"),
            BasicBlockEntry::new(2, 20, "bar"),
        ];
        assert!(contains_line(&entries, 10));
        assert!(contains_line(&entries, 20));
    }

    #[test]
    fn contains_line_returns_false_when_absent() {
        let entries = vec![BasicBlockEntry::new(1, 10, "foo")];
        assert!(!contains_line(&entries, 99));
    }

    #[test]
    fn entry_serializes_to_json() {
        let e = BasicBlockEntry::new(3, 15, "check");
        let json = serde_json::to_string(&e).unwrap();
        assert!(json.contains("\"step\":3"));
        assert!(json.contains("\"line\":15"));
        assert!(json.contains("\"check\""));
    }

    /// `is_in_tracked` (`TrackBBLog.c:23-33`), private in the Rust core
    /// (SD-22): whether any row has `line`, whatever its function name.
    #[test]
    fn is_in_tracked_matches_any_row_of_the_line() {
        let rows = vec![
            BasicBlockEntry::new(1, 10, "foo"),
            BasicBlockEntry::new(2, 20, "bar"),
        ];
        assert!(is_in_tracked(10, &rows));
        assert!(is_in_tracked(20, &rows));
        assert!(!is_in_tracked(30, &rows));
        assert!(!is_in_tracked(0, &[]));
    }

    /// `trackbb_new_row` (`TrackBBLog.c:15-21`), private in the Rust core
    /// (SD-22): a row with the line and a copy of the name.
    #[test]
    fn trackbb_new_row_copies_line_and_name() {
        let name = String::from("main");
        let row = trackbb_new_row(5, 7, &name);
        drop(name);
        assert_eq!(
            (row.step, row.line, row.function_name.as_str()),
            (5, 7, "main")
        );
    }
}
