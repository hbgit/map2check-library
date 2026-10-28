/* SPDX-License-Identifier: GPL-3.0-only
 *
 * Task 2.7, map2check_init_calls_analysis_init_then_nondet_init: stands in
 * for the mode module and the generator module, and records every call the
 * core makes into them in init-order.txt, in order. Linked by
 * scripts/runtime-ir/test-init-wiring.sh after the four core modules and the
 * Array container, once with the C core and once with the drop-in core. The
 * C core calls analysis_init and then nondet_init from map2check_init
 * (Map2CheckFunctions.c:37-38), so both traces must start with those two
 * lines, in that order.
 */
#include <stdio.h>

void map2check_init(int);
void map2check_success(void);
void nondet_log_init(void);
void nondet_log_destroy(void);

static void trace(const char *what) {
  FILE *f = fopen("init-order.txt", "a");
  if (f) {
    fprintf(f, "%s\n", what);
    fclose(f);
  }
}

/* AnalysisMode.h */
void analysis_init(void) { trace("analysis_init"); }
void analysis_destroy(void) { trace("analysis_destroy"); }
char analysis_is_program_correct(void) { trace("analysis_is_program_correct"); return 1; }
void analysis_generate_aux_witness_files(void) { trace("analysis_generate_aux_witness_files"); }
/* NonDetGenerator.h: nondet_init/destroy as the generators define them. */
void nondet_init(void) { trace("nondet_init"); nondet_log_init(); }
void nondet_destroy(void) { trace("nondet_destroy"); nondet_log_destroy(); }
void nondet_assume(int expr) { (void)expr; trace("nondet_assume"); }
void nondet_generate_aux_witness_files(void) { trace("nondet_generate_aux_witness_files"); }

int main(void) {
  map2check_init(0);
  trace("main: after map2check_init");
  map2check_success();
  return 0;
}
