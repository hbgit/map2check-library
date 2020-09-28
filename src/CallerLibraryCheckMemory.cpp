//===-- include/CallerLibraryCheckMemory.cpp - class definition -------*- C++
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
/// This file contains the declaration of the CallerLibraryCheckMemory.cpp
/// class, which performs the programa analysis to validate memory safety
/// verification condition by map2check tool.
///
//===----------------------------------------------------------------------===//

#include "../include/AnalysisModeMemory.hpp"
#include "../include/CallerLibraryResult.hpp"

bool FlagDeref = false;
bool IsCleanUpCheck = false;
long AddressDeref;

extern "C" void map2check_set_memcleanup() { IsCleanUpCheck = true; }

extern "C" void map2check_check_load(void *ptr, int size) {
  if (!IsCleanUpCheck) {
    AnalysisModeMemory ModeMemObj(ResultCntrMemoryLog.ContainerLog_);
    if (!(ModeMemObj.isValidAllocaAddress((long)ptr, size) &&
          ModeMemObj.isValidHeapAddress((long)ptr, size))) {
      FlagDeref = true;
      AddressDeref = (long)ptr;
    }
  }
}

extern "C" void map2check_check_deref(int line, const char *function_name) {
  if (!IsCleanUpCheck) {
    if (FlagDeref) {
      LineNumberOfPropertyChecked = line;
      VerificationResult = FALSE;
      PropertyChecked = MEMSAFETY_DEREF;
      FunctionNamePrpChecked = function_name;
      map2checkPrintJsonCheckResult(CMEMSAFETY);
      abort();
    }
  }
}

extern "C" void map2check_check_free_resolved_address(void *ptr, unsigned line,
                                                      const char *function_name,
                                                      short int isNullValid) {
  if (!IsCleanUpCheck) {
    AnalysisModeMemory ModeMemObj(ResultCntrMemoryLog.ContainerLog_);
    ModeMemObj.IsNullValid = isNullValid;
    if (ModeMemObj.freeResolvedAddress((long)ptr)) {
      LineNumberOfPropertyChecked = line;
      VerificationResult = FALSE;
      PropertyChecked = MEMSAFETY_FREE;
      FunctionNamePrpChecked = function_name;
      map2checkPrintJsonCheckResult(CMEMSAFETY);
      abort();
    }
  }
}

extern "C" void map2check_check_free(const char *name, void *ptr,
                                     unsigned scope, unsigned line,
                                     const char *function_name) {

  if (!IsCleanUpCheck) {
    AnalysisModeMemory ModeMemObj(ResultCntrMemoryLog.ContainerLog_);

    if (ModeMemObj.isInvalidFree((long)ptr)) {
      LineNumberOfPropertyChecked = line;
      VerificationResult = FALSE;
      PropertyChecked = MEMSAFETY_FREE;
      FunctionNamePrpChecked = function_name;
      map2checkPrintJsonCheckResult(CMEMSAFETY);
      abort();
    }
  }
}

extern "C" void map2check_check_mem_endprog() {
  AnalysisModeMemory ModeMemObj(ResultCntrMemoryLog.ContainerLog_);
  ModeMemObj.IsCheckMemCleanUp = IsCleanUpCheck;
  auto resultSearch = ModeMemObj.isAllAllocaAddressValidInTheEnd();

  if (resultSearch.begin()->first) {
    if (ModeMemObj.IsCheckMemCleanUp) {
      if (ModeMemObj.isMemCleanUpError(resultSearch.begin()->second)) {
        // LineNumberOfPropertyChecked = line;
        VerificationResult = FALSE;
        PropertyChecked = MEMSAFETY_MEMCLEANUP;
        // FunctionNamePrpChecked = function_name;
        map2checkPrintJsonCheckResult(CMEMSAFETY);
        abort();
      }
    } else {
      // LineNumberOfPropertyChecked = line;
      VerificationResult = FALSE;
      PropertyChecked = MEMSAFETY_MEMTRACK;
      // FunctionNamePrpChecked = function_name;
      map2checkPrintJsonCheckResult(CMEMSAFETY);
      abort();
    }
  }
}