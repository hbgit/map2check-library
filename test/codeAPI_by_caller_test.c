/* SPDX-License-Identifier: GPL-3.0-only
 *
 * Integration smoke test for the map2check-library core API (M3).
 * Exercises memtrack, assert, nondet and basic-block tracking end to end
 * against a real compiled libmap2check.a. Built without extra features
 * (see .github/workflows/CI.yml).
 */
#include <assert.h>
#include <stddef.h>
#include <stdint.h>

#include "../include/map2check.h"

int main(void) {
    map2check_init();

    /* Stack allocation: loading within its bounds is safe. */
    int local = 42;
    map2check_map_alloca("local", &local, sizeof(local), sizeof(local), 10, 0);
    map2check_check_load(&local, 11, 0, sizeof(local), "main");
    assert(get_current_property() == None);

    /* Non-static (VLA-like) allocation: same load-safety contract as alloca. */
    int vla[4];
    map2check_map_non_static_alloca("vla", vla, sizeof(vla), sizeof(int), 12, 0);
    map2check_check_load(vla, 12, 0, sizeof(int), "main");
    assert(get_current_property() == None);

    /* Function-address tracking: registers a target as always valid to load. */
    static int dummy_target = 7;
    map2check_map_funct_address("dummy_fn", (void *)&dummy_target);
    map2check_check_load((void *)&dummy_target, 14, 0, sizeof(dummy_target), "main");
    assert(get_current_property() == None);

    /* Heap allocation: check-before-free must be safe on both free checks. */
    void *heap_ptr = (void *)0x1000; /* synthetic address, never dereferenced */
    void *heap_var = &heap_ptr;      /* the pointer variable being freed */
    map2check_map_malloc(heap_ptr, 16);
    map2check_check_free("heap_obj", heap_var, heap_ptr, 0, 15, "main");
    assert(get_current_property() == None);
    map2check_check_free_resolved_address(heap_ptr, 15, "main", 0);
    assert(get_current_property() == None);

    /* After the free is recorded, both checks must flag the double free. */
    map2check_map_free("heap_obj", heap_var, heap_ptr, 0, 16, "main");
    map2check_check_free("heap_obj", heap_var, heap_ptr, 0, 17, "main");
    assert(get_current_property() == MemsafetyFree);
    map2check_check_free_resolved_address(heap_ptr, 17, "main", 0);
    assert(get_current_property() == MemsafetyFree);
    vcc_reset_meta_data();
    assert(get_current_property() == None);

    /* Basic-block + nondet + step-counter tracking. */
    map2check_save_basic_block_log(18, "main");
    assert(map2check_is_in_trackbb_container(18) == 1);
    int32_t nondet_value = 7;
    (void)map2check_save_nondet_log_int(19, 0, INT_ID, &nondet_value, "main");
    uint64_t step_before = get_current_step();
    uint64_t step_after = get_next_step();
    assert(step_after == step_before + 1);

    /* A satisfied assert records no violation. */
    map2check_is_valid_assert(20, "main", 1);
    assert(get_current_property() == None);

    /* The end-of-program leak check runs in both modes (SD-04): a leak is
     * MemsafetyMemtrack by default and MemsafetyMemcleanup after
     * map2check_set_memcleanup(), as in the develop C runtime. */
    map2check_reset();
    map2check_map_malloc((void *)0x2000, 8);
    map2check_check_mem_endprog();
    assert(get_current_property() == MemsafetyMemtrack);
    map2check_reset();
    map2check_set_memcleanup();
    map2check_map_malloc((void *)0x2000, 8);
    map2check_check_mem_endprog();
    assert(get_current_property() == MemsafetyMemcleanup);
    vcc_reset_meta_data();

    map2check_success();
    return 0;
}
