/* SPDX-License-Identifier: GPL-3.0-only
 * x == 42 reaches the error. The violation writes the witness nondet log
 * (klee_log.csv), which formats x: D1 condition 7 requires the runtime to
 * concretise x first, or the formatting forks KLEE (2 paths became 22 in
 * the spike). Expected: two paths, one of them an abort with x = 42. */
#include "m2c.h"

int __map2check_main__(void) {
  M2C_START(M2C_MODE_TARGET);
  int x = NONDET(int, int, 10);
  if (x == 42) {
    REACH_ERROR(12);
  }
  map2check_success();
  return 0;
}
