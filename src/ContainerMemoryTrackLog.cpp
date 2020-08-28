//===-- include/ContainerMemoryTrackLog.cpp - class definition -------*- C++ -*-===//
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
/// This file contains the declaration of the ContainerMemoryTrackLog.cpp class, which 
/// modelling the Container to storage a list with TrackBbLog objects.
///
//===----------------------------------------------------------------------===//

#include "../include/ContainerMemoryTrackLog.hpp"
#include "../include/MemoryTrackLog.hpp"
#include "../lib/json.hpp"
#include <algorithm>
using json = nlohmann::json;

#include <iostream>
#include <boost/range/adaptor/reversed.hpp>

/// @brief Print an given TrackBbLog object in Json format.  
/// @param ObjModelIn TrackBbLog object
/// @return The Json string
string ContainerMemoryTrackLog::printJsonObj(MemoryTrackLog ObjModelIn){
    json j;

    j["VarMemoryAddress"] = ObjModelIn.VarMemoryAddress;
    j["MemoryAddressPointsTo"] = ObjModelIn.MemoryAddressPointsTo;
    j["Scope"] = ObjModelIn.Scope;
    j["IsDynamic"] = ObjModelIn.IsDynamic;
    j["IsFree"] = ObjModelIn.IsFree;
    j["LineNumber"] = ObjModelIn.LineNumber;
    j["PointerName"] = ObjModelIn.PointerName;
    j["FunctionName"] = ObjModelIn.FunctionName;   
        
    return j.dump().c_str();
}

/// @brief This replaced the old get_old_reference function.
/// Searching in the container list the last time where the Address
/// was reached
/// @param MemoryAddress to be searched in the list
/// @return The address pointed by the address searched
long ContainerMemoryTrackLog::getLastReference(long MemoryAddress){
    // Search from bottom/reverse
    list<map<long, MemoryTrackLog>> :: reverse_iterator rit; 
    
    for(rit = this->ContainerLog_.rbegin(); 
        rit != this->ContainerLog_.rend(); rit++){            
            if(rit->begin()->second.VarMemoryAddress == MemoryAddress){
                return rit->begin()->second.MemoryAddressPointsTo;
            }
    }
    return 0;
}

/// @brief This replaced the old is_memcleanup_error function.
/// A memcleanup error occurs when a memory leak happens but we still have
/// a pointer that points to the leaked location, so to verify we:
/// 1. From last element to the first check if some variable points to the
/// location
/// 2. If found, iterates from the found element to the last and check if the
/// pointer does not change.
/// 3a. If it doesn't change, then it is a memcleanup error
/// 3b. Else, go on 1 loop.
/// 4. If loop ends without finding leaked address, then it isn't a memcleanup
/// error.
/// @param MemoryAddress to be searched in the list
/// @return bool to check a memcleanup error
bool ContainerMemoryTrackLog::isMemCleanUpError(long MemoryAddress){
    // Search from bottom/reverse
    list<map<long, MemoryTrackLog>> :: reverse_iterator rit; 
    
    for(rit = this->ContainerLog_.rbegin(); 
        rit != this->ContainerLog_.rend(); rit++){            
            if(rit->begin()->second.MemoryAddressPointsTo == MemoryAddress){
               bool error = true;
               for(auto item : boost::adaptors::reverse(this->ContainerLog_)){
                   if(rit->begin()->second.VarMemoryAddress == item.begin()->second.VarMemoryAddress){
                       error = item.begin()->second.MemoryAddressPointsTo == MemoryAddress ? 
                               true : false;
                        break;
                   }
               }
               if(error){
                   return true;
               }
            }
    }
    return false;
}


/// @brief This replaced the old is_deref_error function.
/// Checking in the container memory if a given address
/// execute an operation with derefence error:
/// 1. Where the var memory address is not in the container
/// 2. If the address already executed an dealallocation - free
/// @param MemoryAddress to be searched in the list
/// @return bool as answer
bool ContainerMemoryTrackLog::isDerefError(long MemoryAddress){
    for(auto item : boost::adaptors::reverse(this->ContainerLog_)){
        if(item.begin()->second.VarMemoryAddress == MemoryAddress){
            return false;
        }
        if(item.begin()->second.MemoryAddressPointsTo == MemoryAddress){
            if(item.begin()->second.IsFree || !item.begin()->second.IsDynamic){
                return true;
            }else{
                return false;
            }
        }
    }
    return false;
}

/// @brief This replaced the old is_invalid_free function.
/// Checking in the container memory if a given address
/// execute an invalid free, when that given address was released.
/// @param MemoryAddress to be searched in the list
/// @return bool as answer
bool ContainerMemoryTrackLog::isInvalidFree(long MemoryAddress){
    
    if(MemoryAddress == (long)NULL){
        return false;
    }
    
    for(auto item : boost::adaptors::reverse(this->ContainerLog_)){
        if(item.begin()->second.MemoryAddressPointsTo == MemoryAddress){
            if(item.begin()->second.IsFree || !item.begin()->second.IsDynamic){
                return true;
            }else{
                return false;
            }
        }
    }
    return true;
}


/// @brief This replaced the old get_type_from_list_log_row function.
/// Getting a given MemoryTrackLOg object.
/// @param ObjectMemory to be analyzed
/// @return MemoryAddressStatus
enum MemoryAddressStatus ContainerMemoryTrackLog::getMemoryAddressStatus(MemoryTrackLog ObjectMemory){
    if(ObjectMemory.IsFree && !ObjectMemory.IsDynamic){
        return FREE;
    }else if(ObjectMemory.IsDynamic){
        return DYNAMIC;
    }

    // FIXME: how to known if address if static or invalid?
    return STATIC;
}

