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
    boost::variant<int, unsigned, char, double, float> Value;
    string FunctionName;     
    
    NonDetLog();
    string getTypeValue(boost::variant<int, unsigned, char, double, float> Value);
};

NonDetLog::NonDetLog(){}

/**
 * @brief  Identify the variable type from NonDetLog value
 * @param  object_model_in  NonDetLog object modeled to map2check
 * @return typeofvalue      Returns the variable type as string
 */
string NonDetLog::getTypeValue(boost::variant<int, unsigned, char, double, float> Value){
    //cout << obj.value.which() << endl;
    string typeofvalue;
    if(Value.type() == typeid(int)){
        typeofvalue = "int";
    }
    if(Value.type() == typeid(unsigned)){
        typeofvalue = "unsigned";
    }
    if(Value.type() == typeid(char)){
        typeofvalue = "char";
    }
    if(Value.type() == typeid(double)){
        typeofvalue = "double";
    }
    if(Value.type() == typeid(float)){
        typeofvalue = "float";
    }
    
    return typeofvalue;
}

#endif // __NONDETLOG_H_INCLUDED__ 