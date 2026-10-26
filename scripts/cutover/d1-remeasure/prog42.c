/* Variant of prog.c for the fuzzers: x == 42 aborts, so reaching it is a
 * crash afl-fuzz can count. Same calls otherwise. */
#include <stdlib.h>
extern void map2check_init(int isSvComp);
extern void map2check_success(void);
extern int __VERIFIER_nondet_int(void);
int main(void) {
  map2check_init(0);
  int x = __VERIFIER_nondet_int();
  if (x == 42) abort();
  map2check_success();
  return 0;
}
