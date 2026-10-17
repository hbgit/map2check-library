/* SPDX-License-Identifier: GPL-3.0-only
 * Memtrack mode: malloc returns NULL (AnalysisModeMemtrack.c:305-311).
 */
#include "golden.h"

int __map2check_main__(void) {
  golden_arena();
  map2check_init(0);
  golden_tracking();
  golden_memory();
  map2check_malloc(NULL, 4);
  map2check_success();
  return 0;
}
