//===-- include/ContainerMemoryTrackLog.cpp - class definition -------*- C++
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
/// This file contains the declaration of the ContainerMemoryTrackLog.cpp class,
/// which modelling the Container to storage a list with TrackBbLog objects.
///
//===----------------------------------------------------------------------===//

#include "../include/ContainerMemoryTrackLog.hpp"
#include "../include/MemoryTrackLog.hpp"
#include "../lib/json.hpp"
#include <algorithm>
using json = nlohmann::json;

#include <boost/range/adaptor/reversed.hpp>
#include <iostream>

/// @brief Print an given TrackBbLog object in Json format.
/// @param ObjModelIn TrackBbLog object
/// @return The Json string
string ContainerMemoryTrackLog::printJsonObj(MemoryTrackLog ObjModelIn) {
  json j;

  j["VarMemoryAddress"] = ObjModelIn.VarMemoryAddress;
  j["MemoryAddressPointsTo"] = ObjModelIn.MemoryAddressPointsTo;
  j["Scope"] = ObjModelIn.Scope;
  j["IsDynamic"] = ObjModelIn.IsDynamic;
  j["IsFree"] = ObjModelIn.IsFree;
  j["LineNumber"] = ObjModelIn.LineNumber;
  j["PointerName"] = ObjModelIn.PointerName;
  j["FunctionName"] = ObjModelIn.FunctionName;
  j["SizeToDestiny"] = ObjModelIn.SizeToDestiny;
  j["SizeOfPrimitive"] = ObjModelIn.SizeOfPrimitive;
  j["SizeToLoad"] = ObjModelIn.SizeToLoad;

  return j.dump().c_str();
}

/// @brief This replaced the old get_old_reference function.
/// Searching in the container list the last time where the Address
/// was reached
/// @param MemoryAddress to be searched in the list
/// @return The address pointed by the address searched
long ContainerMemoryTrackLog::getLastReference(long MemoryAddress) {
  // Search from bottom/reverse
  list<map<long, MemoryTrackLog>>::reverse_iterator rit;

  for (rit = this->ContainerLog_.rbegin(); rit != this->ContainerLog_.rend();
       rit++) {
    if (rit->begin()->second.VarMemoryAddress == MemoryAddress) {
      return rit->begin()->second.MemoryAddressPointsTo;
    }
  }
  return 0;
}

/// @brief This replaced the old get_type_from_list_log_row function.
/// Getting a given MemoryTrackLOg object.
/// @param ObjectMemory to be analyzed
/// @return MemoryAddressStatus
enum MemoryAddressStatus
ContainerMemoryTrackLog::getMemoryAddressStatus(MemoryTrackLog ObjectMemory) {
  if (ObjectMemory.IsFree && !ObjectMemory.IsDynamic) {
    return FREE;
  } else if (ObjectMemory.IsDynamic) {
    return DYNAMIC;
  }

  // FIXME: how to known if address if static or invalid?
  return STATIC;
}

// From AllocaLog Begin ============================
/// @brief Searching for an given address in the Container list
/// @param Address to be searched in the list
/// @return An MemoryTrackLog object
MemoryTrackLog
ContainerMemoryTrackLog::searchInContainerLogByAddress(long Address) {

  for (auto item : this->ContainerLog_) {
    if (item.begin()->second.VarMemoryAddress == Address) {
      return item.begin()->second;
    }
  }

  MemoryTrackLog tmp; // Element not found
  return tmp;
}

/// @brief This replaced the old mark_deallocation_log function. Saving
/// in the ContainerLog the action executed
/// @param Step Current step of the program analysis
/// @param Address Address to set up as free
/// @return void
void ContainerMemoryTrackLog::setDealallocInAddress(long Step, long Address) {
  auto AllocaTmp = this->searchInContainerLogByAddress(Address);
  AllocaTmp.IsFree = true;

  map<long, MemoryTrackLog> MapTmp;
  MapTmp.insert(pair<long, MemoryTrackLog>(++Step, AllocaTmp));
  this->ContainerLog_.push_back(MapTmp);
}

/// @brief This replaced the old mark_allocation_log function. Saving
/// in the ContainerLog the alloca action executed, e.g., malloc.
/// @param Step Current step of the program analysis
/// @param Address Address to set up as alloca
/// @return void
void ContainerMemoryTrackLog::setAllocInAddress(long Step, long Address) {
  auto AllocaTmp = this->searchInContainerLogByAddress(Address);
  AllocaTmp.IsFree = false;

  map<long, MemoryTrackLog> MapTmp;
  MapTmp.insert(pair<long, MemoryTrackLog>(++Step, AllocaTmp));
  this->ContainerLog_.push_back(MapTmp);
}

