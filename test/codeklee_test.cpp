#include "../include/NonDetGenKlee.hpp"

#include <assert.h>
#include <limits.h>
#include <stdlib.h>


int __map2check_main__() {
  
  int v = genericKleeNonDetGen<int>();

  if(v == INT_MAX){
    assert(0);
  }

  return 0;
}

int main(){
  __map2check_main__();
  return 0;
}


/*
extern "C" void klee_make_symbolic(void *addr, size_t nbytes, const char *name);

int genericKleeNonDetGen(){
    int non_det;   
    
    klee_make_symbolic(&non_det, sizeof(non_det), "non_det_");
    return non_det;  
}


int __map2check_main__() {
  
  int v = genericKleeNonDetGen();

  if(v == INT_MAX){
    assert(0);
  }

  return 0;
}

int main()
{
  __map2check_main__();
}*/