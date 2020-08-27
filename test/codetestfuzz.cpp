#include "../include/NonDetGenLibFuzzer.hpp"

#include <assert.h>

#include <cstring>
#include <limits>
#include <limits.h>
#include <cmath>
#include <iostream>

using namespace std;

int __map2check_main__(){
    unsigned long vint64 = libFuzzerNonDetInt64_t();    
    //char * vstr = libFuzzerNonDetPChar();
    //bool vbool = libFuzzerNonDetBool();
    //short vshrt = libFuzzerNonDetShort();
    //unsigned vuns = libFuzzerNonDetUnsigned();
    double vdouble = libFuzzerNonDetDouble();
    float vfloat = libFuzzerNonDetFloat();
    //unsigned long vulong = libFuzzerNonDetULong();
    //long vlong = libFuzzerNonDetLong(); //vlong == LONG_MAX &&
    //char vchar = libFuzzerNonDetChar(); //vchar == '?'
    //int32_t vi32 = libFuzzerNonDetInt32_t();
   

   //if(strcmp(vstr, "hello") == 0){
   if(vdouble > 1.45 && vfloat > 1.0145f && vint64 == INT64_MAX){   
    
       cout << "Value vdouble: " << vdouble << endl;
       cout << "Value vfloat: " << vfloat << endl;
       cout << "Value vint64: " << vint64 << endl;
       
       assert(0);

    }
  // }

   /* if(vint64 == INT64_MAX &&
       vint32 == INT32_MAX &&
       vchar  == '-'       &&
       fabs(vfloat == 0.0302548) < std::numeric_limits<float>::epsilon()  &&
       vlong == LONG_MAX   &&
       vun == UINT_MAX     &&
       fabs(vdouble == std::numeric_limits<double>::max()) < std::numeric_limits<double>::epsilon() &&
       vulong == numeric_limits<unsigned long>::max() &&
       vshr == SHRT_MAX    &&
       vbool == false      &&
       vstr == "map2check"
       ){
    
       cout << vint64 << endl;
       cout << vint32 << endl;
       cout << vchar << endl;
       cout << vfloat << endl;
       cout << vun << endl;
       cout << vdouble << endl;
       cout << vulong << endl;
       cout << vshr << endl;
       cout << vbool << endl;
       cout << vstr << endl;
       assert(0);

    }*/

    return 0;
}