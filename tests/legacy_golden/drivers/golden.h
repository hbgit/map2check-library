/* SPDX-License-Identifier: GPL-3.0-only
 *
 * Shared scenario for the golden-file drivers. Each driver plays the calls
 * that an instrumented program makes on the C runtime of Map2Check develop
 * (modules/backend/library/lib), so the files that runtime writes can be
 * compared byte for byte with the files written by this library for the
 * same calls (rust/src/ffi_golden_tests.rs).
 *
 * Every address the runtime sees lives in an arena mapped at a fixed
 * address, so the %p columns of the logs are the same on every run. The
 * runtime never dereferences a heap block; it only reads the pointer slot
 * in map2check_free and calls free() on a leaked block at exit
 * (AllocationLog.c:91). The build links with -Wl,--wrap=free and
 * __wrap_free below ignores arena addresses.
 */
#ifndef GOLDEN_H
#define GOLDEN_H

#include <limits.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>

/* develop runtime entry points, as the passes declare them. */
void map2check_init(int isSvComp);
void map2check_success(void);
void map2check_track_bb(unsigned line, const char *function_name);
void map2check_target_function(const char *func_name, int scope, int line);
void map2check_nondet_int(unsigned line, unsigned scope, int value,
                          const char *function_name);
void map2check_nondet_uint(unsigned line, unsigned scope, int value,
                           const char *function_name);
void map2check_nondet_char(unsigned line, unsigned scope, int value,
                           const char *function_name);
void map2check_nondet_long(unsigned line, unsigned scope, int value,
                           const char *function_name);
void map2check_nondet_double(unsigned line, unsigned scope, double value,
                             const char *function_name);
void map2check_alloca(const char *name, void *ptr, int size,
                      int size_of_primitive, int line, int scope);
void map2check_function(const char *name, void *ptr);
void map2check_malloc(void *ptr, int size);
void map2check_posix(void *ptr, int size);
void map2check_add_store_pointer(void *var, void *value, unsigned scope,
                                 const char *name, int line,
                                 const char *function_name);
void map2check_free(const char *name, void *ptr, unsigned scope, unsigned line,
                    const char *function_name);
void map2check_free_resolved_address(void *ptr, unsigned line,
                                     const char *function_name,
                                     short int isNullValid);
void map2check_load(void *ptr, int size);
void map2check_check_deref(int line, const char *function_name);
void map2check_binop_add(long long param1, long long param2, unsigned width,
                         unsigned line, unsigned scope, char *function_name);
void map2check_binop_sdiv(long long param1, long long param2, unsigned width,
                          unsigned line, unsigned scope, char *function_name);
void map2check_assert(int condition, int line, const char *func_name);

/* Fixed addresses, mirrored by rust/src/output/golden_tests.rs. */
#define GOLDEN_ARENA 0x10000000UL
#define GOLDEN_ARENA_SIZE 4096UL
#define SLOT_P ((void *)(GOLDEN_ARENA + 0x0))   /* the pointer variable p */
#define FN_MAIN ((void *)(GOLDEN_ARENA + 0x40)) /* address of main */
#define BLOCK ((void *)(GOLDEN_ARENA + 0x100))  /* heap block, 16 bytes */
#define WILD ((void *)(GOLDEN_ARENA + 0x800))   /* never allocated */
#define SLOT_Q ((void *)(GOLDEN_ARENA + 0x8))   /* the pointer variable q */
#define BLOCK2 ((void *)(GOLDEN_ARENA + 0x200)) /* heap block, 32 bytes */

void __real_free(void *ptr);
void __wrap_free(void *ptr) {
  if ((uintptr_t)ptr - GOLDEN_ARENA < GOLDEN_ARENA_SIZE) {
    return;
  }
  __real_free(ptr);
}

static void golden_arena(void) {
  void *arena = mmap((void *)GOLDEN_ARENA, GOLDEN_ARENA_SIZE,
                     PROT_READ | PROT_WRITE,
                     MAP_PRIVATE | MAP_ANONYMOUS | MAP_FIXED_NOREPLACE, -1, 0);
  if (arena != (void *)GOLDEN_ARENA) {
    fprintf(stderr, "golden: cannot map the arena\n");
    exit(2);
  }
}

/* Basic blocks (one repeated line) and one nondet value of each kind the
 * Rust library logs. */
static void golden_tracking(void) {
  map2check_track_bb(3, "main");
  map2check_track_bb(4, "main");
  map2check_track_bb(3, "main");
  map2check_nondet_int(5, 0, 42, "main");
  map2check_nondet_uint(6, 0, (int)4000000000u, "main");
  /* NonDetPass.cpp:240-258,281 widens a char with CreateIntegerCast(..., false),
   * a zero extension: the wrapper receives (unsigned char)-3. */
  map2check_nondet_char(7, 0, (int)(unsigned char)(char)-3, "main");
  map2check_nondet_long(8, 0, -7, "main");
  map2check_nondet_double(9, 0, 2.5, "main");
}

/* int *p (stack slot of 8 bytes); &main; p = malloc(16). */
static void golden_memory(void) {
  map2check_alloca("p", SLOT_P, 8, 8, 10, 1);
  map2check_function("main", FN_MAIN);
  map2check_malloc(BLOCK, 16);
  *(void **)SLOT_P = BLOCK;
  map2check_add_store_pointer(SLOT_P, BLOCK, 1, "p", 11, "main");
}

#endif
