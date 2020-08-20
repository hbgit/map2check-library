/**
 * Copyright (C) 2014 - 2020 Map2Check tool
 * This file is part of the Map2Check tool, and is made available under
 * the terms of the GNU General Public License version 3.
 *
 * SPDX-License-Identifier: (GPL-3.0)
 *
 * Abstract: This file has all structure to handle the container objects.
 **/


#include "../include/Nondetlog.hpp"

/**
 * @brief  Identify the variable type from NonDetLog value
 * @return typeofvalue      Returns the variable type as string
 */
string NonDetLog::getTypeValue(boost::variant<int, unsigned int, long, char, double, float> Value){
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
    if(Value.type() == typeid(long)){
        typeofvalue = "long";
    }
    if(Value.type() == typeid(double)){
        typeofvalue = "double";
    }
    if(Value.type() == typeid(float)){
        typeofvalue = "float";
    }
    
    return typeofvalue;
}
