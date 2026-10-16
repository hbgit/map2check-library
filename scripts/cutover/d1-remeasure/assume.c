/* Assume-heavy program for the D1 re-measurement (Task 2.5b): most inputs
 * are rejected by an assume, and the bug sits behind a magic value. */
#include <stdlib.h>
extern void map2check_init(void);
extern void map2check_success(void);
extern int __VERIFIER_nondet_int(void);
extern void __VERIFIER_assume(int);
int main(void) {
  map2check_init();
  int x = __VERIFIER_nondet_int();
  __VERIFIER_assume(x > 100);
  __VERIFIER_assume(x < 200);
  if (x == 150) abort();
  map2check_success();
  return 0;
}
