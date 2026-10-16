// SPDX-License-Identifier: GPL-3.0-only
#![cfg_attr(not(feature = "libfuzzer"), deny(unsafe_code))]

use serde::Serialize;

/// Typed nondeterministic value — replaces `union Data` + `enum var_type_t`.
/// Each variant carries the actual value, eliminating unsafe type-punning.
///
/// One variant per `enum NONDET_TYPE` of Map2Check `develop`
/// (`Map2CheckTypes.h:41-58`), with the C type `NonDetGenerator.h` gives it
/// (`bool` is `typedef int bool`, `sector_t` is `unsigned long`, `loff_t` is
/// glibc's `long long`, `pointer` and `pchar` are addresses), plus `Float`,
/// which develop does not instrument.
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
    Char(i8),
    #[serde(rename = "FLOAT")]
    Float(f32),
    #[serde(rename = "DOUBLE")]
    Double(f64),
    #[serde(rename = "UNSIGNED")]
    Unsigned(u32),
    #[serde(rename = "POINTER")]
    Pointer(usize),
    #[serde(rename = "USHORT")]
    UShort(u16),
    #[serde(rename = "SHORT")]
    Short(i16),
    #[serde(rename = "ULONG")]
    ULong(u64),
    #[serde(rename = "BOOL")]
    Bool(i32),
    #[serde(rename = "UCHAR")]
    UChar(u8),
    #[serde(rename = "PCHAR")]
    PChar(usize),
    #[serde(rename = "SIZE_T")]
    SizeT(usize),
    #[serde(rename = "LOFF_T")]
    LoffT(i64),
    #[serde(rename = "SECTOR_T")]
    SectorT(u64),
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
            Self::Unsigned(_) => "UNSIGNED",
            Self::Pointer(_) => "POINTER",
            Self::UShort(_) => "USHORT",
            Self::Short(_) => "SHORT",
            Self::ULong(_) => "ULONG",
            Self::Bool(_) => "BOOL",
            Self::UChar(_) => "UCHAR",
            Self::PChar(_) => "PCHAR",
            Self::SizeT(_) => "SIZE_T",
            Self::LoffT(_) => "LOFF_T",
            Self::SectorT(_) => "SECTOR_T",
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

    #[test]
    fn type_name_covers_every_variant() {
        let cases = [
            (NonDetValue::Int(-1), "INT"),
            (NonDetValue::UInt(1), "UINT"),
            (NonDetValue::Long(-1), "LONG"),
            (NonDetValue::Char(-1), "CHAR"),
            (NonDetValue::Float(0.5), "FLOAT"),
            (NonDetValue::Double(0.5), "DOUBLE"),
            (NonDetValue::Unsigned(1), "UNSIGNED"),
            (NonDetValue::Pointer(1), "POINTER"),
            (NonDetValue::UShort(1), "USHORT"),
            (NonDetValue::Short(-1), "SHORT"),
            (NonDetValue::ULong(1), "ULONG"),
            (NonDetValue::Bool(1), "BOOL"),
            (NonDetValue::UChar(1), "UCHAR"),
            (NonDetValue::PChar(1), "PCHAR"),
            (NonDetValue::SizeT(1), "SIZE_T"),
            (NonDetValue::LoffT(-1), "LOFF_T"),
            (NonDetValue::SectorT(1), "SECTOR_T"),
        ];
        for (value, name) in cases {
            assert_eq!(value.type_name(), name);
            assert!(serde_json::to_string(&value).unwrap().contains(name));
        }
    }
}
