# Integration guide — the drop-in runtime for Map2Check

This guide covers what a Map2Check maintainer or a C program needs to use
the Rust `map2check-library` **2.0.0-rc.1**: what the release ships, how to
install the 21 bitcode modules in place of the C runtime's, the Map2Check
commit they were validated against, how to reproduce the validation, and how
to link the C ABI by hand. Paths of the form `map2check-library: <path>` and the `scripts/` and
`docs/cutover/` files named below are in the source repository, not in the
release archive, which ships only this guide, `api-deltas.md` and
`semantic-deltas.md` under `docs/`. Compatibility details are in
[`api-deltas.md`](api-deltas.md) (symbols and signatures) and
[`semantic-deltas.md`](semantic-deltas.md) (behaviour). The steps a
maintainer would take to adopt the package are suggested in
`map2check-library: docs/cutover/handoff-map2check.md`.

**What the library is (D6, 2.0.0).** The library exports the C runtime ABI of
Map2Check `develop`: the names its core modules own and the `__m2c_rt_*`
entry points that the generated IR modules (`scripts/runtime-ir/gen_ll.py`)
forward to. Together with those IR modules it is the 21 `.bc` files that
`Caller::linkLLVM` links into an instrumented program, so Map2Check runs
unchanged with them. It is not a library with its own API next to the
runtime: the 1.x core API (`map2check_set_mode`, `map2check_map_*`,
`print_all_containers_as_json`...) and the `libfuzzer` and `klee` features
left the C ABI (`CHANGELOG.md`). Those functions remain Rust functions of
`map2check::ffi` for the Rust tests, and the JSON report below belongs to
that Rust API.

## Release contents

A release archive `map2check-library-<version>-<target>.tar.gz` (see
`map2check-library: docs/release.md`) unpacks to:

```
map2check-library-<version>-<target>/
├── include/map2check.h           # C header; MAP2CHECK_VERSION == <version>
├── lib/*.bc                      # the 21 runtime modules (below)
├── lib/libmap2check.a            # no features
├── lib/libmap2check_runtime.a    # runtime profile, feature wasm
├── MAP2CHECK_VERSION             # Map2Check develop commit validated
├── SHA256SUMS                    # sha256 of every other file
├── docs/integration-guide.md
├── docs/api-deltas.md
├── docs/semantic-deltas.md
├── CHANGELOG.md
└── LICENSE                       # GPL-3.0-only
```

The 21 modules are listed in `scripts/runtime-modules.txt` (`Map2CheckFunctions`,
`TrackBBLog`, `NonDetLog`, `PropertyGenerator`, `ContainerRealloc`,
`ContainerBTree`, `BTree`, `AnalysisModeMemtrack`, `AnalysisModeMemcleanup`,
`AnalysisModeOverflow`, `AnalysisModeAssert`, `AnalysisModeNone`,
`AllocationLog`, `ListLog`, `HeapLog`, `NonDetGeneratorNone`,
`NonDetGeneratorKlee`, `NonDetGeneratorAFL`, `WasmRuntimeStubs`,
`WitnessGeneration`, `WitnessGenerationNone`), each as `<Module>.bc`. The
layout and the reasons for it are in
`map2check-library: docs/cutover/d7-layout.md`.

## Validated Map2Check commit

The package was validated against Map2Check `develop` commit
`0bca42eb89d116178e6b52f52acaf73f7c305088`, recorded in
`vendor/MAP2CHECK_VERSION` and shipped as `MAP2CHECK_VERSION`. The 21 C
runtime modules are byte for byte the same at `0bca42eb` and at the commit of
the first gate (`3e914528ec57`). Use a Map2Check install built from that
commit, or from one whose `lib/*.bc` are identical to it. Other commits were
not tested.

## Installing the 21 modules in place of the C ones

Verify the archive, then either overlay a copy or patch in place:

```sh
tar -xzf map2check-library-<version>-<target>.tar.gz
cd map2check-library-<version>-<target>
sha256sum -c SHA256SUMS                  # every file must say OK
cd ..

# a copy of an existing install with only lib/*.bc replaced (recommended)
scripts/it/overlay-install.sh <c-install> map2check-library-<version>-<target>/lib <out-install>

# or in place: copy the modules over the C ones
cp map2check-library-<version>-<target>/lib/*.bc "${MAP2CHECK_PATH}/lib/"
```

