/**
 * Copyright (C) 2014 - 2020 Map2Check tool
 * This file is part of the Map2Check tool, and is made available under
 * the terms of the GNU General Public License version 3.
 *
 * SPDX-License-Identifier: (GPL-3.0)
 *
 * Abstract: This file has all structure to handle the container log objects.
 **/

// include guard
#ifndef __CONTAINER_H_INCLUDED__
#define __CONTAINER_H_INCLUDED__

#include <map>
#include <string>
#include <list> 

using namespace std; 

class ContainerLog { 
public:    
    list<string> JsonLogString;
    
    // Methods to handle with the Container
    //map<long, T> appendContainerLog(long Step, T ObjModelIn);    
    template<typename T>    
    map<long, T> appendContainerLog(long Step, T ObjModelIn);    
    //void printJsonAllContainer();
};

/**
 * @brief Create a Container object to save the data from model proposed
 * in this library. In this case, for each object k of type T in 
 * the set of models {} we have a list<map<unsigned, T>>, i.e., 
 * the private attribute containerLog_.
 */


#endif // __CONTAINER_H_INCLUDED__ 