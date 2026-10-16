/* SPDX-License-Identifier: GPL-3.0-only
 * Target mode: __VERIFIER_error() alone reports nothing. Reachability comes
 * only from map2check_reach_target, which the target pass emits (reach.c).
 * Expected: two paths, no abort, map2check_property NONE. */
#include "m2c.h"

int __map2check_main__(void) {
  M2C_START(M2C_MODE_TARGET);
  int x = NONDET(int, int, 8);
  if (x == 42) {
    __VERIFIER_error();
#ifndef M2C_DEVELOP
    __VERIFIER_assert(0);
#endif
  }
  map2check_success();
  return 0;
}
