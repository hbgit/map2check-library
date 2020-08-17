/**
 * Copyright (C) 2014 - 2020 Map2Check tool
 * This file is part of the Map2Check tool, and is made available under
 * the terms of the GNU General Public License version 3.
 *
 * SPDX-License-Identifier: (GPL-3.0)
 *
 * Abstract: This file has NonDetLog object model.
 **/

#include <boost/variant.hpp>

// include guard
#ifndef __NONDETLOG_H_INCLUDED__
#define __NONDETLOG_H_INCLUDED__

using namespace std; 

//typename int::name;

class NonDetLog {
public:    
    unsigned Line;
    unsigned Scope;
    boost::variant<int, unsigned int, char, double, float> Value;
    string FunctionName;     
    
    string getTypeValue(boost::variant<int, unsigned int, char, double, float> Value);
};

//NonDetLog::NonDetLog(){}


#endif // __NONDETLOG_H_INCLUDED__ 