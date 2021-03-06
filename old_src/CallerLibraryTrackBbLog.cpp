//===-- include/CallerLibraryTrackBbLog.cpp - class definition -------*- C++
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
/// This file contains the declaration of the CallerWrapperLibrary.cpp class,
/// which performs the track the basic block for the programa analysis 
/// by map2check tool.
///
//===----------------------------------------------------------------------===//

#include "../include/CallerLibraryTrackBbLog.hpp"
#include "../include/CallerLibraryResult.hpp"


extern "C" bool map2checkIsInTrackedBb(unsigned LineNumber){
    return ResultCntrTrackBbLog.isInTrackedBbLog(LineNumber);
}

extern "C" void map2checkAddInTrackedBb(unsigned LineNumber, const char *FunctionName){
    TrackBbLog TrackBbLogObj;
    incrCurrentStep();
    TrackBbLogObj.Step = getCurrentStep();
    TrackBbLogObj.Line = LineNumber;
    TrackBbLogObj.FunctName = FunctionName;
    ResultCntrTrackBbLog.ContainerLog_.push_back(TrackBbLogObj);
}