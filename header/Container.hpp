// include guard
#ifndef __CONTAINER_H_INCLUDED__
#define __CONTAINER_H_INCLUDED__

#include <iostream>
#include <string>
#include <list> 
#include <map>
#include <iterator> 

using namespace std; 

template <typename T> 
class Container { 
private:
    T obj_container;

public:    
    Container();
    void setTypeObj(T type);
    //T getAllValueObj();
    void printMyTest(); 
    //unsigned scope;  
};

#endif // __CONTAINER_H_INCLUDED__ 