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
/// which modelling the Container to storage a list with MemoryTrackLog objects.
/// The functions to track memory are based on paper "Memory Management
/// Test-Case Generation of C Programs" (SEFM 2015).
///
//===----------------------------------------------------------------------===//

#include "../include/ContainerMemoryTrackLog.hpp"
#include "../include/MemoryTrackLog.hpp"
#include "../lib/json.hpp"
#include <algorithm>

using json = nlohmann::json;

#include <boost/range/adaptor/reversed.hpp>
#include <iostream>

/// @brief Print all MemoryTrackLog object inside the Container as Json string
/// format.
/// @return The Json string
string ContainerMemoryTrackLog::printContainerAsJson() {

  // Search from bottom/reverse
  list<map<long, MemoryTrackLog>>::iterator it;
  std::string JsonString;

  for (it = this->ContainerLog_.begin(); it != this->ContainerLog_.end();
       it++) {
    json j = it->begin()->second;
    JsonString += j.dump().c_str();
  }

  return JsonString;
}


/// @brief Searching in reverse order in the container list by a given address.
/// @param Address to be searched in the container.
/// @return A MemoryTrackLog object that has the address.
MemoryTrackLog
ContainerMemoryTrackLog::searchInContainerLogByAddress(long Address) {

  for (auto item : boost::adaptors::reverse(this->ContainerLog_)) {
    if (item.begin()->second.VarMemoryAddress == Address) {
      return item.begin()->second;
    }
  }

  MemoryTrackLog t; // default object and empty
  t.MemoryAddressPointsTo = 0;
  t.MemoryAddressPointsTo = 0;
  t.FunctionName = "NULL";
  t.IsDynamic = false;
  t.IsFree = true;
  t.Scope = -1; // Indicates default object
  return t;
}


/// @brief Check if two object are equals, i.e., they have the value in their
/// attributes
/// @param ObjMemory1 First MemoryTrackLog object to be compared
/// @param ObjMemory2 Second MemoryTrackLog object to be compared
/// @return bool
bool ContainerMemoryTrackLog::isEqualMemoryTrackObj(MemoryTrackLog ObjMemory1,
                                                    MemoryTrackLog ObjMemory2) {

  if (ObjMemory1.VarMemoryAddress == ObjMemory2.VarMemoryAddress &&
      ObjMemory1.MemoryAddressPointsTo == ObjMemory2.MemoryAddressPointsTo &&
      ObjMemory1.Scope == ObjMemory2.Scope &&
      ObjMemory1.IsDynamic == ObjMemory2.IsDynamic &&
      ObjMemory1.IsFree == ObjMemory2.IsFree && 
      ObjMemory1.LineNumber == ObjMemory2.LineNumber) {

    return true;
  }

  return false;
}

/// @brief This replaced the old map2check_alloca function.
/// Tracking alloca instruction in LLVM-IR, i.e., variable declaration.
/// @param Step Current step to track this action
/// @param ObjectMemory MemoryTrackLog object
/// @return void
void ContainerMemoryTrackLog::mapAlloca(long Step,
                                        MemoryTrackLog ObjectMemory) {
  map<long, MemoryTrackLog> MapTmp;
  MapTmp.insert(pair<long, MemoryTrackLog>(++Step, ObjectMemory));
  this->ContainerLog_.push_back(MapTmp);
}

/// @brief This replaced the old map2check_non_static_alloca function.
/// Tracking alloca instruction in LLVM-IR, i.e., static var declaration.
/// @param Step Current step to track this action
/// @param ObjectMemory MemoryTrackLog object
/// @return void
void ContainerMemoryTrackLog::mapNonStaticAlloca(long Step,
                                                 MemoryTrackLog ObjectMemory) {
  ObjectMemory.SizeToDestiny =
      ObjectMemory.SizeToDestiny * ObjectMemory.SizeOfPrimitive;
  this->mapAlloca(Step, ObjectMemory);
}

/// @brief This replaced the old map2check_function function.
/// Tracking function address in LLVM-IR, i.e., function declaration.
/// @param Step Current step to track this action
/// @param ObjectMemory MemoryTrackLog object
/// @return void
void ContainerMemoryTrackLog::mapFunctionAddress(long Step,
                                                 MemoryTrackLog ObjectMemory) {
  map<long, MemoryTrackLog> MapTmp;
  MapTmp.insert(pair<long, MemoryTrackLog>(++Step, ObjectMemory));
  this->ContainerLog_.push_back(MapTmp);
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
    AllocaTmp.IsDynamic = true;
  } else {
    AllocaTmp.VarMemoryAddress = Address;
    AllocaTmp.SizeToDestiny = Size;
    AllocaTmp.IsFree = false;
    AllocaTmp.IsDynamic = true;
  }
  map<long, MemoryTrackLog> MapTmp;
  MapTmp.insert(pair<long, MemoryTrackLog>(++Step, AllocaTmp));
  this->ContainerLog_.push_back(MapTmp);
}

/// @brief Tracks address that was pass as input to calloc function.
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
/// Tracking pointer store, i.e., pointer assignment.
/// @param Step Current step to track this action
/// @param ObjectMemory MemoryTrackLog object
/// @return void
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
        cout << ObjectMemory.IsDynamic << endl;
        this->ContainerLog_.push_back(MapTmp);
        break;
      }
      break;
    }
  }
}

/// @brief This replaced the old map2check_free_resolved_address function.
/// Tracks address that is given as input to a free function.
/// @param Step Current step to track this action
/// @param ObjectMemory MemoryTrackLog object
/// @param IsNullValid Flag to identify if Null address is valid
void ContainerMemoryTrackLog::setFree(long Step, MemoryTrackLog ObjectMemory,
                                      short int IsNullValid) {
  if (ObjectMemory.VarMemoryAddress == (long)NULL && IsNullValid) {
    return;
  }

  // TODO: Add check invalid free

  ObjectMemory.SizeToDestiny = 0;
  ObjectMemory.IsFree = true;
  ObjectMemory.IsDynamic = false;

  map<long, MemoryTrackLog> MapTmp;
  MapTmp.insert(pair<long, MemoryTrackLog>(++Step, ObjectMemory));
  this->ContainerLog_.push_back(MapTmp);
}