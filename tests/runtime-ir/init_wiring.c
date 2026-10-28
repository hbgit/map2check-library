/* SPDX-License-Identifier: GPL-3.0-only
 *
 * Task 2.7 (pulled forward from Task 3.1): map2check_init of the core calls
 * the external analysis_init of the linked mode module, then nondet_init of
 * the linked generator module (Map2CheckFunctions.c:37-38). Linked to the
 * .bc modules (core + Array container + mode + NonDetGeneratorNone +
 * WitnessGenerationNone) by scripts/runtime-ir/test-init-wiring.sh, once with
 * the C runtime and once with the drop-in. Nothing here calls analysis_init:
 * only map2check_init can select the mode, and only a selected mode writes
 * the property files and aborts. One violation per mode, chosen with
 * -DM2C_MODE_<mode> at compile time (NonDetGeneratorNone's main takes no
 * arguments).
 */
#include <limits.h>
#include <stdlib.h>

void map2check_init(int);
void map2check_success(void);
/* Map2CheckFunctions.c:57-59, "DO NOTHING": defined by the core module on
 * both sides (the link fails otherwise) and without effect on the verdict. */
void __VERIFIER_error(void);
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

int __map2check_main__(void) {
  map2check_init(0);
  __VERIFIER_error();
#if defined(M2C_MODE_overflow)
  map2check_binop_add(INT_MAX, 1, 32, 40, 0, "main");
#elif defined(M2C_MODE_assert)
  map2check_assert(0, 41, "main");
#elif defined(M2C_MODE_none)
  map2check_target_function("main", 0, 42);
#elif defined(M2C_MODE_memtrack)
  int local = 0;
  map2check_free("local", &local, 0, 43, "main"); /* not a heap block */
#elif defined(M2C_MODE_memcleanup)
  /* int *p = malloc(8); never freed: p still points to the block at the
   * end of main (AnalysisModeMemcleanup.c:138-148). */
  static void *p;
  p = malloc(8);
  map2check_malloc(p, 8);
  map2check_add_store_pointer(&p, p, 1, "p", 44, "main");
#else
#error "define M2C_MODE_<mode>"
#endif
  map2check_success();
  return 0;
}
