// SPDX-License-Identifier: GPL-3.0-only
#![deny(unsafe_code)]

use serde::Serialize;

/// Properties that can be violated during program analysis.
/// `#[repr(C)]` allows FFI callers to pass this enum across the ABI boundary.
///
/// The discriminants are the values of `enum ViolatedProperty` of the C
/// runtime of Map2Check `develop` (`Map2CheckTypes.h:80-91`), so the C ABI
/// (`write_property`, `set_false_result`, `get_current_property`) uses the C
/// numbers; `tests/abi/enum-map.tsv` pairs the enumerators and
/// `tests/abi/check-signatures.sh` checks the values. `Concurrency` has no C
/// counterpart and comes after them.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Default)]
#[repr(C)]
pub enum ViolatedProperty {
    /// `NONE`: no violation.
    #[default]
    None = 0,
    /// The analysis could not decide (`UNKNOWN` in `PropertyGenerator.c`).
    Unknown = 1,
    /// `FALSE_FREE`.
    MemsafetyFree = 2,
    /// `FALSE_DEREF`.
    MemsafetyDeref = 3,
    /// `FALSE_MEMTRACK`.
    MemsafetyMemtrack = 4,
    /// The target function was reached (`TARGET_REACHED`).
    Reachability = 5,
    /// `FALSE_OVERFLOW`.
    Overflow = 6,
    /// A failed `map2check_is_valid_assert` (`ASSERT` in `PropertyGenerator.c`).
    Assert = 7,
    /// `FALSE_MEMCLEANUP`.
    MemsafetyMemcleanup = 8,
    /// Signed division or remainder by zero (`FALSE_DIVBYZERO`), reported by
    /// `map2check_binop_div_signed` and `map2check_binop_rem_signed`.
    DivByZero = 9,
    /// No counterpart in the C runtime.
    Concurrency = 10,
}

impl ViolatedProperty {
    pub fn as_str(self) -> &'static str {
        match self {
            Self::Overflow => "OVERFLOW",
            Self::MemsafetyFree => "MEMSAFETY_FREE",
            Self::MemsafetyDeref => "MEMSAFETY_DEREF",
            Self::MemsafetyMemtrack => "MEMSAFETY_MEMTRACK",
            Self::MemsafetyMemcleanup => "MEMSAFETY_MEMCLEANUP",
            Self::Reachability => "REACHABILITY",
            Self::Concurrency => "CONCURRENCY",
            Self::None => "NONE",
            Self::Assert => "ASSERT",
            Self::Unknown => "UNKNOWN",
            Self::DivByZero => "DIVBYZERO",
        }
    }
}

/// Central analysis result, analogous to `caller_result_t` in C.
#[derive(Debug, Clone, Serialize)]
pub struct AnalysisResult {
    pub step: u64,
    pub line: u32,
    pub function_name: String,
    pub ok: bool,
    pub property: ViolatedProperty,
}

impl Default for AnalysisResult {
    fn default() -> Self {
        Self {
            step: 0,
            line: 0,
            function_name: String::new(),
            ok: true,
            property: ViolatedProperty::None,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn default_result_is_ok_with_none_property() {
        let r = AnalysisResult::default();
        assert!(r.ok);
        assert_eq!(r.property, ViolatedProperty::None);
        assert_eq!(r.step, 0);
    }

    #[test]
    fn violated_property_as_str() {
        assert_eq!(ViolatedProperty::Overflow.as_str(), "OVERFLOW");
        assert_eq!(ViolatedProperty::Reachability.as_str(), "REACHABILITY");
        assert_eq!(ViolatedProperty::None.as_str(), "NONE");
    }

    /// The discriminants are the values of develop's `enum ViolatedProperty`
    /// (`Map2CheckTypes.h:80-91`), so `write_property` takes the C values;
    /// `Concurrency` has no C counterpart and comes after them.
    #[test]
    fn discriminants_are_the_values_of_the_c_enum() {
        let cases = [
            (ViolatedProperty::None, 0),
            (ViolatedProperty::Unknown, 1),
            (ViolatedProperty::MemsafetyFree, 2),
            (ViolatedProperty::MemsafetyDeref, 3),
            (ViolatedProperty::MemsafetyMemtrack, 4),
            (ViolatedProperty::Reachability, 5),
            (ViolatedProperty::Overflow, 6),
            (ViolatedProperty::Assert, 7),
            (ViolatedProperty::MemsafetyMemcleanup, 8),
            (ViolatedProperty::DivByZero, 9),
            (ViolatedProperty::Concurrency, 10),
        ];
        for (property, value) in cases {
            assert_eq!(property as i32, value, "{property:?}");
        }
    }

    #[test]
    fn violated_property_as_str_covers_every_variant() {
        let cases = [
            (ViolatedProperty::Overflow, "OVERFLOW"),
            (ViolatedProperty::MemsafetyFree, "MEMSAFETY_FREE"),
            (ViolatedProperty::MemsafetyDeref, "MEMSAFETY_DEREF"),
            (ViolatedProperty::MemsafetyMemtrack, "MEMSAFETY_MEMTRACK"),
            (
                ViolatedProperty::MemsafetyMemcleanup,
                "MEMSAFETY_MEMCLEANUP",
            ),
            (ViolatedProperty::Reachability, "REACHABILITY"),
            (ViolatedProperty::Concurrency, "CONCURRENCY"),
            (ViolatedProperty::None, "NONE"),
            (ViolatedProperty::Assert, "ASSERT"),
            (ViolatedProperty::Unknown, "UNKNOWN"),
            (ViolatedProperty::DivByZero, "DIVBYZERO"),
        ];
        for (property, name) in cases {
            assert_eq!(property.as_str(), name);
        }
    }
}
