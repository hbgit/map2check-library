/* SPDX-License-Identifier: GPL-3.0-only
 * Task 2.8, driver (no Map2Check pass): calls every generator of
 * NonDetGeneratorAFL directly and prints what it returns, so the C and the
 * drop-in reader can be compared byte for byte on the same input: the 21
 * typed generators (sizeof(type) bytes each, in memory order, zeros past the
 * end), map2check_non_det_memory and map2check_non_det_pchar (an unsigned
 * length, NULL for 0, capped at 4096, length - 1 chars and a NUL). Run under
 * tests/runtime-ir/afl/fake_afl_rt.c, which feeds the input. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void map2check_init(int);
void map2check_success(void);

#define G(name, type) type map2check_non_det_##name(void);
G(char, char) G(pointer, void *) G(ushort, unsigned short) G(short, short)
G(long, long) G(ulong, unsigned long) G(bool, int) G(uchar, unsigned char)
G(size_t, unsigned long) G(loff_t, long) G(sector_t, unsigned long)
G(double, double) G(int, int) G(uint, unsigned) G(unsigned, unsigned)
G(float, float) G(longlong, long long) G(ulonglong, unsigned long long)
G(u8, unsigned char) G(u16, unsigned short) G(u32, unsigned)
#undef G
void map2check_non_det_memory(void *, unsigned long);
char *map2check_non_det_pchar(void);

static void hex(const char *name, const void *p, size_t n) {
  const unsigned char *b = p;
  printf("%s:", name);
  for (size_t i = 0; i < n; i++)
    printf("%02x", b[i]);
  printf("\n");
}

#define P(name)                                                                \
  do {                                                                         \
    __typeof__(map2check_non_det_##name()) v = map2check_non_det_##name();    \
    hex(#name, &v, sizeof v);                                                  \
  } while (0)

int __map2check_main__(void) {
  map2check_init(0);
  P(char); P(pointer); P(ushort); P(short); P(long); P(ulong); P(bool);
  P(uchar); P(size_t); P(loff_t); P(sector_t); P(double); P(int); P(uint);
  P(unsigned); P(float); P(longlong); P(ulonglong); P(u8); P(u16); P(u32);
  unsigned char mem[5];
  memset(mem, 0xee, sizeof mem);
  map2check_non_det_memory(mem, sizeof mem);
  hex("memory", mem, sizeof mem);
  char *s = map2check_non_det_pchar();
  if (s == NULL) {
    printf("pchar:NULL\n");
  } else {
    size_t n = strlen(s);
    printf("pchar:len=%zu ", n);
    hex("bytes", s, n);
    free(s);
  }
  P(int); /* the reader after pchar */
  map2check_success();
  return 0;
}
