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

#include "../include/CallerLibraryResult.hpp"

#include <iostream>

using namespace std;

using json = nlohmann::json;

// Initialize global variables
long CurrentStep = 0;
long LineNumberOfPropertyChecked = -1;
string JsonFinalResult = "NONE";
string FunctionNamePrpChecked = "NONE";
VerificationResultName VerificationResult = UNKNOWN;
ViolatedProperty PropertyChecked = NONE;

ContainerNonDetLog ResultCntrNonDetLog;
ContainerTrackBbLog ResultCntrTrackBbLog;
ContainerMemoryTrackLog ResultCntrMemoryLog;

// Handling with enums
const char *ToEnum_VerificationResultName[] = {"FALSE", "TRUE", "UNKNOWN"};
const char *ToEnum_ViolatedProperty[] = {"OVERFLOW",
                                         "MEMSAFETY_FREE",
                                         "MEMSAFETY_DEREF",
                                         "MEMSAFETY_MEMTRACK",
                                         "MEMSAFETY_MEMCLEANUP",
                                         "REACHABILITY",
                                         "CONCURRENCY",
                                         "NONE"};

/// @brief Print all data gathering from code instrumentation, such as,
/// property location, and values adopting in the program verification.
/// @return The Json string
extern "C" void
map2checkPrintJsonCheckResult(PropertyType PropertyCheckedTyped) {
  json VarJson;

  string TmpJson;

  if (PropertyCheckedTyped == CNONE) {
    VarJson["VerificationResult"] = ToEnum_VerificationResultName[TRUE];
  } else {
    VarJson["VerificationResult"] =
        ToEnum_VerificationResultName[VerificationResult];
  }

  if (PropertyCheckedTyped != CNONE && VerificationResult != TRUE) {
    VarJson["ViolatedProperty"] = ToEnum_ViolatedProperty[PropertyChecked];
    VarJson["LineNumProperty"] = LineNumberOfPropertyChecked;
    VarJson["FunctionName"] = FunctionNamePrpChecked;
  }

  // Print NonDetValues
  VarJson["ValuesTracked"] = ResultCntrNonDetLog.printContainerAsJson();

  // Print Tracked Basic Block
  VarJson["BasicBlocks"] = ResultCntrTrackBbLog.printContainerAsJson();

  // Print Memory Tracked if it was performed
  if (PropertyCheckedTyped == CMEMSAFETY) {
    VarJson["MemoryTracked"] = ResultCntrMemoryLog.printContainerAsJson();
  }

  JsonFinalResult = VarJson.dump();
  cout << JsonFinalResult << endl;
  // const char * s = VarJson.dump().c_str();
}

extern "C" void map2check_success() {
  VerificationResult = TRUE;
  map2checkPrintJsonCheckResult(CNONE);
  abort();
}

extern "C" void incrCurrentStep() { CurrentStep++; }

extern "C" long getCurrentStep() { return CurrentStep; }