//===-- include/AllocaLog.hpp - class definition -------*- C++ -*-===//
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
/// This file contains the declaration of the AllocaLog.hpp class, which 
/// modelling the AllocaLog object.
///
//===----------------------------------------------------------------------===//

#ifndef __ALLOCATIONLOG_H_INCLUDED__
#define __ALLOCATIONLOG_H_INCLUDED__

class AllocaLog {
    public:
        long Address;
        int  SizeToDestiny;
        bool IsFree;
};

#endif // __ALLOCATIONLOG_H_INCLUDED__ 