#include <boost/variant/variant.hpp>
#include <iostream>

#ifndef __ALLOCATIONLOG_H_INCLUDED__
#define __ALLOCATIONLOG_H_INCLUDED__

using namespace std; 

class AllocaLog {
public:
    AllocaLog();
    
    long address;
    int size_to_destiny;
    bool is_free;
};

AllocaLog::AllocaLog(){}

#endif // __ALLOCATIONLOG_H_INCLUDED__ 