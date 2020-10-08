#include "../include/CallerLibraryResult.hpp"
#include "../include/CallerLibraryTrackBbLog.hpp"
#include "../include/CallerLibraryMemoryTrackLog.hpp"
#include "../include/CallerLibraryNonDetLogFuzzer.hpp"
#include "../include/CallerLibraryCheckReach.hpp"

#include <assert.h>

#include <cmath>
#include <cstring>
#include <iostream>
#include <limits.h>
#include <limits>

using namespace std;

int __map2check_main__() {
  resetCntrs();

  unsigned int vuint = map2checkGenNonDet_unsigned();
  map2checkStoreNonDetLogUnsignedInt(29, 0, vuint, "foo");
  map2checkAddInTrackedBb(18, "main");
  void * p = &vuint;
  map2checkMap_Alloca("a", p, 12, 4, 18, 0);
  
  map2check_assert(vuint < 12, 33, "main");

  return 0;
}