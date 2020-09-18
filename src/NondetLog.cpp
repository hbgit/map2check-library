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

#include "../lib/json.hpp"
using json = nlohmann::json;

#include <boost/variant/get.hpp>


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


string NonDetLog::printJsonObj(){
    json j;

    j["Step"] = this->Step;
    j["Line"] = this->Line;
    j["FunctName"] = this->FunctionName;
    j["Scope"] = this->Scope;
    j["Type"] = this->getTypeValue(this->Value);

    if(this->Value.type() == typeid(int)){
        j["Value"] = boost::get<int>(this->Value);  
    }else if(this->Value.type() == typeid(unsigned)){
        j["Value"] = boost::get<unsigned>(this->Value); 
    }else if(this->Value.type() == typeid(long)){
        j["Value"] = boost::get<long>(this->Value); 
    }else if(this->Value.type() == typeid(char)){
        j["Value"] = boost::get<char>(this->Value);  
    }else if(this->Value.type() == typeid(double)){
        j["Value"] = boost::get<double>(this->Value);  
    }else if(this->Value.type() == typeid(float)){
        j["Value"] = boost::get<float>(this->Value);  
    }   
    
    return j.dump().c_str();
}