# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Map2Check-Library is a Rust library with a C ABI for the Map2Check program verification tool. It tracks memory, basic blocks, and nondeterministic values, and checks safety properties (overflow, memory safety, assert reachability) in programs analyzed by LibFuzzer. The build produces the static library (`libmap2check.a`) and generates `include/map2check.h`. Remaining parity work with the legacy C implementation is tracked in [TODO.md](TODO.md).

## Build Commands

The project uses the Rust toolchain pinned in `rust-toolchain.toml`. Run Cargo commands from the repository root.

```sh
# Debug build
cargo build

# Release build
cargo build --release

# Generate the C header and build all features
cargo build --all-features
```

## Running Tests

```sh
# Run all Rust unit tests
cargo test --all-features

# Lint and dependency checks (also run in CI)
cargo fmt --check
cargo clippy --all-targets --all-features -- -D warnings
cargo deny check

# Exercise the C ABI with ASan and UBSan (requires clang)
cargo build --release --all-features
clang -fsanitize=address,undefined -fno-omit-frame-pointer \
  tests/ffi_harness.c target/release/libmap2check.a \
  -ldl -lpthread -lm -o target/ffi_harness
target/ffi_harness
```

## Architecture

### Source Layout

- [rust/src/](rust/src/) — Rust implementation and C FFI
- [tests/ffi_harness.c](tests/ffi_harness.c) — C ABI stress harness

### Module Packages

Each package lives in a subdirectory of `rust/src/`:

| Package | Purpose |
|---|---|
| `caller/` | Result and violated-property types, global step counter. |
| `nondet/` | Typed nondeterministic values and LibFuzzer generators. |
| `memtrack/` | Memory allocation tracking and memory-safety checks. |
| `bbtrack/` | Basic-block entries and lookup. |
| `analysismode/` | Verification condition checkers: `analysis_assert` (assert reachability), `analysis_overflow` (arithmetic overflow), `analysis_memory` (memory safety). |

### Container Pattern

Analysis records are stored in vectors in the process-wide `AnalysisState`, protected by a mutex and reset by `map2check_reset()`.

### Output Format

At analysis end, `print_all_containers_as_json()` serializes the state to RFC 8259 JSON on stdout using `serde_json`.

### Generated Header

`build.rs` runs `cbindgen` (config in `cbindgen.toml`) and rewrites `include/map2check.h`. Change Rust exports or `cbindgen.toml`, never the header.

## Repository Conventions

- Commits must have verified signatures.
- Never add AI attributions (e.g. "Co-authored-by", "Generated with ...") to commits or PR descriptions.
- See [.github/copilot-instructions.md](.github/copilot-instructions.md) for the same conventions in more detail.

## Key Entry Points

- `map2check_init()` — initializes the global analysis state
- `map2check_success()` / `set_false_result(prp, line, func)` — set final verification result
- `print_all_containers_as_json()` — emits the JSON result report
- `map2check_is_valid_assert()`, `map2check_map_malloc()`, `map2check_map_free()` etc. — called by LLVM instrumentation passes in the Map2Check tool
