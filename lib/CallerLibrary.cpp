//#include "../header/CallerLibrary.hpp"

#include "../header/Nondetlog.hpp"
#include "../header/Container.hpp"
#include "../lib/Container.cpp"

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
    map2check_nondet.functionName = str_functname;
    map2check_nondet.line = line;
    map2check_nondet.scope = scope;
    map2check_nondet.value = value;

    // Add object in the container
    container_nondetlog.appendContainerNondetLog(
        execution_step, map2check_nondet
    );
    execution_step++;
}


void showItemsFromContNonDetLog(){
    container_nondetlog.showItemsFromContNonDetLog();
}