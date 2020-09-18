//===-- include/MemoryTrackLog.cpp - class definition -------*- C++ -*-===//
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
/// This file contains the declaration of the MemoryTrackLog.cpp class, which
/// it handles the MemoryTrackLog object.
///
//===----------------------------------------------------------------------===//

#include "../include/MemoryTrackLog.hpp"

/// @brief This replaced the old map2check_malloc function.
/// Tracks address that was pass as input to malloc function.
/// @return void
void MemoryTrackLog::setMalloc() {

  if (this->VarMemoryAddress != 0) {
    this->IsFree = false;
    this->IsDynamic = true;
  } else {
    this->IsFree = false;
    this->IsDynamic = true;
  }

  this->Step = ++this->Step;
}

/// @brief Tracks address that was pass as input to calloc function.
/// @param Step Current step of the program analysis
/// @param Quantity The number of the elements
/// @return void
void MemoryTrackLog::setCalloc(int Quantity) {
  this->SizeToDestiny = Quantity * this->SizeToDestiny;
  this->setMalloc();
}

/// @brief This replaced the old map2check_free_resolved_address function.
/// Tracks address that is given as input to a free function.
void MemoryTrackLog::setFree() {
  if (this->VarMemoryAddress == (long)NULL && this->IsNullValid) {
    return;
  }

  // TODO: Add check invalid free

  this->SizeToDestiny = 0;
  this->IsFree = true;
  this->IsDynamic = false;

  this->Step = ++this->Step;
}


/// @brief Check if two object are equals, i.e., they have the value in their
/// attributes
/// @param ObjMemory1 First MemoryTrackLog object to be compared
/// @param ObjMemory2 Second MemoryTrackLog object to be compared
/// @return bool
bool MemoryTrackLog::isEqualMemoryTrackObj(MemoryTrackLog ObjMemory1,
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