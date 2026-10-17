/* SPDX-License-Identifier: GPL-3.0-only
 * spikes/llvm16/prog.c (D1 spike) as the passes leave it: main renamed, mode
 * and init first, the nondet logged, map2check_success before each return.
 * KLEE must explore both sides of x == 42: two paths. */
#include "m2c.h"

int __map2check_main__(void) {
  M2C_START(M2C_MODE_TARGET);
  int x = NONDET(int, int, 9);
  if (x == 42) {
    map2check_success();
    return 1;
  }
  map2check_success();
  return 0;
}