/// @brief This replaced the old check_address_allocation_log function.
/// We iterate over all elements starting from back of allocation log
/// in the ContainerLog to get the type of that Address.
/// @param Address Address to set up as alloca
/// @return bool
enum MemoryAddressStatus
ContainerMemoryTrackLog::getAddressTypeInLog(long Address) {
  // Search from bottom/reverse
  list<map<long, MemoryTrackLog>>::reverse_iterator rit;

  for (rit = this->ContainerLog_.rbegin(); rit != this->ContainerLog_.rend();
       rit++) {
    if (rit->begin()->second.VarMemoryAddress == Address) {
      if (rit->begin()->second.IsFree == true) {
        return FREE;
      }
      return DYNAMIC;
    }
  }
  return STATIC;
}

/// @brief This replaced the old valid_allocation_log function.
/// It is to check if all address allocated
/// were released at the end of the program, to check this, we iterate
/// over all elements starting from bottom of allocation log, if the
/// address of the current item is not Free, we iterate from the top
/// if we find that the address was released, then we go on
/// if not we return FALSE
/// @param Step Current step of the program analysis
/// @param Address Address to set up as alloca
/// @return map<Error,Address>
map<bool, long> ContainerMemoryTrackLog::isAllAllocaAddressValidInLog() {
  long MemTrackAddressError = 0;
  map<bool, long> MapTmp;

  // Search from bottom/reverse
  list<map<long, MemoryTrackLog>>::reverse_iterator rit;

  for (rit = this->ContainerLog_.rbegin(); rit != this->ContainerLog_.rend();
       rit++) {
    if (rit->begin()->second.IsFree == false) {
      bool ReleasedFound = false;
      MemTrackAddressError = rit->begin()->second.VarMemoryAddress;
      // Search from top
      for (auto item : this->ContainerLog_) {
        if (MemTrackAddressError == item.begin()->second.VarMemoryAddress &&
            item.begin()->second.IsFree) {
          ReleasedFound = true;
        }
      }

      if (ReleasedFound == false) {
        MapTmp.insert(pair<bool, long>(false, MemTrackAddressError));
        return MapTmp;
      }
    }
  }
  MapTmp.insert(pair<bool, long>(true, 0));
  return MapTmp;
}

/// @brief This replaced the old is_valid_allocation_address function.
/// Checking if a given Address is valid in the Alloca Address
/// We iterate over all elements of the allocation log,
/// beggining from back, if the address that we are looking for is in the range
/// of the element address memory space and the element is not free, then it's
/// TRUE otherwise FALSE and we set last_address to the address of last memory
/// address of the current heap space i.e. a int on space 0x10 on a 32bit would
/// set the var to 0x13 (if the int has 4 bytes)
/// @param Address Address to set up as alloca
/// @param Step Current step of the program analysis
/// @return bool if is valid or not
bool ContainerMemoryTrackLog::isValidAllocaAddress(long Address, int Size) {
  // Search from bottom/reverse
  list<map<long, MemoryTrackLog>>::reverse_iterator rit;

  for (rit = this->ContainerLog_.rbegin(); rit != this->ContainerLog_.rend();
       rit++) {
    long RangeAddress = rit->begin()->second.VarMemoryAddress +
                        (rit->begin()->second.SizeToDestiny - Size) + 1;
    if (rit->begin()->second.VarMemoryAddress <= Address &&
        Address < RangeAddress) {
      if (rit->begin()->second.IsFree) {
        return false;
      }
      return true;
    }
  }
  return false;
}

/// @brief This replaced the old map2check_malloc function.
/// Tracks address that are resolved during free (this function is
/// to be used for instrumentation)
/// @param Step Current step of the program analysis
/// @param Address Address to set up as alloca
/// @param Size Size of the allocated addres
/// @return void
void ContainerMemoryTrackLog::setMalloc(long Step, long Address, int Size) {
  auto AllocaTmp = this->searchInContainerLogByAddress(Address);

  if (AllocaTmp.VarMemoryAddress != 0) {
    AllocaTmp.SizeToDestiny = Size;
    AllocaTmp.IsFree = false;
  } else {
    AllocaTmp.VarMemoryAddress = Address;
    AllocaTmp.SizeToDestiny = Size;
    AllocaTmp.IsFree = false;
  }
  map<long, MemoryTrackLog> MapTmp;
  MapTmp.insert(pair<long, MemoryTrackLog>(++Step, AllocaTmp));
  this->ContainerLog_.push_back(MapTmp);
}

/// @brief This replaced the old map2check_malloc function.
/// Tracks address that are resolved during free (this function is
/// to be used for instrumentation)
/// @param Step Current step of the program analysis
/// @param Address Address to set up as calloca to alloca
/// @param Quantity The Size
/// @param Size Size of the allocated addres
/// @return void
void ContainerMemoryTrackLog::setCalloc(long Step, long Address, int Quantity,
                                        int Size) {
  this->setMalloc(Step, Address, Quantity * Size);
}
// From AllocaLog End ============================

