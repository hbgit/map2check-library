//#include "../header/CallerLibrary.hpp"

#include "../include/Nondetlog.hpp"
#include "../include/Container.hpp"
#include "../src/Container.cpp"

using namespace std;

int execution_step = 1;
Container<NonDetLog> container_nondetlog;

// NOTE: https://isocpp.org/wiki/faq/templates#separate-template-fn-defn-from-decl

template<typename T>
void add_item_map2check_nondet_log(
    unsigned line,
    unsigned scope,
    T value,
    const char *functionName
);

template<typename T>
void add_item_map2check_nondet_log(
    unsigned line,
    unsigned scope,
    T value,
    const char *functionName
){
    NonDetLog map2check_nondet;
    std::string str_functname(functionName);
    
    // Set data on NonDetLog object
    map2check_nondet.FunctionName = str_functname;
    map2check_nondet.Line = line;
    map2check_nondet.Scope = scope;
    map2check_nondet.Value = value;

    // Add object in the container
    container_nondetlog.append_container(
        execution_step, map2check_nondet
    );
    execution_step++;
}


void showItemsFromContNonDetLog(){
    container_nondetlog.nonDetLog_show_items_from_log();
}