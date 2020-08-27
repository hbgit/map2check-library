#include "../include/NonDetGenLibFuzzer.hpp"

#include <assert.h>

#include <cmath>
#include <cstring>
#include <iostream>
#include <limits.h>
#include <limits>

using namespace std;

int __map2check_main__() {
  //unsigned long vint64 = libFuzzerNonDetInt64_t();
  // char *vstr = libFuzzerNonDetPChar();
  // bool vbool = libFuzzerNonDetBool();
  // short vshrt = libFuzzerNonDetShort();
  // unsigned vuns = libFuzzerNonDetUnsigned();
  // double vdouble = libFuzzerNonDetDouble();
  // float vfloat = libFuzzerNonDetFloat();
  // unsigned long vulong = libFuzzerNonDetULong();
  // long vlong = libFuzzerNonDetLong();
  // char vchar = libFuzzerNonDetChar();
  // int32_t vi32 = libFuzzerNonDetInt32_t();

  unsigned int vuint = libFuzzerNonDetUint();

  // FULL test time: more than 40min
  /*if (vdouble > 1.45 && vfloat > 1.0145f && vint64 == INT64_MAX &&
      vi32 == INT_MAX && vchar == '?' && vuns == UINT_MAX && vbool == false &&
      vshrt == SHRT_MAX && vlong == LONG_MAX && vulong == ULONG_MAX &&
      strcmp(vstr, "hello") == 0) {

    cout << "Value vdouble: " << vdouble << endl;
    cout << "Value vfloat: " << vfloat << endl;
    cout << "Value vint64: " << vint64 << endl;
    cout << "Value vi32: " << vi32 << endl;
    cout << "Value vchar: " << vchar << endl;
    cout << "Value vuns: " << vuns << endl;
    cout << "Value vbool: " << vbool << endl;
    cout << "Value vshrt: " << vshrt << endl;
    cout << "Value vlong: " << vlong << endl;
    cout << "Value vstr: " << vstr[0] << endl;

    assert(0);
  }*/

  if (vuint == UINT_MAX) {

    cout << "Value vint64: " << vuint << endl;

    assert(0);
  }

  return 0;
}