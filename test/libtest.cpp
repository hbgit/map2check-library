#include "../header/Container.hpp"
#include "../lib/Container.cpp"

#include "../header/Nondetlog.hpp"

#include <boost/variant.hpp>


int main(int argc, char *argv[]){

   NonDetLog map2check_nondet_int;
   map2check_nondet_int.line = 12;
   map2check_nondet_int.scope = 0;
   map2check_nondet_int.value = 7;   
   map2check_nondet_int.functionName = "test";

   Container<NonDetLog> container_nondetlog;
   container_nondetlog.appendContainerNondetLog(12, map2check_nondet_int);
   map2check_nondet_int.value = 15;
   container_nondetlog.appendContainerNondetLog(13, map2check_nondet_int);
   container_nondetlog.showItemsFromContNonDetLog(); 


   return 0;
}