//===-- include/CallerLibraryCheckReach.cpp - class definition -------*- C++
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
/// This file contains the declaration of the CallerLibraryCheckReach.cpp class,
/// which performs the programa analysis to validate an assert by map2check tool.
///
//===----------------------------------------------------------------------===//

#include "../include/CallerLibraryResult.hpp"
#include "../include/AnalysisModeAssert.hpp"

#include <assert.h> 

extern "C" void map2check_assert(int Condition, int LineNumber, const char *FunctionName){
    AnalysisModeAssert CheckAssert;

    incrCurrentStep();
    CheckAssert.Step = getCurrentStep();
    CheckAssert.LineNumber = LineNumber;
    CheckAssert.FunctionName = FunctionName;
    
    if(!CheckAssert.checkAssert(Condition)){
        LineNumberOfPropertyChecked = CheckAssert.LineNumber;
        VerificationResult = FALSE;
        PropertyChecked = REACHABILITY;
        FunctionNamePrpChecked = CheckAssert.FunctionName;
        map2checkPrintJsonCheckResult(CREACHABILITY);
        //abort();
        assert(0);
    }
}