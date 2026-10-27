// SPDX-License-Identifier: GPL-3.0-only
//
// map2check-library — Rust rewrite of the C map2check-library.
//
// Unsafe code policy:
//   - `ffi.rs` is the sole module containing unsafe code (FFI boundary), with
//     `wasm.rs` (feature `wasm`: libc allocation and wasm-rt struct access)
//     and `sys.rs` (the libc calls of the result files, the environment and
//     stderr).
//   - All other modules use `#![deny(unsafe_code)]` internally.
//   - Every unsafe block in `ffi.rs` is annotated with a SAFETY comment.
//
// FFI safety policy:
//   - Production code must not contain panics that can escape the Rust/C boundary.
//   - `unwrap`, `expect`, and `panic!` are denied outside test builds.
//   - `with_state` serializes access to the global analysis state and is not
//     reentrant: nested calls must not call back into FFI while the lock is held.
#![cfg_attr(
    not(test),
    deny(clippy::unwrap_used, clippy::expect_used, clippy::panic)
)]

pub mod analysismode;
pub mod bbtrack;
pub mod caller;
pub mod cfmt;
pub mod error;
pub mod ffi;
pub mod memtrack;
pub mod nondet;
pub mod output;
pub mod state;
pub mod sys;
/// wasm2c runtime (`--wasm` mode of Map2Check) — feature-gated.
#[cfg(feature = "wasm")]
pub mod wasm;
