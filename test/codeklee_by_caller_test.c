/* SPDX-License-Identifier: GPL-3.0-only
 *
 * KLEE-shaped integration smoke test through the C runtime ABI (rewritten
 * against the C ABI in Task 2.10, D6). The `symex` generator is the
 * generated IR module NonDetGeneratorKlee.ll, whose `main` calls
 * `__map2check_main__(argc, argv)`; the mode is AnalysisModeAssert.ll and
 * map2check_assume comes from the glue IR (Map2CheckFunctions-glue.ll).
 * Built with scripts/build-c-abi-program.sh -m Map2CheckFunctions-glue -m
 * NonDetGeneratorKlee -m AnalysisModeAssert (see .github/workflows/CI.yml).
 *
 * This runs natively, not under KLEE: klee_make_symbolic is a local stub
 * that records the object names and leaves the value concrete. Real KLEE
 * runs are scripts/runtime-ir/test-klee-generator.sh (Map2Check image).
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

/* AnalysisMode.h, NonDetGenerator.h and Map2CheckFunctions.h (IR modules). */
void analysis_init(void);
void map2check_assert(int expr, int line, const char *function_name);
void nondet_init(void);
void map2check_assume(int expr);
int map2check_non_det_int(void);

/* KLEE intrinsic, stubbed: records the name, keeps the value. */
static char last_symbolic[64];
static int symbolic_count;

void klee_make_symbolic(void *addr, size_t nbytes, const char *name) {
    (void)addr;
    (void)nbytes;
    snprintf(last_symbolic, sizeof last_symbolic, "%s", name);
    symbolic_count++;
}

/* Used by nondet_generate_aux_witness_files (the witness klee_log.csv),
 * which this test does not reach; a concrete value is its own value. */
int64_t klee_get_value_i64(int64_t value) { return value; }
void klee_assume(uintptr_t condition) { assert(condition); }

static void read_file(const char *name, char *buf, size_t size) {
    buf[0] = '\0';
    FILE *f = fopen(name, "r");
    if (f != NULL) {
        size_t n = fread(buf, 1, size - 1, f);
        buf[n] = '\0';
        fclose(f);
    }
}

int __map2check_main__(int argc, char **argv) {
    (void)argc;
    (void)argv;
    char dir[] = "/tmp/map2check-codeklee-XXXXXX";
    char buf[128];
    assert(mkdtemp(dir) != NULL);
    assert(chdir(dir) == 0);

    /* map2check_init as Map2CheckFunctions.c:29-40 runs it in a Map2Check
     * build: the linked mode, then the linked generator. */
    map2check_init(0);
    analysis_init();
    nondet_init();

    /* NonDetGeneratorKlee.c: one symbolic object per value, named
     * non_det_<t>. */
    int value = map2check_non_det_int();
    assert(symbolic_count == 1 && strcmp(last_symbolic, "non_det_int") == 0);
    map2check_nondet_int(12, 0, value, "main");
    assert(__m2c_rt_nondet_log_len() == 1);
    map2check_track_bb(12, "main");

    /* A true assume keeps the path. */
    map2check_assume(value >= 0);
    assert(symbolic_count == 1);

    /* A false assume prunes the path: a symbolic `map2check_pruned`, then
     * _exit(0) (NonDetGeneratorKlee.c, nondet_assume). */
    fflush(NULL);
    pid_t pid = fork();
    assert(pid >= 0);
    if (pid == 0) {
        map2check_assume(0);
        _exit(3);
    }
    int status = 0;
    assert(waitpid(pid, &status, 0) == pid);
    assert(WIFEXITED(status) && WEXITSTATUS(status) == 0);

    /* An assert that holds: the run ends with NONE. */
    map2check_assert(value >= 0, 13, "main");
    map2check_success();
    read_file("map2check_property", buf, sizeof buf);
    assert(strcmp(buf, "NONE\n") == 0);

    /* A failing assert writes ASSERT and aborts. */
    fflush(NULL);
    pid = fork();
    assert(pid >= 0);
    if (pid == 0) {
        map2check_assert(value < 0, 14, "main");
        _exit(3);
    }
    assert(waitpid(pid, &status, 0) == pid);
    assert(WIFSIGNALED(status) && WTERMSIG(status) == SIGABRT);
    read_file("map2check_property", buf, sizeof buf);
    assert(strcmp(buf, "ASSERT\nLine: 14\nFunction: main\n") == 0);

    unlink("map2check_property");
    unlink("map2check_property_assert");
    assert(chdir("/") == 0);
    assert(rmdir(dir) == 0);
    return 0;
}
