//===-- include/ContainerNonDetLog.h - class definition -------*- C++ -*-===//
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
/// This file contains the declaration of the ContainerNonDetLog class, which 
/// modelling the Container to storage a list with NonDetLog objects.
///
//===----------------------------------------------------------------------===//

#ifndef __CONTAINERNONDETLOG_H_INCLUDED__
#define __CONTAINERNONDETLOG_H_INCLUDED__

#include "Nondetlog.hpp"

#include <list>
#include <map>

class ContainerNonDetLog {   
    public:
        list<NonDetLog> ContainerLog_;        
        //string printContainerAsJson();
};



#endif // __CONTAINERNONDETLOG_H_INCLUDED__ 