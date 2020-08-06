// include guard
#ifndef __CONTAINER_H_INCLUDED__
#define __CONTAINER_H_INCLUDED__

#include <iostream>
#include <string>
#include <list> 
#include <map>
#include <iterator> 

#include "../header/Nondetlog.hpp"

using namespace std; 

template <class T>
class Container { 
private:
    list<map<int, T>> containerLog_;    

public:    
    Container();
    void appendContainerNondetLog(int step, T object_model_in);
    string getNonDetLogTypeValue_(NonDetLog obj);
    void showItemsFromContNonDetLog();
    
};

#endif // __CONTAINER_H_INCLUDED__ 