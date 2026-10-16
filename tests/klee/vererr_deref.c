/* SPDX-License-Identifier: GPL-3.0-only
 * Memtrack mode: __VERIFIER_error() (and, on the Rust runtime, a false
 * __VERIFIER_assert) is reached before the off-by-one read. With a mode set
 * both are no-ops, as in develop, so KLEE (stopping at the first abort, as
 * the frontend runs it) must still find the read: FALSE-DEREF, not an
 * abort with no property. */
#include <stdlib.h>
#include "m2c.h"

int __map2check_main__(void) {
  M2C_START(M2C_MODE_MEMTRACK);
  int *p = malloc(4 * sizeof(int));
  TRACK_MALLOC(p, (int)(4 * sizeof(int)), 13);
  for (int k = 0; k < 4; k++)
    p[k] = k;
  int i = NONDET(int, int, 16);
  __VERIFIER_error();
#ifndef M2C_DEVELOP
  __VERIFIER_assert(0);
#endif
  int v = 0;
  if (i >= 0 && i <= 4) {
    CHECK_LOAD(&p[i], (int)sizeof(int), 23);
    v = p[i];
  }
  TRACK_FREE(p, 26);
  free(p);
  map2check_success();
  return v;
}
