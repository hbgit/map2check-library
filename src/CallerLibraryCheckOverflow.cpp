//===-- include/CallerLibraryCheckOverflow.cpp - class definition -------*- C++
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
/// This file contains the declaration of the CallerLibraryCheckOverflow.cpp
/// class, which performs the programa analysis to validate overflow
/// verification condition by map2check tool.
///
//===----------------------------------------------------------------------===//

// For int
#include "../include/CallerLibraryCheckOverflow.hpp"
#include "AnalysisModeOverflow.hpp"
#include <cstdlib>

extern "C" void map2check_binop_add_int(int param1, int param2, unsigned line,
                                        unsigned scope, char *function_name) {
  AnalysisModeOverflow CheckOverObj;
  CheckOverObj.ValueParam1 = param1;
  CheckOverObj.ValueParam2 = param2;
  CheckOverObj.FunctionName = *function_name;
  CheckOverObj.Scope = scope;
  CheckOverObj.LineNumber = line;

  if (CheckOverObj.checkOverBinopAddInt()) {
    LineNumberOfPropertyChecked = CheckOverObj.LineNumber;
    VerificationResult = FALSE;
    PropertyChecked = OVERFLOW;
    FunctionNamePrpChecked = CheckOverObj.FunctionName;
    map2checkPrintJsonCheckResult(COVERFLOW);
    abort();
  }
}

extern "C" void map2check_binop_sub_int(int param1, int param2, unsigned line,
                                        unsigned scope, char *function_name) {
  AnalysisModeOverflow CheckOverObj;
  CheckOverObj.ValueParam1 = param1;
  CheckOverObj.ValueParam2 = param2;
  CheckOverObj.FunctionName = *function_name;
  CheckOverObj.Scope = scope;
  CheckOverObj.LineNumber = line;

  if (CheckOverObj.checkOverBinopSubInt()) {
    LineNumberOfPropertyChecked = CheckOverObj.LineNumber;
    VerificationResult = FALSE;
    PropertyChecked = OVERFLOW;
    FunctionNamePrpChecked = CheckOverObj.FunctionName;
    map2checkPrintJsonCheckResult(COVERFLOW);
    abort();
  }
}

extern "C" void map2check_binop_mul_int(int param1, int param2, unsigned line,
                                        unsigned scope, char *function_name) {
  AnalysisModeOverflow CheckOverObj;
  CheckOverObj.ValueParam1 = param1;
  CheckOverObj.ValueParam2 = param2;
  CheckOverObj.FunctionName = *function_name;
  CheckOverObj.Scope = scope;
  CheckOverObj.LineNumber = line;

  if (CheckOverObj.checkOverBinopMulInt()) {
    LineNumberOfPropertyChecked = CheckOverObj.LineNumber;
    VerificationResult = FALSE;
    PropertyChecked = OVERFLOW;
    FunctionNamePrpChecked = CheckOverObj.FunctionName;
    map2checkPrintJsonCheckResult(COVERFLOW);
    abort();
  }
}

extern "C" void map2check_binop_div_int(int param1, int param2, unsigned line,
                                        unsigned scope, char *function_name) {
  AnalysisModeOverflow CheckOverObj;
  CheckOverObj.ValueParam1 = param1;
  CheckOverObj.ValueParam2 = param2;
  CheckOverObj.FunctionName = *function_name;
  CheckOverObj.Scope = scope;
  CheckOverObj.LineNumber = line;

  if (CheckOverObj.checkOverBinopDivInt()) {
    LineNumberOfPropertyChecked = CheckOverObj.LineNumber;
    VerificationResult = FALSE;
    PropertyChecked = OVERFLOW;
    FunctionNamePrpChecked = CheckOverObj.FunctionName;
    map2checkPrintJsonCheckResult(COVERFLOW);
    abort();
  }
}

extern "C" void map2check_binop_shl_int(int param1, int param2, unsigned line,
                                        unsigned scope, char *function_name) {
  AnalysisModeOverflow CheckOverObj;
  CheckOverObj.ValueParam1 = param1;
  CheckOverObj.ValueParam2 = param2;
  CheckOverObj.FunctionName = *function_name;
  CheckOverObj.Scope = scope;
  CheckOverObj.LineNumber = line;

  if (CheckOverObj.checkOverBinopShlInt()) {
    LineNumberOfPropertyChecked = CheckOverObj.LineNumber;
    VerificationResult = FALSE;
    PropertyChecked = OVERFLOW;
    FunctionNamePrpChecked = CheckOverObj.FunctionName;
    map2checkPrintJsonCheckResult(COVERFLOW);
    abort();
  }
}

extern "C" void map2check_binop_shr_int(int param1, int param2, unsigned line,
                                        unsigned scope, char *function_name) {
  AnalysisModeOverflow CheckOverObj;
  CheckOverObj.ValueParam1 = param1;
  CheckOverObj.ValueParam2 = param2;
  CheckOverObj.FunctionName = *function_name;
  CheckOverObj.Scope = scope;
  CheckOverObj.LineNumber = line;

  if (CheckOverObj.checkOverBinopShRInt()) {
    LineNumberOfPropertyChecked = CheckOverObj.LineNumber;
    VerificationResult = FALSE;
    PropertyChecked = OVERFLOW;
    FunctionNamePrpChecked = CheckOverObj.FunctionName;
    map2checkPrintJsonCheckResult(COVERFLOW);
    abort();
  }
}

