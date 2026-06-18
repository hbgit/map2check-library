// SPDX-License-Identifier: GPL-3.0-only
// Integer overflow verification conditions.
#![deny(unsafe_code)]
// Replaces analysis_overflow.c — uses Rust's checked_* arithmetic
// instead of manual INT_MAX/INT_MIN boundary comparisons.

use crate::{
    analysismode::{VccChecker, VccContext, VccOutcome},
    caller::ViolatedProperty,
    error::Map2CheckError,
};

// ── Helpers ───────────────────────────────────────────────────────────────────

fn overflow_outcome() -> VccOutcome {
    VccOutcome::Violated {
        property: ViolatedProperty::Overflow,
    }
}

fn check_result(ok: bool) -> VccOutcome {
    if ok { VccOutcome::Safe } else { overflow_outcome() }
}

// ── i32 checkers ─────────────────────────────────────────────────────────────

pub struct AddI32 { pub lhs: i32, pub rhs: i32 }
pub struct SubI32 { pub lhs: i32, pub rhs: i32 }
pub struct MulI32 { pub lhs: i32, pub rhs: i32 }
pub struct DivI32 { pub lhs: i32, pub rhs: i32 }
pub struct ShlI32 { pub lhs: i32, pub rhs: u32 }
pub struct ShrI32 { pub lhs: i32, pub rhs: u32 }
pub struct NegI32 { pub val: i32 }

impl VccChecker for AddI32 {
    fn check(&self, _ctx: &VccContext) -> Result<VccOutcome, Map2CheckError> {
        Ok(check_result(self.lhs.checked_add(self.rhs).is_some()))
    }
}

impl VccChecker for SubI32 {
    fn check(&self, _ctx: &VccContext) -> Result<VccOutcome, Map2CheckError> {
        Ok(check_result(self.lhs.checked_sub(self.rhs).is_some()))
    }
}

impl VccChecker for MulI32 {
    fn check(&self, _ctx: &VccContext) -> Result<VccOutcome, Map2CheckError> {
        Ok(check_result(self.lhs.checked_mul(self.rhs).is_some()))
    }
}

impl VccChecker for DivI32 {
    fn check(&self, _ctx: &VccContext) -> Result<VccOutcome, Map2CheckError> {
        Ok(check_result(self.lhs.checked_div(self.rhs).is_some()))
    }
}

impl VccChecker for ShlI32 {
    fn check(&self, _ctx: &VccContext) -> Result<VccOutcome, Map2CheckError> {
        Ok(check_result(self.rhs < i32::BITS && self.lhs.checked_shl(self.rhs).is_some()))
    }
}

impl VccChecker for ShrI32 {
    fn check(&self, _ctx: &VccContext) -> Result<VccOutcome, Map2CheckError> {
        Ok(check_result(self.rhs < i32::BITS))
    }
}

impl VccChecker for NegI32 {
    fn check(&self, _ctx: &VccContext) -> Result<VccOutcome, Map2CheckError> {
        Ok(check_result(self.val != i32::MIN))
    }
}

// ── u32 checkers ─────────────────────────────────────────────────────────────

pub struct AddU32 { pub lhs: u32, pub rhs: u32 }
pub struct SubU32 { pub lhs: u32, pub rhs: u32 }
pub struct MulU32 { pub lhs: u32, pub rhs: u32 }
pub struct DivU32 { pub lhs: u32, pub rhs: u32 }
pub struct ShrU32 { pub lhs: u32, pub rhs: u32 }

impl VccChecker for AddU32 {
    fn check(&self, _ctx: &VccContext) -> Result<VccOutcome, Map2CheckError> {
        Ok(check_result(self.lhs.checked_add(self.rhs).is_some()))
    }
}

impl VccChecker for SubU32 {
    fn check(&self, _ctx: &VccContext) -> Result<VccOutcome, Map2CheckError> {
        Ok(check_result(self.lhs.checked_sub(self.rhs).is_some()))
    }
}

