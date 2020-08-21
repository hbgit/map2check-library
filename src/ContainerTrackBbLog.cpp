//===-- include/ContainerTrackBbLog.hpp - class definition -------*- C++ -*-===//
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
/// This file contains the declaration of the ContainerTrackBbLog.hpp class, which 
/// modelling the Container to storage a list with TrackBbLog objects.
///
//===----------------------------------------------------------------------===//

#include "../include/ContainerTrackBbLog.hpp"

/// @brief Print an given TrackBbLog object in Json format.  
/// @param ObjModelIn TrackBbLog object
/// @return The Json string
string ContainerTrackBbLog::printJsonObj(TrackBbLog ObjModelIn){
    json j;

    j["Line"] = ObjModelIn.Line;
    j["FunctName"] = ObjModelIn.FunctName;
    
    return j.dump().c_str();
}

/// @brief Check if a given Line Number is in the Track Basic Block Log.  
/// @param LineNumber line number
/// @return bool
bool ContainerTrackBbLog::isInTrackedBbLog(long LineNumber){
    for(auto item : this->ContainerLog_){
        if(item.begin()->second.Line == LineNumber){
            return true;
        }        
    }
    return false;
}