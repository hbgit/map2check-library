# Suggestion for the Map2Check maintainer: adopting the Rust runtime

This is a suggestion document. It describes what the Map2Check project could
change to adopt the `map2check-library` 2.0.0-rc.1 package in place of its C
runtime. The agents and the authors of `map2check-library` take no action in
the Map2Check repository: nothing here has been applied, opened as a pull
request or tested there, and every step is the maintainer's choice.

## What the package is

The 21 bitcode modules `lib/*.bc` that `Caller::linkLLVM` links into an
instrumented program, with the same file names, the same C ABI and the same
result files as the C runtime. The frontend, the passes and the generators do
not change. How to install it is in
[`../integration-guide.md`](../integration-guide.md), and the release layout
in [`../release.md`](../release.md).

## What was validated

Against Map2Check `develop` `0bca42eb89d116178e6b52f52acaf73f7c305088` (the C
runtime modules are byte for byte the same as at `3e914528ec57`), in two
differential gates on a 41-pair corpus with the `afl`, `symex` and `hybrid`
generators, both `gate: PASS`:

- [`gate-2026-10-27.md`](gate-2026-10-27.md) (first gate);
- [`gate-2026-10-28.md`](gate-2026-10-28.md) (second gate, with the comparator
  command to reproduce it).

The verdict differences that remain are approved deviations (SD-20, SD-24,
SD-25, SD-26 in [`../semantic-deltas.md`](../semantic-deltas.md)); the
approved compile-time allowance for `afl` and `hybrid` is in
[`decisoes.md`](decisoes.md). Please read those before deciding: on some
corpus tasks the drop-in answers differently from the C runtime.

**What the gates did not exercise.** The gate corpus has no `no-overflow`
task, `scripts/it/run-corpus.sh` skips the `coverage-*` properties, and no
gate run used `--btree` or `--wasm`. These modes were never compared end to
end through the frontend. They are covered by less direct evidence:

- `--check-overflow`, `--cover-branches` and wasm:
  `scripts/runtime-ir/test-klee-generator.sh` runs `unsafe-overflow.c`, the
  cover-branches mode and a wasm program under KLEE in the Map2Check image,
  against the C runtime;
- `--btree` and `--wasm`: the link matrix
  (`scripts/it/check-link-matrix.sh`, both containers, with and without
  `WasmRuntimeStubs`) links and runs every combination;
- the OVERFLOW result files: the legacy goldens
  (`tests/legacy_golden/OVERFLOW/`).

Users of `--check-overflow` rely on this less direct evidence. A later gate
could add an overflow task and a `--btree` pass.

## Possible changes in Map2Check

1. **Build.** The C sources under `modules/backend/library/lib/` are compiled
   to the 21 `lib/*.bc` by the CMake of that directory. A conservative way to
   adopt the package is an opt-in CMake option (off by default, for example
   `MAP2CHECK_RUST_RUNTIME`) that, when on, copies the 21 `.bc` of a release
   archive into the install's `lib/` instead of building them, after checking
   `SHA256SUMS`. Keeping the option off keeps today's build.
2. **Version pin.** Record the `map2check-library` release (tag and the
   archive's `SHA256SUMS`) the install uses, the way `MAP2CHECK_VERSION` pins
   the Map2Check commit in `map2check-library`. The package's `MAP2CHECK_VERSION` file
   says which `develop` commit it was validated on.
3. **CI.** A job that installs the package over a normal build and runs the
   regression corpus would catch a future runtime change early. The corpus
   and the comparator we used are `scripts/it/run-corpus.sh` and
   `scripts/it/compare_baselines.py` in `map2check-library`, as an example.
4. **Removing the C runtime.** Only after the option has run for a release
   cycle without unexplained differences, the C sources of the 21 modules
   could be dropped and the Rust package become the only runtime. Until then,
   keeping both allows going back by copying the C `.bc` files back.
5. **Docker images.** The images that build Map2Check need no Rust toolchain
   to use the package, since it ships the `.bc` files. A Rust toolchain
   (rustc 1.72.1 with LLVM 16 tools, the bitcode toolchain of `build-runtime-bc.sh`, distinct from the toolchain pinned in `rust-toolchain.toml`) is needed only to rebuild them with
   `scripts/build-runtime-bc.sh`.

## What could change for users

- Verdicts on the tasks listed by the approved deviations.
- Wall time of `afl` and `hybrid` runs within the gate's limits (median
  0.905 of the C's with the 2.0 s allowance, second gate).
- The result files, the witness files and the stderr diagnostics are meant to
  match the C runtime's; a difference there would be a bug to report in
  `map2check-library`.
