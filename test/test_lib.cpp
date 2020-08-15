#include <boost/variant.hpp>

#include "gtest/gtest.h"


int main(int argc, char *argv[]){

   ::testing::InitGoogleTest(&argc, argv);
   return RUN_ALL_TESTS();

   /*// Testing NonDetLog 
   NonDetLog map2check_nondet_int;
   map2check_nondet_int.line = 12;
   map2check_nondet_int.scope = 0;
   map2check_nondet_int.value = 7;   
   map2check_nondet_int.functionName = "test";

   Container<NonDetLog> container_nondetlog;
   container_nondetlog.append_container(12, map2check_nondet_int);
   container_nondetlog.nonDetLog_show_items_from_log(); 

   // Testing NonDetLog
   AllocaLog map2check_alloc;
   map2check_alloc.address = (long)&map2check_alloc;
   map2check_alloc.is_free = false;
   map2check_alloc.size_to_destiny = sizeof(map2check_alloc);
   Container<AllocaLog> container_allocalog;
   container_allocalog.append_container(12, map2check_alloc);
   container_allocalog.allocaLog_show_items_from_log();*/

   



   return 0;
}