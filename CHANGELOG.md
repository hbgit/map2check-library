# Changelog

All notable changes to `map2check-library` are recorded here. The format
follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and
versions follow [Semantic Versioning](https://semver.org/). The version
comes from `Cargo.toml` and is repeated in `MAP2CHECK_VERSION`
(`include/map2check.h`) and in the `Dockerfile` label.
`tests/header_version.rs` fails when this file has no section for the
current version.

Compatibility with the legacy C library is tracked in
[`docs/api-deltas.md`](docs/api-deltas.md) and
[`docs/semantic-deltas.md`](docs/semantic-deltas.md); a change that touches
the C ABI or the JSON report must update them.

## [Unreleased]

### Breaking changes

- `map2check_init` takes the C runtime's `int isSvComp` (ignored), and
  `ViolatedProperty` has the values of the C runtime's `enum ViolatedProperty`
  (`NONE` 0 … `FALSE_DIVBYZERO` 9, `Concurrency` 10), which
  `set_false_result` and `get_current_property` now use. `map2check_init` no
  longer removes property files of an earlier run, as the C runtime.

### Added

- The core of the Map2Check C runtime ABI (Task 2.1 of the drop-in plan):
  `map2check_track_bb`, `map2check_target_function`, `map2check_error`,
  `map2check_exit`, `map2check_destroy`, `map2check_get_current_step`,
  `map2check_next_current_step` and `write_property`, with the C signatures,
  and the witness entry points `__m2c_rt_witness_generate_aux_files` and
  `__m2c_rt_witness_generate_confirmation_file`.

## [1.1.0-rc1] - 2026-10-17

Release candidate of the cutover work: the library becomes the runtime of
Map2Check (Tasks 1.2, 2.1-2.5, 2.7 and 2.8 of the cutover plan). Read the
breaking changes first.

### Breaking changes

- `map2check_check_free` and `map2check_map_free` take one more argument, the
  address of the pointer variable (the pointer slot), so the free is logged
  like the C runtime does. Passes built against 1.0.0-rc1 must be rebuilt
  (`docs/api-deltas.md`).
- `map2check_set_mode` takes an `int32_t`. Invalid modes are rejected.
- Default verdicts changed: the end-of-program leak check (memcleanup) is no
  longer opt-in, and the first violation is final; a later passing check does
  not clear it (#36). See `docs/semantic-deltas.md`.
- With an analysis mode set, the library prints no JSON, and an unreadable
  fuzzer input ends the run instead of continuing.

### Added

- Runtime profile `runtime` (`cargo build --profile runtime --features
  libfuzzer,wasm`): release optimisations with `panic = "unwind"`, so the FFI
  guard can recover panics. This is the build Map2Check links.
- Lifecycle: `map2check_init` and every fuzzer iteration reset the analysis
  state (#9); every export is guarded against panics and works before
  `map2check_init` (#8).
- Runtime analysis modes: `map2check_set_mode` and `map2check_reach_target`
  select assert, overflow, memory or reachability checking at run time.
- Legacy result files consumed by Map2Check (property, log and witness files)
  and abort on the first violation (#19, #14).
- Core API completion: signed binary operations checked at the operation's
  width with `DivByZero`, `posix_memalign` tracking through the `void **` it
  wrote (#13), the full `__VERIFIER_nondet_*` family logged as develop writes
  it (#6), AFL++-style fuzzer input reading, and rejection of
  `__VERIFIER_assume` inside loops.
- KLEE runtime (#20): `klee/Cargo.toml`, a second manifest built with rustc
  1.72.1 (LLVM 16) into one bitcode module by
  `scripts/build-klee-runtime.sh`, with CI. The bitcode is built separately
  and is not in the release archive.
- The KLEE bitcode now includes the `wasm` feature (`--features klee,wasm`): the `wasm_rt_*` stubs and the `map2check_wasm_*` exports, so Map2Check's `--wasm` mode with the `symex` generator no longer stops with "failed external call: wasm_rt_is_initialized". `tests/klee_paths.sh` runs a wasm2c-lifted module (`tests/klee/wasm.c`) and expects OVERFLOW at line 0, as develop's C runtime gives (SD-19).
- `lib/libmap2check_runtime.a` in the release archive: the `runtime` profile
  with features `libfuzzer,wasm`.

- Feature `wasm`: the runtime of Map2Check's `--wasm` mode (D2) ported from the
  C runtime: the `wasm_rt_*` stubs, `w2c_wasi__snapshot__preview1_proc_exit` and
  `map2check_wasm_malloc`, `map2check_wasm_free`, `map2check_wasm_check_access`
  (SD-19). `tests/core_api_coverage.rs` checks every `core_symbol` of
  `docs/cutover/abi-mapping.tsv` against the staticlib.
- `docs/api-deltas.md` symbol/signature matrix for the core C API and the
  Map2Check passes, and `docs/semantic-deltas.md` with reproducible
  behaviour differences, both checked by `tests/compat_docs.rs` (#5).
- `docs/integration-guide.md` and `docs/release.md`;
  `scripts/package-release.sh` builds the release archive with the C
  header, both static libraries and the docs (#5).

### Fixed

- Memory tracking: addresses are validated by their latest alloc/free event
  (#11), an untracked resolved free is reported as invalid (#37), a passing
  resolved free records the release (#11, #37), and a VLA is a static slot
  sized in elements (#38).
- Option semantics: `memcleanup` and null-is-valid are honoured by the memory
  checks, and runtime options are separate from the analysis configuration
  (#10).
- The memcleanup verdict matches develop's.
- Throughput of the KLEE (`symex`) runtime: the load check no longer builds a
  hash set per call, the check context borrows the function name, and no
  build is instrumented for coverage any more (the repo-wide
  `.cargo/config.toml` that added `-C instrument-coverage` is removed;
  `cargo tarpaulin` adds it itself, and `scripts/build-klee-runtime.sh`
  rejects it). On list-ext the runtime spends about 4 times fewer KLEE
  instructions per path and finds the FALSE-DEREF that it missed before.
- The legacy result files are written to a temporary file and renamed, so
  KLEE states that run in the same directory no longer truncate each other's
  `map2check_property` (SD-20 records the C runtime's behaviour).
- A NULL block from `malloc`/`calloc` is reported as UNKNOWN before its size
  is checked, as develop does. Before, a negative size was checked first and
  on lis_unsafe (`symex`) KLEE grew to 4.4 GB.
- The KLEE runtime bitcode no longer carries std's backtrace symbolizer
  (gimli, addr2line, miniz_oxide, rustc_demangle): `scripts/build-klee-runtime.sh`
  replaces those bodies with an abort and fails the build if one is still
  reachable. The bitcode drops from 2.30 MB to 1.24 MB, and KLEE start-up per
  task from about 3.1 s to 1.3 s.
- The test stage of the `Dockerfile` copies the files the tests read
  (`tests/`, `docs/`, `CHANGELOG.md`, `Dockerfile`).

### Changed

- The KLEE runtime bitcode includes the wasm2c runtime, so `--wasm` works
  with the `symex` generator.
- cbindgen is 0.28, which drops the unsound `atty` dependency
  (RUSTSEC-2021-0145).
- `develop` replaces `feature/rust` as the integration branch: CI runs on
  pushes and pull requests to `main`, `develop` and `release/**`, and
  `scripts/branch-protection.sh` protects `develop` instead of
  `feature/rust`.
- The release branch `master` is renamed to `main`; CI, the
  branch-protection script and the docs follow the new name.

## [1.0.0-rc1] - Unreleased

First release candidate of the Rust rewrite (milestones M1–M3).

### Added

- Rust implementation of the C ABI in `rust/src/ffi.rs`, with
  `include/map2check.h` generated by `cbindgen` from `build.rs`.
- `map2check_reset()`, `get_next_step()`,
  `map2check_map_non_static_alloca`, `map2check_map_funct_address`,
  `map2check_check_free_resolved_address`, and the LibFuzzer generators
  `__VERIFIER_nondet_*`, `__VERIFIER_assume`, `__VERIFIER_assert`,
  `__VERIFIER_error` and `map2check_fuzzer_assume` (feature `libfuzzer`)
  (#2, #3).
- `#define MAP2CHECK_VERSION` in the generated header (#28).
- Unit tests for every exported FFI symbol and a checklist that fails on an
  untested export (#29).
- CI: formatting, Clippy, tests, an ASan/UBSan C harness, C integration
  programs, cargo-deny, cargo-audit, Docker build, and an 80% coverage gate
  outside `ffi*.rs` (#1, #30); branch protection for `feature/rust` and
  `master` (#26).

### Changed

- JSON report produced by `serde_json`; shape in
  `docs/integration-guide.md`, differences in SD-01.
- `map2check_save_nondet_log_char` takes `char` as `i8` (see
  `docs/api-deltas.md`).
- Every export catches panics at the FFI boundary, and the global state
  sits behind a mutex (#2).

### Removed

- `map2check_gen_data_fuzzer_*`, `next_current_step` and the C-era build
  files and docs (#27). See `docs/api-deltas.md` for each removal.
