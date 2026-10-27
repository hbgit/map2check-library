/* SPDX-License-Identifier: GPL-3.0-only
 *
 * Link test of the generated AnalysisModeOverflow.ll (Task 2.3, D7 A-fwd):
 * built from the .ll and target/release/libmap2check.a, it calls the C names
 * that only the IR defines; each must reach its __m2c_rt_overflow_* entry
 * point in the Rust core. Run by scripts/runtime-ir/test-overflow-link.sh,
 * one scenario per process (argv[1]); the script checks the exit status and
 * the property files written in the current directory.
 */
#include <limits.h>
#include <stdio.h>
#include <string.h>

/* AnalysisMode.h and AnalysisModeOverflow.c of Map2Check develop. */
void analysis_init(void);
void analysis_destroy(void);
char analysis_is_program_correct(void);
void analysis_generate_aux_witness_files(void);
void overflowError(unsigned line, const char *function_name);
void map2check_binop_add(long long, long long, unsigned, unsigned, unsigned, char *);
void map2check_binop_sub(long long, long long, unsigned, unsigned, unsigned, char *);
void map2check_binop_mul(long long, long long, unsigned, unsigned, unsigned, char *);
void map2check_binop_sdiv(long long, long long, unsigned, unsigned, unsigned, char *);
void map2check_binop_srem(long long, long long, unsigned, unsigned, unsigned, char *);
void map2check_binop_add_uint(unsigned long long, unsigned long long, unsigned, unsigned,
                              unsigned, char *);
void map2check_binop_sub_uint(unsigned long long, unsigned long long, unsigned, unsigned,
                              unsigned, char *);
void map2check_binop_mul_uint(unsigned long long, unsigned long long, unsigned, unsigned,
                              unsigned, char *);
/* Map2CheckFunctions.h (Rust core). */
void map2check_init(int);
void map2check_success(void);

int __map2check_main__(void) { return 0; }

int main(int argc, char **argv) {
  const char *c = argc > 1 ? argv[1] : "";
  char fn[] = "main";
  /* In C, map2check_init calls analysis_init (Map2CheckFunctions.c:37); so does
   * the drop-in core (feature dropin, scripts/runtime-ir/test-init-wiring.sh).
   * This staticlib has no such feature, so the call is made by hand; a
   * second call would be harmless in both runtimes (new empty logs). */
  map2check_init(0);
  analysis_init();
  if (!strcmp(c, "add")) map2check_binop_add(INT_MAX, 1, 32, 20, 0, fn);
  else if (!strcmp(c, "sub")) map2check_binop_sub(INT_MIN, 1, 32, 21, 0, fn);
  else if (!strcmp(c, "mul")) map2check_binop_mul(INT_MAX, 2, 32, 22, 0, fn);
  else if (!strcmp(c, "sdiv")) map2check_binop_sdiv(INT_MIN, -1, 32, 23, 0, fn);
  else if (!strcmp(c, "srem")) map2check_binop_srem(5, 0, 32, 24, 0, fn);
  else if (!strcmp(c, "overflowError")) overflowError(25, "f");
  else if (!strcmp(c, "uint")) {
    map2check_binop_add_uint(UINT_MAX, 1, 32, 26, 0, fn);
    map2check_binop_sub_uint(0, 1, 32, 27, 0, fn);
    map2check_binop_mul_uint(UINT_MAX, 2, 32, 28, 0, fn);
  } else if (!strcmp(c, "safe")) {
    map2check_binop_add(-5, 3, 32, 29, 0, fn);
    map2check_binop_sdiv(INT_MIN, 1, 32, 29, 0, fn);
    if (analysis_is_program_correct() != 1) return 3;
    analysis_generate_aux_witness_files();
    analysis_destroy();
  } else {
    fprintf(stderr, "unknown scenario '%s'\n", c);
    return 2;
  }
  map2check_success();
  return 0;
}
