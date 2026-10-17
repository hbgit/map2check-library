/* SPDX-License-Identifier: GPL-3.0-only
 * Assert mode: a failed assert.
 */
#include "golden.h"

int __map2check_main__(void) {
  golden_arena();
  map2check_init(0);
  golden_tracking();
  map2check_assert(0, 21, "main");
  map2check_success();
  return 0;
}
