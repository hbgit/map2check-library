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

### SD-04 — End-of-program leak check runs in both modes

**Classification:** fixed (#10)
**Tests:** `rust/src/ffi_tests.rs::without_memcleanup_leak_is_reported_as_memtrack_at_exit`, `rust/src/ffi_tests.rs::memcleanup_reports_leak_as_memcleanup_at_exit`, `rust/src/ffi_tests.rs::endprog_keeps_an_earlier_violation`, `rust/src/ffi_tests.rs::options_survive_init_and_reset`

**Rust:** `map2check_check_mem_endprog()` always runs the leak check. A
dynamic allocation that was never freed reports `MEMSAFETY_MEMCLEANUP` after
`map2check_set_memcleanup()` and `MEMSAFETY_MEMTRACK` otherwise. The option
is configuration: `map2check_init()` and `map2check_reset()` keep it. Since
Task 2.3 the check runs `analysis_is_program_correct` of the analysis mode
(SD-14): with the mode unset or memtrack the option picks between the
memtrack and memcleanup verdicts, memcleanup mode always reports memcleanup,
and the other modes report no leak. A violation recorded earlier stays final
(SD-03).

**Before #10:** the Rust function did nothing until
`map2check_set_memcleanup()` had been called, so a leak in memtrack mode went
unreported.

**C runtime of Map2Check `develop`:** `map2check_exit()` calls
`analysis_is_program_correct()` when no error was recorded
(`Map2CheckFunctions.c:89-92`). In memtrack mode it writes `FALSE_MEMTRACK`
(`AnalysisModeMemtrack.c:138-146`, tag at `:141`); in memcleanup mode it
writes `FALSE_MEMCLEANUP` (`AnalysisModeMemcleanup.c:138-146`, tag at `:142`).
Both use the same `valid_allocation_log()` scan, and both report line 0 with
an empty function name.

**Reproduce:**

```c
map2check_init();
map2check_map_malloc((void *)0x1000, 16);
map2check_check_mem_endprog();   /* MemsafetyMemtrack */
/* with map2check_set_memcleanup() first: MemsafetyMemcleanup */
```

### SD-05 — NULL load is a violation unless NULL is declared valid

**Classification:** intentional
**Tests:** `rust/src/ffi_tests.rs::check_load_null_depends_on_null_is_valid`, `rust/src/ffi_tests.rs::null_is_valid_accepts_null_load`, `rust/src/ffi_tests.rs::options_survive_init_and_reset`

**Rust:** `map2check_check_load(NULL, ...)` reports `MEMSAFETY_DEREF` unless
`map2check_set_null_is_valid()` was called first. After that call it is
safe. The option survives `map2check_init()` and `map2check_reset()`.

**C runtime of Map2Check `develop`:** there is no NULL-is-valid notion on
load. `map2check_load(ptr, size)` finds NULL in neither the heap log nor the
allocation log and sets `ERROR_DEREF` (`AnalysisModeMemtrack.c:156-162`);
`map2check_check_deref` then reports `FALSE_DEREF` (`:297-301`). The default
(option off) matches that verdict. The only NULL flag in `develop` is
`isNullValid` of `map2check_free_resolved_address`, for frees
(`:164-169`). The load option is a Rust extension, hence intentional.

**Reproduce:**

```c
map2check_init();
map2check_check_load(NULL, 12, 0, 4, "main");   /* MemsafetyDeref */
map2check_set_null_is_valid();
map2check_check_load(NULL, 12, 0, 4, "main");   /* None */
```

### SD-06 — Freeing an address with no record

**Classification:** fixed (#37)
**Tests:** `rust/src/ffi_tests.rs::sd06_untracked_free_is_invalid`, `rust/src/ffi_tests.rs::check_free_resolved_address_rejects_stack_slot`, `rust/src/ffi_tests.rs::check_free_rejects_double_free_and_untracked_address`, `rust/src/analysismode/memory.rs::free_resolved_checker_outcomes`, `rust/src/memtrack/mod.rs::free_resolved_unknown_address_is_invalid`

**Rust:** `map2check_check_free` and `map2check_check_free_resolved_address`
both report `MEMSAFETY_FREE` for an address with no heap record (no
allocation or free event; a stack slot or a pointer store does not count).
The most recent heap record for the address decides: a freed block is an
invalid free, a live one is valid. When the resolved check passes, it also
records the release, as `develop` does (`AnalysisModeMemtrack.c:178-182`).

Before #37, `map2check_check_free_resolved_address` treated an address with
no record as a safe free (`is_invalid_free_resolved` ended in
`.unwrap_or(false)`).

**C runtime of Map2Check `develop`:** `is_invalid_free`
(`modules/backend/library/lib/ListLog.c:95-118`) returns false for NULL,
lets the most recent `list_log` row pointing to the address decide
(invalid if freed or not dynamic) and returns true when no row is found.
Both `map2check_free` (`AnalysisModeMemtrack.c:351`) and
`map2check_free_resolved_address` (`AnalysisModeMemtrack.c:171`) use it in
memtrack mode. `develop` matches `lib_old` here.

Parity is on the verdict for an untracked address only, not on the lookup.
`develop` scans `list_log` (pointer stores, free rows and reference
updates) and never `allocation_log`. Rust scans the allocation and free
records and skips pointer stores, which carry no status snapshot here. The
two differ when a block is freed without ever being stored through a
tracked pointer store; that case is SD-13. (In memcleanup mode,
`AnalysisModeMemcleanup.c:167` and `:341` hard-code `error = FALSE`; this
library does not have that mode split.)

**Reproduce:**

```c
map2check_init();
map2check_check_free_resolved_address((void *)0x5000, 3, "main", 0);  /* MemsafetyFree (before #37: None) */
map2check_reset();
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

### SD-12 — `map2check_map_non_static_alloca`: a VLA is a static slot, and `size` is an element count

**Classification:** fixed (#38)
**Tests:** `rust/src/ffi_tests.rs::sd12_vla_is_not_a_leak_and_size_is_elements`, `rust/src/ffi_tests.rs::map_non_static_alloca_records_static_slot_of_elements_times_primitive`, `rust/src/ffi_tests.rs::map_non_static_alloca_ignores_negative_or_overflowing_size`

**Rust:** `map2check_map_non_static_alloca(name, ptr, size, size_primitive,
line, scope)` registers a static slot of `size * size_primitive` bytes,
like `map2check_map_alloca` with that size. A VLA never counts as a leak at
end of program, and loads anywhere inside its `size` elements are valid. A
negative argument, or a byte size that overflows `usize`, drops the record
(SD-09). The signature is unchanged.

Before #38 the record was marked dynamic (a VLA reported
`MEMSAFETY_MEMCLEANUP` with `map2check_set_memcleanup()` on) and `size` was
taken in bytes, so a caller passing the element count registered a block
that was too small.

**C runtime of Map2Check `develop`:** `map2check_non_static_alloca`
(`modules/backend/library/lib/AnalysisModeMemtrack.c:368-372`) calls
`map2check_alloca(name, ptr, size * size_of_primitive, size_of_primitive,
line, scope)`, which appends a `heap_log` row (`:374-379`). `heap_log` rows
are stack/static slots: `map2check_load` accepts them
(`HeapLog.c:37-52`) and the leak check only walks `allocation_log`
(`AllocationLog.c:69-101`). `develop` matches `lib_old` here.

**Reproduce:**

```c
map2check_init();
int n = 4; int vla[n];
map2check_map_non_static_alloca("vla", vla, n, sizeof(int), 3, 0);  /* element count */
map2check_set_memcleanup();
map2check_check_mem_endprog();                                     /* None (before #38: MemsafetyMemcleanup) */
map2check_check_load(&vla[2], 4, 0, sizeof(int), "main");          /* None (before #38: MemsafetyDeref) */
```

### SD-13 — Freeing a block that was never stored through a pointer

**Classification:** intentional
**Tests:** `rust/src/ffi_tests.rs::sd13_free_of_a_never_stored_pointer_is_valid`

**Rust:** the free check decides by the allocation and free records. A live
block is a valid free even if its address was never written to a tracked
pointer variable, so `free(malloc(8))` reports nothing. This is the correct
verdict: the program frees a live heap block exactly once.

**C runtime of Map2Check `develop`:** `is_invalid_free`
(`modules/backend/library/lib/ListLog.c:95-118`) only scans `list_log`,
which `map2check_add_store_pointer` fills (`AnalysisModeMemtrack.c:246-295`)
together with free rows and reference updates (`:185-244`). `map2check_malloc`
writes only `allocation_log` (`:305-323`). When the freed pointer was never
stored through a tracked store, there is no row, `is_invalid_free` returns
TRUE and `map2check_free_resolved_address` reports FALSE_FREE
(`AnalysisModeMemtrack.c:171-177`). This happens for `free(malloc(8))`, or
for `free(mk())` where `mk` returns `malloc(n)`. At -O0 the result is not
stored, and the pass takes the resolved path (`MemoryTrackPass.cpp:311-327`).
This is a false positive in `develop`.

**Reproduce:**

```c
map2check_init();
map2check_map_malloc((void *)0x1000, 8);
map2check_check_free_resolved_address((void *)0x1000, 3, "main", 0);  /* None; develop: FALSE_FREE */
```

### SD-14 — The analysis mode is chosen at run time; unset keeps every check

**Classification:** intentional
**Tests:** `rust/src/ffi_tests.rs::unset_mode_keeps_every_check_active`, `rust/src/ffi_tests.rs::mode_none_reports_nothing`, `rust/src/ffi_tests.rs::mode_memtrack_reports_memory_errors_only`, `rust/src/ffi_tests.rs::mode_memcleanup_reports_only_the_leak_as_memcleanup`, `rust/src/ffi_tests.rs::mode_overflow_reports_overflow_only`, `rust/src/ffi_tests.rs::mode_assert_reports_assert_only`, `rust/src/ffi_tests.rs::mode_target_reports_nothing_from_checks`, `rust/src/ffi_tests.rs::memcleanup_option_is_an_alias_of_memcleanup_mode_for_the_leak`, `rust/src/ffi_tests.rs::is_valid_assert_false_reports_assert`, `rust/src/analysismode/mode.rs::program_correct_memcleanup_reports_leak_as_memcleanup`

**Rust:** `map2check_set_mode()` selects the mode before `map2check_init()`;
init and reset keep it. Each mode activates the checks that its
`AnalysisMode*.c` defines in develop; a check of another mode records
nothing. Tracking calls record in every mode, and an inactive
`map2check_check_free_resolved_address` still records the release. When
`map2check_set_mode()` is never called the mode is unset: every check is
active and the leak tag follows the memcleanup option, as before Task 2.3.
The memcleanup option is an alias of the memcleanup mode for the leak tag,
so memtrack mode plus the option reports `MEMSAFETY_MEMCLEANUP`. A failed
assert reports `ASSERT` instead of `REACHABILITY`. In memcleanup mode a leak
is any live allocation by the Rust leak rule; develop also requires
`is_memcleanup_error` (`ListLog.c:40-65`) to hold.

**C runtime of Map2Check `develop`:** the mode is fixed at link time
(`modules/frontend/caller.cpp:575-612`): one of `AnalysisModeNone.c`
(cover-branches and reachability), `AnalysisModeMemtrack.c`,
`AnalysisModeMemcleanup.c`, `AnalysisModeOverflow.c` or
`AnalysisModeAssert.c` is linked, so calls of another mode are never emitted
and there is no unset mode. `map2check_assert` writes `ASSERT`
(`AnalysisModeAssert.c:18-23`, `PropertyGenerator.c:92-97`). The memcleanup
mode never fails a load, deref or free (`AnalysisModeMemcleanup.c:158`,
`:293`, `:166`, `:343`).

**Reproduce:**

```c
map2check_set_mode(AnalysisMode_None);
map2check_init();
map2check_check_deref((void *)0xdead, 0, 1, "main");   /* None */
map2check_set_mode(AnalysisMode_Memtrack);
map2check_init();
map2check_check_deref((void *)0xdead, 0, 1, "main");   /* MemsafetyDeref */
```

### SD-15 — Reaching the target records the violation and returns

**Classification:** accepted limitation
**Tests:** `rust/src/ffi_tests.rs::map2check_reach_target_records_and_returns`, `rust/src/ffi_tests.rs::reach_target_keeps_the_first_violation`, `rust/src/ffi_tests.rs::reach_target_works_in_every_mode_and_accepts_null_name`

**Rust:** `map2check_reach_target(func, scope, line)` records
`REACHABILITY` at `line` in `func` and returns. The first violation stays
final (SD-03). It works in every mode and ignores `scope`. Ending the run
with the result files belongs to Task 2.4 of the cutover plan; until then
the program keeps running after the target.

**C runtime of Map2Check `develop`:** `map2check_target_function` writes
`TARGET-REACHED` and calls `map2check_error()`, which ends the process
(`Map2CheckFunctions.c:61-65`, `:72-75`, `:89-102`). It is part of
`Map2CheckFunctions.c`, linked in every mode.

**Reproduce:**

```c
map2check_set_mode(AnalysisMode_Target);
map2check_init();
map2check_reach_target("reach_error", 0, 12);   /* Reachability, line 12; returns */
```
