/**
 * Copyright (C) 2014 - 2020 Map2Check tool
 * This file is part of the Map2Check tool, and is made available under
 * the terms of the GNU General Public License version 3.
 *
 * SPDX-License-Identifier: (GPL-3.0)
 *
 * Abstract: This file has all structure to handle the container objects.
 **/

#include "../include/Container.hpp"
#include <list> 
#include <iterator> 

#include <boost/variant.hpp>

/**
 * @brief Create a Container object to save the data from model proposed
 * in this library. In this case, for each object k of type T in 
 * the set of models {} we have a list<map<unsigned, T>>, i.e., 
 * the private attribute containerLog_.
 */
template <class T>
Container<T>::Container(){}


/**
 * @brief Append an object in its container 
 * @param  step             Step is a number of the current map2check functions called
 * @param  object_model_in  Object modeled to map2check
 * @return                  Returns is void
 */
template <class T>
void Container<T>::append_container(int step, T object_model_in){
    
    map<int, T> item_to_container; 
    item_to_container.insert(pair<int, T>(step, object_model_in));
    containerLog_.push_back(item_to_container);

}


/**
 * @brief  Print in CSV format all data from the NonDetLog Container
 */
template <class T>
void Container<T>::nonDetLog_show_items_from_log(){

    cout << containerLog_.back().size() << endl;

    cout << "Step;\tLine;\tScope;\tValue;\tType;\tFunction" << endl;
    for(auto item : containerLog_){
        for(auto map_item : item){
            cout << map_item.first << "\t" ;
            cout << map_item.second.Line << "\t" ;
            cout << map_item.second.Scope << "\t" ;
            cout << map_item.second.Value << "\t" ;
            cout << this->nonDetLog_get_type_value(map_item.second) << "\t" ;
            cout << map_item.second.FunctionName << "\t" << endl;
        }
    }
}


/**
 * @brief  Print in CSV format all data from the AllocaLog Container
 */
template <class T>
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
}
