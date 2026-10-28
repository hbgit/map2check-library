/* SPDX-License-Identifier: GPL-3.0-only
 * Task 2.7, klee_unsafe_program_reports_same_line (overflow mode): a signed
 * addition overflows for some nondet values, after a bounded loop. */
extern int __VERIFIER_nondet_int(void);
extern long __VERIFIER_nondet_long(void);
extern unsigned __VERIFIER_nondet_uint(void);
int main(void) {
  int x = __VERIFIER_nondet_int();
  long l = __VERIFIER_nondet_long();
  unsigned u = __VERIFIER_nondet_uint();
  int s = 0;
  for (int i = 0; i < 3; i++)
    s += i;
  if (l == 5 && u < 10) {
    int r = x + s; /* overflows when x > INT_MAX - 3 */
    return r & 1;
  }
  return 0;
}
