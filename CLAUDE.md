# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Map2Check-Library is a Rust library (crate `map2check-library`, lib name `map2check`) that supports the Map2Check program verification tool. It tracks memory, basic blocks, and nondeterministic values, and checks safety properties (overflow, memory safety, assert reachability) in programs analyzed by KLEE or LibFuzzer. It is built as a static library (`libmap2check.a`) plus an `rlib`, and exposes a C ABI consumed by LLVM instrumentation. The original C/CMake implementation was removed; the Rust port is still reaching parity with it (see [TODO.md](TODO.md) and [docs/plano_map2check_library_rust.md](docs/plano_map2check_library_rust.md)).

## Build, Test and Lint

Run from the repo root. The toolchain (Rust 1.82.0, with clippy and rustfmt) is pinned by `rust-toolchain.toml`.

```sh
cargo build --release
cargo test --all-features
cargo test --all-features analysismode::overflow::tests::add_i32_overflow_detected   # single test (name filter)
cargo fmt --check
cargo clippy --all-targets --all-features -- -D warnings
cargo audit
cargo deny check
docker build .
```

CI (`.github/workflows/CI.yml`) runs formatting, Clippy, release build, all-feature tests, dependency checks, and the Docker build. The Dockerfile also has a KLEE bitcode stage (`--features klee`) and a tarpaulin coverage stage that excludes `rust/src/ffi.rs`. `run_klee_test.sh` is the KLEE integration check (expects `build/fullprogram_2.bc` and Docker).

Cargo features: `klee` and `libfuzzer` select the analysis mode.

## Architecture

### Source Layout

- [rust/src/lib.rs](rust/src/lib.rs) — crate root (`[lib] path` in `Cargo.toml`)
- [rust/src/ffi.rs](rust/src/ffi.rs) — all `extern "C"` exports; the only place with `unsafe`
- [rust/src/state.rs](rust/src/state.rs) — global `AnalysisState`, accessed via `state::with_state`
- [rust/src/error.rs](rust/src/error.rs) — `Map2CheckError` (thiserror)
- [include/map2check.h](include/map2check.h) — **generated** C header; do not edit
- [test/](test/) — C sample programs (`codeAPI_by_caller_test.c`, `codeklee_by_caller_test.c`, `codefuzz_by_caller_test.c`) used for KLEE/LibFuzzer integration; unit tests live inline in the Rust modules
- [docs/](docs/) — Rust migration plan, Doxyfile, UML diagrams

### Modules (`rust/src/`)

| Module | Purpose |
|---|---|
| `caller/` | C-represented violated property and result metadata |
| `nondet/` | Nondeterministic value tracking; `libfuzzer.rs` (feature `libfuzzer`) has the LibFuzzer callback and input generators |
| `memtrack/` | Allocation tracking (alloca/malloc/calloc/free, pointer stores) and memory-safety lookups |
| `bbtrack/` | Basic-block execution path records |
| `analysismode/` | Verification condition checkers (`assert`, `overflow`, `memory`) behind the `VccChecker` trait |
| `output/` | Serializes state to the JSON report on stdout (serde_json) |

Checkers use `VccContext` for source location and return `Result<VccOutcome, Map2CheckError>`; `VccOutcome` is `Safe` or a violated property. The FFI layer records violations in the shared state.

### Key Design Decisions

- Global state is a single `OnceLock<Arc<Mutex<AnalysisState>>>`; don't create parallel globals for existing logs/results.
- `unsafe` is confined to `ffi.rs`; other modules use `#![deny(unsafe_code)]`. Every unsafe block at an FFI boundary needs a `// SAFETY:` comment.
- Exports use `#[unsafe(no_mangle)]` and `#[repr(C)]` for types crossing the ABI.
- Verification rules go in `analysismode`; reusable tracking/query logic goes in `bbtrack`, `nondet`, or `memtrack`.
- JSON field names and omission rules are part of the output contract — update the focused tests in `output/mod.rs` when changing them.

### Generated Header

`build.rs` runs `cbindgen` (config in `cbindgen.toml`) on every build and rewrites `include/map2check.h`. Change Rust exports or `cbindgen.toml`, never the header.

## Repository Conventions

- Commits must have verified signatures.
- Never add AI attributions (e.g. "Co-authored-by", "Generated with ...") to commits or PR descriptions.
- See [.github/copilot-instructions.md](.github/copilot-instructions.md) for the same conventions in more detail.

## Key Entry Points (C ABI)

- `map2check_init()` — initialize state; call before any tracking
- `map2check_success()` / `set_false_result(prp, line, func)` — set final verification result
- `print_all_containers_as_json()` — emit the JSON report
- `map2check_is_valid_assert()`, `map2check_map_malloc()`, `map2check_map_free()`, `map2check_save_nondet_log_*` — called by Map2Check's LLVM instrumentation passes

Some legacy C entry points (`get_next_step`, `map2check_map_non_static_alloca`, `map2check_map_funct_address`, `map2check_check_free_resolved_address`) and the C signatures of `map2check_save_nondet_log_*` are not yet matched in Rust; see TODO.md.
