/* SPDX-License-Identifier: GPL-3.0-only
 * D7 spike: unsafe program with a magic-value guard (time to first crash
 * under AFL++ with CmpLog; FALSE under KLEE). */
extern void __assert_fail(const char *, const char *, unsigned int, const char *);
void reach_error(void) { __assert_fail("0", "magic.c", 5, "reach_error"); }
extern int __VERIFIER_nondet_int(void);
int main(void) {
  int x = __VERIFIER_nondet_int();
  int y = __VERIFIER_nondet_int();
  if (x == 0x13572468 && y > 7)
    reach_error();
  return 0;
}
