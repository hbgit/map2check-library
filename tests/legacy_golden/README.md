# Golden files of the C runtime of Map2Check `develop`

Each `<TAG>/` directory holds every file that the C runtime of Map2Check
`develop` (`modules/backend/library/lib/`) writes for one scenario, plus
`.exit_status` (134 = `abort()`, 0 = normal exit).
`rust/src/ffi_golden_tests.rs` makes the same calls through this library,
with the mode set and witness on, in a child process, and compares every
file byte for byte (#19).

The Map2Check frontend deletes its scratch directory, so the files cannot be
copied out of a normal run. Instead `drivers/<TAG>.c` calls the C runtime
API directly, with the calls an instrumented program makes, and
`drivers/build_goldens.sh` builds each driver as `Caller::linkLLVM` does
(`modules/frontend/caller.cpp:550-640`): the driver bitcode, then
`Map2CheckFunctions`, `TrackBBLog`, `NonDetLog`, `PropertyGenerator`,
`ContainerRealloc`, the `AnalysisMode*.c` of the tag (and `AllocationLog`,
`ListLog`, `HeapLog` for the memory modes), the nondet generator and
`WitnessGeneration` (the witness binary), linked with `llvm-link-16` and
compiled with `clang-16`. Each binary runs in a fresh directory.

| Tag | Mode file | Calls after `map2check_init(0)` and the shared tracking calls |
|---|---|---|
| `FALSE-FREE` | `AnalysisModeMemtrack.c` | memory prelude, `map2check_free` of `p` twice (the second fails after appending its FREE row) |
| `FALSE-FREE-RESOLVED` | `AnalysisModeMemtrack.c` | memory prelude, `map2check_free` of `p`, `map2check_free_resolved_address` of the same block |
| `FALSE-DEREF` | `AnalysisModeMemtrack.c` | memory prelude, `map2check_load` of an unallocated address, `map2check_check_deref` |
| `FALSE-MEMTRACK` | `AnalysisModeMemtrack.c` | memory prelude, `map2check_success` (the block leaks) |
| `FALSE-MEMCLEANUP` | `AnalysisModeMemcleanup.c` | memory prelude, `map2check_success` (the block leaks, `p` points to it) |
| `NONE` | `AnalysisModeMemtrack.c` | memory prelude, `map2check_free` of `p`, `map2check_success` |
| `UNKNOWN` | `AnalysisModeMemtrack.c` | memory prelude, `map2check_malloc(NULL, 4)` |
| `OVERFLOW` | `AnalysisModeOverflow.c` | `map2check_binop_add(INT_MAX, 1, 32, ...)` |
| `DIVBYZERO` | `AnalysisModeOverflow.c` | `map2check_binop_sdiv(7, 0, 32, ...)` |
| `POSIX-MEMALIGN` | `AnalysisModeMemtrack.c` | memory prelude, `q` on the stack, `q = BLOCK2` written into its slot, `map2check_posix(&q, 32)`, `map2check_success` (both blocks leak) |
| `ASSERT` | `AnalysisModeAssert.c` | `map2check_assert(0, ...)` |
| `TARGET-REACHED` | `AnalysisModeNone.c` (`REACHABILITY_MODE`) | `map2check_target_function` |
| `NONDET-TYPES` | `AnalysisModeAssert.c` | one `map2check_nondet_<t>` of each of the 16 `NONDET_TYPE`s, with the value as `NonDetPass.cpp` casts it to `int`, then `map2check_assert(0, ...)` |

`drivers/golden.h` holds the shared calls: three basic blocks (one line
repeated), five nondet values (int, uint, char, long, double; the char zero-extended, as `NonDetPass.cpp` passes it) and the
memory prelude (`p` on the stack, `&main`, `p = malloc(16)`).

Two accommodations make the output reproducible and complete:

- **Fixed addresses.** Every address the runtime sees lies in an arena
  mapped at `0x10000000` (`MAP_FIXED_NOREPLACE`), so the `%p` columns are
  the same on every run and the Rust test can pass the same numbers. The
  runtime calls `free()` on a leaked block at exit (`AllocationLog.c:91`);
  the link uses `-Wl,--wrap=free` and `__wrap_free` ignores arena addresses.
- **Nondet log.** `NonDetGeneratorNone.c` writes no `klee_log.csv` (its
  `nondet_generate_aux_witness_files` is empty, `:42`), so the drivers link
  `drivers/NonDetGeneratorLog.c`: the `nondet_init`, `nondet_destroy` and
  `nondet_generate_aux_witness_files` of `NonDetGeneratorAFL.c` (`:25`,
  `:27`, `:39-41`) with the plain `main` of `NonDetGeneratorNone.c`.

## Regenerating

From the repository root, with the develop checkout of Map2Check at
`$MAP2CHECK` (here `/home/rock/Documents/Dev/Map2Check-cutover`, branch
`test/cutover-baseline` at `b3c10cb7`, whose `modules/backend/library` and
`caller.cpp` are those of `f01e8c3e`, the commit of the image), mounting
read-only what is only read:

```sh
docker run --rm --user "$(id -u):$(id -g)" \
  -v "$MAP2CHECK/modules/backend/library":/runtime:ro \
  -v "$PWD/tests/legacy_golden/drivers":/drivers:ro \
  -v "$PWD/tests/legacy_golden":/out \
  map2check-dev:cutover-f01e8c3e bash /drivers/build_goldens.sh
```

The script prints, per tag, the exit status and the files written. The
runtime compiles with warnings (`map2check_posix` prototypes); they are
expected.
