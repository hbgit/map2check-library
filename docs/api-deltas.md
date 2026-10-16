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
| `map2check_init` | `void map2check_init(void)` | `map2check_init` | same | Starts a fresh analysis through the `analysis_init` of the selected mode and keeps the options and the mode (#10, SD-14). With a mode set, also removes the `map2check_property*` files left in the current directory (see “Result files”). Map2Check passes call `map2check_init(int)`; see the pass matrix. |
| `map2check_reset` | `void map2check_reset(void)` | — | new | Clears containers, result and step counter (#9). Keeps the options set by `map2check_set_memcleanup()` and `map2check_set_null_is_valid()` and the mode set by `map2check_set_mode()`: they are configuration, not analysis state (#10, SD-14). |
| `map2check_success` | `void map2check_success(void)` | `map2check_success` | same | Prints the JSON report when the mode is unset (SD-01). With a mode set it prints nothing and is develop's `map2check_success`: writes `NONE`, runs the end-of-program verdict, writes the witness files when enabled, and returns; a violating verdict writes its property and aborts (see “Result files”). |
| `set_false_result` | `void set_false_result(int32_t prp, int32_t line_number, const char *function_name)` | `set_false_result` | same | `ViolatedProperty` keeps the C variant order (`caller_lib_result.h:22-31`); the appended `Assert` (8), `Unknown` (9) and `DivByZero` (10) are accepted; unknown values are ignored (SD-09). Ignored when a violation is already recorded (SD-03). |
| `get_current_property` | `enum ViolatedProperty get_current_property(void)` | `get_current_property` | same |  |
| `get_current_step` | `uint64_t get_current_step(void)` | `long get_current_step(void)` | changed | Returns `uint64_t` instead of `long`. |
| `get_next_step` | `uint64_t get_next_step(void)` | `get_next_step()` / `next_current_step()` | same | Advances and returns the step counter. `next_current_step` is not exported; see its row. |
| `print_all_containers_as_json` | `void print_all_containers_as_json(void)` | `print_all_containers_as_json` | changed | Report shape and whitespace differ (SD-01, SD-02). An additional channel with its own schema, pinned by a snapshot test; Map2Check reads the result files instead (#14, see “Result files”). |
| `vcc_reset_meta_data` | `void vcc_reset_meta_data(void)` | `vcc_reset_meta_data` | same | Host/test-only: the Map2Check passes never call it. It clears a recorded violation by design, bypassing the first-violation rule (SD-03). |
| `map2check_set_memcleanup` | `void map2check_set_memcleanup(void)` | `map2check_set_memcleanup` | same | Selects `MEMSAFETY_MEMCLEANUP` instead of `MEMSAFETY_MEMTRACK` for the end-of-program leak (SD-04): an alias of the memcleanup mode for the leak tag, in every mode that checks leaks (SD-14). Kept by `map2check_init()` and `map2check_reset()`. |
| `map2check_set_null_is_valid` | `void map2check_set_null_is_valid(void)` | `map2check_set_null_is_valid` | same | Makes a NULL load safe (SD-05). Kept by `map2check_init()` and `map2check_reset()`. |
| `map2check_enable_witness` | `void map2check_enable_witness(void)` | — | new | Turns on witness generation, the run-time counterpart of develop linking `WitnessGeneration.c` instead of `WitnessGenerationNone.c` (`caller.cpp:624-640`). A Map2Check run (mode set) then also writes `track_bb_log.st`, the memory logs and, on a violation, `klee_log.csv` and `map2check_checked_error`. Kept by `map2check_init()` and `map2check_reset()`. The frontend links a constructor that calls it into witness binaries. See “Result files”. |
| `map2check_set_mode` | `void map2check_set_mode(int32_t mode)` | — | new | Selects the analysis mode at run time; `mode` is one of the `enum AnalysisMode` values the header declares (`AnalysisMode_None` 0, `_Memtrack` 1, `_Memcleanup` 2, `_Overflow` 3, `_Assert` 4, `_Target` 5). Develop selects it at link time. Called before `map2check_init()`; kept by `map2check_init()` and `map2check_reset()`. Never called: mode unset, every check active. Any other value is ignored with a diagnostic on stderr and leaves the mode unchanged. See “Analysis modes” (SD-14). |
| `map2check_reach_target` | `void map2check_reach_target(const char *func, int32_t scope, int32_t line)` | — | new | Replaces the pass symbol `map2check_target_function`. Records `REACHABILITY` (develop `TARGET-REACHED`) at `line` in `func`, in every mode; `scope` is ignored. With a mode set, ends the run like any first violation; unset, it returns (SD-15). |
| `map2check_save_nondet_log_int` | `non_det_log_t *map2check_save_nondet_log_int(int line, int scope, enum var_type_t type_var, int *value, const char *function_name)` | returns `non_det_log_t *` | same | Returned record is not linked into a list (SD-10). |
| `map2check_save_nondet_log_uint` | `non_det_log_t *map2check_save_nondet_log_uint(int line, int scope, enum var_type_t type_var, unsigned int *value, const char *function_name)` | returns `non_det_log_t *` | same | Returned record is not linked into a list (SD-10). |
| `map2check_save_nondet_log_long` | `non_det_log_t *map2check_save_nondet_log_long(int line, int scope, enum var_type_t type_var, long *value, const char *function_name)` | returns `non_det_log_t *` | same | Returned record is not linked into a list (SD-10). |
| `map2check_save_nondet_log_float` | `non_det_log_t *map2check_save_nondet_log_float(int line, int scope, enum var_type_t type_var, float *value, const char *function_name)` | returns `non_det_log_t *` | same | Returned record is not linked into a list (SD-10). |
| `map2check_save_nondet_log_double` | `non_det_log_t *map2check_save_nondet_log_double(int line, int scope, enum var_type_t type_var, double *value, const char *function_name)` | returns `non_det_log_t *` | same | Returned record is not linked into a list (SD-10). |
| `map2check_save_nondet_log_char` | `non_det_log_t *map2check_save_nondet_log_char(int line, int scope, enum var_type_t type_var, char *value, const char *function_name)` | returns `non_det_log_t *`; `char` value | same | `char` is `i8` on the Rust side; see “`char` ABI”. Returned record is not linked (SD-10). |
| `map2check_save_nondet_log_unsigned` | `non_det_log_t *map2check_save_nondet_log_unsigned(int line, int scope, int type_var, unsigned int *value, const char *function_name)` | — | new | Develop `map2check_nondet_unsigned` (`NonDetLog.c:105-150`), called by the pass with the value stored in an `alloca` of its C type (#6, #13). Row type UNSIGNED (5), value printed with `%u`; see “Nondet generators and the nondet log”. `type_var` is only kept in the returned record. Returned record is not linked (SD-10). |
| `map2check_save_nondet_log_ulong` | `non_det_log_t *map2check_save_nondet_log_ulong(int line, int scope, int type_var, unsigned long *value, const char *function_name)` | — | new | Develop `map2check_nondet_ulong` (`NonDetLog.c:105-150`), called by the pass with the value stored in an `alloca` of its C type (#6, #13). Row type ULONG (6), low 32 bits with `%d`; see “Nondet generators and the nondet log”. `type_var` is only kept in the returned record. Returned record is not linked (SD-10). |
| `map2check_save_nondet_log_uchar` | `non_det_log_t *map2check_save_nondet_log_uchar(int line, int scope, int type_var, unsigned char *value, const char *function_name)` | — | new | Develop `map2check_nondet_uchar` (`NonDetLog.c:105-150`), called by the pass with the value stored in an `alloca` of its C type (#6, #13). Row type UCHAR (8), value zero-extended; see “Nondet generators and the nondet log”. `type_var` is only kept in the returned record. Returned record is not linked (SD-10). |
| `map2check_save_nondet_log_short` | `non_det_log_t *map2check_save_nondet_log_short(int line, int scope, int type_var, short *value, const char *function_name)` | — | new | Develop `map2check_nondet_short` (`NonDetLog.c:105-150`), called by the pass with the value stored in an `alloca` of its C type (#6, #13). Row type SHORT (14), value zero-extended as the pass does (`-2` is logged as `65534`); see “Nondet generators and the nondet log”. `type_var` is only kept in the returned record. Returned record is not linked (SD-10). |
| `map2check_save_nondet_log_ushort` | `non_det_log_t *map2check_save_nondet_log_ushort(int line, int scope, int type_var, unsigned short *value, const char *function_name)` | — | new | Develop `map2check_nondet_ushort` (`NonDetLog.c:105-150`), called by the pass with the value stored in an `alloca` of its C type (#6, #13). Row type USHORT (3), value zero-extended; see “Nondet generators and the nondet log”. `type_var` is only kept in the returned record. Returned record is not linked (SD-10). |
| `map2check_save_nondet_log_bool` | `non_det_log_t *map2check_save_nondet_log_bool(int line, int scope, int type_var, int *value, const char *function_name)` | — | new | Develop `map2check_nondet_bool` (`NonDetLog.c:105-150`), called by the pass with the value stored in an `alloca` of its C type (#6, #13). Row type BOOL (7); develop's `bool` is `typedef int bool` (`NonDetGenerator.h:74`), so the pass widens the `_Bool` to `int` before storing it; see “Nondet generators and the nondet log”. `type_var` is only kept in the returned record. Returned record is not linked (SD-10). |
| `map2check_save_nondet_log_size_t` | `non_det_log_t *map2check_save_nondet_log_size_t(int line, int scope, int type_var, size_t *value, const char *function_name)` | — | new | Develop `map2check_nondet_size_t` (`NonDetLog.c:105-150`), called by the pass with the value stored in an `alloca` of its C type (#6, #13). Row type SIZE_T (10), low 32 bits with `%d`; see “Nondet generators and the nondet log”. `type_var` is only kept in the returned record. Returned record is not linked (SD-10). |
| `map2check_save_nondet_log_loff_t` | `non_det_log_t *map2check_save_nondet_log_loff_t(int line, int scope, int type_var, long long *value, const char *function_name)` | — | new | Develop `map2check_nondet_loff_t` (`NonDetLog.c:105-150`), called by the pass with the value stored in an `alloca` of its C type (#6, #13). Row type LOFF_T (11); `loff_t` is glibc's `long long`; low 32 bits with `%d`; see “Nondet generators and the nondet log”. `type_var` is only kept in the returned record. Returned record is not linked (SD-10). |
| `map2check_save_nondet_log_sector_t` | `non_det_log_t *map2check_save_nondet_log_sector_t(int line, int scope, int type_var, unsigned long *value, const char *function_name)` | — | new | Develop `map2check_nondet_sector_t` (`NonDetLog.c:105-150`), called by the pass with the value stored in an `alloca` of its C type (#6, #13). Row type SECTOR_T (12); `sector_t` is `unsigned long` (`NonDetGenerator.h:112`); low 32 bits with `%d`; see “Nondet generators and the nondet log”. `type_var` is only kept in the returned record. Returned record is not linked (SD-10). |
| `map2check_save_nondet_log_pointer` | `non_det_log_t *map2check_save_nondet_log_pointer(int line, int scope, int type_var, void **value, const char *function_name)` | — | new | Develop `map2check_nondet_pointer` (`NonDetLog.c:105-150`), called by the pass with the value stored in an `alloca` of its C type (#6, #13). Row type POINTER (2); the address, logged as its low 32 bits (the pass's `ptrtoint` to `i32`); see “Nondet generators and the nondet log”. `type_var` is only kept in the returned record. Returned record is not linked (SD-10). |
| `map2check_save_nondet_log_pchar` | `non_det_log_t *map2check_save_nondet_log_pchar(int line, int scope, int type_var, char **value, const char *function_name)` | — | new | Develop `map2check_nondet_pchar` (`NonDetLog.c:105-150`), called by the pass with the value stored in an `alloca` of its C type (#6, #13). Row type PCHAR (9); the string's address, logged as its low 32 bits; see “Nondet generators and the nondet log”. `type_var` is only kept in the returned record. Returned record is not linked (SD-10). |
| `map2check_save_basic_block_log` | `bbtrack_log_t *map2check_save_basic_block_log(int32_t line, const char *function_name)` | returns `bbtrack_log_t *` | same | Returned record is not linked into a list (SD-10). |
| `map2check_is_in_trackbb_container` | `int32_t map2check_is_in_trackbb_container(int32_t line)` | `map2check_is_in_trackbb_container` | same |  |
| `map2check_map_alloca` | `void map2check_map_alloca(const char *var_name, const void *ptr_address, int32_t size, int32_t size_primitive, int32_t line_number, int32_t scope)` | `container_memtracklog.h:41` | same |  |
| `map2check_map_non_static_alloca` | `void map2check_map_non_static_alloca(const char *var_name, const void *ptr_address, int32_t size, int32_t size_primitive, int32_t line_number, int32_t scope)` | `container_memtracklog.h:44` | same | `size` is an element count; static slot of `size * size_primitive` bytes, never a leak (SD-12, #38). |
| `map2check_map_funct_address` | `void map2check_map_funct_address(const char *var_name, const void *ptr_address)` | `container_memtracklog.h:48` | same | Signature and semantics reconstructed; see its section. |
| `map2check_map_malloc` | `void map2check_map_malloc(const void *ptr_address, int32_t size)` | `map2check_map_malloc` | same | Negative sizes are ignored (SD-09). |
| `map2check_map_calloc` | `void map2check_map_calloc(const void *ptr_address, int32_t quantity, int32_t size)` | `map2check_map_calloc` | same | Negative sizes are ignored (SD-09). |
| `map2check_map_posix_memalign` | `void map2check_map_posix_memalign(const void *ptr_address, int32_t size)` | `map2check_posix` (develop) | new | `ptr_address` is posix_memalign's `memptr` (`void **`): reads the block from it, records it as `map2check_map_malloc`, then the store of the block into `*ptr_address` with scope 1, line 1, name `pointer`, function `cocoiso`, as develop's `map2check_posix` (`AnalysisModeMemtrack.c:327-333`); golden `POSIX-MEMALIGN`. NULL `ptr_address` ignored (SD-09); NULL block: as `map2check_map_malloc`, and no store. |
| `map2check_map_free` | `void map2check_map_free(const char *var_name, const void *var_address, const void *ptr_address, uint32_t scope, uint32_t line_number, const char *function_name)` | `map2check_map_free` | changed | Task 2.5: gains `var_address`, the address of the pointer variable freed (the slot develop's `map2check_free` receives); `ptr_address` stays the block, which the release is keyed on. The slot only names the variable in the FREE row of `list_log.csv` (`AnalysisModeMemtrack.c:339-347`). |
| `map2check_map_store_pointer` | `void map2check_map_store_pointer(const void *var_address, const void *value, uint32_t scope, const char *var_name, int32_t line_number, const char *funct_name)` | `map2check_map_store_pointer` | same |  |
| `map2check_is_valid_assert` | `void map2check_is_valid_assert(int32_t line_number, const char *function_name, int32_t expression)` | `map2check_is_valid_assert` | changed | A failed assertion reports `ASSERT` (before Task 2.3: `REACHABILITY`) and, with the mode unset, prints the JSON report; with a mode set it ends the run (“Result files”) and prints nothing. Active in unset and assert modes only (SD-14). |
| `map2check_binop_add_int` | `void map2check_binop_add_int(int32_t param1, int32_t param2, uint32_t line, uint32_t scope, const char *function_name)` | `map2check_binop_add_int` | same | `int`/`unsigned` (32-bit) only, as in C. Active in unset and overflow modes only (SD-14). |
| `map2check_binop_sub_int` | `void map2check_binop_sub_int(int32_t param1, int32_t param2, uint32_t line, uint32_t scope, const char *function_name)` | `map2check_binop_sub_int` | same | `int`/`unsigned` (32-bit) only, as in C. Active in unset and overflow modes only (SD-14). |
| `map2check_binop_mul_int` | `void map2check_binop_mul_int(int32_t param1, int32_t param2, uint32_t line, uint32_t scope, const char *function_name)` | `map2check_binop_mul_int` | same | `int`/`unsigned` (32-bit) only, as in C. Active in unset and overflow modes only (SD-14). |
| `map2check_binop_div_int` | `void map2check_binop_div_int(int32_t param1, int32_t param2, uint32_t line, uint32_t scope, const char *function_name)` | `map2check_binop_div_int` | same | `int`/`unsigned` (32-bit) only, as in C. Active in unset and overflow modes only (SD-14). |
| `map2check_binop_neg_int` | `void map2check_binop_neg_int(int32_t param1, int32_t _param2, uint32_t line, uint32_t scope, const char *function_name)` | `map2check_binop_neg_int` | same | `int`/`unsigned` (32-bit) only, as in C. Active in unset and overflow modes only (SD-14). |
| `map2check_binop_shl_int` | `void map2check_binop_shl_int(int32_t param1, uint32_t param2, uint32_t line, uint32_t scope, const char *function_name)` | `map2check_binop_shl_int` | same | `int`/`unsigned` (32-bit) only, as in C. Active in unset and overflow modes only (SD-14). |
| `map2check_binop_shr_int` | `void map2check_binop_shr_int(int32_t param1, uint32_t param2, uint32_t line, uint32_t scope, const char *function_name)` | `map2check_binop_shr_int` | same | `int`/`unsigned` (32-bit) only, as in C. Active in unset and overflow modes only (SD-14). |
| `map2check_binop_add_unsigned` | `void map2check_binop_add_unsigned(uint32_t param1, uint32_t param2, uint32_t line, uint32_t scope, const char *function_name)` | `map2check_binop_add_unsigned` | same | `int`/`unsigned` (32-bit) only, as in C. Active in unset and overflow modes only (SD-14). |
| `map2check_binop_sub_unsigned` | `void map2check_binop_sub_unsigned(uint32_t param1, uint32_t param2, uint32_t line, uint32_t scope, const char *function_name)` | `map2check_binop_sub_unsigned` | same | `int`/`unsigned` (32-bit) only, as in C. Active in unset and overflow modes only (SD-14). |
| `map2check_binop_mul_unsigned` | `void map2check_binop_mul_unsigned(uint32_t param1, uint32_t param2, uint32_t line, uint32_t scope, const char *function_name)` | `map2check_binop_mul_unsigned` | same | `int`/`unsigned` (32-bit) only, as in C. Active in unset and overflow modes only (SD-14). |
| `map2check_binop_div_unsigned` | `void map2check_binop_div_unsigned(uint32_t param1, uint32_t param2, uint32_t line, uint32_t scope, const char *function_name)` | `map2check_binop_div_unsigned` | same | `int`/`unsigned` (32-bit) only, as in C. Active in unset and overflow modes only (SD-14). |
| `map2check_binop_shr_unsigned` | `void map2check_binop_shr_unsigned(uint32_t param1, uint32_t param2, uint32_t line, uint32_t scope, const char *function_name)` | `map2check_binop_shr_unsigned` | same | `int`/`unsigned` (32-bit) only, as in C. Active in unset and overflow modes only (SD-14). |
| `map2check_binop_add_signed` | `void map2check_binop_add_signed(int64_t a, int64_t b, uint32_t bits, uint32_t line, const char *function_name)` | `map2check_binop_add` (develop) | changed | Operands sign-extended to 64 bits, `bits` the width of the result type (0 or above 64 means 64), as the pass sends them; reports `OVERFLOW` when the exact sum leaves the range of `bits` (`AnalysisModeOverflow.c:110-276`). No `scope` argument. Records and continues with the mode unset; ends the run with a mode set (SD-03). Active in unset and overflow modes only (SD-14). |
| `map2check_binop_sub_signed` | `void map2check_binop_sub_signed(int64_t a, int64_t b, uint32_t bits, uint32_t line, const char *function_name)` | `map2check_binop_sub` (develop) | changed | Operands sign-extended to 64 bits, `bits` the width of the result type (0 or above 64 means 64), as the pass sends them; reports `OVERFLOW` when the exact difference leaves the range of `bits` (`AnalysisModeOverflow.c:110-276`). No `scope` argument. Records and continues with the mode unset; ends the run with a mode set (SD-03). Active in unset and overflow modes only (SD-14). |
| `map2check_binop_mul_signed` | `void map2check_binop_mul_signed(int64_t a, int64_t b, uint32_t bits, uint32_t line, const char *function_name)` | `map2check_binop_mul` (develop) | changed | Operands sign-extended to 64 bits, `bits` the width of the result type (0 or above 64 means 64), as the pass sends them; reports `OVERFLOW` when the exact product leaves the range of `bits` (`AnalysisModeOverflow.c:110-276`). No `scope` argument. Records and continues with the mode unset; ends the run with a mode set (SD-03). Active in unset and overflow modes only (SD-14). |
| `map2check_binop_div_signed` | `void map2check_binop_div_signed(int64_t a, int64_t b, uint32_t bits, uint32_t line, const char *function_name)` | `map2check_binop_sdiv` (develop) | changed | Operands sign-extended to 64 bits, `bits` the width of the result type (0 or above 64 means 64), as the pass sends them; reports `DIVBYZERO` (`ViolatedProperty` 10, develop `FALSE-DIVBYZERO`) when `b` is 0, `OVERFLOW` for MIN / -1 of `bits` (`AnalysisModeOverflow.c:110-276`). No `scope` argument. Records and continues with the mode unset; ends the run with a mode set (SD-03). Active in unset and overflow modes only (SD-14). |
| `map2check_binop_rem_signed` | `void map2check_binop_rem_signed(int64_t a, int64_t b, uint32_t bits, uint32_t line, const char *function_name)` | `map2check_binop_srem` (develop) | changed | Operands sign-extended to 64 bits, `bits` the width of the result type (0 or above 64 means 64), as the pass sends them; reports `DIVBYZERO` when `b` is 0, `OVERFLOW` for MIN % -1 of `bits` (`AnalysisModeOverflow.c:110-276`). No `scope` argument. Records and continues with the mode unset; ends the run with a mode set (SD-03). Active in unset and overflow modes only (SD-14). |
| `map2check_check_load` | `void map2check_check_load(const void *ptr, int32_t line, uint32_t scope, int32_t size, const char *function_name)` | `map2check_check_load` | changed | Address-validity rule rewritten (plan R1; differential check in #15); since #11 a heap block is valid only while its latest alloc/free event is an allocation, as in `develop` (`AllocationLog.c:127-148`). The first violation is final; a later check never clears or replaces it (SD-03); NULL handling in SD-05. Active in unset and memtrack modes only (SD-14). |
| `map2check_check_free` | `void map2check_check_free(const char *name, const void *var_address, const void *ptr, uint32_t scope, uint32_t line, const char *function_name)` | `map2check_check_free` | changed | Task 2.5: same arguments as `map2check_map_free` (gains `var_address`; `name` and `scope` are now used): on a first violation it keeps the FREE row develop's `map2check_free` appends to `list_log.csv` before it fails (`AnalysisModeMemtrack.c:346-358`). The check itself is unchanged and keyed on `ptr`. Untracked address is a violation (SD-06). Active in unset and memtrack modes only (SD-14). |
| `map2check_check_free_resolved_address` | `void map2check_check_free_resolved_address(const void *ptr, uint32_t line, const char *function_name, int16_t is_null_valid)` | `analysis_memory.h:46` | same | Semantics in its section; records the release when the check passes, unlike `map2check_check_free`; untracked address is a violation (SD-06); see also SD-13. The check is active in unset and memtrack modes only; when inactive the release is still recorded (SD-14). |
| `map2check_check_deref` | `void map2check_check_deref(const void *ptr, uint32_t scope, uint32_t line, const char *function_name)` | `map2check_check_deref` | same | Name collides with the pass ABI `map2check_check_deref(i64, ptr)`; see the pass matrix (#21). Active in unset and memtrack modes only (SD-14). |
| `map2check_check_mem_endprog` | `void map2check_check_mem_endprog(void)` | `map2check_check_mem_endprog` | changed | Leak algorithm rewritten. Runs `analysis_is_program_correct` of the mode: unset and memtrack report memtrack or memcleanup by option, memcleanup mode reports memcleanup only for a still-referenced last leak, the other modes nothing (SD-04, SD-14). |
| `LLVMFuzzerTestOneInput` | `int32_t LLVMFuzzerTestOneInput(const uint8_t *data, uintptr_t size)` | `LLVMFuzzerTestOneInput` | same | Feature `libfuzzer`. Resets the analysis state on every iteration (SD-11). |
| `__VERIFIER_nondet_bool` | `bool __VERIFIER_nondet_bool(void)` | — | new | Feature `libfuzzer`; replaces `map2check_gen_data_fuzzer_*`. Reads four bytes, develop's `typedef int bool`, and returns that `int != 0` (SD-18). |
| `__VERIFIER_nondet_char` | `int8_t __VERIFIER_nondet_char(void)` | — | new | Feature `libfuzzer`; replaces `map2check_gen_data_fuzzer_*`. Reads `sizeof` bytes like develop's AFL++ generator, rewinding at the end of the input (SD-18). |
| `__VERIFIER_nondet_uchar` | `uint8_t __VERIFIER_nondet_uchar(void)` | — | new | Feature `libfuzzer`; replaces `map2check_gen_data_fuzzer_*`. Reads `sizeof` bytes like develop's AFL++ generator, rewinding at the end of the input (SD-18). |
| `__VERIFIER_nondet_short` | `int16_t __VERIFIER_nondet_short(void)` | — | new | Feature `libfuzzer`; replaces `map2check_gen_data_fuzzer_*`. Reads `sizeof` bytes like develop's AFL++ generator, rewinding at the end of the input (SD-18). |
| `__VERIFIER_nondet_ushort` | `uint16_t __VERIFIER_nondet_ushort(void)` | — | new | Feature `libfuzzer`; replaces `map2check_gen_data_fuzzer_*`. Reads `sizeof` bytes like develop's AFL++ generator, rewinding at the end of the input (SD-18). |
| `__VERIFIER_nondet_int` | `int32_t __VERIFIER_nondet_int(void)` | — | new | Feature `libfuzzer`; replaces `map2check_gen_data_fuzzer_*`. Reads `sizeof` bytes like develop's AFL++ generator, rewinding at the end of the input (SD-18). |
| `__VERIFIER_nondet_uint` | `uint32_t __VERIFIER_nondet_uint(void)` | — | new | Feature `libfuzzer`; replaces `map2check_gen_data_fuzzer_*`. Reads `sizeof` bytes like develop's AFL++ generator, rewinding at the end of the input (SD-18). |
| `__VERIFIER_nondet_long` | `int64_t __VERIFIER_nondet_long(void)` | — | new | Feature `libfuzzer`; replaces `map2check_gen_data_fuzzer_*`. Reads `sizeof` bytes like develop's AFL++ generator, rewinding at the end of the input (SD-18). |
| `__VERIFIER_nondet_ulong` | `uint64_t __VERIFIER_nondet_ulong(void)` | — | new | Feature `libfuzzer`; replaces `map2check_gen_data_fuzzer_*`. Reads `sizeof` bytes like develop's AFL++ generator, rewinding at the end of the input (SD-18). |
| `__VERIFIER_nondet_float` | `float __VERIFIER_nondet_float(void)` | — | new | Feature `libfuzzer`; replaces `map2check_gen_data_fuzzer_*`. Reads four bytes; develop has no `float` generator (SD-18). |
| `__VERIFIER_nondet_double` | `double __VERIFIER_nondet_double(void)` | — | new | Feature `libfuzzer`; replaces `map2check_gen_data_fuzzer_*`. Reads `sizeof` bytes like develop's AFL++ generator, rewinding at the end of the input (SD-18). |
| `__VERIFIER_nondet_size_t` | `uintptr_t __VERIFIER_nondet_size_t(void)` | — | new | Feature `libfuzzer`; replaces `map2check_gen_data_fuzzer_*`. Reads `sizeof` bytes like develop's AFL++ generator, rewinding at the end of the input (SD-18). |
| `__VERIFIER_nondet_pointer` | `void *__VERIFIER_nondet_pointer(void)` | — | new | Feature `libfuzzer`; replaces `map2check_gen_data_fuzzer_*`. Reads `sizeof` bytes like develop's AFL++ generator, rewinding at the end of the input (SD-18). |
| `__VERIFIER_nondet_loff_t` | `int64_t __VERIFIER_nondet_loff_t(void)` | `map2check_gen_data_fuzzer_loff_t` | new | Feature `libfuzzer`. Core target of the pass's `map2check_non_det_loff_t` (#6); `loff_t` is glibc's `long long`, eight bytes (SD-18). |
| `__VERIFIER_nondet_sector_t` | `unsigned long __VERIFIER_nondet_sector_t(void)` | `map2check_gen_data_fuzzer_sector_t` | new | Feature `libfuzzer`. Core target of `map2check_non_det_sector_t` (#6); develop's `sector_t` is `unsigned long` (`NonDetGenerator.h:112`), eight bytes (SD-18). |
| `__VERIFIER_nondet_pchar` | `char *__VERIFIER_nondet_pchar(void)` | `map2check_gen_data_fuzzer_pchar` | new | Feature `libfuzzer`. Core target of `map2check_non_det_pchar` (#6). An `unsigned` length, NULL for 0, capped at 4096, then `length - 1` chars and a NUL, as `NonDetGeneratorAFL.c:101-118`; the string comes from the C `malloc` and the program may `free` it (SD-18). |
| `__VERIFIER_assume` | `void __VERIFIER_assume(int32_t condition)` | — | new | Feature `libfuzzer`. `__VERIFIER_assume(0)` abandons the current fuzzer input and `LLVMFuzzerTestOneInput` returns 0, as develop's `nondet_cancel`; with no iteration running it calls `exit(0)` (SD-07). Defined `extern "C-unwind"`; see “`__VERIFIER_assume` under a fuzzer”. |
| `map2check_fuzzer_assume` | `void map2check_fuzzer_assume(int32_t condition)` | `map2check_fuzzer_assume(int)` (`nondet_gen_libfuzzer.h:41`) | changed | Feature `libfuzzer`. Same behaviour as `__VERIFIER_assume` (SD-07). |
| `__VERIFIER_error` | `void __VERIFIER_error(void)` | — | new | Feature `libfuzzer`. Records REACHABILITY, prints the JSON report when the mode is unset, then aborts (SD-08). |
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
| `map2check_init` | `map2check_init(int)` | changed | Core export takes `void`; the mode the frontend chose at link time comes from `map2check_set_mode()` (Task 2.3, SD-14). |
| `map2check_check_deref` | `map2check_check_deref(i64, ptr)` | changed | Same name, incompatible core signature `(ptr, u32, u32, ptr)`. The plan (§2.1, D1) proposes renaming the core export to `map2check_check_deref_v2` inside the compat layer; decision in #21. |
| `map2check_track_bb` | `(u32, ptr)` | pending | Core equivalent: `map2check_save_basic_block_log` (#21). |
| `map2check_alloca` | `(ptr, ptr, i64, i64, i64, i64)` | pending | Core equivalent: `map2check_map_alloca` with `int32_t` sizes (#21). |
| `map2check_non_static_alloca` | `(ptr, ptr, i64, i64, i64, i64)` | pending | Core equivalent: `map2check_map_non_static_alloca` (#21). |
| `map2check_malloc` | `(ptr, i64)` | pending | Core equivalent: `map2check_map_malloc` (#21). |
| `map2check_calloc` | `(ptr, i64, i64)` | pending | Core equivalent: `map2check_map_calloc` (#21). |
| `map2check_posix` | `(ptr, i64)` | pending | Core equivalent: `map2check_map_posix_memalign(ptr, int32_t)`; the pass narrows the size (`coerceToParamType`) and switches to it in Task 3.2. |
| `map2check_free` | `(ptr, ptr, i64, i64, ptr)` | pending | Core equivalent: `map2check_check_free` then `map2check_map_free`, both `(name, var_slot, *var_slot, scope, line, fn)`; the pass loads the block and skips both calls for NULL (Task 3.2). |
| `map2check_free_resolved_address` | `(ptr, i64, ptr, i1)` | pending | Core equivalent: `map2check_check_free_resolved_address` (#21). |
| `map2check_load` | `(ptr, i64)` | pending | Core `map2check_check_load` takes 5 arguments (#21). |
| `map2check_add_store_pointer` | 6 arguments | pending | Core `map2check_map_store_pointer` differs in order and types (#21). |
| `map2check_function` | `(ptr, ptr)` | pending | Core equivalent: `map2check_map_funct_address` (#21). |
| `map2check_target_function` | `(ptr, i32, i32)` | pending | Core equivalent: `map2check_reach_target`, same arguments; with a mode set it ends the run as develop does, unset it records and returns (SD-15). The pass switches to it later in the cutover. |
| `map2check_assume` | — | pending | #21. |
| `map2check_assume_loop` | — | pending | #21. |
| `map2check_crab_assume` | — | pending | #21. |
| `map2check_assert` | — | pending | #21. |
| `map2check_non_det_*` | 16 typed generators: bool, char, double, int, loff_t, long, pchar, pointer, sector_t, short, size_t, uchar, uint, ulong, unsigned, ushort | pending | Core equivalents: `__VERIFIER_nondet_<t>` for every type (`unsigned` → `__VERIFIER_nondet_uint`), reading the input as develop's AFL++ generator (#6, SD-18). The pass stops renaming the call in Task 3.2. |
| `map2check_nondet_*` | `(u32 line, u32 scope, i32 value, ptr fn)`, `double` value for `double` | pending | Core equivalents: `map2check_save_nondet_log_<t>(line, scope, type_var, T *value, fn)` for every type; the pass stores the value in an `alloca` and passes its address (Task 3.2). See “Nondet generators and the nondet log”. |
| `map2check_nondet_cast_*` | — | pending | #21. |
| `map2check_pointer_cast` | — | pending | #21. |
| `map2check_wasm_malloc` | — | out-of-scope | Only used by the `feat-wasm-verification` flow (#21). |
| `map2check_wasm_free` | — | out-of-scope | As above. |
| `map2check_wasm_check_access` | — | out-of-scope | As above. |
| `__VERIFIER_nondet_*` | `int`, `uint`, `char`, `long`, `ushort`, `pointer` | same | Feature `libfuzzer`. |
| `__VERIFIER_assume` | `(int)` | same | Feature `libfuzzer` (SD-07). |
| `__VERIFIER_assert` | `(int)` | same | Feature `libfuzzer` (SD-08). |
| `__VERIFIER_error` | `(void)` | same | Feature `libfuzzer` (SD-08). |

The passes also expect the result channel of the embedded library: the
files that the Map2Check frontend parses. This library writes them when a
mode is set (#19); see “Result files”.

## Analysis modes

`map2check_set_mode()` replaces the link-time choice of
`AnalysisMode*.c` in the Map2Check frontend (`caller.cpp:575-612`). The
per-mode `match` is in `rust/src/analysismode/mode.rs`. Tracking calls
(`map2check_map_*`, nondet and basic-block logs) record in every mode.

| Mode | Frontend mode | Checks that report | End of program (`map2check_check_mem_endprog`) |
|---|---|---|---|
| unset (`map2check_set_mode` never called) | — | all | leak → `MEMSAFETY_MEMTRACK`, or `MEMSAFETY_MEMCLEANUP` with the option |
| `AnalysisMode_None` (0) | `COVER_BRANCHES_MODE` | none | nothing |
| `AnalysisMode_Memtrack` (1) | `MEMTRACK_MODE` | load, deref, free, free resolved | any live heap block (reachable or not) → `MEMSAFETY_MEMTRACK`, or `MEMSAFETY_MEMCLEANUP` with the option |
| `AnalysisMode_Memcleanup` (2) | `MEMCLEANUP_MODE` | none (free resolved still records the release) | `MEMSAFETY_MEMCLEANUP` only when the last leaked block is still referenced by a pointer variable, as in develop; an unreachable leak gives no verdict |
| `AnalysisMode_Overflow` (3) | `OVERFLOW_MODE` | `map2check_binop_*` | nothing |
| `AnalysisMode_Assert` (4) | `ASSERT_MODE` | `map2check_is_valid_assert` (`ASSERT`) | nothing |
| `AnalysisMode_Target` (5) | `REACHABILITY_MODE` | none | nothing |

The memcleanup option only changes the tag of the unset/memtrack leak
verdict; it does not apply the memcleanup-mode reachability rule.
`map2check_reach_target` and `set_false_result` record in every mode.
`ViolatedProperty` gained `Assert` (8), `Unknown` (9) and `DivByZero` (10),
appended after `None`; `Reachability` is the target-reached property.

## Result files

The Map2Check frontend does not read JSON. It reads the files that the
runtime writes into the current directory and learns of a violation from
the process aborting (`modules/frontend/utils/tools.cpp`, `caller.cpp`,
`counter_example/`). That file channel is the result channel Map2Check
consumes. The JSON report of `print_all_containers_as_json()`,
`map2check_success()`, a failing `map2check_is_valid_assert()` and
`__VERIFIER_error()` is an additional channel with its own schema (SD-01),
pinned by `rust/src/output/mod.rs::json_report_snapshot` (#14). It is
printed only when the mode is unset: with a mode set no export writes to
stdout, as in develop, so the analysed program's output stays clean. The
report is serialised under the state lock and printed after the lock is
released, and a stdout error is only reported on stderr, so stdout can
never change a verdict.

The channel is tied to the mode. When `map2check_set_mode()` was called
(a Map2Check-instrumented program):

- `map2check_init()` removes stale `map2check_property*` files;
- the first violation writes the property files, then, with witness on,
  the witness files, runs the mode's `analysis_destroy`, writes
  `map2check_checked_error` (witness on) and calls `abort()`, as develop's
  `map2check_error` → `map2check_exit` (`Map2CheckFunctions.c:72-102`);
- `map2check_success()` writes `NONE`, runs the end-of-program verdict
  and, if it holds, writes the witness files (witness on) and returns;
  otherwise it ends the run as a violation;
- if the analysis state cannot be read at the end (its lock was poisoned
  by an earlier panic), the verdict is unknown: the property files already
  written are removed, `map2check_property__unknown` is written (plus
  `map2check_checked_error` with witness on) and the process aborts, as
  develop's UNKNOWN path does.

When the mode is unset (direct API users, `tests/ffi_harness.c`) nothing
is written and nothing ends the process: violations are only recorded.
In memtrack and memcleanup modes `map2check_map_malloc` and
`map2check_map_calloc` with a NULL block report `UNKNOWN`, as develop's
`map2check_malloc` does.

| File | Develop writer | Rust writer (`rust/src/output/`) | When |
|---|---|---|---|
| `map2check_property` | `PropertyGenerator.c:50-106` | `legacy_files::write_property_files` | mode set: on the first violation (every property but `UNKNOWN`; `DIVBYZERO` writes `FALSE-DIVBYZERO` here only, as `:98-102`) and `NONE` on `map2check_success` |
| `map2check_property_{free,deref,overflow,assert,memtrack,memcleanup}` | `PropertyGenerator.c:24-48`, `:108-130` | `legacy_files::write_property_files` | mode set: with `map2check_property` for that property |
| `map2check_property__unknown` | `PropertyGenerator.c:16`, `:24-28` | `legacy_files::write_property_files` | mode set: `UNKNOWN` (double underscore kept, SD-16) |
| `track_bb_log.st` | `TrackBBLog.c:35-44` | `legacy_files::write_trackbb_log` | mode set, witness on: end of run |
| `heap_log.csv`, `allocation_log.csv`, `list_log.csv` | `HeapLog.c:54-66`, `AllocationLog.c:161-174`, `ListLog.c:138-157` | `legacy_files::LegacyLogs` | memtrack or memcleanup mode, witness on: end of run (SD-17) |
| `klee_log.csv` | `NonDetLog.c:17-60` (via `WitnessGeneration.c:22-24`) | `legacy_files::LegacyLogs::write_nondet_log` | mode set, witness on: end of a violating run |
| `map2check_checked_error` | `WitnessGeneration.c:28-32` | `legacy_files::write_checked_error` | mode set, witness on: before the abort |

`tests/legacy_golden/` holds the files the develop C runtime writes for one
scenario per verdict, and `rust/src/ffi_golden_tests.rs` checks that this
library writes the same bytes for the same calls.

## Nondet generators and the nondet log

Task 2.5 (#6) completed the nondet family for the Map2Check passes. Every
`map2check_non_det_<t>` the pass emits has a core `__VERIFIER_nondet_<t>`
target, `pchar`, `loff_t` and `sector_t` included, and every
`map2check_nondet_<t>` logger has a `map2check_save_nondet_log_<t>`
(`docs/cutover/abi-mapping.tsv`). The earlier decision not to port the
`pchar`/`loff_t`/`sector_t` generators is reversed: the pass does emit
them (`NonDetPass.cpp:155-171`).

**Generators.** Each reads the fuzzer input as develop's AFL++ generator
does (`NonDetGeneratorAFL.c`), which D1 conditions 4 and 9 require so that
CmpLog sees input bytes in the values and a KLEE vector means the same
thing as an AFL++ seed: `sizeof(type)` bytes per value, in order, little-endian
on x86-64, rewinding at the end of the input (SD-18).

| Type | C type (develop) | Bytes |
|---|---|---|
| `char`, `uchar` | `char`, `unsigned char` | 1 |
| `short`, `ushort` | `short`, `unsigned short` | 2 |
| `int`, `uint`/`unsigned`, `bool` | `int`, `unsigned`, `int` (`typedef int bool`) | 4 |
| `long`, `ulong`, `size_t`, `loff_t`, `sector_t`, `pointer`, `double` | `long`, `unsigned long`, `size_t`, `long long`, `unsigned long`, `void *`, `double` | 8 |
| `pchar` | `char *` | 4 (length) + `length - 1` |

**Nondet log.** `map2check_save_nondet_log_<t>` keeps the core signature
`(int line, int scope, int type_var, T *value, const char *function_name)`
returning `non_det_log_t *`, with `T` the C type of the table above
(`pointer` and `pchar` pass a `void **` and a `char **`), the decision of
#13. The pass stores the call's result in an `alloca` of that type and
passes its address; for `bool` it widens the `_Bool` to `int` first. The
`klee_log.csv` row is the one develop writes: the `enum NONDET_TYPE`
number of the export (`Map2CheckTypes.h:41-58`), and the value as
`NonDetPass.cpp` would have passed it to develop's `int` wrapper (narrow
types zero-extended, wide types and addresses truncated to 32 bits),
printed with `%u` for `unsigned`, `%lf` for `double` and `%d` otherwise
(`NonDetLog.c:45-54`). The golden `tests/legacy_golden/NONDET-TYPES/` holds
one row of each type. `type_var` is only kept in the returned record.

## `__VERIFIER_assume` under a fuzzer

`__VERIFIER_assume(0)` and `map2check_fuzzer_assume(0)` abandon the current
input, as develop's `nondet_cancel` does with `longjmp`
(`NonDetGeneratorAFL.c:31-37`, `:171-184`), and the fuzzer continues with
the next input in the same process (SD-07).

The mechanism is an unwind, not `longjmp`. Rust cannot call `setjmp`
soundly (it returns twice), and a `longjmp` over Rust frames is undefined
when one of them owns a destructor, as `LLVMFuzzerTestOneInput` does. The
assume calls `std::panic::resume_unwind` with a private payload (no panic
hook runs, nothing is printed), and `LLVMFuzzerTestOneInput` catches it with
`catch_unwind` and returns 0. The exports and the `__map2check_main__`
import are `extern "C-unwind"`, the ABI that lets a Rust unwind cross C
frames (RFC 2945). The analysed program's frames in between must carry
unwind tables, which clang emits by default on x86-64 Linux; they hold no
cleanups, so the unwind skips exactly what develop's `longjmp` skips. The
unwind needs `panic = "unwind"` (the `release` and `runtime` profiles).

With no iteration running (no `LLVMFuzzerTestOneInput` on the stack), or in
a `panic = "abort"` build, the assume keeps ending the process with
`exit(0)`, the SV-COMP convention for an infeasible path.

## Accepted: failure behaviour at the FFI boundary (panic strategy)

Every `#[no_mangle]` export runs its body through `ffi_guard`
(`rust/src/ffi.rs`), enforced by the source-scanning test
`tests/ffi_guard_coverage.rs`.

| Build | Panic strategy | Behaviour on a Rust panic inside an export |
|---|---|---|
| `dev`, `release`, `runtime` | `unwind` | Caught by `catch_unwind` in `ffi_guard`; a diagnostic goes to stderr and the export returns its neutral default. Nothing unwinds into C. |
| any `panic = "abort"` build (future KLEE build) | `abort` | No recovery: the process aborts at the panic. `ffi_guard` is then a no-op wrapper. |

Deliberate termination (`__VERIFIER_error` aborts; `__VERIFIER_assume(0)`
abandons the fuzzer input, or exits with 0 outside one) is not a failure and
is unaffected. `tests/ffi_harness.c`
calls every export before `map2check_init()` with valid boundary inputs
under ASan/UBSan.

## Accepted: `map2check_map_non_static_alloca` / `map2check_map_funct_address` semantics

The legacy C headers that defined these symbols
(`container_memtracklog.h:44,48`) no longer exist in this repository (the
`master` C branch's history was not carried over). Their signatures and exact
semantics were reconstructed from the paridade table and from the existing
`map2check_map_alloca`/`map2check_map_malloc` patterns in
`rust/src/ffi.rs`, not from the original C source:

- `map2check_map_non_static_alloca` — same shape as `map2check_map_alloca`.
  The M3 reconstruction marked the entry dynamic and took `size` in bytes;
  #38 replaced that with the `develop` semantics below.
- `map2check_map_funct_address` — registers a function's address as an
  always-valid load target (pointer-width `size_destiny`), so that reading a
  function pointer through `map2check_check_load`/`map2check_check_deref`
  does not get flagged as an invalid address.

Since #38 `map2check_map_non_static_alloca` follows the C runtime of
Map2Check `develop` (`modules/backend/library/lib/AnalysisModeMemtrack.c:368-372`):
`size` is an element count and the export registers a static slot of
`size * size_primitive` bytes, so a VLA never shows up as a leak at end of
program; see SD-12.

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
- records the release (a free event for `ptr`) when the check passes, so
  the caller must not add `map2check_map_free`. A NULL `ptr` and a failed
  check record nothing.

This matches the C runtime of Map2Check `develop`
(`modules/backend/library/lib/AnalysisModeMemtrack.c:164-183`): the
function checks with `is_invalid_free` (`ListLog.c:95-118`) and then marks
the block freed (`:178-182`). The pass uses it for `realloc` and for frees
whose argument is not a load, so it is a single call.

**Asymmetry with `map2check_check_free`:** `map2check_check_free` only
checks; the pass calls `map2check_map_free` after it to record the
release. `map2check_check_free_resolved_address` checks and records in one
call.

The free check itself consults the allocation and free records, not the
pointer stores that `develop` scans; see SD-13.
