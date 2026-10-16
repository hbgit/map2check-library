# API deltas — Rust `map2check-library` vs. the legacy C implementations

This document is the symbol/signature compatibility matrix of the C ABI
exported by `libmap2check.a` (declared in the generated
`include/map2check.h`). Behaviour differences that need a reproducible
example live in [`semantic-deltas.md`](semantic-deltas.md) and are cited
here by ID (`SD-NN`).

Two baselines are compared:

- **Legacy C library** — the C `map2check-library` that this repository
  shipped before the Rust rewrite (`master` C branch; its history was not
  carried over). Its symbols come from the parity table in
  `docs/plano_map2check_library_rust.md` §1.2(a) on `master`.
- **Map2Check passes** — the symbols the LLVM passes of
  `hbgit/Map2Check@develop` insert today, taken from §1.2(b) of the same
  plan. The passes link against the C library embedded in Map2Check, not
  against this repository.

`tests/compat_docs.rs` keeps this file honest: every function in the
generated header must have a row in the core matrix with its exact
declaration, and every `SD-NN` cited here must exist in
`semantic-deltas.md`. Update this file in the same change that adds,
removes or changes an export.

## Status vocabulary

| Status | Meaning | Exported? |
|---|---|---|
| `same` | Same name and contract as the baseline. | yes |
| `changed` | Exported, but the signature or behaviour differs from the baseline; the Notes say how. | yes |
| `new` | No baseline counterpart. | yes |
| `discontinued` | Baseline symbol deliberately not ported. | no |
| `pending` | Required by the baseline; decision tracked in the cited issue. | no |
| `out-of-scope` | Required by the baseline, excluded on purpose. | no |

## Core C API matrix

The declaration column is copied from `include/map2check.h` with
whitespace collapsed. The header declares the `libfuzzer` symbols even
when the library is built without that feature; link them only from a
build with `--features libfuzzer`.

