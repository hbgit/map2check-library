/* SPDX-License-Identifier: GPL-3.0-only
 *
 * Task 3.1, witness_module_is_called_once: stands in for the witness module
 * (WitnessGeneration.bc / WitnessGenerationNone.bc) and records every call
 * the core makes into it in witness-trace.txt, in order. Linked by
 * scripts/runtime-ir/test-witness-wiring.sh in place of the witness module,
 * once with the C core and once with the drop-in core. The C map2check_exit
 * calls generate_aux_files once, with the violation flag, and on a violation
 * generate_confirmation_file once, before the abort (Map2CheckFunctions.c:
 * 89-102).
 */
#include <stdio.h>

static void trace(const char *what, int arg) {
  FILE *f = fopen("witness-trace.txt", "a");
  if (f) {
    if (arg < 0)
      fprintf(f, "%s\n", what);
    else
      fprintf(f, "%s %d\n", what, arg);
    fclose(f);
  }
}

/* WitnessGeneration.h; Bool is char. */
void generate_aux_files(void *trackbb_log, char violation) {
  (void)trackbb_log;
  trace("generate_aux_files", violation);
}
void generate_confirmation_file(void) { trace("generate_confirmation_file", -1); }
