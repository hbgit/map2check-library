/* SPDX-License-Identifier: GPL-3.0-only
 * The shape of sv-benchmarks lis_unsafe: two mallocs of 4 * n bytes with a
 * symbolic n. KLEE returns NULL for a size over 2^31; the pass truncates
 * the size to int, so the runtime sees NULL with a negative size, and must
 * report UNKNOWN (develop's map2check_malloc) instead of letting the state
 * run on to the second malloc, which KLEE then binds to a concrete 2 GiB
 * object (task-2.7c-report.md). */
#include <stdlib.h>
#include "m2c.h"

int __map2check_main__(void) {
  M2C_START(M2C_MODE_MEMTRACK);
  int n = NONDET(int, int, 10);
  int *best = malloc(sizeof(int) * (long)n);
  TRACK_MALLOC(best, (int)(sizeof(int) * (long)n), 11);
  int *prev = malloc(sizeof(int) * (long)n);
  TRACK_MALLOC(prev, (int)(sizeof(int) * (long)n), 12);
  int v = 0;
  if (n > 0) {
    CHECK_LOAD(&best[0], (int)sizeof(int), 15);
    v = best[0];
  }
  free(best);
  free(prev);
  map2check_success();
  return v;
}
