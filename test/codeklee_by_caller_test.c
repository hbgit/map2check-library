#include "../include/CallerLibraryResult.hpp"
#include "../include/CallerLibraryTrackBbLog.hpp"
#include "../include/CallerLibraryMemoryTrackLog.hpp"
#include "../include/CallerLibraryNonDetLog.hpp"
#include "../include/CallerLibraryCheckReach.hpp"

int k =24;

extern "C" int __map2check_main__() {
  return 0;
}

extern "C" void klee_assume(int);

int main(){
  
  unsigned int vuint = map2checkGenNonDet_unsigned();  
  map2checkStoreNonDetLog(29, 0, vuint, "foo");
  map2checkAddInTrackedBb(18, "main");
  void * p = &vuint;
  map2checkMap_Alloca("a", p, 12, 4, 18, 0);
  map2checkMap_Alloca("b", p, 12, 4, 18, 0);
  
  map2check_assert(vuint == 12, 33, "main");
  map2check_assert(vuint == 15, 33, "main");
  
  //map2check_assert(vuint == UINT_MAX, 33, "main");

  return 0;
}