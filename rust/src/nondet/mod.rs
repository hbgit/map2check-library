// SPDX-License-Identifier: GPL-3.0-only
#![cfg_attr(not(feature = "libfuzzer"), deny(unsafe_code))]

use serde::Serialize;

/// Typed nondeterministic value — replaces `union Data` + `enum var_type_t`.
/// Each variant carries the actual value, eliminating unsafe type-punning.
#[derive(Debug, Clone, Serialize, PartialEq)]
#[serde(tag = "type", content = "value")]
pub enum NonDetValue {
    #[serde(rename = "INT")]
    Int(i32),
    #[serde(rename = "UINT")]
    UInt(u32),
    #[serde(rename = "LONG")]
    Long(i64),
    #[serde(rename = "CHAR")]
    Char(u8),
    #[serde(rename = "FLOAT")]
    Float(f32),
    #[serde(rename = "DOUBLE")]
    Double(f64),
}

impl NonDetValue {
    pub fn type_name(&self) -> &'static str {
        match self {
            Self::Int(_) => "INT",
            Self::UInt(_) => "UINT",
            Self::Long(_) => "LONG",
            Self::Char(_) => "CHAR",
            Self::Float(_) => "FLOAT",
            Self::Double(_) => "DOUBLE",
        }
    }
}

/// Analogous to `non_det_log_t` in C.
#[derive(Debug, Clone, Serialize)]
pub struct NonDetEntry {
    pub step: u64,
    pub line: u32,
    pub scope: u32,
    pub function_name: String,
    pub value: NonDetValue,
}

impl NonDetEntry {
    pub fn new(step: u64, line: u32, scope: u32, function_name: &str, value: NonDetValue) -> Self {
        Self {
            step,
            line,
            scope,
            function_name: function_name.to_owned(),
            value,
        }
    }
}

/// LibFuzzer nondeterministic value generator — feature-gated.
#[cfg(feature = "libfuzzer")]
pub mod libfuzzer;

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn nondet_entry_int_serializes() {
        let entry = NonDetEntry::new(1, 42, 0, "foo", NonDetValue::Int(99));
        assert_eq!(entry.value, NonDetValue::Int(99));
        assert_eq!(entry.value.type_name(), "INT");
        let json = serde_json::to_string(&entry).unwrap();
        assert!(json.contains("\"INT\""));
        assert!(json.contains("99"));
    }

    #[test]
    fn nondet_float_from_bits_is_safe() {
        // Replaces C union FloatPattern type-punning
        let bytes: u32 = 0x3f80_0000; // 1.0f32
        let val = f32::from_bits(bytes);
        let entry = NonDetEntry::new(1, 1, 0, "main", NonDetValue::Float(val));
        assert!((val - 1.0_f32).abs() < f32::EPSILON);
        assert_eq!(entry.value.type_name(), "FLOAT");
    }

    #[test]
    fn nondet_double_from_bits_is_safe() {
        // Replaces C union DoublePattern type-punning
        let bytes: u64 = 0x3ff0_0000_0000_0000; // 1.0f64
        let val = f64::from_bits(bytes);
        let _entry = NonDetEntry::new(1, 1, 0, "main", NonDetValue::Double(val));
        assert!((val - 1.0_f64).abs() < f64::EPSILON);
    }
}
