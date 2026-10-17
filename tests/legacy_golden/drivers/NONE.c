/* SPDX-License-Identifier: GPL-3.0-only
 * Memtrack mode: free(p), then a normal exit.
 */
#include "golden.h"

int __map2check_main__(void) {
  golden_arena();
  map2check_init(0);
  golden_tracking();
  golden_memory();
  map2check_free("p", SLOT_P, 1, 12, "main");
  map2check_success();
  return 0;
}
