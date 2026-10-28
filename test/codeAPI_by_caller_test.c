/* SPDX-License-Identifier: GPL-3.0-only
 *
 * Integration smoke test of the memory analysis through the C runtime ABI
 * (M3, rewritten against the C ABI in Task 2.10, D6). Exercises memtrack,
 * assert, nondet and basic-block tracking end to end, as an instrumented
 * program calls them: the memory names (map2check_alloca, map2check_load,
 * map2check_free...) come from the generated IR module
 * AnalysisModeMemtrack.ll, which forwards to the release libmap2check.a.
 * Built with scripts/build-c-abi-program.sh -m AnalysisModeMemtrack (see
 * .github/workflows/CI.yml).
 *
 * A violation ends a Map2Check run (the result files, then abort), so each
 * violating scenario runs in a forked child in a directory of its own; the
 * parent checks the exit and map2check_property.
 */
#include <assert.h>
#include <signal.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/wait.h>
#include <unistd.h>

#include "map2check.h"

/* AnalysisMode.h and AnalysisModeMemtrack.c of Map2Check develop (IR). */
void analysis_init(void);
void map2check_load(void *ptr, int size);
void map2check_free_resolved_address(void *ptr, unsigned line, const char *function_name,
                                     short int isNullValid);
void map2check_add_store_pointer(void *var, void *value, unsigned scope, const char *name,
                                 int line, const char *function_name);
void map2check_check_deref(int line, const char *function_name);
void map2check_malloc(void *ptr, int size);
void map2check_alloca(const char *name, void *ptr, int size, int size_of_primitive, int line,
                      int scope);
void map2check_non_static_alloca(const char *name, void *ptr, int size, int size_of_primitive,
                                 int line, int scope);
void map2check_function(const char *name, void *ptr);
void map2check_free(const char *name, void *ptr, unsigned scope, unsigned line,
                    const char *function_name);

/* map2check_init as Map2CheckFunctions.c:29-40 runs it: then analysis_init
 * of the linked mode (the drop-in .bc does both; this host build does not
 * have the `dropin` feature). */
static void start(void) {
    map2check_init(0);
    analysis_init();
}

static void read_file(const char *dir, const char *name, char *buf, size_t size) {
    char path[512];
    snprintf(path, sizeof path, "%s/%s", dir, name);
    buf[0] = '\0';
    FILE *f = fopen(path, "r");
    if (f != NULL) {
        size_t n = fread(buf, 1, size - 1, f);
        buf[n] = '\0';
        fclose(f);
    }
}

static void clean(const char *dir) {
    static const char *const files[] = {"map2check_property", "map2check_property_free",
                                        "map2check_property_memtrack",
                                        "map2check_property_memcleanup",
                                        "map2check_property_deref", NULL};
    char path[512];
    for (int i = 0; files[i] != NULL; i++) {
        snprintf(path, sizeof path, "%s/%s", dir, files[i]);
        unlink(path);
    }
    rmdir(dir);
}

/* Runs `scenario` in a child; returns its map2check_property in `out` and
 * whether it aborted. */
static int run(void (*scenario)(void), char *out, size_t size) {
    char dir[] = "/tmp/map2check-codeapi-XXXXXX";
    assert(mkdtemp(dir) != NULL);
    fflush(NULL);
    pid_t pid = fork();
    assert(pid >= 0);
    if (pid == 0) {
        if (chdir(dir) != 0) {
            _exit(90);
        }
        scenario();
        _exit(0);
    }
    int status = 0;
    assert(waitpid(pid, &status, 0) == pid);
    read_file(dir, "map2check_property", out, size);
    clean(dir);
    return WIFSIGNALED(status) && WTERMSIG(status) == SIGABRT;
}

static void *heap_slot;

