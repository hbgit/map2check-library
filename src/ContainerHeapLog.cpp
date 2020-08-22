//===-- include/ContainerHeapLog.hpp - class definition -------*- C++ -*-===//
//
// Copyright (C) 2014 - 2020 Map2Check tool
// This file is part of the Map2Check tool, and is made available under
// the terms of the GNU General Public License version 3.
//
// SPDX-License-Identifier: (GPL-3.0)
//
//===----------------------------------------------------------------------===//
///
/// \file
/// This file contains the declaration of the ContainerHeapLog.hpp class, which 
/// modelling the Container to storage a list with HeapLog objects.
///
//===----------------------------------------------------------------------===//

#include "../include/ContainerHeapLog.hpp"
#include "HeapLog.hpp"

#include "../lib/json.hpp"
#include <memory>
using json = nlohmann::json;

/// @brief Print an given HeapLog object in Json format.  
/// @param ObjModelIn HeapLog object
/// @return The Json string
string ContainerHeapLog::printJsonObj(HeapLog ObjModelIn){
    json j;

    j["Address"] = (long)std::addressof(ObjModelIn.Address);
    j["FunctName"] = ObjModelIn.FunctName;
    j["Size"] = ObjModelIn.Size;
    j["SizeOfPrimitive"] = ObjModelIn.SizeOfPrimitive;
    j["SizeToLoad"] = ObjModelIn.SizeToLoad;
    j["LineNumber"] = ObjModelIn.LineNumber;
    j["Scope"] = ObjModelIn.Scope;
    
    return j.dump().c_str();
}

/// @brief This replaced the old is_valid_heap_address function.
/// Checking if a given Address is valid in the Heap Address.
/// We iterate over all elements of the allocation log,
/// beggining from back, if the address that we are looking for is in the range of
/// the element address memory space, different from Alloca here
/// we do not check if the element is not free. 
/// @param Address Address to set up as alloca
/// @param Size    Size memory
/// @return bool if is valid or not
bool ContainerHeapLog::isValidHeapAddress(void * Address, int Size){
    // Search from bottom/reverse
    list<map<long, HeapLog>> :: reverse_iterator rit; 
    
    for(rit = this->ContainerLog_.rbegin(); 
        rit != this->ContainerLog_.rend(); rit++){              
            long RangeAddress = (long)rit->begin()->second.Address + 
                                (rit->begin()->second.Size - Size) + 1;
            if(rit->begin()->second.Address <= Address &&
                (long)Address < RangeAddress){
               return true;
            }
    }
    return false;
}