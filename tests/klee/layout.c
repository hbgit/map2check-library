/* SPDX-License-Identifier: GPL-3.0-only
 * D1 condition 9: the KLEE vector of this path, turned into a fuzzer seed
 * the way the frontend does (exportKleeVectorsAsSeeds: the objects' bytes
 * concatenated in order), must drive the AFL++/libFuzzer reader of the Rust
 * runtime down the same path. One value per width and signedness, each a
 * pattern no other byte layout would produce. */
#include "m2c.h"

int __map2check_main__(void) {
  M2C_START(M2C_MODE_TARGET);
  char c = NONDET(char, char, 11);
  short s = NONDET(short, short, 12);
  unsigned short us = NONDET(ushort, unsigned short, 13);
  int x = NONDET(int, int, 14);
  unsigned u = NONDET(uint, unsigned, 15);
  long l = NONDET(long, long, 16);
  unsigned long ul = NONDET(ulong, unsigned long, 17);
  unsigned char uc = NONDET(uchar, unsigned char, 18);
  if (c == 'A' && s == -2 && us == 0xBEEF && x == 42 && u == 0xDEADBEEFu &&
      l == -5 && ul == 0x0123456789ABCDEFul && uc == 0x7F) {
    REACH_ERROR(21);
  }
  map2check_success();
  return 0;
}
