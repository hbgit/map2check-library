/**
 * Copyright (C) 2014 - 2020 Map2Check tool
 * This file is part of the Map2Check tool, and is made available under
 * the terms of the GNU General Public License version 3.
 *
 * SPDX-License-Identifier: (GPL-3.0)
 *
 * Abstract: This file has all structure to handle the container objects.
 **/

// include guard
#ifndef __CONTAINER_H_INCLUDED__
#define __CONTAINER_H_INCLUDED__

#include <iostream>
#include <string>
#include <list> 
#include <map>
#include <iterator> 

#include "../include/Nondetlog.hpp"
#include "../include/AllocationLog.hpp"

using namespace std; 

template <class T>
class Container { 
private:
    list<map<int, T>> containerLog_;    

public:    
    Container();
    
    // Methods to handle with the Container
    void append_container(int step, T object_model_in);

    // Methods to handle NonDetLog obj    
    string nonDetLog_get_type_value(NonDetLog obj);
    void nonDetLog_show_items_from_log();

    // Methods to handle AllocaLog obj
    void allocaLog_append_container(int step, T object_model_in);
    bool allocaLog_is_valid();
    bool allocaLog_is_valid_alloca_address(long address, int size_to_destiny);
    AllocaLog allocaLog_get_data_alloca_address_from_log(long address);
    bool allocaLog_has_address_in_log(long address);
    void allocaLog_set_dealalloc_in_address(long address);
    void allocaLog_set_not_dealalloc_in_address(long address);  
    void allocaLog_show_items_from_log();  
};

#endif // __CONTAINER_H_INCLUDED__ 