//===-- include/ContainerAllocaLog.hpp - class definition -------*- C++ -*-===//
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
/// This file contains the declaration of the ContainerAllocaLog.hpp class, which 
/// modelling the Container to storage a list with AllocaLog objects.
///
//===----------------------------------------------------------------------===//

#include "../include/ContainerAllocaLog.hpp"
#include "AllocaLog.hpp"
#include "../lib/json.hpp"
using json = nlohmann::json;


/// @brief Print an given AllocaLog object in Json format.  
/// @param ObjModelIn AllocaLog object
/// @return The Json string
string ContainerAllocaLog::printJsonObj(AllocaLog ObjModelIn){
    json j;

    j["Address"] = ObjModelIn.Address;
    j["IsFree"] = ObjModelIn.IsFree;
    j["SizeToDestiny"] = ObjModelIn.SizeToDestiny;
    
    return j.dump().c_str();
}

/// @brief Searching for an given address in the ContainerAllocaLog list
/// @param Address to be searched in the list
/// @return An AllocaLog object
AllocaLog ContainerAllocaLog::searchContainerAllocaLog(long Address){

    for(auto item : this->ContainerLog_){
        if(item.begin()->second.Address == Address){
            return item.begin()->second;
        }
    }

    AllocaLog t;
    return t;

}

/// @brief This replaced the old mark_deallocation_log function. Saving
/// in the ContainerLog the action executed  
/// @param Step Current step of the program analysis
/// @param Address Address to set up as free
/// @return void
void ContainerAllocaLog::setDealallocInAddress(long Step, long Address){
    auto AllocaTmp = this->searchContainerAllocaLog(Address);
    AllocaTmp.IsFree = true;
    
    map<long, AllocaLog> MapTmp;
    MapTmp.insert(
        pair<long, AllocaLog>(
            Step++, AllocaTmp
        )
    );
    this->ContainerLog_.push_back(MapTmp);
}

/// @brief This replaced the old mark_allocation_log function. Saving
/// in the ContainerLog the alloca action executed  
/// @param Step Current step of the program analysis
/// @param Address Address to set up as alloca
/// @return void
void ContainerAllocaLog::setAllocInAddress(long Step, long Address){
    auto AllocaTmp = this->searchContainerAllocaLog(Address);
    AllocaTmp.IsFree = false;
    
    map<long, AllocaLog> MapTmp;
    MapTmp.insert(
        pair<long, AllocaLog>(
            Step++, AllocaTmp
        )
    );
    this->ContainerLog_.push_back(MapTmp);
}

/// @brief This replaced the old valid_allocation_log function.
/// It is to check if all address allocated
/// were released at the end of the program, to check this, we iterate
/// over all elements starting from bottom of allocation log, if the
/// address of the current item is not Free, we iterate from the top
/// if we find that the address was released, then we go on
/// if not we return FALSE
/// @param Step Current step of the program analysis
/// @param Address Address to set up as alloca
/// @return map<Error,Address>
map<bool, long> ContainerAllocaLog::allocaLogIsValid(){
    long MemTrackAddressError = 0;

    // Search from bottom/reverse
    list<map<long, AllocaLog>> :: reverse_iterator rit; 
    
    for(rit = this->ContainerLog_.rbegin(); 
        rit != this->ContainerLog_.rend(); rit++){            
            if(rit->begin()->second.IsFree == false){
                bool ReleasedFound = false;
                MemTrackAddressError = rit->begin()->second.Address;
                // Search from top
                for(auto item : this->ContainerLog_){
                    if(MemTrackAddressError == item.begin()->second.Address && 
                       item.begin()->second.IsFree){
                        ReleasedFound = true;
                    }
                }
                
                if(ReleasedFound == false){
                    map<bool, long> MapTmp;
                    MapTmp.insert(
                        pair<bool, long>(
                            true, MemTrackAddressError
                        )
                    );
                    return MapTmp;
                }
            }
    }
}