/* SPDX-License-Identifier: GPL-3.0-only
 * Off-by-one read: i == 4 loads past the 4-int block. The memtrack check
 * before the load must report it (FALSE-DEREF), and KLEE must find that
 * path. */
#include <stdlib.h>
#include "m2c.h"

int __map2check_main__(void) {
  M2C_START(M2C_MODE_MEMTRACK);
  int *p = malloc(4 * sizeof(int));
  TRACK_MALLOC(p, (int)(4 * sizeof(int)), 11);
  for (int k = 0; k < 4; k++)
    p[k] = k;
  int i = NONDET(int, int, 14);
  int v = 0;
  if (i >= 0 && i <= 4) {
    CHECK_LOAD(&p[i], (int)sizeof(int), 17);
    v = p[i];
  }
  TRACK_FREE(p, 20);
  free(p);
  map2check_success();
  return v;
}
