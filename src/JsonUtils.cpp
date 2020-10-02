/**
 * Copyright (C) 2014 - 2020 Map2Check tool
 * This file is part of the Map2Check tool, and is made available under
 * the terms of the GNU General Public License version 3.
 *
 * SPDX-License-Identifier: (GPL-3.0)
 *
 * Abstract: This file has all structure to handle the container objects.
 **/


#include "../include/JsonUtils.hpp"

#include "../lib/json.hpp"
using json = nlohmann::json;


string JsonUtils::printJsonObj(json VarJson){
    string tmp = VarJson.dump().c_str();
    return tmp;
}