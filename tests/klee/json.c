/* SPDX-License-Identifier: GPL-3.0-only
 * D1 condition 7, the spike's case: with no analysis mode the runtime
 * prints the JSON report at map2check_success, serde_json formatting an
 * unconstrained x. The spike measured 22 paths instead of 2 for that; with
 * the value concretised first there is one. Rust runtime only (develop has
 * no JSON report). */
#ifdef M2C_DEVELOP
#error "json.c exercises the Rust runtime's JSON report only"
#endif
#include "m2c.h"

int __map2check_main__(void) {
  map2check_init();
  int x = NONDET(int, int, 15);
  (void)x;
  map2check_success();
  return 0;
}