`<c-install>` is a Map2Check install whose `lib/` holds the 21 C modules
(for example the output of `scripts/it/build-map2check.sh`). The overlay
script is in this repository, not in the archive. It leaves `<c-install>`
untouched, replaces only `lib/*.bc` (`bin/`, the pass plugins and every
symlink stay as they are), refuses a `<bc-dir>` that is not exactly the 21
module names (the `.a` files of the archive's `lib/` are ignored), and writes
the marker `.map2check-overlay` with the sha256 of the 21 modules. The
in-place copy has no such checks: do not mix modules of two builds, and
back up the C ones first if you want to go back.

The frontend then links the program with the Rust runtime and nothing else
changes. Whether a run writes the witness files depends only on the witness
module it links (`WitnessGeneration.bc` or `WitnessGenerationNone.bc`), as in
the C runtime.

## Reproducing the validation

Two differential gates compared the C runtime and the drop-in on a
41-pair corpus (`afl`, `symex` and `hybrid` generators, 5 repetitions, 615
runs per side), with `scripts/it/compare_baselines.py`. Both finished with
`gate: PASS`:

| Gate | Map2Check `develop` | Report | Baseline |
|---|---|---|---|
| 1 (2026-10-27, accepted 2026-10-28) | `3e914528ec57` | `map2check-library: docs/cutover/gate-2026-10-27.md` | `docs/cutover/baselines/c-3e914528ec57.tsv` |
| 2 (2026-10-28) | `0bca42eb89d1` | `map2check-library: docs/cutover/gate-2026-10-28.md` | `docs/cutover/baselines/c-0bca42eb89d1.tsv` |

The reports hold the exact comparator commands and outputs; this is the
second gate's:

```sh
python3 scripts/it/compare_baselines.py docs/cutover/baselines/c-0bca42eb89d1.tsv docs/cutover/baselines/rust-fa279fe2af8c.tsv --deltas docs/cutover/deltas-aceitos.tsv
```

To produce new measurements, from the repository root (Docker needed, and
a clone of Map2Check `develop` in `vendor/map2check/`, which
`scripts/fetch-map2check.sh` makes and `.gitignore` keeps out of git):

```sh
scripts/it/build-map2check.sh                       # image and the C install: target/map2check-it/c
scripts/build-runtime-bc.sh target/map2check-it/bc  # exactly the 21 drop-in modules
scripts/it/overlay-install.sh target/map2check-it/c target/map2check-it/bc target/map2check-it/ov
GENERATORS="afl symex hybrid" TIMEOUT_S=45 KILL_MARGIN_S=30 REPS=5 \
  scripts/it/run-corpus.sh target/map2check-it/c  c.tsv
GENERATORS="afl symex hybrid" TIMEOUT_S=45 KILL_MARGIN_S=30 REPS=5 \
  scripts/it/run-corpus.sh target/map2check-it/ov rust.tsv
python3 scripts/it/compare_baselines.py c.tsv rust.tsv --deltas docs/cutover/deltas-aceitos.tsv
```

The gate reports interleave C and drop-in repetitions on the same day; do the
same, because wall time depends on the host load.

What passing means: no verdict, failed-detail or witness difference that is
not an approved deviation (`docs/cutover/deltas-aceitos.tsv`, each row tied to
an `SD-NN` of [`semantic-deltas.md`](semantic-deltas.md)), the median wall
time of the drop-in at most 1.10 times the C's, the median peak memory
at most 1.36 times, and no new timeouts. For `afl` and `hybrid` the wall time
discounts up to 2.0 s of fixed compile time per run (the approved allowance
in `map2check-library: docs/cutover/decisoes.md`; it is not an SD): the drop-in
core is compiled with the program, and the median stays below the limit with
it (0.905 on the second gate; 1.192 without it). The deviations that the
gates accepted are SD-20, SD-24, SD-25 and SD-26.

## Building from source

Without a release archive, run this from the repository root:

```sh
cargo build --release                       # no features
scripts/build-runtime-bc.sh <out-dir>       # the 21 lib/*.bc, deterministic
```

`build-runtime-bc.sh` builds the Rust core from `klee/Cargo.toml` with
rustc 1.72.1 and the LLVM 16 tools, plus the IR modules, and fails when the
core exceeds 9 500 instruction lines or 13 600 IR lines (the frontend compiles
the program with the core three times with `afl-clang-fast`, so its size is
compile time). `scripts/package-release.sh` makes the archive from them.

The `runtime` profile (release optimisations with `panic = "unwind"`, so the
FFI guard can recover panics) is what `libmap2check_runtime.a` is:

```sh
cargo build --profile runtime --features wasm   # target/runtime/libmap2check.a
```

`build.rs` regenerates `include/map2check.h` on every build. The header is
not committed (`.gitignore`), so always take it from the same build as the
library.

## Linking a C program by hand

```sh
scripts/build-c-abi-program.sh -o my_program -m Map2CheckFunctions-glue -m NonDetGeneratorAFL my_program.c
```

This is what `tests/ffi_harness.c` uses, and what Map2Check does with its
passes. Without the script, the pieces are:

```sh
cc -I include my_program.c lib/libmap2check.a <the .ll/.bc of the modules> -ldl -lpthread -lm -o my_program
```

- `-ldl -lpthread -lm` are the system libraries that the Rust standard
  library needs.
- The C names that an IR module defines (`map2check_malloc`,
  `map2check_assert`, `analysis_init`, `map2check_non_det_<t>`, `main` of a
  generator...) are not in `libmap2check.a`: link the module's `.ll` (or
  `.bc`) too, as `scripts/build-c-abi-program.sh -m <Module>` does.
