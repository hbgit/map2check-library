//===-- include/AnalysisModeMemory.cpp - class definition -------*- C++ -*-===//
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
/// This file contains the declaration of the AnalysisModeMemory.cpp class, which 
/// peforms the programa analysis to check memory operation in a given C code.
///
//===----------------------------------------------------------------------===//


#include "../include/AnalysisModeMemory.hpp"
#include <boost/range/adaptor/reversed.hpp>


// This file adopted other Container to analysis so we need to check given as
// input the needed containers


/// old map2check_free_resolved_address
/// Tracks address that are resolved during free (this function is to be used for
/// instrumentation)
bool AnalysisModeMemory::freeResolvedAddress(ContainerMemoryTrackLog CntrMemTrkLog){
    
    /*if(this->PtrAddress == NULL && this->IsNullValid){
        return false;
    }*/

    return false;
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
bool AnalysisModeMemory::isMemCleanUpError(long MemoryAddress){
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
bool AnalysisModeMemory::isDerefError(long MemoryAddress){
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
bool AnalysisModeMemory::isInvalidFree(long MemoryAddress){
    
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
