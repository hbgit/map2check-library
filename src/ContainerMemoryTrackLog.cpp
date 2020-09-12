//===-- include/ContainerMemoryTrackLog.cpp - class definition -------*- C++
//-*-===//
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
/// This file contains the declaration of the ContainerMemoryTrackLog.cpp class,
/// which modelling the Container to storage a list with TrackBbLog objects.
/// The functions are based on paper "Memory Management Test-Case Generation of
/// C Programs" (SEFM 2015).
///
//===----------------------------------------------------------------------===//

#include "../include/ContainerMemoryTrackLog.hpp"
#include "../include/MemoryTrackLog.hpp"
#include "../lib/json.hpp"
#include <algorithm>
using json = nlohmann::json;

#include <boost/range/adaptor/reversed.hpp>
#include <iostream>

/// @brief Print an given TrackBbLog object in Json format.
/// @param ObjModelIn TrackBbLog object
/// @return The Json string
string ContainerMemoryTrackLog::printJsonObj(MemoryTrackLog ObjModelIn) {
  json j;

  j["VarMemoryAddress"] = ObjModelIn.VarMemoryAddress;
  j["MemoryAddressPointsTo"] = ObjModelIn.MemoryAddressPointsTo;
  j["Scope"] = ObjModelIn.Scope;
  j["IsDynamic"] = ObjModelIn.IsDynamic;
  j["IsFree"] = ObjModelIn.IsFree;
  j["LineNumber"] = ObjModelIn.LineNumber;
  j["PointerName"] = ObjModelIn.PointerName;
  j["FunctionName"] = ObjModelIn.FunctionName;
  j["SizeToDestiny"] = ObjModelIn.SizeToDestiny;
  j["SizeOfPrimitive"] = ObjModelIn.SizeOfPrimitive;

  return j.dump().c_str();
}

/// @brief Check if two object are equals, i.e., they have the
/// same atributes.
bool ContainerMemoryTrackLog::isEqualMemoryTrackObj(MemoryTrackLog ObjMemory1,
                                                    MemoryTrackLog ObjMemory2) {

  if (ObjMemory1.VarMemoryAddress == ObjMemory2.VarMemoryAddress &&
      ObjMemory1.MemoryAddressPointsTo == ObjMemory2.MemoryAddressPointsTo &&
      ObjMemory1.Scope == ObjMemory2.Scope &&
      ObjMemory1.IsDynamic == ObjMemory2.IsDynamic &&
      ObjMemory1.IsFree == ObjMemory2.IsFree) {

    return true;
  }

  return false;
}

/// @brief This replaced the old map2check_alloca function.
/// Tracking alloca instruction in LLVM-IR, i.e., var decl.
void ContainerMemoryTrackLog::mapAlloca(long Step,
                                        MemoryTrackLog ObjectMemory) {
  map<long, MemoryTrackLog> MapTmp;
  MapTmp.insert(pair<long, MemoryTrackLog>(++Step, ObjectMemory));
  this->ContainerLog_.push_back(MapTmp);
}

/// @brief This replaced the old map2check_non_static_alloca function.
/// Tracking alloca instruction in LLVM-IR, i.e., static var decl.
void ContainerMemoryTrackLog::mapNonStaticAlloca(long Step,
                                                 MemoryTrackLog ObjectMemory) {
  ObjectMemory.SizeToDestiny =
      ObjectMemory.SizeToDestiny * ObjectMemory.SizeOfPrimitive;
  this->mapAlloca(Step, ObjectMemory);
}

