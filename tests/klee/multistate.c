/* SPDX-License-Identifier: GPL-3.0-only
 * Several KLEE states reach the exit path (map2check_success writes the
 * property file) and one of them hits a violation. KLEE runs the library's
 * file writes as external calls on the real file system, shared by the
 * states, so a write that truncates and then writes in separate calls lets
 * a state erase the violation another state wrote before KLEE halts on the
 * abort (list-ext with --nondet-generator symex: an empty
 * map2check_property, reported as UNKNOWN). The files are written through a
 * temporary file and a rename, so the property file must end non-empty with
 * the violation, and no temporary file may remain. */
#include "m2c.h"

int __map2check_main__(void) {
  M2C_START(M2C_MODE_TARGET);
  int a = NONDET(int, int, 15);
  int b = NONDET(int, int, 16);
  int c = NONDET(int, int, 17);
  int d = NONDET(int, int, 18);
  if (a == 1 && b == 2 && c == 3 && d == 4) {
    REACH_ERROR(21);
  }
  map2check_success();
  return 0;
}
