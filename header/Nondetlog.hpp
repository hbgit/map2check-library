#include <iostream>
#include <string>
using namespace std; 

//template <typename T>
class NonDetLog {
public:
    unsigned line;
    unsigned scope;
    //T value;
    string functionName;     

    NonDetLog(); 
};