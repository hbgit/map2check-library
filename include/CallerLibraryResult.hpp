//===-- include/CallerWrapperLibrary.cpp - class definition -------*- C++
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
/// which performs the programa analysis by map2check tool.
///
//===----------------------------------------------------------------------===//

#ifndef __CALLERLIBRARYRESULT_H_INCLUDED__
#define __CALLERLIBRARYRESULT_H_INCLUDED__

#include "../include/ContainerNonDetLog.hpp"
#include "../include/ContainerTrackBbLog.hpp" 
#include "../include/ContainerMemoryTrackLog.hpp"

//#include "../lib/json.hpp"

enum ViolatedProperty {
  OVERFLOW,
  MEMSAFETY_FREE,
  MEMSAFETY_DEREF,
  MEMSAFETY_MEMTRACK,
  MEMSAFETY_MEMCLEANUP,
  REACHABILITY,
  CONCURRENCY,
  NONE
};

enum PropertyType {
  COVERFLOW,
  CMEMSAFETY,
  CREACHABILITY,
  CCONCURRENCY,
  CNONE
};

enum VerificationResultName { FALSE, TRUE, UNKNOWN };

//template ContainerNonDetLog<unsigned int>;

// Objects to performs the program analysis
extern ContainerNonDetLog ResultCntrNonDetLog;
extern ContainerTrackBbLog ResultCntrTrackBbLog;
extern ContainerMemoryTrackLog ResultCntrMemoryLog;

// Variables of the verification result
extern long LineNumberOfPropertyChecked;
extern string JsonFinalResult;
extern string FunctionNamePrpChecked;
extern VerificationResultName VerificationResult;
extern ViolatedProperty PropertyChecked;

extern long CurrentStep;

/// @brief Print all data gathering from code instrumentation, such as,
/// property location, and values adopting in the program verification.
/// @return The Json string
extern "C" void map2checkPrintJsonCheckResult(PropertyType PropertyChecked);

extern "C" void map2check_success();

extern "C" void incrCurrentStep();

extern "C" long getCurrentStep();

string printAllContainerAsJson();

void resetCntrs();

#endif // __CALLERLIBRARYRESULT_H_INCLUDED__ 