extern "C" void map2check_binop_neg_int(int param1, int param2, unsigned line,
                                        unsigned scope, char *function_name) {
  AnalysisModeOverflow CheckOverObj;
  CheckOverObj.ValueParam1 = param1;
  CheckOverObj.ValueParam2 = param2;
  CheckOverObj.FunctionName = *function_name;
  CheckOverObj.Scope = scope;
  CheckOverObj.LineNumber = line;

  if (CheckOverObj.checkOverBinopNegInt()) {
    LineNumberOfPropertyChecked = CheckOverObj.LineNumber;
    VerificationResult = FALSE;
    PropertyChecked = OVERFLOW;
    FunctionNamePrpChecked = CheckOverObj.FunctionName;
    map2checkPrintJsonCheckResult(COVERFLOW);
    abort();
  }
}

// For unsigned
extern "C" void map2check_binop_add_unsigned(unsigned param1, unsigned param2,
                                             unsigned line, unsigned scope,
                                             char *function_name) {
  AnalysisModeOverflow CheckOverObj;
  CheckOverObj.ValueParam1 = param1;
  CheckOverObj.ValueParam2 = param2;
  CheckOverObj.FunctionName = *function_name;
  CheckOverObj.Scope = scope;
  CheckOverObj.LineNumber = line;

  if (CheckOverObj.checkOverBinopAddUint()) {
    LineNumberOfPropertyChecked = CheckOverObj.LineNumber;
    VerificationResult = FALSE;
    PropertyChecked = OVERFLOW;
    FunctionNamePrpChecked = CheckOverObj.FunctionName;
    map2checkPrintJsonCheckResult(COVERFLOW);
    abort();
  }
}

extern "C" void map2check_binop_sub_unsigned(unsigned param1, unsigned param2,
                                             unsigned line, unsigned scope,
                                             char *function_name) {
  AnalysisModeOverflow CheckOverObj;
  CheckOverObj.ValueParam1 = param1;
  CheckOverObj.ValueParam2 = param2;
  CheckOverObj.FunctionName = *function_name;
  CheckOverObj.Scope = scope;
  CheckOverObj.LineNumber = line;

  if (CheckOverObj.checkOverBinopSubUint()) {
    LineNumberOfPropertyChecked = CheckOverObj.LineNumber;
    VerificationResult = FALSE;
    PropertyChecked = OVERFLOW;
    FunctionNamePrpChecked = CheckOverObj.FunctionName;
    map2checkPrintJsonCheckResult(COVERFLOW);
    abort();
  }
}

extern "C" void map2check_binop_mul_unsigned(unsigned param1, unsigned param2,
                                             unsigned line, unsigned scope,
                                             char *function_name) {
  AnalysisModeOverflow CheckOverObj;
  CheckOverObj.ValueParam1 = param1;
  CheckOverObj.ValueParam2 = param2;
  CheckOverObj.FunctionName = *function_name;
  CheckOverObj.Scope = scope;
  CheckOverObj.LineNumber = line;

  if (CheckOverObj.checkOverBinopMulUint()) {
    LineNumberOfPropertyChecked = CheckOverObj.LineNumber;
    VerificationResult = FALSE;
    PropertyChecked = OVERFLOW;
    FunctionNamePrpChecked = CheckOverObj.FunctionName;
    map2checkPrintJsonCheckResult(COVERFLOW);
    abort();
  }
}

extern "C" void map2check_binop_div_unsigned(unsigned param1, unsigned param2,
                                             unsigned line, unsigned scope,
                                             char *function_name) {
  AnalysisModeOverflow CheckOverObj;
  CheckOverObj.ValueParam1 = param1;
  CheckOverObj.ValueParam2 = param2;
  CheckOverObj.FunctionName = *function_name;
  CheckOverObj.Scope = scope;
  CheckOverObj.LineNumber = line;

  if (CheckOverObj.checkOverBinopDivUint()) {
    LineNumberOfPropertyChecked = CheckOverObj.LineNumber;
    VerificationResult = FALSE;
    PropertyChecked = OVERFLOW;
    FunctionNamePrpChecked = CheckOverObj.FunctionName;
    map2checkPrintJsonCheckResult(COVERFLOW);
    abort();
  }
}

extern "C" void map2check_binop_shr_unsigned(unsigned param1, unsigned param2,
                                             unsigned line, unsigned scope,
                                             char *function_name) {
  AnalysisModeOverflow CheckOverObj;
  CheckOverObj.ValueParam1 = param1;
  CheckOverObj.ValueParam2 = param2;
  CheckOverObj.FunctionName = *function_name;
  CheckOverObj.Scope = scope;
  CheckOverObj.LineNumber = line;

  if (CheckOverObj.checkOverBinopShRUint()) {
    LineNumberOfPropertyChecked = CheckOverObj.LineNumber;
    VerificationResult = FALSE;
    PropertyChecked = OVERFLOW;
    FunctionNamePrpChecked = CheckOverObj.FunctionName;
    map2checkPrintJsonCheckResult(COVERFLOW);
    abort();
  }
}