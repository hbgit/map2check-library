// SPDX-License-Identifier: GPL-3.0-only
#![deny(unsafe_code)]

/// The errors of the library. The messages are written by
/// [`Map2CheckError::describe`] into a byte buffer, without `core::fmt`, so
/// that the drop-in core can print them (Task 3.3); `Display` (host builds)
/// prints the same text.
#[derive(Debug)]
pub enum Map2CheckError {
    /// `state not initialized; call map2check_init() first`
    NotInitialized,

    /// `lock poisoned: <cause>`
    LockPoisoned(String),

    /// `address <0x..> not found in memory tracker`
    AddressNotFound(usize),

    /// `JSON serialization failed: <cause>` (the JSON channel, which the
    /// drop-in core does not have).
    #[cfg(not(feature = "dropin"))]
    Serialization(serde_json::Error),

    /// `integer overflow in <operation> at line <line>`
    OverflowDetected { operation: &'static str, line: u32 },

    /// `null pointer dereference at line <line> in <function>`
    NullDereference { line: u32, function: String },

    /// `invalid free of address <0x..> at line <line>`
    InvalidFree { address: usize, line: u32 },
}

impl Map2CheckError {
    /// Appends the message of the error to `out`.
    pub fn describe(&self, out: &mut Vec<u8>) {
        use crate::cfmt::{put_hex, put_u64};
        match self {
            Self::NotInitialized => {
                out.extend_from_slice(b"state not initialized; call map2check_init() first");
            }
            Self::LockPoisoned(cause) => {
                out.extend_from_slice(b"lock poisoned: ");
                out.extend_from_slice(cause.as_bytes());
            }
            Self::AddressNotFound(address) => {
                out.extend_from_slice(b"address 0x");
                put_hex(out, *address as u64);
                out.extend_from_slice(b" not found in memory tracker");
            }
            #[cfg(not(feature = "dropin"))]
            Self::Serialization(cause) => {
                out.extend_from_slice(b"JSON serialization failed: ");
                out.extend_from_slice(cause.to_string().as_bytes());
            }
            Self::OverflowDetected { operation, line } => {
                out.extend_from_slice(b"integer overflow in ");
                out.extend_from_slice(operation.as_bytes());
                out.extend_from_slice(b" at line ");
                put_u64(out, u64::from(*line));
            }
            Self::NullDereference { line, function } => {
                out.extend_from_slice(b"null pointer dereference at line ");
                put_u64(out, u64::from(*line));
                out.extend_from_slice(b" in ");
                out.extend_from_slice(function.as_bytes());
            }
            Self::InvalidFree { address, line } => {
                out.extend_from_slice(b"invalid free of address 0x");
                put_hex(out, *address as u64);
                out.extend_from_slice(b" at line ");
                put_u64(out, u64::from(*line));
            }
        }
    }
}

#[cfg(not(feature = "dropin"))]
impl std::fmt::Display for Map2CheckError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        let mut text = Vec::new();
        self.describe(&mut text);
        f.write_str(&String::from_utf8_lossy(&text))
    }
}

#[cfg(not(feature = "dropin"))]
impl std::error::Error for Map2CheckError {
    fn source(&self) -> Option<&(dyn std::error::Error + 'static)> {
        match self {
            Self::Serialization(cause) => Some(cause),
            _ => None,
        }
    }
}

#[cfg(not(feature = "dropin"))]
impl From<serde_json::Error> for Map2CheckError {
    fn from(e: serde_json::Error) -> Self {
        Self::Serialization(e)
    }
}

/// Host builds only: the drop-in core is built with `panic = "abort"`, so
/// no panic can poison its lock (`state::with_state`).
#[cfg(not(feature = "dropin"))]
impl<T> From<std::sync::PoisonError<T>> for Map2CheckError {
    fn from(e: std::sync::PoisonError<T>) -> Self {
        Self::LockPoisoned(e.to_string())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    /// The texts the `thiserror` attributes printed before Task 3.3.
    #[test]
    fn messages_are_unchanged() {
        let cases: [(Map2CheckError, &str); 6] = [
            (
                Map2CheckError::NotInitialized,
                "state not initialized; call map2check_init() first",
            ),
            (Map2CheckError::LockPoisoned("x".into()), "lock poisoned: x"),
            (
                Map2CheckError::AddressNotFound(0x1f),
                "address 0x1f not found in memory tracker",
            ),
            (
                Map2CheckError::OverflowDetected {
                    operation: "add",
                    line: 7,
                },
                "integer overflow in add at line 7",
            ),
            (
                Map2CheckError::NullDereference {
                    line: 3,
                    function: "main".into(),
                },
                "null pointer dereference at line 3 in main",
            ),
            (
                Map2CheckError::InvalidFree {
                    address: 0,
                    line: 4294967295,
                },
                "invalid free of address 0x0 at line 4294967295",
            ),
        ];
        for (e, text) in cases {
            assert_eq!(e.to_string(), text);
        }
    }

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
