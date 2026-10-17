/* SPDX-License-Identifier: GPL-3.0-only
 * Overflow mode: 7 / 0 on a 32-bit int.
 */
#include "golden.h"

int __map2check_main__(void) {
  golden_arena();
  map2check_init(0);
  golden_tracking();
  map2check_binop_sdiv(7, 0, 32, 23, 0, "main");
  map2check_success();
  return 0;
}
