// SPDX-License-Identifier: GPL-3.0-only
#![cfg_attr(not(any(feature = "libfuzzer", feature = "klee")), deny(unsafe_code))]

use serde::Serialize;

/// Typed nondeterministic value — replaces `union Data` + `enum var_type_t`.
/// Each variant carries the actual value, eliminating unsafe type-punning.
///
/// One variant per `enum NONDET_TYPE` of Map2Check `develop`
/// (`Map2CheckTypes.h:41-58`), with the C type `NonDetGenerator.h` gives it
/// (`bool` is `typedef int bool`, `sector_t` is `unsigned long`, `loff_t` is
/// glibc's `long long`, `pointer` and `pchar` are addresses), plus `Float`,
/// which develop does not instrument, and the types Map2Check 9.0 added
/// (`LongLong` .. `MemoryByte`, `enum NONDET_TYPE` 17-22).
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
    // Map2Check 9.0's types for the SV-COMP names develop did not model
    // (issue #74 of Map2Check): FLOAT 16 is `Float` above; these are 17-22.
    #[serde(rename = "LONGLONG")]
    LongLong(i64),
    #[serde(rename = "ULONGLONG")]
    ULongLong(u64),
    #[serde(rename = "U8")]
    U8(u8),
    #[serde(rename = "U16")]
    U16(u16),
    #[serde(rename = "U32")]
    U32(u32),
    /// One byte of a `__VERIFIER_nondet_memory(p, n)`, which the validators'
    /// harness reads as `n` uchar inputs. Its own type, not `UChar`, so the
    /// frontend's seed converter can tell that `n` rows are one KLEE object.
    #[serde(rename = "MEMORY_BYTE")]
    MemoryByte(u8),
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
            Self::LongLong(_) => "LONGLONG",
            Self::ULongLong(_) => "ULONGLONG",
            Self::U8(_) => "U8",
            Self::U16(_) => "U16",
            Self::U32(_) => "U32",
            Self::MemoryByte(_) => "MEMORY_BYTE",
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

/// KLEE nondeterministic value generator (`symex`) — feature-gated, built
/// only from `klee/Cargo.toml` with rustc 1.72.1 (D1, route A'). Not in the
/// C header: the KLEE runtime is linked as bitcode, and its `main` and the
/// KLEE intrinsics it imports are not library API.
///
/// cbindgen:ignore
#[cfg(feature = "klee")]
pub mod klee;

/// Body of `__VERIFIER_error`, the same for every generator. Returns
/// whether the export must abort.
///
/// With an analysis mode set (a Map2Check run) it does nothing, as develop's
/// `__VERIFIER_error` (`Map2CheckFunctions.c:57-59`) and `__VERIFIER_assert`
/// (`AnalysisModeAssert.c:25-27`): there the passes carry the checks, the
/// target through `map2check_reach_target` and asserts through
/// `map2check_is_valid_assert`. An abort here would end the run with no
/// property recorded, and under KLEE's `--exit-on-error-type=Abort` stop the
/// exploration before the real violation (SD-08).
///
/// With the mode unset (direct API users), records a `Reachability`
/// violation, prints the JSON report and asks the export to abort.
#[cfg(any(feature = "libfuzzer", feature = "klee"))]
fn record_verifier_error() -> bool {
    if crate::state::config().mode.is_some() {
        return false;
    }
    if let Err(e) = crate::state::with_state(|s| {
        s.set_false(
            crate::caller::ViolatedProperty::Reachability,
            0,
            "__VERIFIER_error",
        );
        Ok(())
    }) {
        eprintln!("[map2check] error: {e}");
    }
    // Out of the lock (#19 ruling).
    crate::output::print_report_unless_mode_set();
    true
}

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
