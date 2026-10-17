/* SPDX-License-Identifier: GPL-3.0-only
 * Memtrack mode: free(p) twice through map2check_free, the path of a free
 * whose argument is a load of the pointer variable. The second call appends
 * its FREE row to the list log before it fails (AnalysisModeMemtrack.c:346-358).
 */
#include "golden.h"

int __map2check_main__(void) {
  golden_arena();
  map2check_init(0);
  golden_tracking();
  golden_memory();
  map2check_free("p", SLOT_P, 1, 12, "main");
  map2check_free("p", SLOT_P, 1, 13, "main");
  map2check_success();
  return 0;
}
