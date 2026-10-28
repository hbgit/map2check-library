/* SPDX-License-Identifier: GPL-3.0-only
 * Task 2.8, afl_persistent_iterations_start_from_clean_state (memcleanup and
 * memtrack modes). One nondet int selects what the input does with a heap
 * block:
 *   0  frees it: no violation;
 *   1  leaves it allocated and is rejected by __VERIFIER_assume(0): the
 *      input ends (longjmp back to the __AFL_LOOP) while the block that would
 *      be the violation is still recorded;
 *   2  leaves it allocated and returns: the end-of-program check reports the
 *      leak and the process aborts.
 * The block is left behind the way each mode reports it at the end of the
 * program: unreachable in memtrack (the pointer is dropped), still pointed to
 * and unfreed in memcleanup (AnalysisModeMemcleanup.c:138-148), through
 * `kept`, which later inputs never overwrite; M2C_MEMCLEANUP (prepended by
 * the test for that mode) selects the latter. */
#include <stdio.h>
#include <stdlib.h>
extern int __VERIFIER_nondet_int(void);
extern void __VERIFIER_assume(int);
int *g;
int *kept;
int main(void) {
  int x = __VERIFIER_nondet_int();
  g = malloc(sizeof(int));
  if (g == NULL)
    return 0;
  *g = x;
  if (x == 1 || x == 2) {
#ifdef M2C_MEMCLEANUP
    kept = g;
#endif
    g = NULL;
    __VERIFIER_assume(x != 1);
    printf("main end %d (leak)\n", x);
    return 0;
  }
  free(g);
  g = NULL;
  printf("main end %d\n", x);
  return 0;
}
