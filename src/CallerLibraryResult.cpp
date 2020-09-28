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

using json = nlohmann::json;

long CurrentStep = 0;

/// @brief Print all data gathering from code instrumentation, such as,
/// property location, and values adopting in the program verification.
/// @return The Json string
extern "C" const char *
map2checkPrintJsonCheckResult(PropertyType PropertyChecked) {
  json VarJson;

  string TmpJson;

  VarJson["VerificationResult"] = VerificationResult;

  if (PropertyChecked != CNONE) {
    VarJson["ViolatedProperty"] = PropertyChecked;
    VarJson["LineNumProperty"] = LineNumberOfPropertyChecked;
    VarJson["FunctionName"] = FunctionNamePrpChecked;
  }

  // Print NonDetValues
  VarJson["ValuesTracked"] = ResultCntrNonDetLog.printContainerAsJson();

  // Print Tracked Basic Block
  VarJson["BasicBlocks"] = ResultCntrTrackBbLog.printContainerAsJson();

  // Print Memory Tracked if it was performed
  if (PropertyChecked == CMEMSAFETY) {
    VarJson["MemoryTracked"] = ResultCntrMemoryLog.printContainerAsJson();
  }

  return VarJson.dump().c_str();
}

extern "C" void map2check_success() {
  VerificationResult = TRUE;
  map2checkPrintJsonCheckResult(CNONE);
  abort();
}

extern "C"  void incrCurrentStep(){
  CurrentStep++;
}

extern "C" long getCurrentStep(){
  return CurrentStep;
}