- The header and the library must come from the same build. The header
  carries the version as a string, `MAP2CHECK_VERSION` (for example
  `"2.0.0-rc.1"`), so you can log it or check it in your build:

  ```c
  #include "map2check.h"
  #ifndef MAP2CHECK_VERSION
  #error "map2check.h is older than 2.0.0-rc.1"
  #endif
  ```

## Call order

The call order is the C runtime's, and the Map2Check passes and the IR
modules make the calls; a program that links the runtime by hand follows it:

1. `map2check_init(0)` once, before any other call (the argument is the C
   runtime's `isSvComp`, ignored).

   1b. Then `analysis_init()` of the linked analysis mode module and
   `nondet_init()` of the linked generator module, in that order. The
   `Map2CheckFunctions.bc` core of a Map2Check install makes these two
   calls inside `map2check_init`, as the C runtime does; the staticlib
   `libmap2check.a` does not, because it cannot reference names that only
   the IR modules define. Without them the staticlib runs with the mode
   unset: it writes no `map2check_property*` file, never aborts on a
   violation, and prints the JSON report at exit. `tests/ffi_harness.c`
   calls the mode's init for this reason.
2. `map2check_track_bb` and the `map2check_nondet_<t>` calls as the program
   runs, and the check calls of the analysis mode module linked (the names
   of the C runtime, defined by the IR modules; `api-deltas.md` lists
   them).
3. `map2check_success()` at the end of a program that held its property,
   `map2check_error()` or `map2check_exit()` when it did not. With an
   analysis mode selected the verdict goes to the `map2check_property*`
   files of the C runtime; with the none mode `map2check_success()` prints
   the JSON report below.

The first violation is final. `semantic-deltas.md` says where the behaviour
differs from the C runtime and from 1.x.

## JSON report

This is the report of the Rust API (`map2check::output`), kept for the Rust tests
and for `map2check_success()` with no analysis mode. `print_all_containers_as_json()`
and the calls below are no longer C exports (D6).

`print_all_containers_as_json()` prints one pretty-printed JSON object on
stdout when no analysis mode is set (with a mode set, a Map2Check run, it
prints nothing; see below). Whitespace is not part of the contract; parse it. The examples
below are checked against the real serializer by
`tests/compat_docs.rs::integration_guide_json_examples_match_the_serializer`.

Calls `map2check_save_basic_block_log(10, "main")` and then
`map2check_save_nondet_log_int(11, 0, INT_ID, &seven, "main")` print:

<!-- example: success -->
```json
{
  "map2check_log": {
    "result": "TRUE",
    "step": 2,
    "Container_TrackBBLog": [
      { "step": 1, "line": 10, "function_name": "main" }
    ],
    "Container_NonDetLog": [
      {
        "step": 2,
        "line": 11,
        "scope": 0,
        "function_name": "main",
        "value": { "type": "INT", "value": 7 }
      }
    ]
  }
}
```

The same calls followed by `set_false_result(5 /* Reachability */, 12, "main")`
print:

<!-- example: violation -->
```json
{
  "map2check_log": {
    "result": "FALSE",
    "step": 2,
    "property": "REACHABILITY",
    "line_number": 12,
    "function_name": "main",
    "Container_TrackBBLog": [
      { "step": 1, "line": 10, "function_name": "main" }
    ],
    "Container_NonDetLog": [
      {
        "step": 2,
        "line": 11,
        "scope": 0,
        "function_name": "main",
        "value": { "type": "INT", "value": 7 }
      }
    ]
  }
}
```

`Container_AllocationLog` appears only for memory-safety violations (SD-02).
`map2check_map_malloc((void *)0x1000, 16)` followed by
`map2check_check_free("p", (void *)0x10, (void *)0x2000, 0, 20, "main")`
(free of `p`, at `0x10`, holding `0x2000`) prints:

<!-- example: memory -->
```json
{
  "map2check_log": {
    "result": "FALSE",
    "step": 1,
    "property": "MEMSAFETY_FREE",
    "line_number": 20,
    "function_name": "main",
    "Container_TrackBBLog": [],
    "Container_NonDetLog": [],
    "Container_AllocationLog": [
      {
        "step": 1,
        "line": 0,
        "scope": 0,
        "var_mem_address": 4096,
        "mem_address_points_to": 4096,
        "is_dynamic": true,
        "is_free": false,
        "ptr_name": "",
        "function_name": "",
        "size_destiny": 16,
        "size_primitive": 1,
        "is_null_valid": false
      }
    ]
  }
}
```

`property` takes one of `OVERFLOW`, `MEMSAFETY_FREE`, `MEMSAFETY_DEREF`,
`MEMSAFETY_MEMTRACK`, `MEMSAFETY_MEMCLEANUP`, `REACHABILITY`,
`CONCURRENCY`, `ASSERT` and `UNKNOWN`. Nondet `type` takes one of `INT`, `UINT`, `LONG`, `CHAR`,
`FLOAT` and `DOUBLE`. Map2Check does not read this JSON: it reads the
result files described below. The JSON is an additional channel with its
own schema, pinned by a snapshot test (#14, SD-01).

## Result files for Map2Check

The analysis mode and generator modules linked into the program select what
the runtime writes, as in the C runtime of Map2Check `develop`. In a
Map2Check run the library writes into the current directory the files the
frontend reads, byte for byte as the C runtime does (`map2check_property*`,
and with the witness module `WitnessGeneration.bc` linked `track_bb_log.st`,
`heap_log.csv`, `allocation_log.csv`, `list_log.csv`, `klee_log.csv` and
`map2check_checked_error`). The first violation ends the process, and
`map2check_success()` returns when the end-of-program verdict holds. With the
none mode nothing is written. The `map2check::ffi` functions that the
paragraph on the JSON report names set a mode directly, for the Rust tests.
See “Result files” in `api-deltas.md` and SD-20 for how the files are written.

## Known gaps

- **Validated commit only:** the gates ran on Map2Check `develop`
  `0bca42eb` (and `3e914528ec57`, same C runtime modules). A later
  `develop` that changes the runtime modules or the frontend needs a new
  gate.
- **KLEE and AFL++ differences:** the accepted deviations SD-20, SD-24, SD-25
  and SD-26 change verdicts on a few corpus tasks (the gate reports list the
  exact keys).
- **Thread safety:** the state sits behind one global mutex. The calls are
  safe from any thread but serialise, and a callback must not re-enter the
  library while a call is running.
