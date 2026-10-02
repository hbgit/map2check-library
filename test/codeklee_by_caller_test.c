/* SPDX-License-Identifier: GPL-3.0-only
 *
 * KLEE-shaped integration smoke test for the map2check-library core API.
 *
 * NOTE: the `klee` feature (M4 — see Logs/plano_map2check_library_rust.md)
 * is not implemented yet: this crate has no symbolic-execution-specific
 * nondet generator. Until M4 lands, this file provides local stub
 * definitions of klee_make_symbolic/klee_assume so it stays compilable and
 * runnable as a plain smoke test in CI under concrete execution, not actual
 * symbolic execution under a real KLEE binary. When M4 implements the
 * `klee` feature, this file is the natural place to switch to the real
 * klee_make_symbolic/klee_assume intrinsics and drop these stubs.
 */
#include <assert.h>
#include <stddef.h>
#include <stdint.h>

#include "../include/map2check.h"

extern void map2check_save_nondet_log_int(int32_t line, int32_t scope, int32_t value, const char *function_name);

/* Local stubs — see file header note. */
void klee_make_symbolic(void *addr, size_t nbytes, const char *name) {
    (void)addr;
    (void)nbytes;
    (void)name;
}

void klee_assume(int cond) {
    (void)cond;
}

int main(void) {
    map2check_init();

    int value = 0;
    klee_make_symbolic(&value, sizeof(value), "value");
    klee_assume(value >= 0);

    map2check_save_nondet_log_int(12, 0, value, "main");
    map2check_save_basic_block_log(12, "main");
    assert(map2check_is_in_trackbb_container(12) == 1);

    map2check_is_valid_assert(13, "main", value >= 0);
    assert(get_current_property() == None);

    print_all_containers_as_json();
    map2check_success();
    return 0;
}
