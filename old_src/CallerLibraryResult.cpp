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
#include "../include/MemoryTrackLog.hpp"
#include "../include/TrackBbLog.hpp" 
//#include "../include/JsonUtils.hpp"

//#include <iostream>

#include <stdio.h>

// using namespace std;

// using json = nlohmann::json;

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



void resetCntrs(){
  ResultCntrNonDetLog.ContainerLog_.clear();
  ResultCntrTrackBbLog.ContainerLog_.clear();
  ResultCntrMemoryLog.ContainerLog_.clear();
}

string printAllContainerAsJson() {
  
  list<TrackBbLog>::iterator it;
  std::string JsonString = "{\"BasicBlocks\":[";

  for (it = ResultCntrTrackBbLog.ContainerLog_.begin(); it != ResultCntrTrackBbLog.ContainerLog_.end();
       it++) {

    json j = *it;

    int CountItems = 0;
    string Comma = ",";
    JsonString += "{";

    for (auto &el : j.items()) {

      JsonString += "\"" + string(el.key().c_str()) + "\":";
      CountItems++;

      if (CountItems == j.size()) {
        Comma = "";
      }

      if (el.value().is_number() || el.value().is_string()) {
        JsonString += string(el.value().dump().c_str()) + Comma;
      } else {
        JsonString += "\"" + string(el.value().dump().c_str()) + "\"" + Comma;
      }
    }

    JsonString += "}";

    list<TrackBbLog>::iterator tmp = it;
    if (++tmp != ResultCntrTrackBbLog.ContainerLog_.end()) {
      JsonString += ",";
    }
  }

  JsonString += "],\n";

  //////////////////////////////////////////////////////
  
  list<NonDetLog>::iterator it3;
  
  JsonString += "{\"NonDetValues\":[";

  //for (auto it3 : ResultCntrNonDetLog.ContainerLog_) {
  for (it3 = ResultCntrNonDetLog.ContainerLog_.begin(); it3 != ResultCntrNonDetLog.ContainerLog_.end();
       it3++) {

    json j = *it3;
    int CountItems = 0;
    string Comma = ",";
    JsonString += "{";

    for (auto &el : j.items()) {

      JsonString += "\"" + string(el.key().c_str()) + "\":";
      CountItems++;

      if (CountItems == j.size()) {
        Comma = "";
      }
      // printf("%s \n", el.key().c_str());
      //printf("%s \n", el.value().type_name());

      if (el.value().is_number() || el.value().is_string()) {
        // printf("%s \n", el.value().dump().c_str());
        JsonString += string(el.value().dump().c_str()) + Comma;
      } else {
        JsonString += "\"" + string(el.value().dump().c_str()) + "\"" + Comma;
      }
    }

    JsonString += "}";

    list<NonDetLog>::iterator tmp = it3;
    if (++tmp != ResultCntrNonDetLog.ContainerLog_.end()) {
      JsonString += ",";
    }
  }

  JsonString += "],\n";

  //////////////////////////////////////////////////////

  list<MemoryTrackLog>::iterator it2;
  JsonString += "\"MemoryTracked\":[";

  for (it2 = ResultCntrMemoryLog.ContainerLog_.begin(); it2 != ResultCntrMemoryLog.ContainerLog_.end();
       it2++) {

    json j = *it2;
    int CountItems = 0;
    string Comma = ",";
    JsonString += "{";

    for (auto &el : j.items()) {

      JsonString += "\"" + string(el.key().c_str()) + "\":";
      CountItems++;

      if (CountItems == j.size()) {
        Comma = "";
      }

      if (el.value().is_number() || el.value().is_string()) {
        JsonString += string(el.value().dump().c_str()) + Comma;
      } else {
        JsonString += "\"" + string(el.value().dump().c_str()) + "\"" + Comma;
      }
    }

    JsonString += "}";

    list<MemoryTrackLog>::iterator tmp = it2;
    if (++tmp != ResultCntrMemoryLog.ContainerLog_.end()) {
      JsonString += ",";
    }
  }

  JsonString += "]}\n";

  return JsonString;
}


/// @brief Print all data gathering from code instrumentation, such as,
/// property location, and values adopting in the program verification.
/// @return The Json string
extern "C" void
map2checkPrintJsonCheckResult(PropertyType PropertyCheckedTyped) {

  /* json VarJson;
  JsonUtils js;


  // string TmpJson;

  if (PropertyCheckedTyped == CNONE) {
    VarJson["VerificationResult"] = ToEnum_VerificationResultName[TRUE];
  }
  else {
    VarJson["VerificationResult"] =
        ToEnum_VerificationResultName[VerificationResult];
  }

  if (PropertyCheckedTyped != CNONE && VerificationResult != TRUE) {
    VarJson["ViolatedProperty"] = ToEnum_ViolatedProperty[PropertyChecked];
    VarJson["LineNumProperty"] = LineNumberOfPropertyChecked;
    VarJson["FunctionName"] = FunctionNamePrpChecked;
  } */

  // Print NonDetValues
  // VarJson["ValuesTracked"] = ResultCntrNonDetLog.printContainerAsJson();

  // // Print Tracked Basic Block
  // VarJson["BasicBlocks"] = ResultCntrTrackBbLog.printContainerAsJson();
  // printf("%s \n", ResultCntrTrackBbLog.printContainerAsJson().c_str());

  // Print Memory Tracked if it was performed
  // if (PropertyCheckedTyped == CMEMSAFETY) {
  //   VarJson["MemoryTracked"] = ResultCntrMemoryLog.printContainerAsJson();
  // }
  // printf("%s \n", ResultCntrMemoryLog.printContainerAsJson().c_str());

  // JsonFinalResult = VarJson.dump();

  // const char * s = VarJson.dump().c_str();
  // ResultCntrTrackBbLog.printContainerAsJson();

  printf("%s \n", printAllContainerAsJson().c_str());

  printf("<<<<<<\t\t\t\t>>>>>>\n");
}

extern "C" void map2check_success() {
  VerificationResult = TRUE;
  map2checkPrintJsonCheckResult(CNONE);
  abort();
}

extern "C" void incrCurrentStep() { CurrentStep++; }

extern "C" long getCurrentStep() { return CurrentStep; }