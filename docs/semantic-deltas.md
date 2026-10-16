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
| `C behaviour preserved on purpose` | The C runtime of Map2Check `develop` does something odd and the Rust library does the same, because a consumer depends on the exact output. |

### SD-01 — JSON report shape

**Classification:** intentional (#14)
**Tests:** `tests/compat_docs.rs::integration_guide_json_examples_match_the_serializer`, `rust/src/output/mod.rs::output_is_valid_json`, `rust/src/output/mod.rs::json_report_snapshot`, `rust/src/ffi_golden_tests.rs::assert_violation_with_mode_set_writes_files_aborts_and_prints_no_json`

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

**Decision (#14):** Map2Check does not read this JSON. It reads the result
files that the library writes when an analysis mode is set (#19, see
“Result files” in [`api-deltas.md`](api-deltas.md#result-files)). The JSON
is an additional channel with its own schema, kept as it is and pinned by
`json_report_snapshot`. It is printed only when no analysis mode is set; a
Map2Check run (mode set) prints nothing on stdout, as develop.

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

**Rust:** with an analysis mode set (a Map2Check run), the first violation
writes the result files and aborts, as in develop (Task 2.4, #19). With the
mode unset, a check that finds a violation records it and returns, and the
process keeps running. Either way the first recorded violation is final: `AnalysisState::set_false`
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

### SD-07 — `__VERIFIER_assume(0)` abandons the fuzzer input; outside one it exits with 0

**Classification:** intentional
**Tests:** `rust/src/nondet/libfuzzer.rs::failed_assume_abandons_only_the_current_iteration`, `rust/src/nondet/libfuzzer.rs::failed_fuzzer_assume_abandons_the_iteration_too`, `rust/src/nondet/libfuzzer.rs::verifier_assume_false_exits_with_zero`, `rust/src/nondet/libfuzzer.rs::map2check_fuzzer_assume_false_exits_with_zero`

**Rust:** inside `LLVMFuzzerTestOneInput`, `__VERIFIER_assume(0)` and
`map2check_fuzzer_assume(0)` abandon the current input: they unwind (a
`resume_unwind` with a private payload) through the analysed program's
frames back to `LLVMFuzzerTestOneInput`, which catches it and returns 0.
The fuzzer goes on with the next input in the same process, and the next
iteration starts from an empty state (SD-11). Both exports, and the
`__map2check_main__` import, are `extern "C-unwind"`. The program must be
compiled with `-fexceptions` (D1 condition 11): without it clang marks the
C frames `nounwind`, and the unwind works only thanks to the default
`.eh_frame`, undefined in LLVM IR. A program frame with
`__attribute__((cleanup))` compiled with `-fexceptions` has its cleanup run
by the unwind, where develop's `longjmp` skips it. With no iteration
running (a program linked without a fuzzer driver), or in a
`panic = "abort"` build, they keep calling `exit(0)`.

**Legacy (Map2Check `develop`):** `nondet_assume` calls `nondet_cancel`,
which `longjmp`s back to the `setjmp` in the `__AFL_LOOP` of `main`, and the
loop moves on to the next input (`NonDetGeneratorAFL.c:31-37`, `:171-184`).
The Rust library does the same with an unwind instead of `longjmp`: Rust
cannot call `setjmp`, and a `longjmp` over Rust frames is undefined when
one of them has a destructor. Outside the `__AFL_LOOP` develop has no
case: its `main` always runs the program inside the loop.

**Reproduce (link with `--features libfuzzer`):**

```c
int __map2check_main__(void) {
  __VERIFIER_assume(__VERIFIER_nondet_int() == 7);
  /* reached only for inputs that start with 07 00 00 00 */
  return 0;
}
/* LLVMFuzzerTestOneInput returns 0 for every input; the process goes on */
```

### SD-08 — `__VERIFIER_error()` / `__VERIFIER_assert(0)` without an analysis mode

**Classification:** fixed (#20)
**Tests:** `rust/src/nondet/libfuzzer.rs::verifier_error_is_a_no_op_with_a_mode_and_the_deref_is_reported`, `rust/src/nondet/libfuzzer.rs::target_mode_reaches_only_through_map2check_reach_target`, `rust/src/nondet/libfuzzer.rs::verifier_error_aborts_and_reports_reachability`, `rust/src/nondet/libfuzzer.rs::verifier_assert_false_aborts_and_reports_reachability`

**Legacy (develop):** both are empty. `__VERIFIER_error()` is
`// DO NOTHING` (`Map2CheckFunctions.c:57-59`) and `__VERIFIER_assert` is
`// DO NOTHING` (`AnalysisModeAssert.c:25-27`, defined only in the assert
mode). The passes carry the checks: the target pass emits
`map2check_target_function` (reachability), the assert pass emits
`map2check_assert`. The earlier text of this entry, "a violation ends in
`abort()` through `map2check_error()`", described `map2check_error`, not
`__VERIFIER_error`.

**Rust, mode set (a Map2Check run):** the same as develop: both return and
record nothing, in the libFuzzer and the KLEE generators. Reachability is
reported only by `map2check_reach_target`, an assert failure only by
`map2check_is_valid_assert`. Before this fix both recorded `REACHABILITY`
and aborted with no property file. Under KLEE's
`--exit-on-error-type=Abort` that stopped the exploration before the real
violation of a memory or overflow task.

Under KLEE the same is checked by `tests/klee_paths.sh` with
`tests/klee/vererr_deref.c` and `tests/klee/vererr_target.c`. Fixed for the
mode-set path in the Task 2.7 review; the mode-unset path below stays as
an intentional delta.

**Rust, mode unset (direct API users):** `__VERIFIER_error()` and
`__VERIFIER_assert(0)` record `REACHABILITY`, print the JSON report
(SD-01) and call `abort()`; LibFuzzer treats the abort as a crash.

**Reproduce (link with `--features libfuzzer`):**

```c
map2check_init();
__VERIFIER_error();   /* no mode: prints "REACHABILITY", then SIGABRT */

map2check_set_mode(1);  /* memtrack */
map2check_init();
__VERIFIER_error();   /* returns; nothing recorded */
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
**Tests:** `rust/src/ffi_tests.rs::unset_mode_keeps_every_check_active`, `rust/src/ffi_tests.rs::mode_none_reports_nothing`, `rust/src/ffi_tests.rs::mode_memtrack_reports_memory_errors_only`, `rust/src/ffi_tests.rs::mode_memcleanup_reports_only_the_leak_as_memcleanup`, `rust/src/ffi_tests.rs::mode_overflow_reports_overflow_only`, `rust/src/ffi_tests.rs::mode_assert_reports_assert_only`, `rust/src/ffi_tests.rs::mode_target_reports_nothing_from_checks`, `rust/src/ffi_tests.rs::memcleanup_option_is_an_alias_of_memcleanup_mode_for_the_leak`, `rust/src/ffi_tests.rs::is_valid_assert_false_reports_assert`, `rust/src/ffi_tests.rs::set_mode_ignores_out_of_range_values`, `rust/src/ffi_tests.rs::memcleanup_mode_leak_never_stored_has_no_verdict`, `rust/src/ffi_tests.rs::memcleanup_mode_checks_only_the_last_leak`, `rust/src/ffi_tests.rs::memtrack_mode_reports_any_leak_reachable_or_not`

**Rust:** `map2check_set_mode()` selects the mode before `map2check_init()`;
init and reset keep it, and a value outside 0–5 is ignored with a
diagnostic. With a mode set, the checks and the end-of-program verdict
follow the `AnalysisMode*.c` of that mode, at parity with develop:

- a check of another mode records nothing;
- memtrack reports any live heap block at exit;
- memcleanup reports `MEMSAFETY_MEMCLEANUP` only when the last leaked
  block, in allocation order, is still referenced by a pointer variable's
  latest stored value.

The differences that remain are these:

- **Unset mode.** When `map2check_set_mode()` is never called the mode is
  unset: every check is active and the leak tag follows the memcleanup
  option, as before Task 2.3. Develop has no unset mode.
- **Memcleanup option.** The option only retags the unset/memtrack leak
  verdict as `MEMSAFETY_MEMCLEANUP`. It does not apply the memcleanup-mode
  reachability rule.
- **Tracking calls** record in every mode.
- **Free records.** The Rust free record has no pointer-variable address.
  So the memcleanup replay does not rebuild the FREE row that develop's
  `map2check_free` appends for the pointer variable
  (`AnalysisModeMemcleanup.c:336-341`). That row matters only when a freed
  address is allocated again.

**C runtime of Map2Check `develop`:**

- **Mode selection.** The mode is fixed at link time
  (`modules/frontend/caller.cpp:575-612`), so calls of another mode are
  never emitted.
- **Memtrack verdict.** Memtrack reports FALSE_MEMTRACK when
  `valid_allocation_log` (`AllocationLog.c:69-101`) returns non-zero
  (`AnalysisModeMemtrack.c:138-146`).
- **Memcleanup verdict.** Memcleanup additionally requires
  `is_memcleanup_error` (`ListLog.c:40-65`) for that last address
  (`AnalysisModeMemcleanup.c:138-148`), over the list log that
  `map2check_add_store_pointer` and `update_reference_list_log` maintain
  (`:181-291`).
- **Asserts.** `map2check_assert` writes `ASSERT`
  (`AnalysisModeAssert.c:18-23`).

**Reproduce:**

```c
map2check_set_mode(AnalysisMode_Memcleanup);
map2check_init();
map2check_map_malloc((void *)0x3000, 8);
map2check_check_mem_endprog();                 /* None: nothing points to it */
map2check_init();
map2check_map_malloc((void *)0x3000, 8);
map2check_map_store_pointer((void *)0x10, (void *)0x3000, 0, "p", 1, "main");
map2check_check_mem_endprog();                 /* MemsafetyMemcleanup */
```

### SD-15 — Reaching the target records the violation and returns

**Classification:** accepted limitation
**Tests:** `rust/src/ffi_tests.rs::map2check_reach_target_records_and_returns`, `rust/src/ffi_tests.rs::reach_target_keeps_the_first_violation`, `rust/src/ffi_tests.rs::reach_target_works_in_every_mode_and_accepts_null_name`

**Rust:** `map2check_reach_target(func, scope, line)` records
`REACHABILITY` at `line` in `func`. The first violation stays final
(SD-03). It works in every mode and ignores `scope`. With a mode set it
ends the run like develop: `map2check_property` gets `TARGET-REACHED`, the
witness files are written when enabled, and the process aborts (Task 2.4,
`rust/src/ffi_golden_tests.rs::target_reached_matches_c_runtime`). The
limitation that remains is the unset mode, where the program keeps running
after the target.

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

### SD-16 — UNKNOWN goes to `map2check_property__unknown`

**Classification:** C behaviour preserved on purpose
**Tests:** `rust/src/output/legacy_files.rs::unknown_uses_legacy_double_underscore_name`, `rust/src/ffi_golden_tests.rs::unknown_matches_c_runtime`

**Rust:** an `UNKNOWN` verdict (`set_false_result(9, ...)`, or a NULL block
from `map2check_map_malloc`/`_calloc` in the memtrack and memcleanup modes)
writes `UNKNOWN\n` to `map2check_property__unknown`, with two
underscores, and writes no `map2check_property`.

**C runtime of Map2Check `develop`:** `PropertyGenerator.c:16` names the
file `map2check_property__unknown`, and `write_property_unknown` (`:24-28`)
is the only UNKNOWN writer that runs (`AnalysisModeMemtrack.c:305-311`).
The frontend looks for `map2check_property_unknown`, with one underscore
(`modules/frontend/utils/tools.cpp:114`), so it never finds the file and
reports UNKNOWN because `map2check_property` is missing (`:98-103`). The
verdict is the same either way; the name is kept so the bytes on disk match
develop.

**Reproduce:**

```c
map2check_set_mode(AnalysisMode_Memtrack);
map2check_init();
map2check_map_malloc(NULL, 4);   /* writes map2check_property__unknown, aborts */
```

### SD-17 — The memory and nondet logs are rebuilt from this library's records

**Classification:** accepted limitation
**Tests:** `rust/src/ffi_golden_tests.rs::false_free_matches_c_runtime`, `rust/src/ffi_golden_tests.rs::false_free_resolved_matches_c_runtime`, `rust/src/ffi_golden_tests.rs::none_matches_c_runtime`, `rust/src/ffi_golden_tests.rs::false_memtrack_matches_c_runtime`, `rust/src/ffi_tests.rs::list_log_free_row_names_the_variable_passed_to_free`, `rust/src/ffi_tests.rs::failing_free_keeps_its_list_log_row_like_develop`, `rust/src/output/legacy_files.rs::nondet_rows_use_develop_types_and_value_formats`, `rust/src/ffi_golden_tests.rs::nondet_types_match_c_runtime`

**Rust:** `heap_log.csv`, `allocation_log.csv`, `list_log.csv` and
`klee_log.csv` are rebuilt at the end of the run by replaying the memory
and nondet records in order with the rules of `AnalysisModeMemtrack.c`,
including develop's own step counter. For the calls of
`tests/legacy_golden/drivers/` the bytes match develop. Since Task 2.5
`map2check_check_free` and `map2check_map_free` receive the pointer
variable's slot, as develop's `map2check_free` does, so the FREE row names
the variable that was freed, and a failing free keeps the row develop
appends before it checks (`AnalysisModeMemtrack.c:346-358`); the golden
`FALSE-FREE` covers that path. These cases still differ:

- **`klee_log.csv`.** Written on every violating witness run. Develop
  writes it only with the AFL++ or KLEE generator; `NonDetGeneratorNone.c`
  writes none (`:42`). A `float` value, which develop has no logger for, is
  logged as a double (type 15). Every other type matches develop byte for
  byte, value format and type number included (golden `NONDET-TYPES`,
  SD-18).
- **Long function names.** Develop copies names into `char[35]` with
  `strncpy` (`FUNCTION_MAX_LENGTH_NAME`), which leaves names of 35 or more
  characters unterminated; this library writes the whole name.
- **NULL names.** Develop prints `(null)` for a NULL name; this library
  prints an empty string, as everywhere else (SD-09).

**Reproduce:**

```c
map2check_set_mode(AnalysisMode_Overflow);
map2check_enable_witness();
map2check_init();
map2check_binop_add_signed(INT64_MAX, 1, 64, 1, "main");
/* klee_log.csv is written; develop's NonDetGeneratorNone.c writes none */
```

### SD-18 — Nondet values: develop's AFL++ input layout and log format, with three differences

**Classification:** intentional
**Tests:** `rust/src/nondet/libfuzzer.rs::every_generator_reads_sizeof_type_bytes_and_wraps_like_develop`, `rust/src/nondet/libfuzzer.rs::seed_a_reads_0x41414141_like_develop`, `rust/src/nondet/libfuzzer.rs::bool_consumes_four_bytes_and_is_the_int_converted_to_bool`, `rust/src/nondet/libfuzzer.rs::empty_input_yields_zero`, `rust/src/nondet/libfuzzer.rs::without_an_iteration_every_generator_yields_zero`, `rust/src/nondet/libfuzzer.rs::pchar_reads_an_unsigned_length_then_length_minus_one_chars`, `rust/src/ffi_golden_tests.rs::nondet_types_match_c_runtime`

**Rust:** the `__VERIFIER_nondet_<t>` generators read the fuzzer input as
develop's `NonDetGeneratorAFL.c` does: `sizeof(type)` bytes per value, in
order, copied in memory order (little-endian on x86-64; `:67-99`), and past
the end of the input the reader rewinds, returning `data[0]` once without
advancing (`get_next_input_from_afl`, `:55-62`). With the 1-byte seed `A`
an `int` is `0x41414141`, as in develop. `pchar` reads an `unsigned`
length, returns NULL for 0, caps it at 4096 and reads `length - 1` chars
(`:101-118`); the string comes from the C `malloc`. The
`map2check_save_nondet_log_<t>` exports write the `klee_log.csv` row
develop writes for the same program: the type number of `enum NONDET_TYPE`
and the value as `NonDetPass.cpp` hands it to the C wrapper (zero-extended
narrow types, so a `char` -3 is `253` and a `short` -2 is `65534`; the low
32 bits of wide types and addresses; `unsigned` with `%u`, `uint` with
`%d`). The differences:

- **Empty input.** Develop reads `data[0]` of an empty buffer, out of
  bounds; the library returns 0 bytes. With no iteration running every
  generator returns 0 and `pchar` returns NULL.
- **`bool`.** Develop's `map2check_non_det_bool` returns the raw `int` of
  its four bytes to a caller that declared `_Bool`, so what the program
  sees depends on how the caller's code reads the register. The library
  reads the same four bytes and returns that `int` converted to `_Bool`
  (`!= 0`).
- **`float`.** Develop has no `float` generator or logger. The library
  reads four bytes for it and logs it as a double (SD-17).

**Reproduce (link with `--features libfuzzer`):**

```c
int __map2check_main__(void) {
  int x = __VERIFIER_nondet_int();   /* input "A": x == 0x41414141 */
  char *s = __VERIFIER_nondet_pchar();
  free(s);
  return 0;
}
```

### SD-19 — The wasm2c runtime: a bad access is OVERFLOW, and four small differences

**Classification:** C behaviour preserved on purpose
**Tests:** `rust/src/ffi_tests.rs::wasm_access_past_the_block_is_reported_as_develop_does`, `rust/src/ffi_tests.rs::wasm_free_of_an_untracked_offset_is_a_false_free_at_the_line`, `rust/src/ffi_tests.rs::wasm_double_free_is_not_reported_as_develop`, `rust/src/ffi_tests.rs::wasm_access_inside_a_freed_inner_block_is_covered_by_the_older_block`, `rust/src/ffi_tests.rs::wasm_checks_are_inactive_in_modes_without_memory_checks`, `rust/src/ffi_tests.rs::wasm_first_violation_is_final`, `rust/src/ffi_tests.rs::rt_funcref_table_allocates_zeroed_elements`

**Rust (feature `wasm`):** `map2check_wasm_check_access(offset, size)`
reports an access that does not lie inside a live registered block as
`OVERFLOW` with line 0 and an empty function name. `map2check_wasm_free` of an
offset that was never registered reports `MEMSAFETY_FREE` at the given line.

**C runtime of Map2Check `develop`:** `AnalysisModeMemtrack.c:416-423`
writes `FALSE_OVERFLOW` (`write_property(FALSE_OVERFLOW, 0, "")`, reported as
`OVERFLOW`), not `FALSE-DEREF`, for a bad access; `:399-407` writes
`FALSE_FREE` at the line for an unknown offset. `tests/integration/test_wasm_pipeline.sh`
of Map2Check accepts `FALSE_OVERFLOW` for the heap-overflow program. The
library keeps develop's tag on purpose, and the table semantics with it: the
newest row whose range `[offset, offset + size - access + 1)` holds the
offset decides, a freed row has size 0 (so its range is empty and an older
covering block still answers), a double free is not an error, and an access
with no registered block is invalid. The checks are active in the modes that
check memory (memtrack and unset); tracking records in every mode.

Differences:

- **No abort without a mode.** As for every check (SD-03, SD-14), the first
  violation is final and the run goes on unless an analysis mode is set,
  when it writes the result files and aborts. develop always aborts.
- **`line` type.** `map2check_wasm_free` takes `int64_t line`, as the pass
  declares it; develop's C parameter is `int`.
- **Trap.** `wasm_rt_trap` records an `UNKNOWN` verdict and aborts (develop
  calls `map2check_error()`, which writes no property, so the frontend reads
  UNKNOWN). The function never returns, with or without a mode, as wasm-rt.h
  declares.
- **Funcref table element size.** develop's `wasm_rt_allocate_funcref_table`
  allocates `elements * sizeof(void*)` bytes for elements of
  `sizeof(wasm_rt_funcref_t)` (32 bytes), a heap overflow once the module's
  element segments are written. The library allocates the real element size.
  `max_size` is left untouched in both.
- **Grow.** `wasm_rt_grow_memory` does not clear bytes when the new size is
  not larger than the old one (develop would `memset` a wrapped length).

**Reproduce (link with `--features wasm`, analysis mode memtrack):**

```c
map2check_set_mode(AnalysisMode_Memtrack);
map2check_init();
map2check_wasm_malloc(0x10000, 16);
map2check_wasm_check_access(0x10010, 4);   /* OVERFLOW, line 0, aborts */
```
