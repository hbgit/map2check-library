/* SPDX-License-Identifier: GPL-3.0-only
 *
 * Link test of the generated AnalysisModeMemtrack.ll (Task 2.5, D7 A-fwd):
 * built from the .ll, the empty container/log modules and
 * target/release/libmap2check.a, it calls the C names that only the IR
 * defines; each must reach its __m2c_rt_memtrack_* entry point in the Rust
 * core. Run by scripts/runtime-ir/test-memtrack-link.sh, one scenario per
 * process (argv[1]); the script checks the exit status and the files written
 * in the current directory.
 *
 * The golden scenarios (FALSE-DEREF, FALSE-FREE, FALSE-FREE-RESOLVED,
 * FALSE-MEMTRACK, NONE, UNKNOWN, POSIX-MEMALIGN) make the calls of
 * tests/legacy_golden/drivers/<TAG>.c with witness on, at the same fixed
 * addresses, so their files are compared with the C runtime's goldens.
 */
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>

/* AnalysisMode.h and AnalysisModeMemtrack.c of Map2Check develop. */
void analysis_init(void);
void analysis_destroy(void);
char analysis_is_program_correct(void);
void analysis_generate_aux_witness_files(void);
void map2check_load(void *ptr, int size);
void map2check_check_cstring(const char *string);
void map2check_free_resolved_address(void *ptr, unsigned line, const char *function_name,
                                     short int isNullValid);
void map2check_add_store_pointer(void *var, void *value, unsigned scope, const char *name,
                                 int line, const char *function_name);
void map2check_check_deref(int line, const char *function_name);
void map2check_malloc(void *ptr, int size);
void map2check_posix(void *ptr, int size);
void map2check_calloc(void *ptr, int quantity, int size);
void map2check_alloca(const char *name, void *ptr, int size, int size_of_primitive, int line,
                      int scope);
void map2check_non_static_alloca(const char *name, void *ptr, int size, int size_of_primitive,
                                 int line, int scope);
void map2check_function(const char *name, void *ptr);
void map2check_free(const char *name, void *ptr, unsigned scope, unsigned line,
                    const char *function_name);
void map2check_wasm_malloc(uint64_t offset, uint64_t size);
void map2check_wasm_free(uint64_t offset, int line);
void map2check_wasm_check_access(uint64_t offset, uint64_t access_size);
/* Map2CheckFunctions.h and NonDetLog.h (Rust core). */
void map2check_init(int);
void map2check_success(void);
void map2check_enable_witness(void);
void map2check_track_bb(unsigned line, const char *function_name);
void map2check_nondet_int(unsigned line, unsigned scope, int value, const char *function_name);
void map2check_nondet_uint(unsigned line, unsigned scope, int value, const char *function_name);
void map2check_nondet_char(unsigned line, unsigned scope, int value, const char *function_name);
void map2check_nondet_long(unsigned line, unsigned scope, int value, const char *function_name);
void map2check_nondet_double(unsigned line, unsigned scope, double value,
                             const char *function_name);

int __map2check_main__(void) { return 0; }

/* tests/legacy_golden/drivers/golden.h */
#define GOLDEN_ARENA 0x10000000UL
#define GOLDEN_ARENA_SIZE 4096UL
#define SLOT_P ((void *)(GOLDEN_ARENA + 0x0))
#define FN_MAIN ((void *)(GOLDEN_ARENA + 0x40))
#define BLOCK ((void *)(GOLDEN_ARENA + 0x100))
#define WILD ((void *)(GOLDEN_ARENA + 0x800))
#define SLOT_Q ((void *)(GOLDEN_ARENA + 0x8))
#define BLOCK2 ((void *)(GOLDEN_ARENA + 0x200))

static void golden_arena(void) {
  void *arena = mmap((void *)GOLDEN_ARENA, GOLDEN_ARENA_SIZE, PROT_READ | PROT_WRITE,
                     MAP_PRIVATE | MAP_ANONYMOUS | MAP_FIXED_NOREPLACE, -1, 0);
  if (arena != (void *)GOLDEN_ARENA) {
    fprintf(stderr, "memtrack_link: cannot map the arena\n");
    exit(2);
  }
}

static void golden_tracking(void) {
  map2check_track_bb(3, "main");
  map2check_track_bb(4, "main");
  map2check_track_bb(3, "main");
  map2check_nondet_int(5, 0, 42, "main");
  map2check_nondet_uint(6, 0, (int)4000000000u, "main");
  map2check_nondet_char(7, 0, (int)(unsigned char)(char)-3, "main");
  map2check_nondet_long(8, 0, -7, "main");
  map2check_nondet_double(9, 0, 2.5, "main");
}

static void golden_memory(void) {
  map2check_alloca("p", SLOT_P, 8, 8, 10, 1);
  map2check_function("main", FN_MAIN);
  map2check_malloc(BLOCK, 16);
  *(void **)SLOT_P = BLOCK;
  map2check_add_store_pointer(SLOT_P, BLOCK, 1, "p", 11, "main");
}

static int is(const char *c, const char *name) { return strcmp(c, name) == 0; }

