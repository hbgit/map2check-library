/* SPDX-License-Identifier: GPL-3.0-only
 *
 * Link test of the generated AnalysisModeAssert.ll and AnalysisModeNone.ll
 * (Task 2.4, D7 A-fwd). Built from ONE of the two modules (-DMODE_ASSERT or
 * -DMODE_NONE) and target/release/libmap2check.a, it calls the C names that
 * only the IR defines; each must reach its __m2c_rt_<mode>_* entry point in
 * the Rust core. Run by scripts/runtime-ir/test-assert-none-link.sh, one
 * scenario per process (argv[1]); the script checks the exit status and the
 * property files written in the current directory.
 */
#include <stdio.h>
#include <string.h>

/* AnalysisMode.h of Map2Check develop. */
void analysis_init(void);
void analysis_destroy(void);
char analysis_is_program_correct(void);
void analysis_generate_aux_witness_files(void);
/* AnalysisModeAssert.c (MODE_ASSERT) and Map2CheckFunctions.h. */
void map2check_assert(int condition, int line, const char *func_name);
void __VERIFIER_assert(int condition);
void map2check_target_function(const char *func_name, int scope, int line);
void map2check_init(int);
void map2check_success(void);

int __map2check_main__(void) { return 0; }

int main(int argc, char **argv) {
  const char *c = argc > 1 ? argv[1] : "";
  /* In C, map2check_init calls analysis_init (Map2CheckFunctions.c:37); so does
   * the drop-in core (feature dropin, scripts/runtime-ir/test-init-wiring.sh).
   * This staticlib has no such feature, so the call is made by hand; a
   * second call would be harmless in both runtimes (new empty logs). */
  map2check_init(0);
  analysis_init();
#ifdef MODE_ASSERT
  if (!strcmp(c, "assert0")) map2check_assert(0, 21, "main");
  else if (!strcmp(c, "assert1")) map2check_assert(1, 21, "main");
  else if (!strcmp(c, "verifier_assert")) {
    /* AnalysisModeAssert.c:25-27: empty, neither condition does anything. */
    __VERIFIER_assert(0);
    __VERIFIER_assert(1);
  } else if (!strcmp(c, "analysis")) {
    if (analysis_is_program_correct() != 1) return 3;
    analysis_generate_aux_witness_files();
    analysis_destroy();
  } else
#else
  if (!strcmp(c, "target")) map2check_target_function("reach_error", 0, 22);
  else if (!strcmp(c, "analysis")) {
    if (analysis_is_program_correct() != 1) return 3;
    analysis_generate_aux_witness_files();
    analysis_destroy();
  } else
#endif
  {
    fprintf(stderr, "unknown scenario '%s'\n", c);
    return 2;
  }
  map2check_success();
  return 0;
}
