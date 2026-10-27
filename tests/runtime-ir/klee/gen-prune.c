/* SPDX-License-Identifier: GPL-3.0-only
 * Task 2.7, klee_generator_driver_matches_c: nondet_assume ends a path whose
 * assumption fails as a normal exit with a one-byte "map2check_pruned"
 * object (NonDetGeneratorKlee.c:78-89), reached as the passes reach it,
 * through map2check_assume of the core glue. Also the generators that take
 * no type name: pchar (non_det_unsigned length + non_det_char each) and
 * memory (one non_det_memory object, logged byte by byte). */
#include <stddef.h>
void map2check_init(int);
void map2check_success(void);
void map2check_assume(int);
int map2check_non_det_int(void);
char *map2check_non_det_pchar(void);
void map2check_non_det_memory(void *, size_t);
int __map2check_main__(int argc, char **argv) {
  (void)argc; (void)argv;
  map2check_init(0);
  int x = map2check_non_det_int();
  map2check_assume(x > 3 && x < 6);
  struct { short a; char b[3]; } s;
  map2check_non_det_memory(&s, sizeof s);
  map2check_assume(s.a != 9);
  char *p = map2check_non_det_pchar();
  (void)p;
  map2check_success();
  return x;
}
