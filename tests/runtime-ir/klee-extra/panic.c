/* SPDX-License-Identifier: GPL-3.0-only
 * Task 2.10 fix round (ported from tests/klee/panic.c of the legacy KLEE
 * route): a Rust panic in the drop-in core under KLEE. x == 7 panics (index
 * out of bounds, through panic_shim.py, test only); that path must end with
 * an abort -- std's rust_panic_with_hook is an abort stub in the core
 * (D7 post-processing) -- and run no backtrace-symbolizer code, with or
 * without RUST_BACKTRACE; the other path ends normally. No C counterpart: the
 * C runtime has no panic. */
void map2check_init(int);
void map2check_success(void);
int map2check_non_det_int(void);
void m2c_test_panic(long index);

int __map2check_main__(int argc, char **argv) {
  (void)argc; (void)argv;
  map2check_init(0);
  int x = map2check_non_det_int();
  if (x == 7)
    m2c_test_panic(x);
  map2check_success();
  return 0;
}
