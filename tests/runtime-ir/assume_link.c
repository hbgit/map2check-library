/* SPDX-License-Identifier: GPL-3.0-only
 *
 * Driver of scripts/runtime-ir/test-assume-link.sh (Task 2.10): the
 * map2check_assume* of Map2CheckFunctions.c:45-47, delivered by the glue IR
 * (Map2CheckFunctions-glue.ll), reach the nondet_assume of the generator
 * module, with the char argument widened as C's (int)expr.
 *
 *   -DRECORD  this file defines nondet_assume and records each argument;
 *             prints them, one per line.
 *   (none)    linked with NonDetGeneratorNone.ll, whose nondet_assume is
 *             empty as in C (NonDetGeneratorNone.c:56): every call returns.
 */
#include <stdio.h>

void map2check_init(int is_sv_comp);
void map2check_assume(int expr);
void map2check_crab_assume(char expr);
void map2check_assume_loop(char expr);

#ifdef RECORD
static int seen[16];
static int n_seen;

void nondet_assume(int expr) {
    if (n_seen < 16) {
        seen[n_seen++] = expr;
    }
}

int main(void) {
    map2check_init(0);
    map2check_assume(5);
    map2check_assume(0);
    map2check_assume(-2147483647 - 1);
    map2check_crab_assume((char)-1);
    map2check_crab_assume(0);
    map2check_assume_loop((char)-128);
    map2check_assume_loop((char)127);
    for (int i = 0; i < n_seen; i++) {
        printf("%d\n", seen[i]);
    }
    return 0;
}
#else
int __map2check_main__(void) {
    map2check_init(0);
    map2check_assume(0);
    map2check_crab_assume(0);
    map2check_assume_loop(0);
    puts("returned");
    return 0;
}
#endif
