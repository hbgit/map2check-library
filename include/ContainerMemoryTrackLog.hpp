//===-- include/ContainerMemoryTrackLog.hpp - class definition -------*- C++
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
/// This file contains the declaration of the ContainerMemoryTrackLog.hpp class,
/// which modelling the Container to storage a list with MemoryTrackLog objects.
///
//===----------------------------------------------------------------------===//

#ifndef __CONTAINERMEMORYTRACKLOG_H_INCLUDED__
#define __CONTAINERMEMORYTRACKLOG_H_INCLUDED__

#include "MemoryTrackLog.hpp"
#include <list>
#include <map>

using namespace std;

#include "../lib/json.hpp"
using json = nlohmann::json;

enum MemoryAddressStatus {
  STATIC = 0,
  FREE = 1,
  DYNAMIC = 2
  //  INVALID = 3
};

class ContainerMemoryTrackLog {
public:
  // Container actions
  list<map<long, MemoryTrackLog>> ContainerLog_;
  string printContainerAsJson();
  MemoryTrackLog searchInContainerLogByAddress(long Address);
  bool isEqualMemoryTrackObj(MemoryTrackLog ObjMemory1,
                             MemoryTrackLog ObjMemory2);

  // Map tracking actions
  void mapAlloca(long Step, MemoryTrackLog ObjectMemory);
  void mapNonStaticAlloca(long Step, MemoryTrackLog ObjectMemory);
  void mapFunctionAddress(long Step, MemoryTrackLog ObjectMemory);
  void mapStorePointer(long Step, MemoryTrackLog ObjectMemory);
  
  // Functions from heap memory
  void setMalloc(long Step, long Address, int Size);
  void setCalloc(long Step, long Address, int Quantity, int Size);
  // NOTE: realloc is modelling by set free and then execute a new malloc  
  void setFree(long Step, MemoryTrackLog ObjectMemory,
                     short int IsNullValid);
};

#endif // __CONTAINERMEMORYTRACKLOG_H_INCLUDED__