/* The safe program: every check passes and the run ends with NONE. */
static void safe_program(void) {
    start();

    /* Stack allocation: loading within its bounds is safe. */
    int local = 42;
    map2check_alloca("local", &local, sizeof(local), sizeof(local), 10, 0);
    map2check_load(&local, sizeof(local));
    map2check_check_deref(11, "main");

    /* Non-static (VLA-like) allocation: same load-safety contract. */
    int vla[4];
    map2check_non_static_alloca("vla", vla, 4, sizeof(int), 12, 0);
    map2check_load(&vla[3], sizeof(int));
    map2check_check_deref(12, "main");

    /* Function-address tracking: a function is valid to load. */
    map2check_function("safe_program", (void *)&safe_program);
    map2check_load((void *)&safe_program, 1);
    map2check_check_deref(14, "main");

    /* Heap allocation freed once through its pointer variable. */
    void *block = malloc(16);
    heap_slot = block;
    map2check_alloca("heap_slot", &heap_slot, sizeof(void *), sizeof(void *), 15, 0);
    map2check_malloc(block, 16);
    map2check_add_store_pointer(&heap_slot, block, 0, "heap_slot", 15, "main");
    map2check_free("heap_slot", &heap_slot, 0, 16, "main");
    free(block);

    /* A block released through its resolved address: safe once a pointer
     * was stored to it (ListLog.c:95-118, is_invalid_free). */
    void *other = malloc(8);
    void *other_slot = other;
    map2check_malloc(other, 8);
    map2check_add_store_pointer(&other_slot, other, 0, "other", 17, "main");
    map2check_free_resolved_address(other, 17, "main", 0);
    free(other);

    /* Basic-block, nondet and step-counter tracking. */
    map2check_track_bb(18, "main");
    map2check_nondet_int(19, 0, 7, "main");
    unsigned step = map2check_get_current_step();
    map2check_next_current_step();
    assert(map2check_get_current_step() == step + 1);

    /* A satisfied assert records no violation. */
    __m2c_rt_assert_map2check_assert(1, 20, "main");

    map2check_success();
}

/* After the free is recorded, a second free is a double free. */
static void double_free(void) {
    start();
    void *block = malloc(16);
    heap_slot = block;
    map2check_alloca("heap_slot", &heap_slot, sizeof(void *), sizeof(void *), 15, 0);
    map2check_malloc(block, 16);
    map2check_add_store_pointer(&heap_slot, block, 0, "heap_slot", 15, "main");
    map2check_free("heap_slot", &heap_slot, 0, 16, "main");
    free(block);
    map2check_free("heap_slot", &heap_slot, 0, 17, "main");
}

/* free_resolved_address of a released block is the same violation. */
static void double_free_resolved(void) {
    start();
    void *block = malloc(16);
    heap_slot = block;
    map2check_alloca("heap_slot", &heap_slot, sizeof(void *), sizeof(void *), 15, 0);
    map2check_malloc(block, 16);
    map2check_add_store_pointer(&heap_slot, block, 0, "heap_slot", 15, "main");
    map2check_free("heap_slot", &heap_slot, 0, 16, "main");
    free(block);
    map2check_free_resolved_address(block, 17, "main", 0);
}

/* The end-of-program leak check (SD-04): memtrack, then memcleanup with a
 * block still referenced by a pointer variable. */
static void leak_memtrack(void) {
    start();
    map2check_malloc(malloc(8), 8);
    map2check_success();
}

static void leak_memcleanup(void) {
    map2check_init(0);
    __m2c_rt_memcleanup_analysis_init();
    void *block = malloc(8);
    heap_slot = block;
    __m2c_rt_memcleanup_map2check_alloca("heap_slot", &heap_slot, 8, 8, 1, 1);
    __m2c_rt_memcleanup_map2check_malloc(block, 8);
    __m2c_rt_memcleanup_map2check_add_store_pointer(&heap_slot, block, 1, "heap_slot", 1, "main");
    map2check_success();
}

int main(void) {
    char prop[256];
    assert(run(safe_program, prop, sizeof prop) == 0);
    assert(strcmp(prop, "NONE\n") == 0);
    assert(run(double_free, prop, sizeof prop) == 1);
    assert(strcmp(prop, "FALSE-FREE\nLine: 17\nFunction: main\n") == 0);
    assert(run(double_free_resolved, prop, sizeof prop) == 1);
    assert(strcmp(prop, "FALSE-FREE\nLine: 17\nFunction: main\n") == 0);
    assert(run(leak_memtrack, prop, sizeof prop) == 1);
    assert(strcmp(prop, "FALSE-MEMTRACK\n") == 0);
    assert(run(leak_memcleanup, prop, sizeof prop) == 1);
    assert(strcmp(prop, "FALSE-MEMCLEANUP\n") == 0);
    return 0;
}
