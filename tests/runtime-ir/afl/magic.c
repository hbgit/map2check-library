/* SPDX-License-Identifier: GPL-3.0-only
 * Task 2.8 (from the D7 spike's progs/magic.c): a magic-value guard, for the
 * time to the first crash under afl-fuzz with CmpLog and for the replay of
 * the crashing input. */
extern void __assert_fail(const char *, const char *, unsigned int, const char *);
void reach_error(void) { __assert_fail("0", "magic.c", 6, "reach_error"); }
extern int __VERIFIER_nondet_int(void);
int main(void) {
  int x = __VERIFIER_nondet_int();
  int y = __VERIFIER_nondet_int();
  if (x == 0x13572468 && y > 7)
    reach_error();
  return 0;
}
