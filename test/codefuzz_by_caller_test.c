/* SPDX-License-Identifier: GPL-3.0-only
 *
 * Integration smoke test for the LibFuzzer nondet generator API (M3).
 * Must be built and linked against libmap2check.a compiled with
 * `--features libfuzzer` (see .github/workflows/CI.yml).
 */
#include <assert.h>
#include <stddef.h>
#include <stdint.h>

#include "../include/map2check.h"

/* rust/src/nondet/libfuzzer.rs only defines a stub __map2check_main__ under
 * cfg(test); any other binary linking against the staticlib must supply its
 * own (the crate compiles as a single object under the release profile's
 * codegen-units = 1, so linking any symbol from it pulls in
 * LLVMFuzzerTestOneInput's unresolved reference to __map2check_main__ too —
 * see the same requirement documented in tests/ffi_harness.c). */
int __map2check_main__(void) {
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

    /* Only truthy conditions here: a falsy one calls exit(0)/abort() by
     * design (see rust/src/nondet/libfuzzer.rs), which would end this
     * process instead of just this check. */
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

    return rc;
}
