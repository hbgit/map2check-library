/* SPDX-License-Identifier: GPL-3.0-only
 * D7 spike: safe program where most inputs are rejected by
 * __VERIFIER_assume (the AFL++ generator's longjmp path). */
#include <stdlib.h>
extern void __assert_fail(const char *, const char *, unsigned int, const char *);
void reach_error(void) { __assert_fail("0", "assume.c", 6, "reach_error"); }
extern int __VERIFIER_nondet_int(void);
extern void __VERIFIER_assume(int);
int main(void) {
  int n = __VERIFIER_nondet_int();
  __VERIFIER_assume(n >= 0 && n <= 8);
  int *a = malloc(sizeof(int) * 9);
  if (a == NULL)
    return 0;
  int s = 0;
  for (int i = 0; i <= n; i++) {
    a[i] = i;
    s += a[i];
  }
  if (s != n * (n + 1) / 2)
    reach_error();
  free(a);
  return 0;
}
