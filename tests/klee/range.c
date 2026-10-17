/* SPDX-License-Identifier: GPL-3.0-only
 * D1 condition 7. On the error path x is only bounded (x > 1000), so the
 * witness nondet log that the violation writes would format a value with
 * many possible digits: unless the runtime concretises x first, every digit
 * forks KLEE. Expected: two paths, the logged value above 1000. */
#include "m2c.h"

int __map2check_main__(void) {
  M2C_START(M2C_MODE_TARGET);
  int x = NONDET(int, int, 10);
  if (x > 1000) {
    REACH_ERROR(12);
  }
  map2check_success();
  return 0;
}
