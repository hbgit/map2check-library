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
  list<MemoryTrackLog>::iterator it;
  std::string JsonString;

  for (it = this->ContainerLog_.begin(); it != this->ContainerLog_.end();
       it++) {
    json j = *it;
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
    if (item.VarMemoryAddress == Address) {
      return item;
    }
  }

  MemoryTrackLog t; // default object and empty
  return t;
}


/// @brief This replaced the old map2check_alloca function.
/// Tracking alloca instruction in LLVM-IR, i.e., variable declaration.
/// @param Step Current step to track this action
/// @param ObjectMemory MemoryTrackLog object
/// @return void
void ContainerMemoryTrackLog::mapAlloca(MemoryTrackLog ObjectMemory) {
  ObjectMemory.Step = ++ObjectMemory.Step;
  this->ContainerLog_.push_back(ObjectMemory);
}


/// @brief This replaced the old map2check_non_static_alloca function.
/// Tracking alloca instruction in LLVM-IR, i.e., static var declaration.
/// @param Step Current step to track this action
/// @param ObjectMemory MemoryTrackLog object
/// @return void
void ContainerMemoryTrackLog::mapNonStaticAlloca(MemoryTrackLog ObjectMemory) {
  ObjectMemory.SizeToDestiny =
      ObjectMemory.SizeToDestiny * ObjectMemory.SizeOfPrimitive;  
  this->mapAlloca(ObjectMemory);
}


/// @brief This replaced the old map2check_function function.
/// Tracking function address in LLVM-IR, i.e., function declaration.
/// @param Step Current step to track this action
/// @param ObjectMemory MemoryTrackLog object
/// @return void
void ContainerMemoryTrackLog::mapFunctionAddress(MemoryTrackLog ObjectMemory) {
  this->mapAlloca(ObjectMemory);
}


/// @brief This replaced the old map2check_add_store_pointer function.
/// Tracking pointer store, i.e., pointer assignment.
/// @param Step Current step to track this action
/// @param ObjectMemory MemoryTrackLog object
/// @return void
void ContainerMemoryTrackLog::mapStorePointer(MemoryTrackLog ObjectMemory) {
  // Search from bottom/reverse
  list<MemoryTrackLog>::reverse_iterator rit;

  for (rit = this->ContainerLog_.rbegin(); rit != this->ContainerLog_.rend();
       rit++) {

    if (rit->VarMemoryAddress ==
        ObjectMemory.VarMemoryAddress) {          
      if (!ObjectMemory.isEqualMemoryTrackObj(*rit, ObjectMemory)) {
        this->mapAlloca(ObjectMemory);
        break;
      }
      break;
    }
  }
}

