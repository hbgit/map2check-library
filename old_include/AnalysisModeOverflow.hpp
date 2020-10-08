//===-- include/AnalysisModeOverflow.hpp - class definition -------*- C++ -*-===//
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
/// This file contains the declaration of the AnalysisModeOverflow.hpp class, which 
/// modelling the programa analysis to check overflow operation in a given C code.
///
//===----------------------------------------------------------------------===//

#ifndef __ANALYSISMODEOVERFLOW_H_INCLUDED__
#define __ANALYSISMODEOVERFLOW_H_INCLUDED__

#include <boost/variant/variant.hpp>
#include <string>

using namespace std;

class AnalysisModeOverflow {
    public:
        unsigned LineNumber;
        string FunctionName;
        boost::variant<int,unsigned> ValueParam1;
        boost::variant<int,unsigned> ValueParam2;
        int Scope;

        size_t popcount(uintmax_t);
        // signed        
        bool checkOverBinopAddInt();        
        bool checkOverBinopSubInt();
        bool checkOverBinopMulInt();
        bool checkOverBinopDivInt();       
        bool checkOverBinopShlInt(); //shift left
        bool checkOverBinopShRInt(); //shift right
        bool checkOverBinopNegInt();
        // unsigned
        bool checkOverBinopAddUint();
        bool checkOverBinopSubUint();
        bool checkOverBinopMulUint();
        bool checkOverBinopDivUint();
        bool checkOverBinopShRUint(); //shift
        
        
         
};

#endif // __ANALYSISMODEOVERFLOW_H_INCLUDED__ 