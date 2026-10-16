/* SPDX-License-Identifier: GPL-3.0-only
 *
 * Nondet generator for the golden drivers. NonDetGeneratorNone.c writes no
 * klee_log.csv (its nondet_generate_aux_witness_files is empty, :42), so the
 * drivers use this one instead: nondet_init, nondet_destroy and
 * nondet_generate_aux_witness_files are those of NonDetGeneratorAFL.c
 * (:25, :27, :39-41), and main is that of NonDetGeneratorNone.c (:16-19),
 * without the AFL++ persistent loop.
 */
#include "NonDetGenerator.h"
#include "NonDetLog.h"

extern int __map2check_main__(void);

int main(void) {
  __map2check_main__();
  return 0;
}

void nondet_init() { nondet_log_init(); }

void nondet_destroy() { nondet_log_destroy(); }

void nondet_assume(int expr) { (void)expr; }

void nondet_generate_aux_witness_files() {
  nondet_log_to_file(map2check_nondet_get_log());
}
