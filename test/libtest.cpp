#include "../header/Container.hpp"
#include "../lib/Container.cpp"

//#include "../header/Nondetlog.hpp"


int main(int argc, char *argv[]){

   /*NonDetLog k = NonDetLog();
   k.line = 12;
   k.scope = 0;
   k.functionName = "test";*/
   
   
   Container<int> c;
   c.printMyTest();
   //c.setTypeObj(k);

   //NonDetLog tmp = c.getAllValueObj();

   //cout << tmp.functionName << endl;


   return 0;
}