| Symbol | Rust declaration (`include/map2check.h`) | Legacy C library | Status | Notes |
|---|---|---|---|---|
| `map2check_init` | `void map2check_init(void)` | `map2check_init` | same | Map2Check passes call `map2check_init(int)`; see the pass matrix. |
| `map2check_reset` | `void map2check_reset(void)` | — | new | Clears containers, result, step counter and flags (#9). |
| `map2check_success` | `void map2check_success(void)` | `map2check_success` | same | Prints the JSON report (SD-01). |
| `set_false_result` | `void set_false_result(int32_t prp, int32_t line_number, const char *function_name)` | `set_false_result` | same | `ViolatedProperty` keeps the C variant order (`caller_lib_result.h:22-31`); unknown values are ignored (SD-09). Ignored when a violation is already recorded (SD-03). |
| `get_current_property` | `enum ViolatedProperty get_current_property(void)` | `get_current_property` | same |  |
| `get_current_step` | `uint64_t get_current_step(void)` | `long get_current_step(void)` | changed | Returns `uint64_t` instead of `long`. |
| `get_next_step` | `uint64_t get_next_step(void)` | `get_next_step()` / `next_current_step()` | same | Advances and returns the step counter. `next_current_step` is not exported; see its row. |
| `print_all_containers_as_json` | `void print_all_containers_as_json(void)` | `print_all_containers_as_json` | changed | Report shape and whitespace differ (SD-01, SD-02; schema decision in #14). |
| `vcc_reset_meta_data` | `void vcc_reset_meta_data(void)` | `vcc_reset_meta_data` | same |  |
| `map2check_set_memcleanup` | `void map2check_set_memcleanup(void)` | `map2check_set_memcleanup` | same | Enables the end-of-program leak check (SD-04). |
| `map2check_set_null_is_valid` | `void map2check_set_null_is_valid(void)` | `map2check_set_null_is_valid` | same | Makes a NULL load safe (SD-05). |
| `map2check_save_nondet_log_int` | `non_det_log_t *map2check_save_nondet_log_int(int line, int scope, enum var_type_t type_var, int *value, const char *function_name)` | returns `non_det_log_t *` | same | Returned record is not linked into a list (SD-10). |
| `map2check_save_nondet_log_uint` | `non_det_log_t *map2check_save_nondet_log_uint(int line, int scope, enum var_type_t type_var, unsigned int *value, const char *function_name)` | returns `non_det_log_t *` | same | Returned record is not linked into a list (SD-10). |
| `map2check_save_nondet_log_long` | `non_det_log_t *map2check_save_nondet_log_long(int line, int scope, enum var_type_t type_var, long *value, const char *function_name)` | returns `non_det_log_t *` | same | Returned record is not linked into a list (SD-10). |
| `map2check_save_nondet_log_float` | `non_det_log_t *map2check_save_nondet_log_float(int line, int scope, enum var_type_t type_var, float *value, const char *function_name)` | returns `non_det_log_t *` | same | Returned record is not linked into a list (SD-10). |
| `map2check_save_nondet_log_double` | `non_det_log_t *map2check_save_nondet_log_double(int line, int scope, enum var_type_t type_var, double *value, const char *function_name)` | returns `non_det_log_t *` | same | Returned record is not linked into a list (SD-10). |
| `map2check_save_nondet_log_char` | `non_det_log_t *map2check_save_nondet_log_char(int line, int scope, enum var_type_t type_var, char *value, const char *function_name)` | returns `non_det_log_t *`; `char` value | same | `char` is `i8` on the Rust side; see “`char` ABI”. Returned record is not linked (SD-10). |
| `map2check_save_basic_block_log` | `bbtrack_log_t *map2check_save_basic_block_log(int32_t line, const char *function_name)` | returns `bbtrack_log_t *` | same | Returned record is not linked into a list (SD-10). |
| `map2check_is_in_trackbb_container` | `int32_t map2check_is_in_trackbb_container(int32_t line)` | `map2check_is_in_trackbb_container` | same |  |
| `map2check_map_alloca` | `void map2check_map_alloca(const char *var_name, const void *ptr_address, int32_t size, int32_t size_primitive, int32_t line_number, int32_t scope)` | `container_memtracklog.h:41` | same |  |
| `map2check_map_non_static_alloca` | `void map2check_map_non_static_alloca(const char *var_name, const void *ptr_address, int32_t size, int32_t size_primitive, int32_t line_number, int32_t scope)` | `container_memtracklog.h:44` | same | Signature and semantics reconstructed; see its section. Counted as a leak at end of program (SD-12). |
| `map2check_map_funct_address` | `void map2check_map_funct_address(const char *var_name, const void *ptr_address)` | `container_memtracklog.h:48` | same | Signature and semantics reconstructed; see its section. |
| `map2check_map_malloc` | `void map2check_map_malloc(const void *ptr_address, int32_t size)` | `map2check_map_malloc` | same | Negative sizes are ignored (SD-09). |
| `map2check_map_calloc` | `void map2check_map_calloc(const void *ptr_address, int32_t quantity, int32_t size)` | `map2check_map_calloc` | same | Negative sizes are ignored (SD-09). |
| `map2check_map_free` | `void map2check_map_free(const char *var_name, const void *ptr_address, uint32_t scope, uint32_t line_number, const char *function_name)` | `map2check_map_free` | same |  |
| `map2check_map_store_pointer` | `void map2check_map_store_pointer(const void *var_address, const void *value, uint32_t scope, const char *var_name, int32_t line_number, const char *funct_name)` | `map2check_map_store_pointer` | same |  |
| `map2check_is_valid_assert` | `void map2check_is_valid_assert(int32_t line_number, const char *function_name, int32_t expression)` | `map2check_is_valid_assert` | same | Prints the JSON report when the assertion fails. |
| `map2check_binop_add_int` | `void map2check_binop_add_int(int32_t param1, int32_t param2, uint32_t line, uint32_t scope, const char *function_name)` | `map2check_binop_add_int` | same | `int`/`unsigned` (32-bit) only, as in C. |
| `map2check_binop_sub_int` | `void map2check_binop_sub_int(int32_t param1, int32_t param2, uint32_t line, uint32_t scope, const char *function_name)` | `map2check_binop_sub_int` | same | `int`/`unsigned` (32-bit) only, as in C. |
| `map2check_binop_mul_int` | `void map2check_binop_mul_int(int32_t param1, int32_t param2, uint32_t line, uint32_t scope, const char *function_name)` | `map2check_binop_mul_int` | same | `int`/`unsigned` (32-bit) only, as in C. |
| `map2check_binop_div_int` | `void map2check_binop_div_int(int32_t param1, int32_t param2, uint32_t line, uint32_t scope, const char *function_name)` | `map2check_binop_div_int` | same | `int`/`unsigned` (32-bit) only, as in C. |
| `map2check_binop_neg_int` | `void map2check_binop_neg_int(int32_t param1, int32_t _param2, uint32_t line, uint32_t scope, const char *function_name)` | `map2check_binop_neg_int` | same | `int`/`unsigned` (32-bit) only, as in C. |
| `map2check_binop_shl_int` | `void map2check_binop_shl_int(int32_t param1, uint32_t param2, uint32_t line, uint32_t scope, const char *function_name)` | `map2check_binop_shl_int` | same | `int`/`unsigned` (32-bit) only, as in C. |
| `map2check_binop_shr_int` | `void map2check_binop_shr_int(int32_t param1, uint32_t param2, uint32_t line, uint32_t scope, const char *function_name)` | `map2check_binop_shr_int` | same | `int`/`unsigned` (32-bit) only, as in C. |
| `map2check_binop_add_unsigned` | `void map2check_binop_add_unsigned(uint32_t param1, uint32_t param2, uint32_t line, uint32_t scope, const char *function_name)` | `map2check_binop_add_unsigned` | same | `int`/`unsigned` (32-bit) only, as in C. |
| `map2check_binop_sub_unsigned` | `void map2check_binop_sub_unsigned(uint32_t param1, uint32_t param2, uint32_t line, uint32_t scope, const char *function_name)` | `map2check_binop_sub_unsigned` | same | `int`/`unsigned` (32-bit) only, as in C. |
| `map2check_binop_mul_unsigned` | `void map2check_binop_mul_unsigned(uint32_t param1, uint32_t param2, uint32_t line, uint32_t scope, const char *function_name)` | `map2check_binop_mul_unsigned` | same | `int`/`unsigned` (32-bit) only, as in C. |
| `map2check_binop_div_unsigned` | `void map2check_binop_div_unsigned(uint32_t param1, uint32_t param2, uint32_t line, uint32_t scope, const char *function_name)` | `map2check_binop_div_unsigned` | same | `int`/`unsigned` (32-bit) only, as in C. |
| `map2check_binop_shr_unsigned` | `void map2check_binop_shr_unsigned(uint32_t param1, uint32_t param2, uint32_t line, uint32_t scope, const char *function_name)` | `map2check_binop_shr_unsigned` | same | `int`/`unsigned` (32-bit) only, as in C. |
| `map2check_check_load` | `void map2check_check_load(const void *ptr, int32_t line, uint32_t scope, int32_t size, const char *function_name)` | `map2check_check_load` | changed | Address-validity rule rewritten (plan R1; differential check in #15). The first violation is final; a later check never clears or replaces it (SD-03); NULL handling in SD-05. |
| `map2check_check_free` | `void map2check_check_free(const char *_name, const void *ptr, uint32_t _scope, uint32_t line, const char *function_name)` | `map2check_check_free` | same | `_name` and `_scope` are ignored. Untracked address is a violation (SD-06). |
| `map2check_check_free_resolved_address` | `void map2check_check_free_resolved_address(const void *ptr, uint32_t line, const char *function_name, int16_t is_null_valid)` | `analysis_memory.h:46` | same | Semantics in its section; untracked address is a violation (SD-06). |
| `map2check_check_deref` | `void map2check_check_deref(const void *ptr, uint32_t scope, uint32_t line, const char *function_name)` | `map2check_check_deref` | same | Name collides with the pass ABI `map2check_check_deref(i64, ptr)`; see the pass matrix (#21). |
| `map2check_check_mem_endprog` | `void map2check_check_mem_endprog(void)` | `map2check_check_mem_endprog` | changed | Leak algorithm rewritten; no-op until `map2check_set_memcleanup()` (SD-04). |
| `LLVMFuzzerTestOneInput` | `int32_t LLVMFuzzerTestOneInput(const uint8_t *data, uintptr_t size)` | `LLVMFuzzerTestOneInput` | same | Feature `libfuzzer`. Resets the analysis state on every iteration (SD-11). |
| `__VERIFIER_nondet_bool` | `bool __VERIFIER_nondet_bool(void)` | — | new | Feature `libfuzzer`; replaces `map2check_gen_data_fuzzer_*`. |
| `__VERIFIER_nondet_char` | `int8_t __VERIFIER_nondet_char(void)` | — | new | Feature `libfuzzer`; replaces `map2check_gen_data_fuzzer_*`. |
| `__VERIFIER_nondet_uchar` | `uint8_t __VERIFIER_nondet_uchar(void)` | — | new | Feature `libfuzzer`; replaces `map2check_gen_data_fuzzer_*`. |
| `__VERIFIER_nondet_short` | `int16_t __VERIFIER_nondet_short(void)` | — | new | Feature `libfuzzer`; replaces `map2check_gen_data_fuzzer_*`. |
| `__VERIFIER_nondet_ushort` | `uint16_t __VERIFIER_nondet_ushort(void)` | — | new | Feature `libfuzzer`; replaces `map2check_gen_data_fuzzer_*`. |
| `__VERIFIER_nondet_int` | `int32_t __VERIFIER_nondet_int(void)` | — | new | Feature `libfuzzer`; replaces `map2check_gen_data_fuzzer_*`. |
| `__VERIFIER_nondet_uint` | `uint32_t __VERIFIER_nondet_uint(void)` | — | new | Feature `libfuzzer`; replaces `map2check_gen_data_fuzzer_*`. |
| `__VERIFIER_nondet_long` | `int64_t __VERIFIER_nondet_long(void)` | — | new | Feature `libfuzzer`; replaces `map2check_gen_data_fuzzer_*`. |
| `__VERIFIER_nondet_ulong` | `uint64_t __VERIFIER_nondet_ulong(void)` | — | new | Feature `libfuzzer`; replaces `map2check_gen_data_fuzzer_*`. |
| `__VERIFIER_nondet_float` | `float __VERIFIER_nondet_float(void)` | — | new | Feature `libfuzzer`; replaces `map2check_gen_data_fuzzer_*`. |
| `__VERIFIER_nondet_double` | `double __VERIFIER_nondet_double(void)` | — | new | Feature `libfuzzer`; replaces `map2check_gen_data_fuzzer_*`. |
| `__VERIFIER_nondet_size_t` | `uintptr_t __VERIFIER_nondet_size_t(void)` | — | new | Feature `libfuzzer`; replaces `map2check_gen_data_fuzzer_*`. |
| `__VERIFIER_nondet_pointer` | `void *__VERIFIER_nondet_pointer(void)` | — | new | Feature `libfuzzer`; replaces `map2check_gen_data_fuzzer_*`. |
| `__VERIFIER_assume` | `void __VERIFIER_assume(int32_t condition)` | — | new | Feature `libfuzzer`. `__VERIFIER_assume(0)` ends the process with `exit(0)` (SD-07). |
| `map2check_fuzzer_assume` | `void map2check_fuzzer_assume(int32_t condition)` | `map2check_fuzzer_assume(int)` (`nondet_gen_libfuzzer.h:41`) | same | Feature `libfuzzer`. Same `exit(0)` behaviour (SD-07). |
| `__VERIFIER_error` | `void __VERIFIER_error(void)` | — | new | Feature `libfuzzer`. Prints a REACHABILITY report, then aborts (SD-08). |
| `__VERIFIER_assert` | `void __VERIFIER_assert(int32_t condition)` | — | new | Feature `libfuzzer`. `__VERIFIER_assert(0)` calls `__VERIFIER_error()` (SD-08). |
| `next_current_step` | — | `next_current_step()` | discontinued | Use `get_next_step()`; same effect (#13). |
| `map2check_save_memtrack_log` | — | `memtracklog.h:44` | discontinued | Covered by the `map2check_map_*` exports; no external caller. |
| `map2check_gen_data_fuzzer_*` | — | bool, char, uchar, short, ushort, int32_t, int64_t, uint, unsigned, long, ulong, float, double, size_t | discontinued | Replaced by `__VERIFIER_nondet_*` (#12). |
| `map2check_gen_data_fuzzer_pchar` | — | kernel type generator | discontinued | See “Discontinued: pchar / loff_t / sector_t” (#6). |
| `map2check_gen_data_fuzzer_loff_t` | — | kernel type generator | discontinued | See “Discontinued: pchar / loff_t / sector_t” (#6). |
| `map2check_gen_data_fuzzer_sector_t` | — | kernel type generator | discontinued | See “Discontinued: pchar / loff_t / sector_t” (#6). |
| `debug_*_set_only_test` | — | 4 C test hooks | discontinued | C unit-test hooks; Rust tests use `state::test_lock()`. |

## Map2Check pass matrix

Symbols inserted by the passes of `hbgit/Map2Check@develop` (plan
§1.2(b)). The compatibility layer that would export them is #21. Until it
lands, `libmap2check.a` cannot replace the C library embedded in
Map2Check.

| Symbol | Signature expected by the passes | Status | Notes |
|---|---|---|---|
| `map2check_init` | `map2check_init(int)` | changed | Core export takes `void`. |
| `map2check_check_deref` | `map2check_check_deref(i64, ptr)` | changed | Same name, incompatible core signature `(ptr, u32, u32, ptr)`. The plan (§2.1, D1) proposes renaming the core export to `map2check_check_deref_v2` inside the compat layer; decision in #21. |
| `map2check_track_bb` | `(u32, ptr)` | pending | Core equivalent: `map2check_save_basic_block_log` (#21). |
| `map2check_alloca` | `(ptr, ptr, i64, i64, i64, i64)` | pending | Core equivalent: `map2check_map_alloca` with `int32_t` sizes (#21). |
| `map2check_non_static_alloca` | `(ptr, ptr, i64, i64, i64, i64)` | pending | Core equivalent: `map2check_map_non_static_alloca` (#21). |
| `map2check_malloc` | `(ptr, i64)` | pending | Core equivalent: `map2check_map_malloc` (#21). |
| `map2check_calloc` | `(ptr, i64, i64)` | pending | Core equivalent: `map2check_map_calloc` (#21). |
| `map2check_posix` | `(ptr, i64)` | pending | Deprecated in the embedded C library (#21). |
| `map2check_free` | `(ptr, ptr, i64, i64, ptr)` | pending | The pass passes the address of the pointer variable (#21). |
| `map2check_free_resolved_address` | `(ptr, i64, ptr, i1)` | pending | Core equivalent: `map2check_check_free_resolved_address` (#21). |
| `map2check_load` | `(ptr, i64)` | pending | Core `map2check_check_load` takes 5 arguments (#21). |
| `map2check_add_store_pointer` | 6 arguments | pending | Core `map2check_map_store_pointer` differs in order and types (#21). |
| `map2check_function` | `(ptr, ptr)` | pending | Core equivalent: `map2check_map_funct_address` (#21). |
| `map2check_target_function` | — | pending | #21. |
| `map2check_assume` | — | pending | #21. |
| `map2check_assume_loop` | — | pending | #21. |
| `map2check_crab_assume` | — | pending | #21. |
| `map2check_assert` | — | pending | #21. |
| `map2check_non_det_*` | 16 typed generators: bool, char, double, int, loff_t, long, pchar, pointer, sector_t, short, size_t, uchar, uint, ulong, unsigned, ushort | pending | #21; see also #6. |
| `map2check_nondet_cast_*` | — | pending | #21. |
| `map2check_pointer_cast` | — | pending | #21. |
| `map2check_wasm_malloc` | — | out-of-scope | Only used by the `feat-wasm-verification` flow (#21). |
| `map2check_wasm_free` | — | out-of-scope | As above. |
| `map2check_wasm_check_access` | — | out-of-scope | As above. |
| `__VERIFIER_nondet_*` | `int`, `uint`, `char`, `long`, `ushort`, `pointer` | same | Feature `libfuzzer`. |
| `__VERIFIER_assume` | `(int)` | same | Feature `libfuzzer` (SD-07). |
| `__VERIFIER_assert` | `(int)` | same | Feature `libfuzzer` (SD-08). |
| `__VERIFIER_error` | `(void)` | same | Feature `libfuzzer` (SD-08). |

The passes also expect the result channel of the embedded library: files
named `map2check_property_*` that the Map2Check frontend parses. This
library only prints the JSON report on stdout (SD-01). The file channel is
tracked in #19.

## Discontinued: `map2check_gen_data_fuzzer_pchar` / `_loff_t` / `_sector_t`

**Status:** discontinued, not ported to `feature/rust`.

The legacy C library exposed LibFuzzer-backed nondet generators for a few
Linux-kernel/POSIX-specific types (`pchar`, `loff_t`, `sector_t`) alongside
the generic numeric ones. `feature/rust` replaces the whole
`map2check_gen_data_fuzzer_*` family with the SV-COMP-standard
`__VERIFIER_nondet_*` functions (`rust/src/nondet/libfuzzer.rs`), which cover
every portable numeric/bool/pointer type. `pchar`/`loff_t`/`sector_t` have no
portable Rust equivalent (they are kernel ABI types, not part of any target
this library instruments), and no consumer in this repository or in
`Map2Check@develop`'s passes references them. Reintroducing them would mean
adding non-portable, untested surface area for a use case nobody currently
exercises.

**Decision:** do not implement. If a concrete consumer appears, add a
`__VERIFIER_nondet_*`-style generator for the specific width needed instead
of resurrecting the old kernel-typed names.

## Accepted: failure behaviour at the FFI boundary (panic strategy)

Every `#[no_mangle]` export runs its body through `ffi_guard`
(`rust/src/ffi.rs`), enforced by the source-scanning test
`tests/ffi_guard_coverage.rs`.

| Build | Panic strategy | Behaviour on a Rust panic inside an export |
|---|---|---|
| `dev`, `release`, `runtime` | `unwind` | Caught by `catch_unwind` in `ffi_guard`; a diagnostic goes to stderr and the export returns its neutral default. Nothing unwinds into C. |
| any `panic = "abort"` build (future KLEE build) | `abort` | No recovery: the process aborts at the panic. `ffi_guard` is then a no-op wrapper. |

Deliberate termination (`__VERIFIER_error` aborts, `__VERIFIER_assume(0)`
exits with 0) is not a failure and is unaffected. `tests/ffi_harness.c`
calls every export before `map2check_init()` with valid boundary inputs
under ASan/UBSan.

## Accepted: `__VERIFIER_assume` / `map2check_fuzzer_assume` end the process

`__VERIFIER_assume(0)` and `map2check_fuzzer_assume(0)` call
`std::process::exit(0)` instead of unwinding back to the caller. LibFuzzer
runs many inputs within a single process, and the assumption is violated
arbitrarily deep in a call stack that began at `LLVMFuzzerTestOneInput`.
There is no portable way to unwind out of it: the entry point is
`extern "C"`, and a Rust panic must not cross an FFI boundary regardless of
the release profile's panic strategy. This matches the
convention used by SV-COMP's native/concrete-execution harnesses. It does end
the fuzzing campaign for the current process — accepted as a known
limitation; full symbolic-execution semantics (path pruning under KLEE) is
deferred to the M4 KLEE spike. See doc comments in
`rust/src/nondet/libfuzzer.rs`.

## Accepted: `map2check_map_non_static_alloca` / `map2check_map_funct_address` semantics

The legacy C headers that defined these symbols
(`container_memtracklog.h:44,48`) no longer exist in this repository (the
`master` C branch's history was not carried over). Their signatures and exact
semantics were reconstructed from the paridade table and from the existing
`map2check_map_alloca`/`map2check_map_malloc` patterns in
`rust/src/ffi.rs`, not from the original C source:

- `map2check_map_non_static_alloca` — same shape as `map2check_map_alloca`,
  but the resulting entry is marked dynamic (`entry.set_malloc()`), so
  `map2check_check_mem_endprog` accounts for it like a heap allocation
  instead of a plain stack slot.
- `map2check_map_funct_address` — registers a function's address as an
  always-valid load target (pointer-width `size_destiny`), so that reading a
  function pointer through `map2check_check_load`/`map2check_check_deref`
  does not get flagged as an invalid address.

The embedded C library of Map2Check (`lib_old/AnalysisModeMemtrack.c:366-377`
on `origin/refactory_memory_log`) does the opposite for
`map2check_non_static_alloca`: it registers a static slot of
`size * size_of_primitive` bytes, so its `size` is an element count. The
Rust export takes `size` in bytes, like `map2check_map_alloca`, and its
choice makes an unfreed VLA show up as a leak at end of program; see SD-12.

**Risk:** if the M5 compatibility layer (`ffi_compat.rs`, consuming the exact
signatures the Map2Check LLVM passes insert) reveals a different expected
semantics, this section documents the M3 baseline that was changed and why.

## Accepted: `char` ABI is `i8`, not the legacy `u8`

`map2check_save_nondet_log_char` now takes `i8` (matching
`__VERIFIER_nondet_char() -> i8`, already `i8` before this change) instead of
`u8`. C's `char` is platform-defined (signed on x86/x86_64, unsigned by
default on most ARM targets); this crate follows the more common
x86/x86_64 convention and does not special-case ARM. If Map2Check ever
targets a plain-`char`-is-unsigned platform, this will need a
target-specific cfg.

## Discontinued: `next_current_step`

The legacy C library had both `get_next_step()` and `next_current_step()`
for advancing the step counter (plan §1.2(a)). Only `get_next_step()` is
exported (#13): it advances the counter and returns the new value, which
covers both uses. No consumer in this repository or in the Map2Check passes
calls `next_current_step`.

## Accepted: `map2check_check_free_resolved_address` semantics

`map2check_check_free_resolved_address(ptr, line, function_name,
is_null_valid)` receives the heap address itself (after the pointer was
loaded), not the address of the pointer variable that `map2check_check_free`
receives. The Rust export:

- returns without a check when `ptr` is NULL and `is_null_valid != 0`;
- reports `MEMSAFETY_FREE` when the most recent record whose
  `mem_address_points_to` equals `ptr` is already freed;
- reports `MEMSAFETY_FREE` for an address with no heap record (SD-06, #37);
- only checks: it does not mark the block freed. The caller records the
  release with `map2check_map_free`.

The C runtime of Map2Check `develop`
(`modules/backend/library/lib/AnalysisModeMemtrack.c:164-183` and
`ListLog.c:95-118`) agrees on the untracked address since #37, and still
differs in one way: the function also marks the block freed. That keeps the
split between checking and recording that the rest of the core API already
uses.
