#include "../header/Container.hpp"
#include <list> 
#include <iterator> 

#include <boost/variant.hpp>


template <class T>
Container<T>::Container(){
    
}

template <class T>
void Container<T>::append_container(int step, T object_model_in){
    
    map<int, T> item_to_container; 
    item_to_container.insert(pair<int, T>(step, object_model_in));
    containerLog_.push_back(item_to_container);

}

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
