# Integration guide — linking `libmap2check.a` from C

This guide covers what a C program or an instrumentation pass needs to use
the Rust `map2check-library`: the release contents, how to link, call
order, the JSON report and the known gaps. Compatibility details are in
[`api-deltas.md`](api-deltas.md) (symbols and signatures) and
[`semantic-deltas.md`](semantic-deltas.md) (behaviour).

## Release contents

A release archive `map2check-library-<version>-<target>.tar.gz` (see
[`release.md`](release.md)) unpacks to:

```
map2check-library-<version>-<target>/
├── include/map2check.h      # C header; MAP2CHECK_VERSION == <version>
├── lib/libmap2check.a            # plain C programs (no features)
├── lib/libmap2check_libfuzzer.a  # LibFuzzer targets (feature libfuzzer)
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
cargo build --release                       # plain C programs
cargo build --release --features libfuzzer  # LibFuzzer targets (overwrites the same .a)
```

`build.rs` regenerates `include/map2check.h` on every build. The header is
not committed (`.gitignore`), so always take it from the same build as the
library.

## Linking

```sh
cc -I include my_program.c lib/libmap2check.a -ldl -lpthread -lm -o my_program
```

- `-ldl -lpthread -lm` are the system libraries that the Rust standard
  library needs.
- Use `lib/libmap2check.a` for ordinary programs. It does not define the
  `__VERIFIER_*` functions or `LLVMFuzzerTestOneInput`, even though the
  header declares them.
- Use `lib/libmap2check_libfuzzer.a` for LibFuzzer targets. It defines
  `LLVMFuzzerTestOneInput`, which calls `int __map2check_main__(void)`. The
  program must define that function and be built with
  `clang -fsanitize=fuzzer`. Without that function, the link fails with
  `undefined reference to '__map2check_main__'`.
- The header and the library must come from the same build. The header
  carries the version as a string, `MAP2CHECK_VERSION` (for example
  `"1.0.0-rc1"`), so you can log it or check it in your build:

  ```c
  #include "map2check.h"
  #ifndef MAP2CHECK_VERSION
  #error "map2check.h is older than 1.0.0-rc1"
  #endif
  ```

## Call order

1. `map2check_init()` once, before any other call.
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

A violation does not stop the program, and a later safe memory check
resets the verdict (SD-03). Read the verdict right after the check you care
about.

## JSON report

`print_all_containers_as_json()` prints one pretty-printed JSON object on
stdout. Whitespace is not part of the contract; parse it. The examples
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
`map2check_check_free("p", (void *)0x2000, 0, 20, "main")` prints:

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
`MEMSAFETY_MEMTRACK`, `MEMSAFETY_MEMCLEANUP`, `REACHABILITY` and
`CONCURRENCY`. Nondet `type` takes one of `INT`, `UINT`, `LONG`, `CHAR`,
`FLOAT` and `DOUBLE`. The schema is not final: container and field names
are still being reconciled with the existing consumer in #14 (SD-01).

## Known gaps

- **Map2Check passes:** the passes of `hbgit/Map2Check@develop` insert a
  different symbol family (`map2check_track_bb`, `map2check_alloca`, …) and
  cannot link against this library yet. See the pass matrix in
  `api-deltas.md` and #21.
- **Result files:** the Map2Check frontend reads `map2check_property_*`
  files; this library only prints JSON (#19).
- **KLEE:** no KLEE build exists yet; the decision is #20.
- **Thread safety:** the state sits behind one global mutex. The calls are
  safe from any thread but serialise, and a callback must not re-enter the
  library while a call is running.