// From HeapLog Begin ============================
/// @brief This replaced the old is_valid_heap_address function.
/// Checking if a given Address is valid in the Heap Address.
/// We iterate over all elements of the allocation log,
/// beggining from back, if the address that we are looking for is in the range
/// of the element address memory space, different from Alloca here we do not
/// check if the element is not free.
/// @param Address Address to set up as alloca
/// @param Size    Size memory
/// @return bool if is valid or not
bool ContainerMemoryTrackLog::isValidHeapAddress(long Address, int Size) {
  // Search from bottom/reverse
  list<map<long, MemoryTrackLog>>::reverse_iterator rit;

  for (rit = this->ContainerLog_.rbegin(); rit != this->ContainerLog_.rend();
       rit++) {
    long RangeAddress = (long)rit->begin()->second.VarMemoryAddress +
                        (rit->begin()->second.SizeToLoad - Size) + 1;
    if (rit->begin()->second.VarMemoryAddress <= Address &&
        (long)Address < RangeAddress) {
      return true;
    }
  }
  return false;
}
// From HeapLog End ============================

// From AnalysisModeMemTrack Begin ============================

/// @brief This replaced the old map2check_non_static_alloca function.
void ContainerMemoryTrackLog::memNonStaticAlloca(long Step,
                                                 MemoryTrackLog ObjectMemory) {
  ObjectMemory.SizeToDestiny =
      ObjectMemory.SizeToDestiny * ObjectMemory.SizeOfPrimitive;
  this->memAlloca(Step, ObjectMemory);
}

/// @brief This replaced the old map2check_alloca function.
void ContainerMemoryTrackLog::memAlloca(long Step,
                                        MemoryTrackLog ObjectMemory) {
  map<long, MemoryTrackLog> MapTmp;
  MapTmp.insert(pair<long, MemoryTrackLog>(++Step, ObjectMemory));
  this->ContainerLog_.push_back(MapTmp);
}

/// @brief This replaced the old map2check_function function.
void ContainerMemoryTrackLog::memFunction(long Step,
                                          MemoryTrackLog ObjectMemory) {
  map<long, MemoryTrackLog> MapTmp;
  MapTmp.insert(pair<long, MemoryTrackLog>(++Step, ObjectMemory));
  this->ContainerLog_.push_back(MapTmp);
}

/// @brief This replaced the old update_reference_list_log function.
/// Updates all variables that points to the address with new status
/// @param Address  Address to be updates
/// @param Status  Current memory status
/// @param LineNumber  Line where operation happened
void ContainerMemoryTrackLog::updateReferenceListLog(long Step, long Address,
                                                     MemoryAddressStatus Status,
                                                     unsigned LineNumber) {
  // Search from top
  list<map<long, MemoryTrackLog>>::iterator it;

  for (it = this->ContainerLog_.begin(); it != this->ContainerLog_.end();
       it++) {
    long CurrentVarAddress = it->begin()->second.VarMemoryAddress;
    long CurrentPointsTo = it->begin()->second.MemoryAddressPointsTo;

    if (CurrentPointsTo == Address &&
        Status != this->getAddressTypeInLog(Address)) {
      // Search from bottom/reverse
      list<map<long, MemoryTrackLog>>::reverse_iterator rit;

      for (rit = this->ContainerLog_.rbegin();
           rit != this->ContainerLog_.rend(); rit++) {
        long RevVarAddress = rit->begin()->second.VarMemoryAddress;
        long RevPointsTo = rit->begin()->second.MemoryAddressPointsTo;

        if (RevPointsTo == Address && RevVarAddress == RevPointsTo) {
          auto GetStatus = this->getAddressTypeInLog(Address);
          if (GetStatus != Status) {
            bool IsDynamic;
            bool IsFree;

            if (Status == STATIC) {
              IsDynamic = false;
              IsFree = false;
            } else if (Status == FREE) {
              IsDynamic = false;
              IsFree = true;
            } else if (Status == DYNAMIC) {
              IsDynamic = true;
              IsFree = false;
            }

            map<long, MemoryTrackLog> MapTmp;
            MemoryTrackLog ObjectMemory = rit->begin()->second;
            ObjectMemory.IsDynamic = IsDynamic;
            ObjectMemory.IsFree = IsFree;
            ObjectMemory.LineNumber = LineNumber;

            MapTmp.insert(pair<long, MemoryTrackLog>(++Step, ObjectMemory));
            this->ContainerLog_.push_back(MapTmp);
          }
          break;
        }
      }
    }
  }
}


void ContainerMemoryTrackLog::memAddStorePointer(MemoryTrackLog ObjectMemory){
  
}
// From AnalysisModeMemTrack End   ============================