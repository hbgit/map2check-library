//===-- include/ContainerNonDetLog.cpp - class definition -------*- C++ -*-===//
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
/// This file contains the implementation of the ContainerNonDetLog class, which 
/// modelling the Container to storage a list with NonDetLog objects.
///
//===----------------------------------------------------------------------===//

#include "../include/ContainerNonDetLog.hpp"

#include "../lib/json.hpp"
using json = nlohmann::json;

#include <boost/variant/get.hpp>


string ContainerNonDetLog::printJsonObj(NonDetLog ObjModelIn){
    json j;

    j["Line"] = ObjModelIn.Line;
    j["FunctName"] = ObjModelIn.FunctionName;
    j["Scope"] = ObjModelIn.Scope;
    j["Type"] = ObjModelIn.getTypeValue(ObjModelIn.Value);

    if(ObjModelIn.Value.type() == typeid(int)){
        j["Value"] = boost::get<int>(ObjModelIn.Value);  
    }else if(ObjModelIn.Value.type() == typeid(unsigned)){
        j["Value"] = boost::get<unsigned>(ObjModelIn.Value); 
    }else if(ObjModelIn.Value.type() == typeid(long)){
        j["Value"] = boost::get<long>(ObjModelIn.Value); 
    }else if(ObjModelIn.Value.type() == typeid(char)){
        j["Value"] = boost::get<char>(ObjModelIn.Value);  
    }else if(ObjModelIn.Value.type() == typeid(double)){
        j["Value"] = boost::get<double>(ObjModelIn.Value);  
    }else if(ObjModelIn.Value.type() == typeid(float)){
        j["Value"] = boost::get<float>(ObjModelIn.Value);  
    }   
    
    return j.dump().c_str();
}

// Here is the explicit instanciation
// template string ContainerNonDetLog::printJsonObj(NonDetLog ObjModelIn, int TypeId); 
// template string ContainerNonDetLog::printJsonObj(NonDetLog ObjModelIn, unsigned TypeId); 
// template string ContainerNonDetLog::printJsonObj(NonDetLog ObjModelIn, char TypeId); 
// template string ContainerNonDetLog::printJsonObj(NonDetLog ObjModelIn, double TypeId); 
// template string ContainerNonDetLog::printJsonObj(NonDetLog ObjModelIn, float TypeId); 