/**
 * Copyright (C) 2014 - 2020 Map2Check tool
 * This file is part of the Map2Check tool, and is made available under
 * the terms of the GNU General Public License version 3.
 *
 * SPDX-License-Identifier: (GPL-3.0)
 *
 * Abstract: This file has all structure to handle the container objects.
 **/

#include "../include/ContainerLog.hpp"
#include "../include/Nondetlog.hpp"

#include <map>
#include <iterator>
#include <boost/variant.hpp>


/**
 * @brief Append an object in its container 
 * @param  Step             Step is a number of the current map2check functions called
 * @param  ObjModelIn       Object modeled to map2check
 * @return                  Returns is void
 */
 // 
template<typename T>
map<long, T> ContainerLog::appendContainerLog(long Step, T ObjModelIn){
    
    map<long, T> ItemContainer; 
    ItemContainer.insert(pair<long, T>(Step, ObjModelIn));
    return ItemContainer;
    //return 0;

}

// Here is the explicit instanciation
template map<long, NonDetLog> 
ContainerLog::appendContainerLog<NonDetLog>(long, NonDetLog); 


/*template <class T>
void Container<T>::allocaLog_show_items_from_log(){

    cout << containerLog_.back().size() << endl;

    cout << "Step;\taddress;\tis_free;\tsize_to_destiny" << endl;
    for(auto item : containerLog_){
        for(auto map_item : item){
            cout << map_item.first << "\t" ;
            cout << map_item.second.address << "\t" ;
            cout << map_item.second.is_free << "\t" ;
            cout << map_item.second.size_to_destiny << endl;
        }
    }
}*/
