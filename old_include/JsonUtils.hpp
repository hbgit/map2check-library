//===-- include/JsonUtils.hpp - class definition -------*- C++ -*-===//
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
/// This file contains the declaration of the JsonUtils.hpp class, which 
/// modelling the JsonUtils object.
///
//===----------------------------------------------------------------------===//

#ifndef __JSONUTILS_H_INCLUDED__
#define __JSONUTILS_H_INCLUDED__

#include <string>
#include "../lib/json.hpp"

using json = nlohmann::json;
using namespace std;

class JsonUtils {
    public:
        string printJsonObj(json VarJson);
};

#endif // __JSONUTILS_H_INCLUDED__ 