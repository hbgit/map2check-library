/* SPDX-License-Identifier: GPL-3.0-only
 *
 * Stress harness of the C ABI of libmap2check.a (M2 acceptance criterion,
 * rewritten against the C runtime ABI in Task 2.10, D6): every function
 * `include/map2check.h` declares -- the core names of the C runtime of
 * Map2Check develop and the `__m2c_rt_*` core entry points the IR modules
 * forward to -- must be reachable from C, survive hostile inputs (null
 * pointers, garbage strings, extreme values, pre-init calls) and run clean
 * under ASan+UBSan (no abort, no UB).
 *
 * The harness is linked as Map2Check links a program (D7): with the
 * staticlib, the glue IR of Map2CheckFunctions.bc (map2check_assume*) and the
 * AFL++ generator module NonDetGeneratorAFL.ll, whose `main` runs
 * `__map2check_main__` once per input of `__AFL_LOOP` and whose
 * `nondet_assume` abandons an input with `longjmp` back to that loop
 * (scripts/build-c-abi-program.sh; the command is in CLAUDE.md and CI). The
 * afl-compiler-rt symbols the module imports are played by this file: its
 * `__afl_persistent_loop` hands the module a scripted list of inputs.
 *
 * Input 0 runs the rounds (pre-init boundary calls, hostile calls, a valid
 * pass, the state checks and the forked mode scenarios); the inputs after it
 * are the fuzzer iterations: independent state per iteration, and a failed
 * assume that abandons only the current input (develop: nondet_cancel).
 */
#include <signal.h>
#include <stdbool.h>
#include <stdint.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/wait.h>
#include <unistd.h>

#include "map2check.h"

/* Issue #28: o header gerado expõe a versão do crate. */
#ifndef MAP2CHECK_VERSION
#error "map2check.h não define MAP2CHECK_VERSION"
#endif

/* The C runtime names the IR modules define (Map2CheckFunctions.h,
 * NonDetGenerator.h): Map2CheckFunctions-glue.ll and NonDetGeneratorAFL.ll. */
void map2check_assume(int expr);
void map2check_crab_assume(char expr);
void map2check_assume_loop(char expr);
int map2check_non_det_int(void);
unsigned map2check_non_det_uint(void);
unsigned map2check_non_det_unsigned(void);
char map2check_non_det_char(void);
unsigned char map2check_non_det_uchar(void);
short map2check_non_det_short(void);
unsigned short map2check_non_det_ushort(void);
long map2check_non_det_long(void);
unsigned long map2check_non_det_ulong(void);
long long map2check_non_det_longlong(void);
unsigned long long map2check_non_det_ulonglong(void);
int map2check_non_det_bool(void);
float map2check_non_det_float(void);
double map2check_non_det_double(void);
size_t map2check_non_det_size_t(void);
long long map2check_non_det_loff_t(void);
unsigned long map2check_non_det_sector_t(void);
void *map2check_non_det_pointer(void);
char *map2check_non_det_pchar(void);
uint8_t map2check_non_det_u8(void);
uint16_t map2check_non_det_u16(void);
uint32_t map2check_non_det_u32(void);

/* wabt 1.0.41 layouts (wasm-rt.h:437-529), as tests/runtime-ir/wasm_link.c. */
typedef struct {
    uint8_t *data;
    uint8_t *data_end;
    uint32_t page_size;
    uint64_t pages, max_pages;
    uint64_t size;
    bool is64;
} harness_wasm_memory_t;

typedef struct {
    const char *func_type;
    void (*func)(void);
    void *func_tailcallee;
    void *module_instance;
} harness_wasm_funcref_t;

typedef struct {
    harness_wasm_funcref_t *data;
    uint32_t max_size;
    uint32_t size;
} harness_wasm_funcref_table_t;

static void harness_fail(const char *what) {
    fprintf(stderr, "ffi_harness: %s\n", what);
    fflush(stderr);
    _exit(1);
}

