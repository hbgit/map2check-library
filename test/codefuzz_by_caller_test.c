/* SPDX-License-Identifier: GPL-3.0-only
 *
 * Integration smoke test for the LibFuzzer nondet generator API (M3).
 * Must be built and linked against libmap2check.a compiled with
 * `--features libfuzzer` (see .github/workflows/CI.yml).
 */
#include <assert.h>
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <unistd.h>

#include "../include/map2check.h"

/* rust/src/nondet/libfuzzer.rs only defines a stub __map2check_main__ under
 * cfg(test); any other binary linking against the staticlib must supply its
 * own (the crate compiles as a single object under the release profile's
 * codegen-units = 1, so linking any symbol from it pulls in
 * LLVMFuzzerTestOneInput's unresolved reference to __map2check_main__ too —
 * see the same requirement documented in tests/ffi_harness.c). */
/* Set by main for the iterations whose program rejects the input. */
static int reject_input = 0;
static int ran_past_assume = 0;
static int completed = 0;

/* An exit(0) in place of the unwind would also end with status 0. */
static void require_completion(void) {
    if (!completed) {
        _exit(97);
    }
}

int __map2check_main__(void) {
    if (reject_input) {
        /* A failed assume abandons this input and unwinds out of this C
         * frame back to LLVMFuzzerTestOneInput (develop: nondet_cancel). */
        __VERIFIER_assume(__VERIFIER_nondet_int() == 42);
        ran_past_assume++;
        return 0;
    }
    (void)__VERIFIER_nondet_bool();
    (void)__VERIFIER_nondet_char();
    (void)__VERIFIER_nondet_uchar();
    (void)__VERIFIER_nondet_short();
    (void)__VERIFIER_nondet_ushort();
    (void)__VERIFIER_nondet_int();
    (void)__VERIFIER_nondet_uint();
    (void)__VERIFIER_nondet_long();
    (void)__VERIFIER_nondet_ulong();
    (void)__VERIFIER_nondet_float();
    (void)__VERIFIER_nondet_double();
    (void)__VERIFIER_nondet_size_t();
    (void)__VERIFIER_nondet_pointer();
    (void)__VERIFIER_nondet_loff_t();
    (void)__VERIFIER_nondet_sector_t();
    free(__VERIFIER_nondet_pchar());

    /* Truthy conditions here; the falsy assume runs in the iterations of
     * main below. A falsy assert aborts by design. */
    __VERIFIER_assume(1);
    __VERIFIER_assert(1);
    map2check_fuzzer_assume(1);

    return 0;
}

int main(void) {
    const uint8_t input[] = {0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08};
    int rc = LLVMFuzzerTestOneInput(input, sizeof(input));
    assert(rc == 0);

    /* Two consecutive iterations must start from independent state (see
     * rust/src/nondet/libfuzzer.rs: state::reset() per call). */
    const uint8_t second_input[] = {0xa0, 0xb0};
    rc = LLVMFuzzerTestOneInput(second_input, sizeof(second_input));
    assert(rc == 0);

    /* Input "A": develop's reader rewinds, so x == 0x41414141, not 0, and
     * the assume rejects it; the four bytes of 42 pass. */
    atexit(require_completion);
    reject_input = 1;
    const uint8_t seed_a[] = {'A'};
    const uint8_t forty_two[] = {0x2a, 0x00, 0x00, 0x00};
    for (int i = 0; i < 10; i++) {
        rc = LLVMFuzzerTestOneInput(seed_a, sizeof(seed_a));
        assert(rc == 0);
    }
    assert(ran_past_assume == 0);
    rc = LLVMFuzzerTestOneInput(forty_two, sizeof(forty_two));
    assert(rc == 0);
    assert(ran_past_assume == 1);
    completed = 1;

    return rc;
}
