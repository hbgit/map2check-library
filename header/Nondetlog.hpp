#include <boost/variant/variant.hpp>
#include <iostream>
// include guard
#ifndef __NONDETLOG_H_INCLUDED__
#define __NONDETLOG_H_INCLUDED__

#include <string>
#include <boost/variant.hpp>
using namespace std; 

class NonDetLog {
public:
    NonDetLog();

    unsigned line;
    unsigned scope;
    boost::variant<int, unsigned, char, double, float> value;
    string functionName;     
 
};

NonDetLog::NonDetLog(){}

#endif // __NONDETLOG_H_INCLUDED__ 