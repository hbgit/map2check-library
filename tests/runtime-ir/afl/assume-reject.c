/* SPDX-License-Identifier: GPL-3.0-only
 * Task 2.8, afl_assume_rejection_cancels_only_current_input (target mode,
 * reach_error). x == 5 is rejected by __VERIFIER_assume before y is read;
 * x == 7 && y == 9 reaches the error. An input that follows a rejected one
 * reads its own bytes from the first one on. */
#include <stdio.h>
extern void __assert_fail(const char *, const char *, unsigned int, const char *);
void reach_error(void) { __assert_fail("0", "assume-reject.c", 8, "reach_error"); }
extern int __VERIFIER_nondet_int(void);
extern void __VERIFIER_assume(int);
int main(void) {
  int x = __VERIFIER_nondet_int();
  __VERIFIER_assume(x != 5);
  int y = __VERIFIER_nondet_int();
  printf("main end %d %d\n", x, y);
  if (x == 7 && y == 9)
    reach_error();
  return 0;
}
