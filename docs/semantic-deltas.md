# Semantic deltas — Rust `map2check-library` vs. the legacy C implementations

Behaviour differences between the Rust library and the legacy C code. Each
entry has an ID (`SD-NN`) that [`api-deltas.md`](api-deltas.md) cites, a
classification, a C snippet against `include/map2check.h` that reproduces
it, and the Rust tests that pin the current behaviour.

"Legacy" means one of two C codebases, and each entry says which:

- the C `map2check-library` that this repository shipped before the rewrite
  (see `docs/plano_map2check_library_rust.md` §1.2 on `master`);
- the C library embedded in Map2Check, available here as `lib_old/` on the
  `origin/refactory_memory_log` branch (commit `68d174d`).

Where the legacy behaviour was not read from source, the entry says so. The
differential harness in #15 will settle those cases.

`tests/compat_docs.rs` checks that IDs run in order with no gaps, that every
classification is from the list below, that `pending decision` and
`suspected regression` and `fixed` cite an issue, and that every test named under
**Tests** exists. When a fix changes one of these behaviours, update the
entry and its tests in the same change.

## Classifications

| Classification | Meaning |
|---|---|
| `intentional` | Deliberate change, kept. |
| `accepted limitation` | Known downside, accepted for now; the entry says why. |
| `suspected regression` | Probably wrong; an issue tracks adjudication. |
| `pending decision` | Waits on the cited issue. |
| `fixed` | Was a regression; the Rust library now matches the C runtime of Map2Check `develop`. The entry cites the fixing issue and the `develop` source. |

### SD-01 — JSON report shape

