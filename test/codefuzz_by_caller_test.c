/* SPDX-License-Identifier: GPL-3.0-only
 *
 * Integration smoke test of the AFL++ nondet generator through the C runtime
 * ABI (M3, rewritten against the C ABI in Task 2.10, D6: the `libfuzzer`
 * feature and LLVMFuzzerTestOneInput are gone). The generator is the
 * generated IR module NonDetGeneratorAFL.ll, whose `main` runs
 * `__map2check_main__` once per input of its `__AFL_LOOP`, and the program's
 * map2check_assume comes from the glue IR (Map2CheckFunctions-glue.ll).
 * Built with scripts/build-c-abi-program.sh -m Map2CheckFunctions-glue -m
 * NonDetGeneratorAFL (see .github/workflows/CI.yml).
 *
 * The afl-compiler-rt symbols the module imports are played here:
 * __afl_persistent_loop hands it the inputs below, one per iteration.
 */
#include <assert.h>
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <unistd.h>

#include "map2check.h"

/* Map2CheckFunctions.h (glue IR) and NonDetGenerator.h (generator IR). */
void map2check_assume(int expr);
int map2check_non_det_bool(void);
char map2check_non_det_char(void);
unsigned char map2check_non_det_uchar(void);
short map2check_non_det_short(void);
unsigned short map2check_non_det_ushort(void);
int map2check_non_det_int(void);
unsigned map2check_non_det_uint(void);
long map2check_non_det_long(void);
unsigned long map2check_non_det_ulong(void);
float map2check_non_det_float(void);
double map2check_non_det_double(void);
size_t map2check_non_det_size_t(void);
void *map2check_non_det_pointer(void);
long long map2check_non_det_loff_t(void);
unsigned long map2check_non_det_sector_t(void);
char *map2check_non_det_pchar(void);

/* afl-compiler-rt, played by the test. */
uint8_t *__afl_fuzz_ptr;
static unsigned int fuzz_len;
unsigned int *__afl_fuzz_len = &fuzz_len;
int __afl_connected = 0;

static const uint8_t input[] = {0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08};
static const uint8_t second_input[] = {0xa0, 0xb0};
static const uint8_t seed_a[] = {'A'};
static const uint8_t forty_two[] = {0x2a, 0x00, 0x00, 0x00};

static int iteration;
static int reject_input;
static int ran_past_assume;
static int completed;

int __afl_persistent_loop(int max) {
    (void)max;
    const uint8_t *data;
    unsigned int len;
    int i = iteration++;
    if (i == 0) {
        data = input, len = sizeof input;
    } else if (i == 1) {
        data = second_input, len = sizeof second_input;
    } else if (i < 12) {
        /* Input "A": the int reads 'A' then zeros past the end (0x41), not
         * 42, and the assume rejects it. */
        data = seed_a, len = sizeof seed_a;
    } else if (i == 12) {
        data = forty_two, len = sizeof forty_two;
    } else {
        return 0;
    }
    reject_input = i >= 2;
    __afl_fuzz_ptr = (uint8_t *)data;
    fuzz_len = len;
    return 1;
}

/* An exit(0) in place of the longjmp would also end with status 0. */
static void require_completion(void) {
    if (!completed) {
        _exit(97);
    }
}

__attribute__((constructor)) static void register_completion_check(void) {
    atexit(require_completion);
}

int __map2check_main__(int argc, char **argv) {
    (void)argc;
    (void)argv;
    /* The map2check_init the pass puts at the start of main: each
     * iteration starts from its own state (SD-21). */
    map2check_init(0);
    if (reject_input) {
        /* A failed assume abandons this input: nondet_assume longjmps out of
         * this C frame back to the __AFL_LOOP of main (develop:
         * nondet_cancel). */
        int x = map2check_non_det_int();
        map2check_nondet_int(10, 0, x, "main");
        map2check_assume(x == 42);
        ran_past_assume++;
        assert(ran_past_assume == 1 && iteration == 13);
        completed = 1;
        return 0;
    }
    (void)map2check_non_det_bool();
    (void)map2check_non_det_char();
    (void)map2check_non_det_uchar();
    (void)map2check_non_det_short();
    (void)map2check_non_det_ushort();
    int x = map2check_non_det_int();
    (void)map2check_non_det_uint();
    (void)map2check_non_det_long();
    (void)map2check_non_det_ulong();
    (void)map2check_non_det_float();
    (void)map2check_non_det_double();
    (void)map2check_non_det_size_t();
    (void)map2check_non_det_pointer();
    (void)map2check_non_det_loff_t();
    (void)map2check_non_det_sector_t();
    free(map2check_non_det_pchar());
    map2check_nondet_int(20, 0, x, "main");
    /* Independent iterations: only this one's row is in the log. */
    assert(__m2c_rt_nondet_log_len() == 1);

    /* A truthy assume returns; the falsy one runs in the iterations above. */
    map2check_assume(1);
    return 0;
}
