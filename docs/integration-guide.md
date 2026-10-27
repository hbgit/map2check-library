# Integration guide — linking `libmap2check.a` from C

This guide covers what a C program or an instrumentation pass needs to use
the Rust `map2check-library`: the release contents, how to link, call
order, the JSON report and the known gaps. Compatibility details are in
[`api-deltas.md`](api-deltas.md) (symbols and signatures) and
[`semantic-deltas.md`](semantic-deltas.md) (behaviour).

**2.0.0 (D6, Task 2.10).** The library exports the C runtime ABI of
Map2Check `develop` only: the names its core modules own and the
`__m2c_rt_*` entry points that the generated IR modules
(`scripts/runtime-ir/gen_ll.py`) forward to. A C program links the
staticlib together with the IR modules that define the other C names, as
Map2Check links a program (`scripts/build-c-abi-program.sh`). The 1.x core
API this guide used to describe (`map2check_set_mode`, `map2check_map_*`,
`print_all_containers_as_json`...) and the `libfuzzer` and `klee` features
left the C ABI (`CHANGELOG.md`); the call order and examples below are
the record of 1.x until the guide is rewritten for the drop-in runtime
(plan Task 5.1). The JSON report is unchanged: `map2check_success()` prints
it when no analysis mode is selected.

## Release contents

A release archive `map2check-library-<version>-<target>.tar.gz` (see
[`release.md`](release.md)) unpacks to:

```
map2check-library-<version>-<target>/
├── include/map2check.h      # C header; MAP2CHECK_VERSION == <version>
├── lib/libmap2check.a            # no features
├── lib/libmap2check_runtime.a    # runtime profile, feature wasm
├── docs/integration-guide.md
├── docs/api-deltas.md
├── docs/semantic-deltas.md
├── CHANGELOG.md
└── LICENSE                  # GPL-3.0-only
```

A `SHA256SUMS` file next to the archive covers it.

## Building from source

Without a release archive, run this from the repository root:

```sh
cargo build --release                       # no features
```

The build Map2Check links is the `runtime` profile (release optimisations
with `panic = "unwind"`, so the FFI guard can recover panics):

```sh
cargo build --profile runtime --features wasm   # target/runtime/libmap2check.a
```

The drop-in runtime as the 21 bitcode modules Map2Check links (the Rust core
built from `klee/Cargo.toml` with rustc 1.72.1 and the LLVM 16 tools, and
the IR modules) is a test build today
(`scripts/runtime-ir/build-test-runtime-bc.sh <out-dir>`); plan Task 3.1
productizes it.

`build.rs` regenerates `include/map2check.h` on every build. The header is
not committed (`.gitignore`), so always take it from the same build as the
library.

## Linking

```sh
cc -I include my_program.c lib/libmap2check.a -ldl -lpthread -lm -o my_program
```

- `-ldl -lpthread -lm` are the system libraries that the Rust standard
  library needs.
- The C names that an IR module defines (`map2check_malloc`,
  `map2check_assert`, `analysis_init`, `map2check_non_det_<t>`, `main` of a
  generator...) are not in the library: link the module's `.ll` (or `.bc`)
  too, as `scripts/build-c-abi-program.sh -m <Module>` does.
- The header and the library must come from the same build. The header
  carries the version as a string, `MAP2CHECK_VERSION` (for example
  `"1.1.0-rc1"`), so you can log it or check it in your build:

  ```c
  #include "map2check.h"
  #ifndef MAP2CHECK_VERSION
  #error "map2check.h is older than 1.1.0-rc1"
  #endif
  ```

## Call order

1. `map2check_init(0)` once, before any other call.
2. Tracking calls as the program runs: `map2check_save_basic_block_log`,
   `map2check_save_nondet_log_*`, `map2check_map_*`.
3. Check calls next to the operation they guard: `map2check_check_load`,
   `map2check_check_free`, `map2check_check_deref`, `map2check_binop_*`,
   `map2check_is_valid_assert`.
4. Optionally, `map2check_set_memcleanup()` and then
   `map2check_check_mem_endprog()` at exit.
5. `map2check_success()` or `print_all_containers_as_json()` to emit the
   report; `get_current_property()` reads the verdict without printing.
6. `map2check_reset()` to analyse another input in the same process.
   LibFuzzer builds do this on every iteration.

A violation does not stop the program, but the first violation is final:
later checks, safe or not, and later `set_false_result` calls leave it in
place (SD-03). Only `map2check_init()`, `map2check_reset()` and
`vcc_reset_meta_data()` clear it.

## JSON report

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

A Map2Check-instrumented program calls `map2check_set_mode()` before
`map2check_init()`, and the witness binary also calls
`map2check_enable_witness()`. With a mode set, the library writes into the
current directory the files the Map2Check frontend reads, byte for byte as
the C runtime of Map2Check `develop` does: `map2check_property*`, and with
witness on `track_bb_log.st`, `heap_log.csv`, `allocation_log.csv`,
`list_log.csv`, `klee_log.csv` and `map2check_checked_error`. The first
violation ends the process with `abort()`; `map2check_success()` returns
when the end-of-program verdict holds. Without a mode nothing is written
and nothing aborts. See “Result files” in `api-deltas.md`.

## Known gaps

- **Map2Check passes:** the passes of `hbgit/Map2Check@develop` insert a
  different symbol family (`map2check_track_bb`, `map2check_alloca`, …) and
  cannot link against this library yet. See the pass matrix in
  `api-deltas.md` and #21.
- **KLEE:** no KLEE build exists yet; the decision is #20.
- **Thread safety:** the state sits behind one global mutex. The calls are
  safe from any thread but serialise, and a callback must not re-enter the
  library while a call is running.
