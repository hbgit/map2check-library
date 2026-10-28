/* SPDX-License-Identifier: GPL-3.0-only
 * Task 2.7, klee_safe_program_drops_no_paths: safe in every mode, with three
 * nondet values and a bounded loop. A fixed-size malloc/free gives the memory
 * modes work; the arithmetic stays far from overflow; reach_error (through
 * __assert_fail, which the assert mode instruments) is unreachable. */
#include <stdlib.h>
extern void __assert_fail(const char *, const char *, unsigned int, const char *);
void reach_error(void) { __assert_fail("0", "safe.c", 9, "reach_error"); }
extern int __VERIFIER_nondet_int(void);
extern unsigned char __VERIFIER_nondet_uchar(void);
extern _Bool __VERIFIER_nondet_bool(void);
int main(void) {
  int n = __VERIFIER_nondet_int();
  unsigned char k = __VERIFIER_nondet_uchar();
  _Bool flip = __VERIFIER_nondet_bool();
  if (n < 0 || n > 4)
    return 0;
  int *a = malloc(sizeof(int) * 5);
  if (a == NULL)
    return 0;
  int s = 0;
  for (int i = 0; i <= n; i++) {
    a[i] = flip ? i : 2 * i;
    s += a[i];
  }
  int want = (flip ? 1 : 2) * (n * (n + 1) / 2);
  if (s != want || k > 255)
    reach_error();
  free(a);
  return 0;
}
