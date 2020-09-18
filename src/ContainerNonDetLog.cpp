//===-- include/ContainerNonDetLog.cpp - class definition -------*- C++ -*-===//
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
/// This file contains the implementation of the ContainerNonDetLog class, which 
/// modelling the Container to storage a list with NonDetLog objects.
///
//===----------------------------------------------------------------------===//

#include "../include/ContainerNonDetLog.hpp"


/// @brief Print all MemoryTrackLog object inside the Container as Json string
/// format.
/// @return The Json string
string ContainerNonDetLog::printContainerAsJson() {

  // Search from bottom/reverse
  list<NonDetLog>::iterator it;
  std::string JsonString;

  for (it = this->ContainerLog_.begin(); it != this->ContainerLog_.end();
       it++) {
    JsonString += it->printJsonObj();;
  }

  return JsonString;
}


// Here is the explicit instanciation
// template string ContainerNonDetLog::printJsonObj(NonDetLog ObjModelIn, int TypeId); 
// template string ContainerNonDetLog::printJsonObj(NonDetLog ObjModelIn, unsigned TypeId); 
// template string ContainerNonDetLog::printJsonObj(NonDetLog ObjModelIn, char TypeId); 
// template string ContainerNonDetLog::printJsonObj(NonDetLog ObjModelIn, double TypeId); 
// template string ContainerNonDetLog::printJsonObj(NonDetLog ObjModelIn, float TypeId); 