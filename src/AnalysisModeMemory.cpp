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


// This file adopted other Container to analysis so we need to check given as
// input the needed containers


/// old map2check_free_resolved_address
/// Tracks address that are resolved during free (this function is to be used for
/// instrumentation)
bool AnalysisModeMemory::freeResolvedAddress(ContainerMemoryTrackLog CntrMemTrkLog){
    
    /*if(this->PtrAddress == NULL && this->IsNullValid){
        return false;
    }*/

    return false;
}