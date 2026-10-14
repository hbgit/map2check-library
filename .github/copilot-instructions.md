# Map2Check Library — Copilot Instructions

## Build, test, and lint

Run these commands from the repository root. The pinned Rust toolchain is
selected by `rust-toolchain.toml`.

```sh
cargo build --release
cargo test --all-features
cargo test --all-features analysismode::overflow::tests::add_i32_overflow_detected
cargo fmt --check
cargo clippy --all-targets --all-features -- -D warnings
cargo audit
cargo deny check
docker build .
```

The test-name argument filters to a single Rust test; replace it with the
fully qualified test name to run another one. `cargo build` runs `build.rs`,
which regenerates `include/map2check.h` with `cbindgen`; edit Rust exports and
`cbindgen.toml`, not the generated header. The CI workflow runs formatting,
Clippy, release build, all-feature tests, dependency checks, and Docker build.
For the documented KLEE integration flow, see `run_klee_test.sh` and the
environment requirements in `README.md`.

## Architecture

The crate root is `rust/src/lib.rs`. C/LLVM instrumentation enters through the
`extern "C"` exports in `ffi.rs`; these convert C inputs, update or read the
shared `AnalysisState` in `state.rs`, and invoke the domain modules.

`state.rs` owns the global analysis result and the basic-block, nondeterminism,
and memory-tracking records. `caller` defines the C-represented violated
property and result metadata. `bbtrack`, `nondet`, and `memtrack` model events
and their lookup/checking operations. `analysismode` implements verification
condition checkers behind the `VccChecker` trait; a checker returns `Safe` or
a violated property, and the FFI layer records violations in the shared state.
`output` serializes that state as the JSON report written to stdout.

The optional `libfuzzer` feature provides the LibFuzzer callback and
nondeterministic input generators in `nondet/libfuzzer.rs`. Cargo features and
the native/bitcode build setup are declared in `Cargo.toml` and `Dockerfile`;
consult those files before changing how analysis modes are linked.

## Repository-specific conventions

- Commits must have verified signatures.
- Never include AI attributions, "Co-authored-by: Copilot", or "Generated with AI" labels in git commits or PR descriptions.
- Keep C ABI declarations and conversions in `ffi.rs`; use `#[repr(C)]` for
  types crossing the ABI. Unsafe operations at FFI boundaries need a local
  `// SAFETY:` explanation describing the caller guarantee.
- Keep verification rules in `analysismode` checkers and reusable event
  tracking/query behavior in `bbtrack`, `nondet`, or `memtrack`. Checkers use
  `VccContext` for source location and return `Result<VccOutcome,
  Map2CheckError>`.
- Shared analysis data is accessed through `state::with_state`; avoid creating
  parallel global state for an existing log or result.
- JSON field names and omission rules are part of the library output contract.
  Update or add the focused tests in `output/mod.rs` when changing serialized
  records or report structure.
- `CLAUDE.md` describes the former C/CMake implementation. For this Rust
  checkout, use `README.md`, `Cargo.toml`, `.github/workflows/CI.yml`, and the
  current Rust sources for build commands and behavior.
