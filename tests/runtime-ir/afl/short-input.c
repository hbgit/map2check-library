/* SPDX-License-Identifier: GPL-3.0-only
 * Task 2.8, short input completed with zeros (target mode, reach_error):
 * past the end of the test case every byte reads as 0
 * (get_next_input_from_afl, NonDetGeneratorAFL.c:61-66). The one-byte input
 * "A" makes a == 0x41 and b == c == 0, and reaches the error; so does the
 * seed "A" of the frontend. */
#include <stdio.h>
extern void __assert_fail(const char *, const char *, unsigned int, const char *);
void reach_error(void) { __assert_fail("0", "short-input.c", 9, "reach_error"); }
extern int __VERIFIER_nondet_int(void);
extern unsigned char __VERIFIER_nondet_uchar(void);
int main(void) {
  int a = __VERIFIER_nondet_int();
  int b = __VERIFIER_nondet_int();
  unsigned char c = __VERIFIER_nondet_uchar();
  printf("a=%d b=%d c=%u\n", a, b, c);
  if (a == 0x41 && b == 0 && c == 0)
    reach_error();
  return 0;
}
