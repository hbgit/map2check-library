#include "../include/CallerLibraryResult.hpp"
#include "../include/CallerLibraryNonDetLog.hpp"
#include "../include/CallerLibraryCheckReach.hpp"

extern "C" int __map2check_main__() {

  unsigned int vuint = map2checkGenNonDet_unsigned();
  map2checkStoreNonDetLog(29, 0, vuint, "foo");
  
  map2check_assert(vuint == 12, 33, "main");

  return 0;
}