impl VccChecker for MulU32 {
    fn check(&self, _ctx: &VccContext) -> Result<VccOutcome, Map2CheckError> {
        Ok(check_result(self.lhs.checked_mul(self.rhs).is_some()))
    }
}

impl VccChecker for DivU32 {
    fn check(&self, _ctx: &VccContext) -> Result<VccOutcome, Map2CheckError> {
        Ok(check_result(self.lhs.checked_div(self.rhs).is_some()))
    }
}

impl VccChecker for ShrU32 {
    fn check(&self, _ctx: &VccContext) -> Result<VccOutcome, Map2CheckError> {
        Ok(check_result(self.rhs < u32::BITS))
    }
}

// ── i64 / u64 (extensibility over C original) ────────────────────────────────

pub struct AddI64 { pub lhs: i64, pub rhs: i64 }
pub struct SubI64 { pub lhs: i64, pub rhs: i64 }
pub struct MulI64 { pub lhs: i64, pub rhs: i64 }

impl VccChecker for AddI64 {
    fn check(&self, _ctx: &VccContext) -> Result<VccOutcome, Map2CheckError> {
        Ok(check_result(self.lhs.checked_add(self.rhs).is_some()))
    }
}
impl VccChecker for SubI64 {
    fn check(&self, _ctx: &VccContext) -> Result<VccOutcome, Map2CheckError> {
        Ok(check_result(self.lhs.checked_sub(self.rhs).is_some()))
    }
}
impl VccChecker for MulI64 {
    fn check(&self, _ctx: &VccContext) -> Result<VccOutcome, Map2CheckError> {
        Ok(check_result(self.lhs.checked_mul(self.rhs).is_some()))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::analysismode::VccContext;

    fn ctx() -> VccContext { VccContext::new(1, 0, "test") }

    #[test]
    fn add_i32_overflow_detected() {
        assert_eq!(AddI32 { lhs: i32::MAX, rhs: 1 }.check(&ctx()).unwrap(), overflow_outcome());
    }
    #[test]
    fn add_i32_normal_is_safe() {
        assert_eq!(AddI32 { lhs: 1, rhs: 2 }.check(&ctx()).unwrap(), VccOutcome::Safe);
    }
    #[test]
    fn sub_i32_underflow_detected() {
        assert_eq!(SubI32 { lhs: i32::MIN, rhs: 1 }.check(&ctx()).unwrap(), overflow_outcome());
    }
    #[test]
    fn mul_i32_overflow_detected() {
        assert_eq!(MulI32 { lhs: i32::MAX, rhs: 2 }.check(&ctx()).unwrap(), overflow_outcome());
    }
    #[test]
    fn div_i32_by_zero_detected() {
        assert_eq!(DivI32 { lhs: 10, rhs: 0 }.check(&ctx()).unwrap(), overflow_outcome());
    }
    #[test]
    fn neg_i32_min_detected() {
        assert_eq!(NegI32 { val: i32::MIN }.check(&ctx()).unwrap(), overflow_outcome());
    }
    #[test]
    fn shr_i32_over_31_detected() {
        assert_eq!(ShrI32 { lhs: 1, rhs: 32 }.check(&ctx()).unwrap(), overflow_outcome());
    }
    #[test]
    fn add_u32_overflow_detected() {
        assert_eq!(AddU32 { lhs: u32::MAX, rhs: 1 }.check(&ctx()).unwrap(), overflow_outcome());
    }
    #[test]
    fn sub_u32_underflow_detected() {
        assert_eq!(SubU32 { lhs: 0, rhs: 1 }.check(&ctx()).unwrap(), overflow_outcome());
    }
    #[test]
    fn div_u32_by_zero_detected() {
        assert_eq!(DivU32 { lhs: 5, rhs: 0 }.check(&ctx()).unwrap(), overflow_outcome());
    }
}
