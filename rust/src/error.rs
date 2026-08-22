// SPDX-License-Identifier: GPL-3.0-only
#![deny(unsafe_code)]

use thiserror::Error;

#[derive(Debug, Error)]
pub enum Map2CheckError {
    #[error("state not initialized; call map2check_init() first")]
    NotInitialized,

    #[error("lock poisoned: {0}")]
    LockPoisoned(String),

    #[error("address {0:#x} not found in memory tracker")]
    AddressNotFound(usize),

    #[error("JSON serialization failed: {0}")]
    Serialization(#[from] serde_json::Error),

    #[error("integer overflow in {operation} at line {line}")]
    OverflowDetected { operation: &'static str, line: u32 },

    #[error("null pointer dereference at line {line} in {function}")]
    NullDereference { line: u32, function: String },

    #[error("invalid free of address {address:#x} at line {line}")]
    InvalidFree { address: usize, line: u32 },
}

impl<T> From<std::sync::PoisonError<T>> for Map2CheckError {
    fn from(e: std::sync::PoisonError<T>) -> Self {
        Self::LockPoisoned(e.to_string())
    }
}
