//===-- include/ContainerTrackBbLog.hpp - class definition -------*- C++
//-*-===//
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
/// This file contains the declaration of the ContainerTrackBbLog.hpp class,
/// which modelling the Container to storage a list with TrackBbLog objects.
///
//===----------------------------------------------------------------------===//

#include "../include/ContainerTrackBbLog.hpp"

#include <iostream>

/// @brief Print an given TrackBbLog object in Json format.
/// @param ObjModelIn TrackBbLog object
/// @return The Json string
string ContainerTrackBbLog::printContainerAsJson() {
  list<TrackBbLog>::iterator it;
  std::string JsonString = "{\"BasicBlocks\":[";

  for (it = this->ContainerLog_.begin(); it != this->ContainerLog_.end();
       it++) {

    json j = *it;
    int CountItems = 0;
    string Comma = ",";
    JsonString += "{";

    for (auto &el : j.items()) {

      JsonString += "\"" + string(el.key().c_str()) + "\":";
      CountItems++;

      if (CountItems == j.size()) {
        Comma = "";
      }

      if (el.value().is_number() || el.value().is_string()) {
        JsonString += string(el.value().dump().c_str()) + Comma;
      } else {
        JsonString += "\"" + string(el.value().dump().c_str()) + "\"" + Comma;
      }
    }

    JsonString += "}";

    list<TrackBbLog>::iterator tmp = it;
    if (++tmp != this->ContainerLog_.end()) {
      JsonString += ",";
    }
  }

  JsonString += "]}\n";

  return JsonString;
}
// void ContainerTrackBbLog::printContainerAsJson() {

//   list<TrackBbLog>::iterator it;
//   std::string JsonString;

//   for (it = this->ContainerLog_.begin(); it != this->ContainerLog_.end();
//        it++) {
//     json j = *it;
//     JsonString += j.dump().c_str();
//     //JsonString += j;
//   }
//   std::cout << JsonString << std::endl;
//   //return JsonString;
// }

/// @brief Check if a given Line Number is in the Track Basic Block Log.
/// @param LineNumber line number
/// @return bool
bool ContainerTrackBbLog::isInTrackedBbLog(long LineNumber) {
  for (auto item : this->ContainerLog_) {
    if (item.Line == LineNumber) {
      return true;
    }
  }
  return false;
}