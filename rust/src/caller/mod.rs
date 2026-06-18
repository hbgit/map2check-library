// SPDX-License-Identifier: GPL-3.0-only
#![deny(unsafe_code)]

use serde::Serialize;

/// Properties that can be violated during program analysis.
/// `#[repr(C)]` allows FFI callers to pass this enum across the ABI boundary.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Default)]
#[repr(C)]
pub enum ViolatedProperty {
    Overflow,
    MemsafetyFree,
    MemsafetyDeref,
    MemsafetyMemtrack,
    MemsafetyMemcleanup,
    Reachability,
    Concurrency,
    #[default]
    None,
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
}