#define REQUIRE(cond)                                   \
    do {                                                \
        if (!(cond)) {                                  \
            harness_fail("check failed: " #cond);       \
        }                                               \
    } while (0)

/* ── afl-compiler-rt, played by the harness ───────────────────────────────
 * NonDetGeneratorAFL.ll reads the input through __afl_fuzz_ptr and
 * *__afl_fuzz_len (shared-memory mode) and loops while
 * __afl_persistent_loop returns nonzero. */
enum phase {
    PHASE_ROUNDS,
    PHASE_INDEPENDENT_1,
    PHASE_INDEPENDENT_2,
    PHASE_REJECT,
    PHASE_ACCEPT,
    PHASE_WRAPPED,
    PHASE_DONE
};

static const uint8_t in_empty[1] = {0};
static const uint8_t in_first[] = {0x01, 0x02, 0x03, 0x04};
static const uint8_t in_second[] = {0xa0, 0xb0};
static const uint8_t in_rejected[] = {0x00, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00};
static const uint8_t in_accepted[] = {0x00, 0x00, 0x00, 0x00, 0x07, 0x00, 0x00, 0x00};
static const uint8_t in_wrapped[] = {0x07};
#define REJECTIONS 100

uint8_t *__afl_fuzz_ptr;
static unsigned int harness_len;
unsigned int *__afl_fuzz_len = &harness_len;
int __afl_connected = 0;

static int input_index;
static enum phase phase;
static int harness_after_assume;
static int harness_completed;

static void feed(enum phase p, const uint8_t *data, unsigned int len) {
    phase = p;
    __afl_fuzz_ptr = (uint8_t *)data;
    harness_len = len;
}

int __afl_persistent_loop(int max) {
    (void)max;
    int i = input_index++;
    if (i == 0) {
        feed(PHASE_ROUNDS, in_empty, 0);
    } else if (i == 1) {
        feed(PHASE_INDEPENDENT_1, in_first, sizeof(in_first));
    } else if (i == 2) {
        feed(PHASE_INDEPENDENT_2, in_second, sizeof(in_second));
    } else if (i < 3 + REJECTIONS) {
        feed(PHASE_REJECT, in_rejected, sizeof(in_rejected));
    } else if (i == 3 + REJECTIONS) {
        feed(PHASE_ACCEPT, in_accepted, sizeof(in_accepted));
    } else if (i == 4 + REJECTIONS) {
        feed(PHASE_WRAPPED, in_wrapped, sizeof(in_wrapped));
    } else if (i == 5 + REJECTIONS) {
        feed(PHASE_DONE, in_empty, 0);
    } else {
        return 0;
    }
    return 1;
}

static void harness_require_completion(void) {
    if (!harness_completed) {
        fprintf(stderr, "ffi_harness: process ended before the last input ran\n");
        _exit(97);
    }
}

/* Calls every map2check_nondet_<t> of NonDetLog.h with `line`, `scope`,
 * the values of `v` and `fn`. */
static void nondet_log_all(unsigned line, unsigned scope, int v, double d,
                           long long ll, unsigned long long ull, unsigned u,
                           const char *fn) {
    map2check_nondet_bool(line, scope, v, fn);
    map2check_nondet_char(line, scope, v, fn);
    map2check_nondet_double(line, scope, d, fn);
    map2check_nondet_float(line, scope, d, fn);
    map2check_nondet_int(line, scope, v, fn);
    map2check_nondet_loff_t(line, scope, v, fn);
    map2check_nondet_long(line, scope, v, fn);
    map2check_nondet_longlong(line, scope, ll, fn);
    map2check_nondet_memory_byte(line, scope, v, fn);
    map2check_nondet_pchar(line, scope, v, fn);
    map2check_nondet_pointer(line, scope, v, fn);
    map2check_nondet_sector_t(line, scope, v, fn);
    map2check_nondet_short(line, scope, v, fn);
    map2check_nondet_size_t(line, scope, v, fn);
    map2check_nondet_u16(line, scope, v, fn);
    map2check_nondet_u32(line, scope, v, fn);
    map2check_nondet_u8(line, scope, v, fn);
    map2check_nondet_uchar(line, scope, v, fn);
    map2check_nondet_uint(line, scope, v, fn);
    map2check_nondet_ulong(line, scope, v, fn);
    map2check_nondet_ulonglong(line, scope, ull, fn);
    map2check_nondet_unsigned(line, scope, u, fn);
    map2check_nondet_ushort(line, scope, v, fn);
}

/* The wasm2c runtime entry points on a real descriptor (no trap: it never
 * returns, so it runs in a forked scenario). */
static void wasm_round(uint64_t pages, uint64_t grow, uint32_t page_size,
                       uint32_t elements) {
    harness_wasm_memory_t mem;
    harness_wasm_funcref_table_t table;
    memset(&mem, 0, sizeof mem);
    memset(&table, 0, sizeof table);
    __m2c_rt_wasm_allocate_memory(&mem, pages, pages + 2, false, page_size);
    (void)__m2c_rt_wasm_grow_memory(&mem, grow);
    __m2c_rt_wasm_free_memory(&mem);
    __m2c_rt_wasm_free_memory(&mem);
    __m2c_rt_wasm_allocate_funcref_table(&table, elements, elements);
    __m2c_rt_wasm_free_funcref_table(&table);
    __m2c_rt_wasm_free_funcref_table(&table);
    __m2c_rt_wasm_free();
    (void)__m2c_rt_wasm_is_initialized();
    __m2c_rt_wasm_init();
    (void)__m2c_rt_wasm_is_initialized();
}

/* ── Round 0 (issue #8): every export called BEFORE map2check_init(), with
 * valid boundary inputs only: NULL where a pointer is allowed, real
 * stack/heap addresses, valid C strings and zero sizes. Nothing that selects
 * a mode or turns the witness on (analysis_init, __m2c_rt_witness_enable):
 * that is configuration the forked scenarios below would inherit. ──────── */
static void run_pre_init_boundary(void) {
    int stack_obj = 0;
    void *heap_obj = malloc(8);
    void *slot = heap_obj;
    char cstr[] = "ok";
    REQUIRE(heap_obj != NULL);

    /* Map2CheckFunctions.h, TrackBBLog.h, PropertyGenerator.h */
    (void)map2check_get_current_step();
    map2check_next_current_step();
    map2check_track_bb(1, "main");
    __VERIFIER_error();
    map2check_target_function("main", 0, 1); /* no mode: records, returns */
    map2check_error();                       /* no mode: returns */
    map2check_exit();                        /* no mode: returns */
    map2check_destroy();
    write_property(None, 0, "");
    write_property(MemsafetyFree, 1, "main");

    /* NonDetLog.h */
    nondet_log_init();
    nondet_log_all(1, 0, -1, 1.5, -1LL, ~0ULL, 0xffffffffu, "main");
    nondet_log_all(1, 0, 0, 0.0, 0, 0, 0, NULL);
    (void)__m2c_rt_nondet_log_len();
    (void)__m2c_rt_nondet_log_get_i64(0);
    __m2c_rt_nondet_log_set_i64(0, 7);
    (void)__m2c_rt_nondet_log_to_file();
    __m2c_rt_output_set_atomic(1); /* the default of the host build */
    nondet_log_destroy();

    /* WitnessGeneration */
    __m2c_rt_witness_generate_aux_files(NULL, 0);
    __m2c_rt_witness_generate_aux_files(NULL, 1);
    __m2c_rt_witness_generate_confirmation_file();

    /* AnalysisModeOverflow core entry points */
    __m2c_rt_overflow_map2check_binop_add(1, 1, 32, 1, 0, "main");
    __m2c_rt_overflow_map2check_binop_sub(1, 1, 32, 1, 0, "main");
    __m2c_rt_overflow_map2check_binop_mul(1, 1, 32, 1, 0, "main");
    __m2c_rt_overflow_map2check_binop_sdiv(1, 1, 32, 1, 0, "main");
    __m2c_rt_overflow_map2check_binop_srem(1, 1, 32, 1, 0, "main");
    __m2c_rt_overflow_map2check_binop_add_uint(1, 1, 32, 1, 0, "main");
    __m2c_rt_overflow_map2check_binop_sub_uint(1, 1, 32, 1, 0, "main");
    __m2c_rt_overflow_map2check_binop_mul_uint(1, 1, 32, 1, 0, "main");
    (void)__m2c_rt_overflow_analysis_is_program_correct();
    __m2c_rt_overflow_analysis_destroy();
    __m2c_rt_overflow_analysis_generate_aux_witness_files();

    /* AnalysisModeAssert / AnalysisModeNone */
    __m2c_rt_assert_map2check_assert(1, 1, "main");
    (void)__m2c_rt_assert_analysis_is_program_correct();
    __m2c_rt_assert_analysis_destroy();
    __m2c_rt_assert_analysis_generate_aux_witness_files();
    (void)__m2c_rt_none_analysis_is_program_correct();
    __m2c_rt_none_analysis_destroy();
    __m2c_rt_none_analysis_generate_aux_witness_files();

    /* AnalysisModeMemtrack: a stack slot that points to a tracked block. */
    __m2c_rt_memtrack_map2check_alloca("x", &stack_obj, 4, 4, 1, 1);
    __m2c_rt_memtrack_map2check_non_static_alloca("v", &stack_obj, 1, 4, 1, 1);
    __m2c_rt_memtrack_map2check_function("main", (void *)&run_pre_init_boundary);
    __m2c_rt_memtrack_map2check_malloc(heap_obj, 8);
    __m2c_rt_memtrack_map2check_calloc(heap_obj, 2, 4);
    __m2c_rt_memtrack_map2check_posix(&slot, 8);
    __m2c_rt_memtrack_map2check_add_store_pointer(&slot, heap_obj, 1, "p", 1, "main");
    __m2c_rt_memtrack_map2check_load(heap_obj, 4);
    __m2c_rt_memtrack_map2check_check_cstring(cstr);
    __m2c_rt_memtrack_map2check_check_deref(1, "main");
    __m2c_rt_memtrack_map2check_free_resolved_address(NULL, 1, "main", 1);
    __m2c_rt_memtrack_map2check_free("p", &slot, 1, 1, "main");
    __m2c_rt_memtrack_map2check_wasm_malloc(0x400, 16);
    __m2c_rt_memtrack_map2check_wasm_check_access(0x400, 4);
    __m2c_rt_memtrack_map2check_wasm_free(0x400, 1);
    (void)__m2c_rt_memtrack_analysis_is_program_correct();
    __m2c_rt_memtrack_analysis_generate_aux_witness_files();
    __m2c_rt_memtrack_analysis_destroy();

    /* AnalysisModeMemcleanup */
    slot = heap_obj;
    __m2c_rt_memcleanup_map2check_alloca("x", &stack_obj, 4, 4, 1, 1);
    __m2c_rt_memcleanup_map2check_non_static_alloca("v", &stack_obj, 1, 4, 1, 1);
    __m2c_rt_memcleanup_map2check_function("main", (void *)&run_pre_init_boundary);
    __m2c_rt_memcleanup_map2check_malloc(heap_obj, 8);
    __m2c_rt_memcleanup_map2check_calloc(heap_obj, 2, 4);
    __m2c_rt_memcleanup_map2check_posix(&slot, 8);
    __m2c_rt_memcleanup_map2check_add_store_pointer(&slot, heap_obj, 1, "p", 1, "main");
    __m2c_rt_memcleanup_map2check_load(heap_obj, 4);
    __m2c_rt_memcleanup_map2check_check_cstring(cstr);
    __m2c_rt_memcleanup_map2check_check_deref(1, "main");
    __m2c_rt_memcleanup_map2check_free_resolved_address(NULL, 1, "main", 1);
    __m2c_rt_memcleanup_map2check_free("p", &slot, 1, 1, "main");
    (void)__m2c_rt_memcleanup_analysis_is_program_correct();
    __m2c_rt_memcleanup_analysis_generate_aux_witness_files();
    __m2c_rt_memcleanup_analysis_destroy();

    /* WasmRuntimeStubs */
    wasm_round(1, 1, 65536, 4);
    wasm_round(0, 0, 0, 0);

    map2check_success(); /* no mode: prints the JSON report, returns */
    free(heap_obj);
}

/* ── Round 1: hostile calls *before* map2check_init() (and, as round 3,
 * after it): null pointers, empty strings, extreme values. ──────────────── */
static void run_bad_inputs(void) {
    /* Map2CheckFunctions.h, TrackBBLog.h, PropertyGenerator.h */
    map2check_track_bb(0, NULL);
    map2check_track_bb(UINT32_MAX, "");
    map2check_target_function(NULL, -1, -1);
    map2check_target_function("", INT32_MIN, INT32_MAX);
    write_property(Concurrency, -1, NULL);
    write_property(DivByZero, INT32_MIN, "");
    map2check_destroy();
    map2check_destroy();
    map2check_error();
    map2check_exit();

    /* NonDetLog.h */
    nondet_log_destroy();
    nondet_log_all(UINT32_MAX, UINT32_MAX, INT32_MIN, -0.0, INT64_MIN, UINT64_MAX, 0, NULL);
    nondet_log_all(0, 0, INT32_MAX, 1e308, INT64_MAX, 0, UINT32_MAX, "");
    (void)__m2c_rt_nondet_log_get_i64(UINT32_MAX);
    __m2c_rt_nondet_log_set_i64(UINT32_MAX, INT64_MIN);
    nondet_log_destroy();
    (void)__m2c_rt_nondet_log_len();
    nondet_log_init();
    nondet_log_init();

    /* Witness entry points with a NULL container and any flag value. */
    __m2c_rt_witness_generate_aux_files(NULL, (char)0xff);

    /* Overflow family: null function names and extreme values. */
    __m2c_rt_overflow_map2check_binop_add(INT64_MAX, 1, 0, 12, 99, NULL);
    __m2c_rt_overflow_map2check_binop_sub(INT64_MIN, 1, 4096, 12, 0, NULL);
    __m2c_rt_overflow_map2check_binop_mul(INT64_MIN, -1, 64, 12, 0, NULL);
    __m2c_rt_overflow_map2check_binop_sdiv(INT64_MIN, -1, 1, 12, 0, NULL);
    __m2c_rt_overflow_map2check_binop_srem(1, 0, 0xffffffffu, 12, 0, NULL);
    __m2c_rt_overflow_map2check_binop_add_uint(UINT64_MAX, 1, 33, 12, 0, NULL);
    __m2c_rt_overflow_map2check_binop_sub_uint(0, UINT64_MAX, 0, 12, 0, NULL);
    __m2c_rt_overflow_map2check_binop_mul_uint(UINT64_MAX, UINT64_MAX, 64, 12, 0, NULL);
    __m2c_rt_overflow_overflowError(0xffffffffu, NULL);
    __m2c_rt_assert_map2check_assert(1, -1, NULL);
    __m2c_rt_assert_map2check_assert(7, 0x7fffffff, NULL);

    /* Memtrack and memcleanup: NULL names and slots, int wrap-around. */
    __m2c_rt_memtrack_map2check_alloca(NULL, NULL, -1, INT32_MIN, -1, -1);
    __m2c_rt_memtrack_map2check_non_static_alloca(NULL, (void *)0x7000, INT32_MAX, INT32_MAX, 0, 0);
    __m2c_rt_memtrack_map2check_function(NULL, NULL);
    __m2c_rt_memtrack_map2check_malloc(NULL, -1);
    __m2c_rt_memtrack_map2check_calloc((void *)0x7100, INT32_MAX, INT32_MAX);
    __m2c_rt_memtrack_map2check_calloc((void *)0x7200, INT32_MIN, -1);
    __m2c_rt_memtrack_map2check_load((void *)UINTPTR_MAX, INT32_MIN);
    __m2c_rt_memtrack_map2check_load(NULL, INT32_MAX);
    __m2c_rt_memtrack_map2check_add_store_pointer(NULL, NULL, 0xffffffffu, NULL, INT32_MIN, NULL);
    __m2c_rt_memtrack_map2check_free(NULL, NULL, 0, 0, NULL);
    __m2c_rt_memtrack_map2check_posix(NULL, -1);
    __m2c_rt_memtrack_map2check_check_cstring(NULL);
    __m2c_rt_memtrack_map2check_check_deref(INT32_MIN, NULL);
    __m2c_rt_memtrack_map2check_free_resolved_address((void *)0x7100, 0xffffffffu, NULL, -1);
    __m2c_rt_memtrack_map2check_wasm_malloc(UINT64_MAX, UINT64_MAX);
    __m2c_rt_memtrack_map2check_wasm_malloc(0, 0);
    __m2c_rt_memtrack_map2check_wasm_check_access(UINT64_MAX, UINT64_MAX);
    __m2c_rt_memtrack_map2check_wasm_free(UINT64_MAX, INT32_MIN);
    (void)__m2c_rt_memtrack_analysis_is_program_correct();
    __m2c_rt_memtrack_analysis_destroy();
    __m2c_rt_memtrack_analysis_destroy();
    __m2c_rt_memcleanup_map2check_alloca(NULL, NULL, -1, INT32_MIN, -1, -1);
    __m2c_rt_memcleanup_map2check_non_static_alloca(NULL, (void *)0x7000, INT32_MAX, INT32_MAX, 0, 0);
    __m2c_rt_memcleanup_map2check_function(NULL, NULL);
    __m2c_rt_memcleanup_map2check_malloc(NULL, -1);
    __m2c_rt_memcleanup_map2check_calloc((void *)0x7200, INT32_MIN, -1);
    __m2c_rt_memcleanup_map2check_load(NULL, INT32_MAX);
    __m2c_rt_memcleanup_map2check_add_store_pointer(NULL, NULL, 0xffffffffu, NULL, INT32_MIN, NULL);
    __m2c_rt_memcleanup_map2check_free(NULL, NULL, 0, 0, NULL);
    __m2c_rt_memcleanup_map2check_posix(NULL, -1);
    __m2c_rt_memcleanup_map2check_check_cstring(NULL);
    __m2c_rt_memcleanup_map2check_check_deref(INT32_MIN, NULL);
    __m2c_rt_memcleanup_map2check_free_resolved_address((void *)0x7100, 0xffffffffu, NULL, -1);
    (void)__m2c_rt_memcleanup_analysis_is_program_correct();
    __m2c_rt_memcleanup_analysis_destroy();

    /* wasm2c runtime: zero pages, a wrapping grow, zero elements. */
    wasm_round(0, UINT64_MAX, 1, 0);
    wasm_round(2, 0, 0, 1);
}

/* ── Round 2: a well-formed pass after map2check_init(), touching every
 * family with sane arguments and checking what the C ABI exposes. ───────── */
static void run_valid_pass(void) {
    REQUIRE(map2check_get_current_step() == 0);
    map2check_next_current_step();
    map2check_next_current_step();
    REQUIRE(map2check_get_current_step() == 2);
    map2check_track_bb(26, "main");
    map2check_track_bb(26, "other"); /* same line: no new row */
    __VERIFIER_error();
    REQUIRE(map2check_get_current_step() == 2);

    /* NonDetLog.c:105-150: one row per call, the value zero-extended. */
    nondet_log_init();
    REQUIRE(__m2c_rt_nondet_log_len() == 0);
    map2check_nondet_int(27, 0, 42, "main");
    map2check_nondet_int(27, 0, -1, "main");
    map2check_nondet_double(28, 0, 1.5, "main");
    REQUIRE(__m2c_rt_nondet_log_len() == 3);
    REQUIRE(__m2c_rt_nondet_log_get_i64(0) == 42);
    REQUIRE(__m2c_rt_nondet_log_get_i64(1) == 0xffffffffLL);
    __m2c_rt_nondet_log_set_i64(0, 7);
    REQUIRE(__m2c_rt_nondet_log_get_i64(0) == 7);
    REQUIRE(__m2c_rt_nondet_log_get_i64(3) == 0); /* out of range */
    nondet_log_all(29, 1, 3, 2.5, 3, 3, 3, "main");
    REQUIRE(__m2c_rt_nondet_log_len() == 3 + 23);
    nondet_log_destroy();
    REQUIRE(__m2c_rt_nondet_log_len() == 0);

    /* No mode: the checks record and return; the first violation is final. */
    __m2c_rt_overflow_map2check_binop_add(1, 2, 32, 29, 0, "main");
    __m2c_rt_overflow_map2check_binop_mul_uint(2, 3, 8, 29, 0, "main");
    __m2c_rt_assert_map2check_assert(1, 28, "main");
    REQUIRE(__m2c_rt_overflow_analysis_is_program_correct() == 1);
    REQUIRE(__m2c_rt_assert_analysis_is_program_correct() == 1);
    REQUIRE(__m2c_rt_none_analysis_is_program_correct() == 1);
    {
        void *block = malloc(16);
        void *slot = block;
        REQUIRE(block != NULL);
        __m2c_rt_memtrack_map2check_alloca("p", &slot, 8, 8, 20, 1);
        __m2c_rt_memtrack_map2check_malloc(block, 16);
        __m2c_rt_memtrack_map2check_add_store_pointer(&slot, block, 1, "p", 21, "main");
        __m2c_rt_memtrack_map2check_load(block, 4);
        __m2c_rt_memtrack_map2check_check_deref(22, "main");
        __m2c_rt_memtrack_map2check_free("p", &slot, 1, 23, "main");
        REQUIRE(__m2c_rt_memtrack_analysis_is_program_correct() == 1);
        __m2c_rt_memtrack_analysis_destroy();
        free(block);
    }
    wasm_round(1, 1, 65536, 4);
    REQUIRE(__m2c_rt_wasm_is_initialized());
}

/* ── Forked scenarios (Tasks 2.1-2.9): with a mode selected by the
 * analysis_init of its module, the first violation writes the result files
 * and aborts, and map2check_success() writes NONE and returns, as the C
 * runtime of Map2Check develop does. Each runs in a child inside its own
 * temporary directory; the parent checks how the child ended and what it
 * wrote. No mode is selected in this process. ─────────────────────────── */
typedef void (*scenario_fn)(void);

static const char *const result_files[] = {
    "map2check_property", "map2check_property__unknown",
    "map2check_property_memtrack", "map2check_property_memcleanup",
    "map2check_property_deref", "map2check_property_free",
    "map2check_property_overflow", "map2check_property_assert",
    "map2check_checked_error", "track_bb_log.st", "klee_log.csv",
    "list_log.csv", "allocation_log.csv", "heap_log.csv", NULL};

/* Reads `name` from `dir` into `buf` (NUL-terminated); "" when missing. */
static void read_result(const char *dir, const char *name, char *buf,
                        size_t size) {
    char path[512];
    snprintf(path, sizeof(path), "%s/%s", dir, name);
    buf[0] = '\0';
    FILE *f = fopen(path, "r");
    if (f == NULL) {
        return;
    }
    size_t n = fread(buf, 1, size - 1, f);
    buf[n] = '\0';
    fclose(f);
}

static void remove_results(const char *dir) {
    char path[512];
    for (int i = 0; result_files[i] != NULL; i++) {
        snprintf(path, sizeof(path), "%s/%s", dir, result_files[i]);
        unlink(path);
    }
    rmdir(dir);
}

/* Runs `scenario` in a child. `aborts`: whether it must end with SIGABRT
 * (otherwise exit 0). `property`: expected map2check_property content ("" =
 * absent). `extra`: one more file to check, or NULL; `extra_content`: its
 * expected content, or NULL when the file must not exist. */
static int run_mode_scenario(scenario_fn scenario, int aborts,
                             const char *property, const char *extra,
                             const char *extra_content) {
    char dir[] = "/tmp/map2check-harness-XXXXXX";
    if (mkdtemp(dir) == NULL) {
        return 1;
    }
    fflush(NULL);
    pid_t pid = fork();
    if (pid < 0) {
        return 1;
    }
    if (pid == 0) {
        if (chdir(dir) != 0) {
            _exit(90);
        }
        scenario();
        _exit(0);
    }
    int status = 0;
    int failed = waitpid(pid, &status, 0) != pid;
    if (aborts) {
        failed |= !(WIFSIGNALED(status) && WTERMSIG(status) == SIGABRT);
    } else {
        failed |= !(WIFEXITED(status) && WEXITSTATUS(status) == 0);
    }
    char buf[256];
    read_result(dir, "map2check_property", buf, sizeof(buf));
    failed |= strcmp(buf, property) != 0;
    if (extra != NULL && extra_content == NULL) {
        char path[512];
        snprintf(path, sizeof(path), "%s/%s", dir, extra);
        failed |= access(path, F_OK) == 0;
    } else if (extra != NULL) {
        read_result(dir, extra, buf, sizeof(buf));
        failed |= strcmp(buf, extra_content) != 0;
    }
    remove_results(dir);
    return failed;
}

static void *harness_slot;

/* None mode (AnalysisModeNone.c): __VERIFIER_error does nothing, the run
 * ends with NONE. */
static void scenario_none_mode(void) {
    map2check_init(0);
    __m2c_rt_none_analysis_init();
    __VERIFIER_error();
    map2check_success();
}

/* AnalysisModeMemtrack.c:159-185: a load outside every block sets
 * ERROR_DEREF; the next check_deref reports it. */
static void scenario_memtrack_deref(void) {
    map2check_init(0);
    __m2c_rt_memtrack_analysis_init();
    __m2c_rt_memtrack_map2check_load((void *)0xdead, 4);
    __m2c_rt_memtrack_map2check_check_deref(1, "main");
}

static void scenario_memtrack_deref_witness(void) {
    __m2c_rt_witness_enable();
    scenario_memtrack_deref();
}

/* Assert mode with every assert satisfied: NONE, no abort. */
static void scenario_assert_holds(void) {
    map2check_init(0);
    __m2c_rt_assert_analysis_init();
    __m2c_rt_assert_map2check_assert(1, 2, "main");
    __m2c_rt_assert_map2check_assert(-5, 3, "main");
    map2check_success();
}

/* map2check_target_function ends the run in any mode (Map2CheckFunctions.c:61-65). */
static void scenario_target(void) {
    map2check_init(0);
    __m2c_rt_assert_analysis_init();
    map2check_target_function("reach_error", 0, 12);
}

/* The mode is configuration: a second map2check_init keeps it. */
static void scenario_init_keeps_the_mode(void) {
    map2check_init(0);
    __m2c_rt_none_analysis_init();
    map2check_init(1);
    map2check_init(-7);
    map2check_target_function("reach_error", 0, 13);
}

/* Memcleanup mode: an unreferenced leak gives no verdict. */
static void scenario_memcleanup_unreferenced(void) {
    map2check_init(0);
    __m2c_rt_memcleanup_analysis_init();
    void *block = malloc(8);
    __m2c_rt_memcleanup_map2check_malloc(block, 8);
    map2check_success();
    free(block);
}

static void scenario_memcleanup_referenced(void) {
    map2check_init(0);
    __m2c_rt_memcleanup_analysis_init();
    void *block = malloc(8);
    harness_slot = block;
    __m2c_rt_memcleanup_map2check_alloca("p", &harness_slot, 8, 8, 1, 1);
    __m2c_rt_memcleanup_map2check_malloc(block, 8);
    __m2c_rt_memcleanup_map2check_add_store_pointer(&harness_slot, block, 1, "p", 1, "main");
    map2check_success();
}

/* AnalysisModeOverflow.bc forwards analysis_init and the binops to these
 * entry points (Task 2.3). */
static void scenario_overflow_rt_add(void) {
    map2check_init(0);
    __m2c_rt_overflow_analysis_init();
    __m2c_rt_overflow_map2check_binop_add(2147483647, 1, 32, 20, 0, "main");
}

static void scenario_overflow_rt_srem(void) {
    map2check_init(0);
    __m2c_rt_overflow_analysis_init();
    __m2c_rt_overflow_map2check_binop_srem(5, 0, 32, 7, 0, "main");
}

static void scenario_assert_rt(void) {
    map2check_init(0);
    __m2c_rt_assert_analysis_init();
    __m2c_rt_assert_map2check_assert(1, 20, "main");
    __m2c_rt_assert_map2check_assert(0, 21, "main");
}

static void scenario_none_rt_target(void) {
    map2check_init(0);
    __m2c_rt_none_analysis_init();
    map2check_target_function("reach_error", 0, 22);
}

/* The drop-in memtrack path (Task 2.5). */
static void scenario_memtrack_rt_double_free(void) {
    map2check_init(0);
    __m2c_rt_memtrack_analysis_init();
    void *block = malloc(16);
    harness_slot = block;
    __m2c_rt_memtrack_map2check_alloca("p", &harness_slot, 8, 8, 1, 1);
    __m2c_rt_memtrack_map2check_malloc(block, 16);
    __m2c_rt_memtrack_map2check_add_store_pointer(&harness_slot, block, 1, "p", 2, "main");
    __m2c_rt_memtrack_map2check_free("p", &harness_slot, 1, 3, "main");
    free(block);
    __m2c_rt_memtrack_map2check_free("p", &harness_slot, 1, 4, "main");
}

static void scenario_memtrack_rt_cstring(void) {
    __m2c_rt_witness_enable();
    map2check_init(0);
    __m2c_rt_memtrack_analysis_init();
    char *s = malloc(4);
    memcpy(s, "abcd", 4);
    __m2c_rt_memtrack_map2check_malloc(s, 4);
    __m2c_rt_memtrack_map2check_check_cstring(s);
    __m2c_rt_memtrack_map2check_check_deref(5, "main");
}

static void scenario_memtrack_rt_leak(void) {
    map2check_init(0);
    __m2c_rt_memtrack_analysis_init();
    void *block = malloc(8);
    __m2c_rt_memtrack_map2check_malloc(block, 8);
    __m2c_rt_memtrack_analysis_generate_aux_witness_files();
    if (__m2c_rt_memtrack_analysis_is_program_correct() != 0) {
        _exit(91);
    }
    free(block);
    map2check_success();
}

/* WasmRuntimeStubs.c:110-116: a trap ends the run (SD-19: UNKNOWN). */
static void scenario_wasm_trap(void) {
    map2check_init(0);
    __m2c_rt_wasm_trap(0);
}

static void scenario_wasm_trap_mode(void) {
    map2check_init(0);
    __m2c_rt_memtrack_analysis_init();
    __m2c_rt_wasm_trap(3);
}

static void test_analysis_modes(void) {
    static const struct {
        scenario_fn fn;
        int aborts;
        const char *property, *extra, *extra_content;
    } cases[] = {
        {scenario_none_mode, 0, "NONE\n", NULL, NULL},
        {scenario_memtrack_deref, 1, "FALSE-DEREF\nLine: 1\nFunction: main\n",
         "map2check_checked_error", NULL},
        {scenario_memtrack_deref_witness, 1, "FALSE-DEREF\nLine: 1\nFunction: main\n",
         "map2check_checked_error", "END OF TIME\n"},
        {scenario_assert_holds, 0, "NONE\n", "map2check_property_assert", NULL},
        {scenario_target, 1, "TARGET-REACHED\nLine: 12\nFunction: reach_error\n", NULL, NULL},
        {scenario_init_keeps_the_mode, 1,
         "TARGET-REACHED\nLine: 13\nFunction: reach_error\n", NULL, NULL},
        {scenario_memcleanup_unreferenced, 0, "NONE\n", "map2check_property_memcleanup", NULL},
        {scenario_memcleanup_referenced, 1, "FALSE-MEMCLEANUP\n",
         "map2check_property_memcleanup", "FALSE-MEMCLEANUP\n"},
        {scenario_overflow_rt_add, 1, "OVERFLOW\nLine: 20\nFunction: main\n",
         "map2check_property_overflow", "OVERFLOW\nLine: 20\nFunction: main\n"},
        {scenario_overflow_rt_srem, 1, "FALSE-DIVBYZERO\nLine: 7\nFunction: main\n",
         "map2check_property_overflow", NULL},
        {scenario_assert_rt, 1, "ASSERT\nLine: 21\nFunction: main\n",
         "map2check_property_assert", "ASSERT\nLine: 21\nFunction: main\n"},
        {scenario_none_rt_target, 1, "TARGET-REACHED\nLine: 22\nFunction: reach_error\n",
         NULL, NULL},
        {scenario_memtrack_rt_double_free, 1, "FALSE-FREE\nLine: 4\nFunction: main\n",
         "map2check_property_free", "FALSE-FREE\nLine: 4\nFunction: main\n"},
        {scenario_memtrack_rt_cstring, 1, "FALSE-DEREF\nLine: 5\nFunction: main\n",
         "map2check_checked_error", "END OF TIME\n"},
        /* analysis_is_program_correct wrote FALSE-MEMTRACK and released the
         * leak; map2check_success then overwrites map2check_property with NONE. */
        {scenario_memtrack_rt_leak, 0, "NONE\n", "map2check_property_memtrack",
         "FALSE-MEMTRACK\n"},
        {scenario_wasm_trap, 1, "", "map2check_property__unknown", NULL},
        /* SD-19: with a mode the trap writes only map2check_property__unknown. */
        {scenario_wasm_trap_mode, 1, "", "map2check_property__unknown", "UNKNOWN\n"},
    };
    for (size_t i = 0; i < sizeof cases / sizeof cases[0]; i++) {
        if (run_mode_scenario(cases[i].fn, cases[i].aborts, cases[i].property,
                              cases[i].extra, cases[i].extra_content)) {
            fprintf(stderr, "test_analysis_modes: scenario %zu failed\n", i + 1);
            _exit(1);
        }
    }
}

/* Input 0: the rounds, in a scratch directory (the no-mode witness and
 * property calls write their files into the current directory). */
static void run_rounds(void) {
    char dir[] = "/tmp/map2check-harness-rounds-XXXXXX";
    char cwd[4096];
    REQUIRE(MAP2CHECK_VERSION[0] != '\0');
    REQUIRE(getcwd(cwd, sizeof cwd) != NULL);
    REQUIRE(mkdtemp(dir) != NULL);
    REQUIRE(chdir(dir) == 0);

    /* round 0: all exports before map2check_init() (issue #8) */
    run_pre_init_boundary();
    /* round 1: adversarial inputs before init */
    run_bad_inputs();
    /* round 2: well-formed use after init */
    map2check_init(0);
    run_valid_pass();
    /* round 3: adversarial inputs again, after a new init */
    map2check_init(0);
    run_bad_inputs();

    test_analysis_modes();

    REQUIRE(chdir(cwd) == 0);
    remove_results(dir);
}

/* The program of the fuzzer iterations, as the passes leave it: the
 * map2check_init at the start of main, then nondet values, logged, and the
 * assume the analysed program wrote. */
int __map2check_main__(int argc, char **argv) {
    (void)argc;
    (void)argv;
    switch (phase) {
    case PHASE_ROUNDS:
        run_rounds();
        break;
    case PHASE_INDEPENDENT_1:
    case PHASE_INDEPENDENT_2: {
        /* Each iteration starts from its own state (SD-21): the log holds
         * only this iteration's row. */
        map2check_init(0);
        int x = map2check_non_det_int();
        map2check_nondet_int(30, 0, x, "main");
        REQUIRE(__m2c_rt_nondet_log_len() == 1);
        REQUIRE(__m2c_rt_nondet_log_get_i64(0) == (int64_t)(uint32_t)x);
        REQUIRE(x == (phase == PHASE_INDEPENDENT_1 ? 0x04030201 : 0x0000b0a0));
        /* Every generator of NonDetGeneratorAFL.c, past the end of the input
         * too (zero), and the assume entry points with a true condition. */
        (void)map2check_non_det_uint();
        (void)map2check_non_det_unsigned();
        (void)map2check_non_det_char();
        (void)map2check_non_det_uchar();
        (void)map2check_non_det_short();
        (void)map2check_non_det_ushort();
        (void)map2check_non_det_long();
        (void)map2check_non_det_ulong();
        (void)map2check_non_det_longlong();
        (void)map2check_non_det_ulonglong();
        (void)map2check_non_det_bool();
        (void)map2check_non_det_float();
        (void)map2check_non_det_double();
        (void)map2check_non_det_size_t();
        (void)map2check_non_det_loff_t();
        (void)map2check_non_det_sector_t();
        (void)map2check_non_det_pointer();
        (void)map2check_non_det_u8();
        (void)map2check_non_det_u16();
        (void)map2check_non_det_u32();
        free(map2check_non_det_pchar());
        map2check_assume(1);
        map2check_crab_assume(1);
        map2check_assume_loop(1);
        break;
    }
    case PHASE_REJECT:
    case PHASE_ACCEPT:
    case PHASE_WRAPPED: {
        /* A failed assume abandons only the current input: nondet_assume
         * longjmps out of this C frame back to the __AFL_LOOP of main, and
         * the next input runs (develop: nondet_cancel). */
        if (phase == PHASE_ACCEPT) {
            REQUIRE(harness_after_assume == 0);
        }
        map2check_init(0);
        char *s = map2check_non_det_pchar();
        int x = map2check_non_det_int();
        free(s);
        map2check_assume(x == 7);
        harness_after_assume++;
        break;
    }
    case PHASE_DONE:
        /* {0x07}: a pchar of length 7 (six zero chars past the end), then
         * x reads zero: rejected, so the count is still the accepted one. */
        REQUIRE(harness_after_assume == 1);
        map2check_init(0);
        harness_completed = 1;
        map2check_success();
        break;
    }
    return 0;
}

/* An exit(0) in place of the longjmp would also end with status 0, so an
 * early exit is turned into a failure. Registered before main runs; the
 * forked scenarios end with _exit or abort, which skip it. */
__attribute__((constructor)) static void harness_register_completion_check(void) {
    atexit(harness_require_completion);
}