**Classification:** pending decision (#14)
**Tests:** `tests/compat_docs.rs::integration_guide_json_examples_match_the_serializer`, `rust/src/output/mod.rs::output_is_valid_json`

**Rust:** `print_all_containers_as_json()`, `map2check_success()` and a
failing `map2check_is_valid_assert()` print one pretty-printed JSON object
on stdout. The top-level key is `map2check_log`; `result` is `"TRUE"` or
`"FALSE"`; `property`, `line_number` and `function_name` appear only when
`result` is `"FALSE"`; containers are named `Container_TrackBBLog`,
`Container_NonDetLog` and `Container_AllocationLog`. Memory records use
`var_mem_address`/`mem_address_points_to`, and nondet values are
`{"type": "INT", "value": 7}`. The exact shape is in
[`integration-guide.md`](integration-guide.md#json-report).

**Legacy (C `map2check-library`):** a hand-built compact JSON. Issue #14
lists container names `container_trackbb_log`, `container_nondet_log` and
`container_memtrack_log`, and asks whether a top-level `function_name` is
part of the schema. Whitespace alone is not a semantic difference.

**Reproduce:**

```c
map2check_init();
map2check_save_basic_block_log(10, "main");
print_all_containers_as_json();
```

### SD-02 — Allocation log only on memory violations

**Classification:** intentional
**Tests:** `rust/src/output/mod.rs::memtrack_included_only_for_memory_violations`

**Rust:** `Container_AllocationLog` is emitted only when the violated
property is `MEMSAFETY_FREE`, `MEMSAFETY_DEREF`, `MEMSAFETY_MEMTRACK` or
`MEMSAFETY_MEMCLEANUP`. Reports for other outcomes stay small.

**Legacy:** not verified against source (#15).

**Reproduce:**

```c
map2check_init();
map2check_map_malloc((void *)0x1000, 16);
set_false_result(0 /* Overflow */, 3, "main");
print_all_containers_as_json();   /* no Container_AllocationLog */
map2check_reset();                /* the first violation is final (SD-03) */
map2check_map_malloc((void *)0x1000, 16);
set_false_result(1 /* MemsafetyFree */, 4, "main");
print_all_containers_as_json();   /* Container_AllocationLog present */
```

### SD-03 — Violations do not stop the analysis; the first one is final

**Classification:** fixed (#36)
**Tests:** `rust/src/ffi_tests.rs::sd03_safe_check_keeps_earlier_violation`, `rust/src/ffi_tests.rs::sd03_later_violation_does_not_overwrite_first`

**Rust:** a check that finds a violation records it and returns. The process
keeps running (ending it, with the result files, is Task 2.4 of the cutover
plan). The first recorded violation is final: `AnalysisState::set_false`
ignores every later violation, whether it comes from a memory check, an
overflow check, an assert or `set_false_result`, and the memory checks
(`map2check_check_load`, `map2check_check_free`,
`map2check_check_free_resolved_address`, `map2check_check_deref`,
`map2check_check_mem_endprog`) no longer reset the result to OK before they
check. Only `map2check_init()`, `map2check_reset()` and the explicit
`vcc_reset_meta_data()` clear it.

Before #36 those memory checks reset the result first, so a later safe
access erased any earlier violation, including one that `set_false_result`
recorded.

**C runtime of Map2Check `develop`:** every violation calls
`map2check_error()` (`modules/backend/library/lib/Map2CheckFunctions.c:72-75`),
which calls `map2check_exit()` (`:89-102`): it writes the result files and
calls `abort()`. For example `map2check_free_resolved_address` and
`map2check_free` (`AnalysisModeMemtrack.c:173-177`, `:355-358`) and
`map2check_check_deref` (`AnalysisModeMemtrack.c:297-303`). The first
violation is therefore final. `develop` matches `lib_old` here.

**Reproduce:**

```c
map2check_init();
map2check_map_malloc((void *)0x1000, 16);
set_false_result(5 /* Reachability */, 1, "main");
map2check_check_load((void *)0x1000, 2, 0, 4, "main");
/* get_current_property() == Reachability (before #36: None) */
```

### SD-04 — End-of-program leak check is opt-in

**Classification:** intentional
**Tests:** `rust/src/ffi_tests.rs::check_mem_endprog_is_a_no_op_until_memcleanup_is_enabled`, `rust/src/ffi_tests.rs::set_memcleanup_enables_end_of_program_check`

**Rust:** `map2check_check_mem_endprog()` does nothing until
`map2check_set_memcleanup()` has been called. After that call, a dynamic
allocation that was never freed reports `MEMSAFETY_MEMCLEANUP`.

**Legacy (embedded C library):** `map2check_exit()` calls
`analysis_is_program_correct()` at the end of every run
(`lib_old/Map2CheckFunctions.c:89-102`). Whether a flag gated it was not
verified (#15).

**Reproduce:**

```c
map2check_init();
map2check_map_malloc((void *)0x1000, 16);
map2check_check_mem_endprog();   /* None */
map2check_set_memcleanup();
map2check_check_mem_endprog();   /* MemsafetyMemcleanup */
```

### SD-05 — NULL load is a violation unless NULL is declared valid

**Classification:** intentional
**Tests:** `rust/src/ffi_tests.rs::check_load_null_depends_on_null_is_valid`

**Rust:** `map2check_check_load(NULL, ...)` reports `MEMSAFETY_DEREF` unless
`map2check_set_null_is_valid()` was called first. After that call it is
safe.

**Legacy (embedded C library):** `map2check_load(ptr, size)` has no NULL
case and no flag (`lib_old/AnalysisModeMemtrack.c:156-162`).

**Reproduce:**

```c
map2check_init();
map2check_check_load(NULL, 12, 0, 4, "main");   /* MemsafetyDeref */
map2check_set_null_is_valid();
map2check_check_load(NULL, 12, 0, 4, "main");   /* None */
```

### SD-06 — Freeing an address with no record

**Classification:** suspected regression (#37; differential check in #15)
**Tests:** `rust/src/ffi_tests.rs::check_free_rejects_double_free_and_untracked_address`, `rust/src/analysismode/memory.rs::free_resolved_checker_outcomes`

**Rust:** `map2check_check_free` reports `MEMSAFETY_FREE` for an address
with no record, but `map2check_check_free_resolved_address` treats that
address as safe.

**Legacy (embedded C library):** `is_invalid_free` returns true for an
address with no record (`lib_old/ListLog.c:95-118`), and both
`map2check_free` and `map2check_free_resolved_address` use it.

**Reproduce:**

```c
map2check_init();
map2check_check_free_resolved_address((void *)0x5000, 3, "main", 0);  /* None */
map2check_check_free("p", (void *)0x5000, 0, 4, "main");             /* MemsafetyFree */
```

### SD-07 — `__VERIFIER_assume(0)` ends the process

**Classification:** accepted limitation
**Tests:** `rust/src/nondet/libfuzzer.rs::verifier_assume_false_exits_with_zero`, `rust/src/nondet/libfuzzer.rs::map2check_fuzzer_assume_false_exits_with_zero`

**Rust:** `__VERIFIER_assume(0)` and `map2check_fuzzer_assume(0)` call
`exit(0)`. A Rust panic must not unwind across `extern "C"`, so there is no
safe way to return to `LLVMFuzzerTestOneInput`. The cost is that the
current fuzzing process ends. See “Accepted: `__VERIFIER_assume` /
`map2check_fuzzer_assume` end the process” in `api-deltas.md`.

**Legacy:** not verified against source (#15).

**Reproduce (link with `--features libfuzzer`):**

```c
__VERIFIER_assume(0);   /* process exits with status 0 */
```

### SD-08 — `__VERIFIER_error()` reports REACHABILITY, then aborts

**Classification:** intentional
**Tests:** `rust/src/nondet/libfuzzer.rs::verifier_error_aborts_and_reports_reachability`, `rust/src/nondet/libfuzzer.rs::verifier_assert_false_aborts_and_reports_reachability`

**Rust:** `__VERIFIER_error()` and `__VERIFIER_assert(0)` record
`REACHABILITY`, print the JSON report and call `abort()`. LibFuzzer treats
the abort as a crash.

**Legacy (embedded C library):** a violation ends in `abort()` through
`map2check_error()` (`lib_old/Map2CheckFunctions.c:72-102`).

**Reproduce (link with `--features libfuzzer`):**

```c
map2check_init();
__VERIFIER_error();   /* prints "REACHABILITY", then SIGABRT */
```

### SD-09 — Invalid arguments are ignored instead of causing undefined behaviour

**Classification:** intentional
**Tests:** `rust/src/ffi_tests.rs::map_alloca_ignores_negative_size`, `rust/src/ffi_tests.rs::map_malloc_ignores_negative_size`, `rust/src/ffi_tests.rs::map_calloc_ignores_negative_arguments`, `rust/src/ffi_tests.rs::set_false_result_ignores_unknown_property`, `rust/src/ffi_tests.rs::set_false_result_accepts_null_function_name`, `rust/src/ffi_tests.rs::check_load_rejects_negative_size`

**Rust:** the FFI layer never trusts its arguments. Negative sizes in the
`map2check_map_*` calls drop the record, and a `calloc` size that
overflows is dropped too. `set_false_result` ignores an unknown property
value. NULL or non-UTF-8 strings become `""`. A negative size in
`map2check_check_load` is a `MEMSAFETY_DEREF` violation. Panics are caught
at the boundary.

**Legacy (embedded C library):** no validation; for example,
`map2check_calloc` multiplies `quantity * size` without an overflow check
(`lib_old/AnalysisModeMemtrack.c:333-335`).

**Reproduce:**

```c
map2check_init();
map2check_map_malloc((void *)0x1000, -1);   /* no record */
set_false_result(99, 1, NULL);              /* ignored; result stays OK */
```

### SD-10 — Returned log records are not linked

**Classification:** intentional
**Tests:** `rust/src/ffi_tests.rs::legacy_records_are_returned_unlinked`

**Rust:** `map2check_save_nondet_log_*` and `map2check_save_basic_block_log`
return a pointer to a record that the library owns. Its `tqe_next` and
`tqe_prev` are always NULL. The pointer stays valid until the next
`map2check_reset()` or fuzzing iteration (SD-11). Callers must not free it
or walk the list.

**Legacy (C `map2check-library`):** records were `TAILQ` entries linked
into global lists.

**Reproduce:**

```c
map2check_init();
bbtrack_log_t *a = map2check_save_basic_block_log(1, "main");
bbtrack_log_t *b = map2check_save_basic_block_log(2, "main");
/* a->tqe_next == NULL && b->tqe_prev == NULL */
```

### SD-11 — Each LibFuzzer iteration starts from an empty state

**Classification:** intentional
**Tests:** `rust/src/nondet/libfuzzer.rs::fuzzer_iteration_resets_analysis_state_and_input`

**Rust:** `LLVMFuzzerTestOneInput` resets the analysis state before it calls
`__map2check_main__`. Records and results from one input never leak into
the next.

**Legacy:** not verified against source (#15).

**Reproduce:** run any LibFuzzer target linked with `--features libfuzzer`
for two inputs; the second report has no records from the first.

### SD-12 — `map2check_map_non_static_alloca`: a VLA counts as a leak, and `size` is in bytes

**Classification:** suspected regression (#38; differential check in #15)
**Tests:** `rust/src/ffi_tests.rs::map_non_static_alloca_records_dynamic_slot`, `rust/src/ffi_tests.rs::non_static_alloca_is_reported_as_leak_at_end_of_program`, `rust/src/ffi_tests.rs::non_static_alloca_size_is_bytes_not_element_count`

**Rust:** `map2check_map_non_static_alloca` differs from the legacy call in
two ways:

- It marks its record dynamic, as the reconstructed semantics in
  `api-deltas.md` describe. With `map2check_set_memcleanup()` on, a VLA
  that goes out of scope without a matching free reports
  `MEMSAFETY_MEMCLEANUP`.
- It stores `size` as the allocation size in bytes, like
  `map2check_map_alloca`. A caller that passes the element count, as the
  legacy contract expects, registers a block that is too small. Loads past
  the first `size` bytes then report `MEMSAFETY_DEREF`.

**Legacy (embedded C library):** `map2check_non_static_alloca` treats
`size` as an element count and registers a static slot of
`size * size_of_primitive` bytes (`lib_old/AnalysisModeMemtrack.c:366-377`).
So a VLA never counts as a leak.

**Reproduce:**

```c
map2check_init();
int n = 4; int vla[n];
map2check_map_non_static_alloca("vla", vla, sizeof(vla), sizeof(int), 3, 0);
map2check_set_memcleanup();
map2check_check_mem_endprog();   /* MemsafetyMemcleanup */

map2check_reset();
map2check_map_non_static_alloca("vla", vla, n, sizeof(int), 3, 0);  /* legacy: element count */
map2check_check_load(&vla[2], 4, 0, sizeof(int), "main");          /* MemsafetyDeref; legacy: valid */
```
