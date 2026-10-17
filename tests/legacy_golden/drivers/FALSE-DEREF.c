/* SPDX-License-Identifier: GPL-3.0-only
 * Memtrack mode: a 4-byte load from an address that was never allocated.
 */
#include "golden.h"

int __map2check_main__(void) {
  golden_arena();
  map2check_init(0);
  golden_tracking();
  golden_memory();
  map2check_load(WILD, 4);
  map2check_check_deref(14, "main");
  map2check_success();
  return 0;
}
