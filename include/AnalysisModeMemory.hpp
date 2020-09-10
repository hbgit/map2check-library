//===-- include/AnalysisModeMemory.hpp - class definition -------*- C++ -*-===//
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
/// This file contains the declaration of the AnalysisModeMemory.hpp class, which 
/// modelling the programa analysis to check memory operation in a given C code.
///
//===----------------------------------------------------------------------===//

#ifndef __ANALYSISMODEMEMORY_H_INCLUDED__
#define __ANALYSISMODEMEMORY_H_INCLUDED__

#include "../include/ContainerMemoryTrackLog.hpp"

#include <string>

using namespace std;

class AnalysisModeMemory {
    private:
        list<map<long, MemoryTrackLog>> ContainerLog_;

    public:
        AnalysisModeMemory(ContainerMemoryTrackLog CntrMemTrkLog);

        bool IsNullValid;
        bool IsCheckMemCleanUp;

        bool freeResolvedAddress(ContainerMemoryTrackLog CntrMemTrkLog);
        bool isMemCleanUpError(long MemoryAddress);
        bool isDerefError(long MemoryAddress);
        bool isInvalidFree(long MemoryAddress);
        bool memLoad(void * PtrAddress, int SizeAddress);
        bool memFree(ContainerMemoryTrackLog CntrMemTrkLog);
        bool memIsMemCleanUpError();
        
};

#endif // __ANALYSISMODEMEMORY_H_INCLUDED__ 