/* SPDX-License-Identifier: GPL-3.0-only
 * Assert mode: one nondet value of every NONDET_TYPE (Map2CheckTypes.h:41-58),
 * then a failed assert, so the witness writes klee_log.csv.
 *
 * Each value reaches its map2check_nondet_<t> wrapper (NonDetLog.c:105-150)
 * as NonDetPass.cpp passes it:
 *  - int, unsigned, uint, double: the call result itself (NONDET_IMPL_HELPER,
 *    :260-275, used at :277-280);
 *  - char, ushort, short, long, ulong, bool, uchar, size_t, loff_t,
 *    sector_t: CreateIntegerCast(v, i32, isSigned = false) (:240-258,
 *    :281-290), a zero extension of the narrow types and a truncation of the
 *    wide ones;
 *  - pchar, pointer: CreatePtrToInt(v, i32) (:224-238, :291-292), the low 32
 *    bits of the address.
 * bool is the `_Bool` of __VERIFIER_nondet_bool, an i1, so it reaches the
 * wrapper as 0 or 1.
 */
#include "golden.h"

void map2check_nondet_unsigned(unsigned line, unsigned scope, unsigned value,
                               const char *function_name);
void map2check_nondet_pointer(unsigned line, unsigned scope, int value,
                              const char *function_name);
void map2check_nondet_ushort(unsigned line, unsigned scope, int value,
                             const char *function_name);
void map2check_nondet_short(unsigned line, unsigned scope, int value,
                            const char *function_name);
void map2check_nondet_ulong(unsigned line, unsigned scope, int value,
                            const char *function_name);
void map2check_nondet_bool(unsigned line, unsigned scope, int value,
                           const char *function_name);
void map2check_nondet_uchar(unsigned line, unsigned scope, int value,
                            const char *function_name);
void map2check_nondet_pchar(unsigned line, unsigned scope, int value,
                            const char *function_name);
void map2check_nondet_size_t(unsigned line, unsigned scope, int value,
                             const char *function_name);
void map2check_nondet_loff_t(unsigned line, unsigned scope, int value,
                             const char *function_name);
void map2check_nondet_sector_t(unsigned line, unsigned scope, int value,
                               const char *function_name);

/* The LLVM casts, in C: zext of a narrow value, trunc of a wide one. */
#define ZEXT8(v) ((int)(unsigned char)(v))
#define ZEXT16(v) ((int)(unsigned short)(v))
#define TRUNC(v) ((int)(unsigned)(unsigned long long)(v))

int __map2check_main__(void) {
  map2check_init(0);
  golden_tracking();
  map2check_nondet_int(30, 1, -5, "f");
  map2check_nondet_unsigned(31, 1, 4000000000u, "f");
  map2check_nondet_char(32, 1, ZEXT8((char)-3), "f");
  map2check_nondet_pointer(33, 1, TRUNC(0x123456789ULL), "f");
  map2check_nondet_long(34, 1, TRUNC(-7L), "f");
  map2check_nondet_ushort(35, 1, ZEXT16((unsigned short)65535), "f");
  map2check_nondet_short(36, 1, ZEXT16((short)-2), "f");
  map2check_nondet_ulong(37, 1, TRUNC(0xFFFFFFFF80000000UL), "f");
  map2check_nondet_bool(38, 1, 1, "f");
  map2check_nondet_uchar(39, 1, ZEXT8((unsigned char)200), "f");
  map2check_nondet_pchar(40, 1, TRUNC(0x7fff12345678ULL), "f");
  map2check_nondet_size_t(41, 1, TRUNC(5000000000UL), "f");
  map2check_nondet_loff_t(42, 1, TRUNC(-1LL), "f");
  map2check_nondet_sector_t(43, 1, TRUNC(0x100000009UL), "f");
  map2check_nondet_uint(44, 1, (int)4000000000u, "f");
  map2check_nondet_double(45, 1, -0.125, "f");
  map2check_assert(0, 46, "f");
  map2check_success();
  return 0;
}
