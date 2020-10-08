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

#include "../lib/json.hpp"
using json = nlohmann::json;

/**
 * @brief Modelling the object to store the data from
 * nondet function calls in the program analysis.
 */
 
class NonDetLog {
public:  
    long Step = 0;
    unsigned Line = -1;
    unsigned Scope = -1;
    //boost::variant<int, unsigned int, long, char, double, float> Value;
    unsigned int Value;
    string FunctionName = "";     
    
    //string getTypeValue(boost::variant<int, unsigned int, long, char, double, float> Value);
    //json printJsonObj();
       
};


NLOHMANN_DEFINE_TYPE_NON_INTRUSIVE(NonDetLog, Step, Line, Scope, Value, FunctionName);
#endif // __NONDETLOG_H_INCLUDED__ 