/* SPDX-License-Identifier: GPL-3.0-only
 * Task 2.7, klee_unsafe_program_reports_same_line (memcleanup mode): a block
 * is not freed on one path chosen by three nondet values. */
#include <stdlib.h>
extern int __VERIFIER_nondet_int(void);
extern unsigned long __VERIFIER_nondet_ulong(void);
extern _Bool __VERIFIER_nondet_bool(void);
int main(void) {
  int n = __VERIFIER_nondet_int();
  unsigned long m = __VERIFIER_nondet_ulong();
  _Bool b = __VERIFIER_nondet_bool();
  if (n < 0 || n > 3)
    return 0;
  int *a = malloc(sizeof(int) * 4);
  if (a == NULL)
    return 0;
  for (int j = 0; j <= n; j++)
    a[j] = j;
  if (n == 2 && m == 9 && b)
    return a[1]; /* leaks a */
  free(a);
  return 0;
}
