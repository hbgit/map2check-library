/**
 * Copyright (C) 2014 - 2020 Map2Check tool
 * This file is part of the Map2Check tool, and is made available under
 * the terms of the GNU General Public License version 2.
 *
 * SPDX-License-Identifier: (GPL-2.0)
 *
 * Abstract: This file has all structure to handle the container objects.
 **/

#include "../header/Container.hpp"
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
 * @brief  Identify the variable type from NonDetLog value
 * @param  object_model_in  NonDetLog object modeled to map2check
 * @return typeofvalue      Returns the variable type as string
 */
template <class T>
string Container<T>::nonDetLog_get_type_value(NonDetLog obj){
    //cout << obj.value.which() << endl;
    string typeofvalue;
    if(obj.value.type() == typeid(int)){
        typeofvalue = "int";
    }
    if(obj.value.type() == typeid(unsigned)){
        typeofvalue = "unsigned";
    }
    if(obj.value.type() == typeid(char)){
        typeofvalue = "char";
    }
    if(obj.value.type() == typeid(double)){
        typeofvalue = "double";
    }
    if(obj.value.type() == typeid(float)){
        typeofvalue = "float";
    }
    
    return typeofvalue;
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
            cout << map_item.second.line << "\t" ;
            cout << map_item.second.scope << "\t" ;
            cout << map_item.second.value << "\t" ;
            cout << this->nonDetLog_get_type_value(map_item.second) << "\t" ;
            cout << map_item.second.functionName << "\t" << endl;
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
