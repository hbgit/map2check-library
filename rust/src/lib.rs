// SPDX-License-Identifier: GPL-3.0-only
//
// map2check-library — Rust rewrite of the C map2check-library.
//
// Unsafe code policy:
//   - `ffi.rs` is the sole module containing unsafe code (FFI boundary).
//   - All other modules use `#![deny(unsafe_code)]` internally.
//   - Every unsafe block in `ffi.rs` is annotated with a SAFETY comment.

pub mod analysismode;
pub mod bbtrack;
pub mod caller;
pub mod error;
pub mod memtrack;
pub mod nondet;
pub mod output;
pub mod state;
pub mod ffi;
