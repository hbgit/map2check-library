// Adopted to see how the LLVM-IR is generated
#include "../lib/CallerLibrary.cpp"

//#include "lib/Callerlibrary.cpp"

int main(){

    // instantiates and calls add_map2check_nondet_log<int>(int)
    
    add_item_map2check_nondet_log<int>(
        12,
        0,
        7,
        "hello"
    );
    //foo();

    showItemsFromContNonDetLog();

}

