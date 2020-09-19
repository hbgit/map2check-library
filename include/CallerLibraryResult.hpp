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

#include "../include/ContainerNonDetLog.hpp"
#include "../include/ContainerTrackBbLog.hpp" 
#include "../include/ContainerMemoryTrackLog.hpp"

#include "../lib/json.hpp"

enum ViolatedProperty {
  OVERFLOW,
  MEMSAFETY_FREE,
  MEMSAFETY_DEREF,
  MEMSAFETY_MEMTRACK,
  MEMCLEANUP,
  REACHABILITY,
  CONCURRENCY
};

enum PropertyType {
  COVERFLOW,
  CMEMSAFETY,
  CREACHABILITY,
  CCONCURRENCY
};

enum VerificationResultName { FALSE, TRUE, UNKNOWN };

// Objects to performs the program analysis
ContainerNonDetLog ResultCntrNonDetLog;
ContainerTrackBbLog ResultCntrTrackBbLog;
ContainerMemoryTrackLog ResultCntrMemoryLog;

// Variables of the verification result
unsigned LineNumberOfPropertyChecked;
string FunctionNamePrpChecked;
VerificationResultName VerificationResult;
ViolatedProperty PropertyChecked;

long CurrentStep = 0;

/// @brief Print all data gathering from code instrumentation, such as,
/// property location, and values adopting in the program verification.
/// @return The Json string
extern "C" const char *map2checkPrintJsonCheckResult(PropertyType PropertyChecked);