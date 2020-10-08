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


#ifndef __CONTAINERTRACKBBLOG_H_INCLUDED__
#define __CONTAINERTRACKBBLOG_H_INCLUDED__

#include "TrackBbLog.hpp"
#include <map>
#include <list>

using namespace std;

#include "../lib/json.hpp"
using json = nlohmann::json;

class ContainerTrackBbLog {
    public:
        list<TrackBbLog> ContainerLog_;
        bool isInTrackedBbLog(long LineNumber);
        string printContainerAsJson();
};

#endif // __CONTAINERTRACKBBLOG_H_INCLUDED__ 