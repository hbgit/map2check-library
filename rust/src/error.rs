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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn poison_error_converts_to_lock_poisoned() {
        let mutex = std::sync::Mutex::new(0_u8);
        std::thread::scope(|scope| {
            let _ = scope
                .spawn(|| {
                    let _held = mutex.lock().unwrap();
                    panic!("poison the mutex on purpose");
                })
                .join();
        });
        let err: Map2CheckError = mutex.lock().unwrap_err().into();
        assert!(matches!(err, Map2CheckError::LockPoisoned(_)));
        assert!(err.to_string().starts_with("lock poisoned"));
    }
}
