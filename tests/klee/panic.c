/* SPDX-License-Identifier: GPL-3.0-only
 * A Rust panic under KLEE, after the backtrace symbolizer was stubbed out
 * (scripts/klee-stub-symbolizer.py): x == 7 panics (index out of bounds,
 * through tests/klee/panic_shim.py, test only), which must end its path
 * with a KLEE error and never run symbolizer code, with or without
 * RUST_BACKTRACE; the other side ends normally. */
#include "m2c.h"

void m2c_test_panic(long index);

int __map2check_main__(void) {
  M2C_START(M2C_MODE_TARGET);
  int x = NONDET(int, int, 12);
  if (x == 7)
    m2c_test_panic(x);
  map2check_success();
  return 0;
}
