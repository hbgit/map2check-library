/* SPDX-License-Identifier: GPL-3.0-only
 * Task 2.7, klee_unsafe_program_reports_same_line (memtrack mode): an
 * off-by-one read past a fixed-size block for some nondet index. */
#include <stdlib.h>
extern int __VERIFIER_nondet_int(void);
extern unsigned char __VERIFIER_nondet_uchar(void);
extern short __VERIFIER_nondet_short(void);
int main(void) {
  int i = __VERIFIER_nondet_int();
  unsigned char k = __VERIFIER_nondet_uchar();
  short h = __VERIFIER_nondet_short();
  if (i < 0 || i > 4 || k != 3)
    return 0;
  int *a = malloc(sizeof(int) * 4);
  if (a == NULL)
    return 0;
  for (int j = 0; j < 4; j++)
    a[j] = j + h;
  int v = a[i]; /* i == 4 reads past the block */
  free(a);
  return v == 0;
}
