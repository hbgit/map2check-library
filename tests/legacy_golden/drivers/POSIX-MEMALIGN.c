/* SPDX-License-Identifier: GPL-3.0-only
 * Memtrack mode: posix_memalign(&q, 16, 32) next to p = malloc(16); both
 * blocks leak.
 */
#include "golden.h"

int __map2check_main__(void) {
  golden_arena();
  map2check_init(0);
  golden_tracking();
  golden_memory();
  map2check_alloca("q", SLOT_Q, 8, 8, 15, 1);
  *(void **)SLOT_Q = BLOCK2;
  map2check_posix(SLOT_Q, 32);
  map2check_success();
  return 0;
}
