/* SPDX-License-Identifier: GPL-3.0-only
 * Task 2.7, klee_unsafe_program_reports_same_line: reach_error is reachable
 * for one combination of three nondet values after a bounded loop. Checked in
 * the none mode (--target-function reach_error) and in the assert mode
 * (reach_error calls __assert_fail, which the assert pass instruments). */
extern void __assert_fail(const char *, const char *, unsigned int, const char *);
void reach_error(void) { __assert_fail("0", "unsafe-reach.c", 7, "reach_error"); }
extern int __VERIFIER_nondet_int(void);
extern unsigned short __VERIFIER_nondet_ushort(void);
extern char __VERIFIER_nondet_char(void);
int main(void) {
  int x = __VERIFIER_nondet_int();
  unsigned short y = __VERIFIER_nondet_ushort();
  char c = __VERIFIER_nondet_char();
  int s = 0;
  for (int i = 0; i < 4; i++)
    s += i;
  if (x == 0x1357 + s && y > 7 && c == 'q')
    reach_error();
  return 0;
}
