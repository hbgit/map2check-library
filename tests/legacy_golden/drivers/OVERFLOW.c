/* SPDX-License-Identifier: GPL-3.0-only
 * Overflow mode: INT_MAX + 1 on a 32-bit int.
 */
#include "golden.h"

int __map2check_main__(void) {
  golden_arena();
  map2check_init(0);
  golden_tracking();
  map2check_binop_add(INT_MAX, 1, 32, 20, 0, "main");
  map2check_success();
  return 0;
}
