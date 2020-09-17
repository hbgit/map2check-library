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

#include <set>
#include <iostream>



AnalysisModeMemory::AnalysisModeMemory(list<map<long, MemoryTrackLog>> CntrContainerLog_) {
    this->ContainerLog_ = CntrContainerLog_;
  }


/// @brief old map2check_free_resolved_address function. 
/// Check if a given address is valid to be dealallocated.
/// @param Address to be analyzed
/// @return bool, TRUE is invalid (BUG was found) and FALSE is valid.
bool AnalysisModeMemory::freeResolvedAddress(long Address){
    
    if(Address == (long)NULL && this->IsNullValid){
        return false;
    }

    if(this->isInvalidFree(Address)){
        return true; 
    }
    
    return false;
}


/// @brief This replaced the old is_valid_allocation_address function.
/// Checking if a given Address is valid in the Alloca Addresses tracked.
/// We iterate over all elements of the allocation log,
/// beggining from back, if the address that we are looking for is in the range
/// of the element address memory space and the element is not free, then it's
/// TRUE otherwise FALSE and we set last_address to the address of last memory
/// address of the current heap space i.e. a int on space 0x10 on a 32bit would
/// set the var to 0x13 (if the int has 4 bytes)
/// @param Address Address to set up as alloca
/// @param Step Current step of the program analysis
/// @return bool, TRUE is invalid (BUG was found) and FALSE is valid.
bool AnalysisModeMemory::isValidAllocaAddress(long Address, int Size) {
  // Search from bottom/reverse
  list<map<long, MemoryTrackLog>>::reverse_iterator rit;

  for (rit = this->ContainerLog_.rbegin(); rit != this->ContainerLog_.rend();
       rit++) {
    long RangeAddress = rit->begin()->second.VarMemoryAddress +
                        (rit->begin()->second.SizeToDestiny - Size) + 1;
    if (rit->begin()->second.VarMemoryAddress <= Address &&
        Address < RangeAddress) {
      if (rit->begin()->second.IsFree) {
        return false;
      }
      return true;
    }
  }
  return false;
}


/// @brief This replaced the old valid_allocation_log function.
/// It is to check if all address allocated and tracked
/// were released at the end of the program, to check this, we iterate
/// over all elements starting from bottom of allocation log, if the
/// address of the current item is not Free, we iterate from the top
/// if we find that the address was released.
/// @param Step Current step of the program analysis
/// @param Address Address to set up as alloca
/// @return map<bool,Address>, TRUE is invalid (BUG was found) and FALSE is valid; 
/// and the invalid Address.
map<bool, long> AnalysisModeMemory::isAllAllocaAddressValidInTheEnd() {
  long MemTrackAddressError = 0;
  map<bool, long> MapTmp;
  set<int> SetOfAddressChecked;

  // Search from bottom/reverse
  list<map<long, MemoryTrackLog>>::reverse_iterator rit;

  for (rit = this->ContainerLog_.rbegin(); rit != this->ContainerLog_.rend();
       rit++) {
      const bool IsIn = SetOfAddressChecked.find(rit->begin()->second.VarMemoryAddress) != SetOfAddressChecked.end();
      //cout << rit->begin()->second.VarMemoryAddress << endl;
      //cout << rit->begin()->second.IsFree << endl;
    
    if (rit->begin()->second.IsFree == false && !IsIn) {      
      bool ReleasedFound = false;
      MemTrackAddressError = rit->begin()->second.VarMemoryAddress;
      // Search from top
      for (auto item : this->ContainerLog_) {
        if (MemTrackAddressError == item.begin()->second.VarMemoryAddress &&
            item.begin()->second.IsFree) {
          ReleasedFound = true;
          SetOfAddressChecked.insert(rit->begin()->second.VarMemoryAddress);
        }
      }

      if (ReleasedFound == false) {
        MapTmp.insert(pair<bool, long>(true, MemTrackAddressError));
        return MapTmp;
      }
    }    
    
  }
  MapTmp.insert(pair<bool, long>(false, 0));
  return MapTmp;
}


/// @brief This replaced the old is_valid_heap_address function.
/// Checking if a given Address is valid in the Heap Address.
/// It is called heap because it is a pile of memory space available to
/// programmers to allocated and de-allocate. We iterate over all elements,
/// beggining from back, if the address that we are looking for is in the range
/// of the element address memory space, different from Alloca here we do not
/// check if the element is not free.
/// @param Address Address to set up as alloca
/// @param Size    Size memory
/// @return bool, TRUE is invalid (BUG was found) and FALSE is valid.
bool AnalysisModeMemory::isValidHeapAddress(long Address, int Size) {
  // Search from bottom/reverse
  list<map<long, MemoryTrackLog>>::reverse_iterator rit;

  for (rit = this->ContainerLog_.rbegin(); rit != this->ContainerLog_.rend();
       rit++) {
    long RangeAddress = (long)rit->begin()->second.VarMemoryAddress +
                        (rit->begin()->second.SizeToDestiny - Size) + 1;
    if (rit->begin()->second.VarMemoryAddress <= Address &&
        (long)Address < RangeAddress) {
      return true;
    }
  }
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
/// @return bool, TRUE is invalid (BUG was found) and FALSE is valid.
bool AnalysisModeMemory::isMemCleanUpError(long MemoryAddress){
    // Search from bottom/reverse
    list<map<long, MemoryTrackLog>> :: reverse_iterator rit; 
    
    for(rit = this->ContainerLog_.rbegin(); 
        rit != this->ContainerLog_.rend(); rit++){            
            if(rit->begin()->second.MemoryAddressPointsTo == MemoryAddress){
               bool error = true;
               
               //for(auto item : boost::adaptors::reverse(this->ContainerLog_)){
                list<map<long, MemoryTrackLog>> :: reverse_iterator Fromrit; 
                for(Fromrit = rit; rit != this->ContainerLog_.rend(); rit++){
                   if(rit->begin()->second.VarMemoryAddress == Fromrit->begin()->second.VarMemoryAddress){
                       error = Fromrit->begin()->second.MemoryAddressPointsTo == MemoryAddress ? 
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
/// @return bool, TRUE is invalid (BUG was found) and FALSE is valid.
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
    return true;
}


/// @brief This replaced the old is_invalid_free function.
/// Checking in the container memory if a given address
/// execute an invalid free, when that given address was released.
/// @param MemoryAddress to be searched in the list
/// @return bool, TRUE is invalid (BUG was found) and FALSE is valid.
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