int main(int argc, char **argv) {
  const char *c = argc > 1 ? argv[1] : "";
  golden_arena();
  int golden = is(c, "FALSE-DEREF") || is(c, "FALSE-FREE") || is(c, "FALSE-FREE-RESOLVED") ||
               is(c, "FALSE-MEMTRACK") || is(c, "NONE") || is(c, "UNKNOWN") ||
               is(c, "POSIX-MEMALIGN");
  if (golden)
    map2check_enable_witness(); /* the goldens are witness binaries */
  /* In C, map2check_init calls analysis_init (Map2CheckFunctions.c:37); so does
   * the drop-in core (feature dropin, scripts/runtime-ir/test-init-wiring.sh).
   * This staticlib has no such feature, so the call is made by hand; a
   * second call would be harmless in both runtimes (new empty logs). */
  map2check_init(0);
  analysis_init();
  if (golden) {
    golden_tracking();
    golden_memory();
  }
  if (is(c, "FALSE-DEREF")) {
    map2check_load(WILD, 4);
    map2check_check_deref(14, "main");
  } else if (is(c, "FALSE-FREE")) {
    map2check_free("p", SLOT_P, 1, 12, "main");
    map2check_free("p", SLOT_P, 1, 13, "main");
  } else if (is(c, "FALSE-FREE-RESOLVED")) {
    map2check_free("p", SLOT_P, 1, 12, "main");
    map2check_free_resolved_address(BLOCK, 13, "main", 0);
  } else if (is(c, "FALSE-MEMTRACK")) {
  } else if (is(c, "NONE")) {
    map2check_free("p", SLOT_P, 1, 12, "main");
  } else if (is(c, "UNKNOWN")) {
    map2check_malloc(NULL, 4);
  } else if (is(c, "POSIX-MEMALIGN")) {
    map2check_alloca("q", SLOT_Q, 8, 8, 15, 1);
    *(void **)SLOT_Q = BLOCK2;
    map2check_posix(SLOT_Q, 32);
  } else if (is(c, "non-heap-free")) {
    /* int x; int *p = &x; free(p); */
    map2check_alloca("x", BLOCK, 4, 4, 3, 1);
    *(void **)SLOT_P = BLOCK;
    map2check_add_store_pointer(SLOT_P, BLOCK, 1, "p", 4, "main");
    map2check_free("p", SLOT_P, 1, 50, "main");
  } else if (is(c, "cstring-beyond")) {
    /* char *s = malloc(4); memcpy(s, "abcd", 4); puts(s); */
    memcpy(BLOCK, "abcd", 4);
    map2check_malloc(BLOCK, 4);
    map2check_check_cstring(BLOCK);
    map2check_check_deref(51, "main");
  } else if (is(c, "wasm-free")) {
    map2check_wasm_malloc(0x400, 16);
    map2check_wasm_free(0x400, 60);
    map2check_wasm_free(0x800, 61);
  } else if (is(c, "wasm-access")) {
    map2check_wasm_malloc(0x400, 16);
    map2check_wasm_check_access(0x40c, 4);
    map2check_wasm_check_access(0x40d, 4);
  } else if (is(c, "wasm-shared-log")) {
    /* Tells the IR forwarders from the legacy map2check_wasm_* exports
     * (feature wasm, own table), both defined under
     * --allow-multiple-definition. The IR shares develop's allocation log
     * with map2check_malloc (AnalysisModeMemtrack.c:403-436): the access and
     * the free of BLOCK are valid and the wasm block leaks (FALSE-MEMTRACK).
     * The legacy table never saw BLOCK: OVERFLOW at the access. */
    map2check_malloc(BLOCK, 16);
    map2check_wasm_check_access((uint64_t)(uintptr_t)BLOCK, 4);
    map2check_wasm_free((uint64_t)(uintptr_t)BLOCK, 70);
    map2check_wasm_malloc(0x400, 8);
  } else if (is(c, "valid")) {
    /* char *s = calloc(2, 2); strcpy(s, "ab"); puts(s); free(s); a VLA; a
     * NULL realloc argument; then the end-of-program hooks. */
    char *vla = (char *)(GOLDEN_ARENA + 0x300);
    map2check_non_static_alloca("vla", vla, 2, 4, 20, 1);
    map2check_load(vla + 4, 4);
    memcpy(BLOCK, "ab", 3);
    map2check_calloc(BLOCK, 2, 2);
    map2check_add_store_pointer(SLOT_P, BLOCK, 1, "s", 21, "main");
    *(void **)SLOT_P = BLOCK;
    map2check_check_cstring(BLOCK);
    map2check_check_deref(22, "main");
    map2check_free_resolved_address(NULL, 23, "main", 1);
    map2check_free("s", SLOT_P, 1, 24, "main");
    if (analysis_is_program_correct() != 1)
      return 3;
    analysis_generate_aux_witness_files();
    analysis_destroy();
  } else if (is(c, "leak-verdict")) {
    map2check_malloc(BLOCK, 16);
    /* AnalysisModeMemtrack.c:138-146: writes FALSE-MEMTRACK, returns FALSE,
     * does not end the run; the leak is then released. */
    if (analysis_is_program_correct() != 0)
      return 3;
    if (analysis_is_program_correct() != 1)
      return 4;
    analysis_generate_aux_witness_files();
    return 0;
  } else {
    fprintf(stderr, "unknown scenario '%s'\n", c);
    return 2;
  }
  map2check_success();
  return 0;
}
