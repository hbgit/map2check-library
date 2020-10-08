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
  list<MemoryTrackLog> ContainerLog_;
  string printContainerAsJson();
  MemoryTrackLog searchInContainerLogByAddress(long Address);

  // Map tracking actions
  void mapAlloca(MemoryTrackLog ObjectMemory);
  void mapNonStaticAlloca(MemoryTrackLog ObjectMemory);
  void mapFunctionAddress(MemoryTrackLog ObjectMemory);
  void mapStorePointer(MemoryTrackLog ObjectMemory);
  
};

#endif // __CONTAINERMEMORYTRACKLOG_H_INCLUDED__