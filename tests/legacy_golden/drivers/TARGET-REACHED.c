/* SPDX-License-Identifier: GPL-3.0-only
 * Reachability mode (AnalysisModeNone.c): the target function is reached.
 */
#include "golden.h"

int __map2check_main__(void) {
  golden_arena();
  map2check_init(0);
  golden_tracking();
  map2check_target_function("reach_error", 0, 22);
  map2check_success();
  return 0;
}