/// @brief This replaced the old map2check_function function.
/// Tracking function address in LLVM-IR, i.e., function decl.
void ContainerMemoryTrackLog::mapFunctionAddress(long Step,
                                                 MemoryTrackLog ObjectMemory) {
  map<long, MemoryTrackLog> MapTmp;
  MapTmp.insert(pair<long, MemoryTrackLog>(++Step, ObjectMemory));
  this->ContainerLog_.push_back(MapTmp);
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
/// @return bool if is valid or not
bool ContainerMemoryTrackLog::isValidAllocaAddress(long Address, int Size) {
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
/// if we find that the address was released, then we go on
/// if not we return FALSE
/// @param Step Current step of the program analysis
/// @param Address Address to set up as alloca
/// @return map<Error,Address>
map<bool, long> ContainerMemoryTrackLog::isAllAllocaAddressValidInTheEnd() {
  long MemTrackAddressError = 0;
  map<bool, long> MapTmp;

  // Search from bottom/reverse
  list<map<long, MemoryTrackLog>>::reverse_iterator rit;

  for (rit = this->ContainerLog_.rbegin(); rit != this->ContainerLog_.rend();
       rit++) {
    if (rit->begin()->second.IsFree == false) {
      bool ReleasedFound = false;
      MemTrackAddressError = rit->begin()->second.VarMemoryAddress;
      // Search from top
      for (auto item : this->ContainerLog_) {
        if (MemTrackAddressError == item.begin()->second.VarMemoryAddress &&
            item.begin()->second.IsFree) {
          ReleasedFound = true;
        }
      }

      if (ReleasedFound == false) {
        MapTmp.insert(pair<bool, long>(false, MemTrackAddressError));
        return MapTmp;
      }
    }
  }
  MapTmp.insert(pair<bool, long>(true, 0));
  return MapTmp;
}

// From HeapLog Begin ============================
/// @brief This replaced the old is_valid_heap_address function.
/// Checking if a given Address is valid in the Heap Address.
/// It is called heap because it is a pile of memory space available to
/// programmers to allocated and de-allocate. We iterate over all elements,
/// beggining from back, if the address that we are looking for is in the range
/// of the element address memory space, different from Alloca here we do not
/// check if the element is not free.
/// @param Address Address to set up as alloca
/// @param Size    Size memory
/// @return bool if is valid or not
bool ContainerMemoryTrackLog::isValidHeapAddress(long Address, int Size) {
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

/// @brief This replaced the old map2check_malloc function.
/// Tracks address that was pass as input to malloc function.
/// @param Step Current step of the program analysis
/// @param Address Address to set up as alloca
/// @param Size Size of the allocated addres
/// @return void
void ContainerMemoryTrackLog::setMalloc(long Step, long Address, int Size) {
  auto AllocaTmp = this->searchInContainerLogByAddress(Address);

  if (AllocaTmp.VarMemoryAddress != 0) {
    AllocaTmp.SizeToDestiny = Size;
    AllocaTmp.IsFree = false;
  } else {
    AllocaTmp.VarMemoryAddress = Address;
    AllocaTmp.SizeToDestiny = Size;
    AllocaTmp.IsFree = false;
  }
  map<long, MemoryTrackLog> MapTmp;
  MapTmp.insert(pair<long, MemoryTrackLog>(++Step, AllocaTmp));
  this->ContainerLog_.push_back(MapTmp);
}

/// @brief This replaced the old map2check_malloc function.
/// Tracks address that are resolved during free (this function is
/// to be used for instrumentation)
/// @param Step Current step of the program analysis
/// @param Address Address to set up as calloca to alloca
/// @param Quantity The Size
/// @param Size Size of the allocated addres
/// @return void
void ContainerMemoryTrackLog::setCalloc(long Step, long Address, int Quantity,
                                        int Size) {
  this->setMalloc(Step, Address, Quantity * Size);
}

/// @brief This replaced the old map2check_add_store_pointer function.
/// Tracking pointer store, i.e., pointer assignment
void ContainerMemoryTrackLog::mapStorePointer(long Step,
                                              MemoryTrackLog ObjectMemory) {
  // Search from bottom/reverse
  list<map<long, MemoryTrackLog>>::reverse_iterator rit;

  for (rit = this->ContainerLog_.rbegin(); rit != this->ContainerLog_.rend();
       rit++) {

    if (rit->begin()->second.VarMemoryAddress ==
        ObjectMemory.VarMemoryAddress) {
      if (!this->isEqualMemoryTrackObj(rit->begin()->second, ObjectMemory)) {
        map<long, MemoryTrackLog> MapTmp;
        MapTmp.insert(pair<long, MemoryTrackLog>(++Step, ObjectMemory));
        this->ContainerLog_.push_back(MapTmp);
      }
    }
  }
}

/// @brief This replaced the old map2check_free_resolved_address function.
/// Tracks address that are resolved during free (this function is to be used for
/// instrumentation)
void ContainerMemoryTrackLog::setFree(long Step, MemoryTrackLog ObjectMemory, short int IsNullValid){
  if(ObjectMemory.VarMemoryAddress == (long)NULL && IsNullValid){
    return ;
  }

  // TODO: Add check invalid free

  ObjectMemory.SizeToDestiny = 0;
  ObjectMemory.IsFree = true;
  ObjectMemory.IsDynamic = false;

  map<long, MemoryTrackLog> MapTmp;
  MapTmp.insert(pair<long, MemoryTrackLog>(++Step, ObjectMemory));
  this->ContainerLog_.push_back(MapTmp);
}