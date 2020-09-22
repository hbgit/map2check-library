//===-- include/CallerLibraryMemoryTrackLog.hpp - class definition -------*- C++
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
/// This file contains the declaration of the CallerLibraryMemoryTrackLog.hpp
/// class, which modelling the memory track in the programa analysis by
/// map2check tool.
///
//===----------------------------------------------------------------------===//

#include "../include/CallerLibraryResult.hpp"
#include "../include/ContainerMemoryTrackLog.hpp"
#include "../include/MemoryTrackLog.hpp"

/// @brief TODO
/// @return The Json string
extern "C" void map2checkMap_Alloca(const char *VarName, void *PtrAddres,
                                    int Size, int SizeOfPrimitive,
                                    int LineNumber, int Scope);

/// @brief TODO
/// @return The Json string
extern "C" void map2checkMap_NonStaticAlloca(const char *VarName,
                                             void *PtrAddres, int Size,
                                             int SizeOfPrimitive,
                                             int LineNumber, int Scope);

/// @brief TODO
/// @return The Json string
extern "C" void map2checkMap_FunctionAddress(const char *VarName,
                                             void *PtrAddres);

/// @brief TODO
/// @return The Json string
extern "C" void map2checkMap_StorePointer(void *VarAddres, void *Value,
                                          unsigned Scope, const char *VarName,
                                          int LineNumber,
                                          const char *FunctionName);

/// @brief TODO
/// @return The Json string
extern "C" void map2checkMap_Free(const char *VarName, void *PtrAddres,
                                  unsigned Scope, unsigned LineNumber,
                                  const char *FunctionName);

/// @brief TODO
/// @return The Json string
extern "C" void map2checkMap_Malloc(void *PtrAddres, int Size);

/// @brief TODO
/// @return The Json string
extern "C" void map2checkMap_Calloc(void *PtrAddres, int Quantity, int Size);