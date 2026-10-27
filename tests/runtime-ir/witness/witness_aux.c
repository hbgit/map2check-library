/* SPDX-License-Identifier: GPL-3.0-only
 *
 * Task 3.1: the witness files of a run, through the generate_aux_files and
 * generate_confirmation_file of the linked witness module
 * (WitnessGeneration.bc or WitnessGenerationNone.bc), which map2check_exit
 * calls (Map2CheckFunctions.c:89-102). Linked to the .bc modules by
 * scripts/runtime-ir/test-witness-wiring.sh, once with the C runtime and once
 * with the drop-in, with the generator chosen there (none, or AFL++ through
 * tests/runtime-ir/afl/fake_afl_rt.c).
 *
 * Two basic blocks and two logged nondet ints, then one outcome chosen at
 * compile time:
 *   -DM2C_SUCCESS              map2check_success with no violation (NONE);
 *   -DM2C_MODE_<mode>          the violation of init_wiring.c for the mode;
 *   -DM2C_TRAP                 wasm_rt_trap (WasmRuntimeStubs.c:110-116),
 *                              which calls map2check_error.
 * Nothing here calls analysis_init or the witness functions: map2check_init
 * selects the linked mode, map2check_exit calls the witness module.
 */
#include <limits.h>
#include <stdlib.h>

void map2check_init(int);
void map2check_success(void);
void map2check_track_bb(unsigned, const char *);
int map2check_non_det_int(void);
void map2check_nondet_int(unsigned, unsigned, int, const char *);
/* AnalysisModeOverflow.c */
void map2check_binop_add(long long, long long, unsigned, unsigned, unsigned, char *);
/* AnalysisModeAssert.c */
void map2check_assert(int, int, const char *);
/* Map2CheckFunctions.c */
void map2check_target_function(const char *, int, int);
/* AnalysisModeMemtrack.c / AnalysisModeMemcleanup.c */
void map2check_malloc(void *, int);
void map2check_free(const char *, void *, unsigned, unsigned, const char *);
void map2check_add_store_pointer(void *, void *, unsigned, const char *, int, const char *);
/* WasmRuntimeStubs.c: enum wasm_rt_trap_t, passed as int. */
void wasm_rt_trap(int);

int __map2check_main__(void) {
  map2check_init(0);
  map2check_track_bb(20, "main");
  int x = map2check_non_det_int();
  map2check_nondet_int(21, 0, x, "main");
  int y = map2check_non_det_int();
  map2check_nondet_int(22, 0, y, "main");
  map2check_track_bb(23, "main");
#if defined(M2C_SUCCESS)
  (void)x;
#elif defined(M2C_TRAP)
  wasm_rt_trap(1);
#elif defined(M2C_MODE_overflow)
  map2check_binop_add(INT_MAX, 1, 32, 40, 0, "main");
#elif defined(M2C_MODE_assert)
  map2check_assert(0, 41, "main");
#elif defined(M2C_MODE_none)
  map2check_target_function("main", 0, 42);
#elif defined(M2C_MODE_memtrack)
  static void *q;
  q = malloc(8);
  map2check_malloc(q, 8);
  map2check_free("q", q, 0, 43, "main");
  map2check_free("q", q, 0, 43, "main"); /* double free */
#elif defined(M2C_MODE_memcleanup)
  static void *p;
  p = malloc(8);
  map2check_malloc(p, 8);
  map2check_add_store_pointer(&p, p, 1, "p", 44, "main");
#else
#error "define M2C_SUCCESS, M2C_TRAP or M2C_MODE_<mode>"
#endif
  map2check_success();
  return 0;
}
