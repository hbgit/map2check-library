// SPDX-License-Identifier: GPL-3.0-only
#![deny(unsafe_code)]

use serde::Serialize;

/// Single basic-block execution record — analogous to `bbtrack_log_t` in C.
#[derive(Debug, Clone, Serialize)]
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
        let entries = vec![BasicBlockEntry::new(1, 10, "foo"), BasicBlockEntry::new(2, 20, "bar")];
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
}
