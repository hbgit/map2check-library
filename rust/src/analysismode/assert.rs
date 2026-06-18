// SPDX-License-Identifier: GPL-3.0-only
#![deny(unsafe_code)]

use crate::{
    analysismode::{VccChecker, VccContext, VccOutcome},
    caller::ViolatedProperty,
    error::Map2CheckError,
};

/// Checks a user-defined assert expression.
/// Replaces `map2check_is_valid_assert` in analysis_assert.c.
pub struct AssertChecker {
    /// The boolean value of the asserted expression (0 = false → violation).
    pub expression: i32,
}

impl VccChecker for AssertChecker {
    fn check(&self, _ctx: &VccContext) -> Result<VccOutcome, Map2CheckError> {
        if self.expression == 0 {
            Ok(VccOutcome::Violated {
                property: ViolatedProperty::Reachability,
            })
        } else {
            Ok(VccOutcome::Safe)
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::analysismode::VccContext;

    fn ctx() -> VccContext {
        VccContext::new(12, 0, "foo")
    }

    #[test]
    fn false_expression_yields_reachability_violation() {
        let checker = AssertChecker { expression: 0 };
        let outcome = checker.check(&ctx()).unwrap();
        assert_eq!(
            outcome,
            VccOutcome::Violated {
                property: ViolatedProperty::Reachability
            }
        );
    }

    #[test]
    fn true_expression_is_safe() {
        let checker = AssertChecker { expression: 1 };
        let outcome = checker.check(&ctx()).unwrap();
        assert_eq!(outcome, VccOutcome::Safe);
    }

    #[test]
    fn nonzero_expression_is_safe() {
        let checker = AssertChecker { expression: 42 };
        assert_eq!(checker.check(&ctx()).unwrap(), VccOutcome::Safe);
    }
}
