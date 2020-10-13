#include "gtest/gtest.h"

#include <limits.h>
#include <float.h>

extern "C" {
#include "../include/nondet/nondetlog.h"
}


TEST(NonDetLog, NonDetLog_int) {
  //char p[] = {0x0c};
  int v=12;
  //v = *(char *)p;
  non_det_log_t *obj = map2check_save_nondet_log_int(1, 12, 0, INT_ID, &v, "foo");

  const char *str = "{\"step\":1,\"line\":12,\"scope\":0,\"function_name\":"
                    "\"foo\",\"type\":0,\"value\":12}";

  
  EXPECT_STREQ(print_obj_as_json(obj), str);
}

TEST(NonDetLog, NonDetLog_uint) {
  //char p[] = {0x0c};
  unsigned v=UINT_MAX;
  //v = *(char *)p;
  non_det_log_t *obj = map2check_save_nondet_log_uint(1, 12, 0, UNIT_ID, &v, "foo");

  const char *str = "{\"step\":1,\"line\":12,\"scope\":0,\"function_name\":"
                    "\"foo\",\"type\":1,\"value\":4294967295}";

  
  EXPECT_STREQ(print_obj_as_json(obj), str);
}

TEST(NonDetLog, NonDetLog_long) {
  //char p[] = {0x0c};
  long v=LONG_MAX;
  //v = *(char *)p;
  non_det_log_t *obj = map2check_save_nondet_log_long(1, 12, 0, LONG_ID, &v, "foo");

  const char *str = "{\"step\":1,\"line\":12,\"scope\":0,\"function_name\":"
                    "\"foo\",\"type\":2,\"value\":9223372036854775807}";

  
  EXPECT_STREQ(print_obj_as_json(obj), str);
}

TEST(NonDetLog, NonDetLog_char) {
  //char p[] = {0x0c};
  char v='?';
  //v = *(char *)p;
  non_det_log_t *obj = map2check_save_nondet_log_char(1, 12, 0, CHAR_ID, &v, "foo");

  const char *str = "{\"step\":1,\"line\":12,\"scope\":0,\"function_name\":"
                    "\"foo\",\"type\":3,\"value\":\"?\"}";

  
  EXPECT_STREQ(print_obj_as_json(obj), str);
}

TEST(NonDetLog, NonDetLog_float) {
  float d = FLT_MAX; 

  non_det_log_t *obj = map2check_save_nondet_log_float(1, 12, 0, FLOAT_ID, &d, "foo");

  const char *str = "{\"step\":1,\"line\":12,\"scope\":0,\"function_name\":"
                    "\"foo\",\"type\":5,\"value\":3.40282e+38}";
  
  EXPECT_STREQ(print_obj_as_json(obj), str);
}

TEST(NonDetLog, NonDetLog_double) {
  double d = 1.256489; 

  non_det_log_t *obj = map2check_save_nondet_log_double(1, 12, 0, DOUBLE_ID, &d, "foo");

  const char *str = "{\"step\":1,\"line\":12,\"scope\":0,\"function_name\":"
                    "\"foo\",\"type\":4,\"value\":1.25649}";
  
  EXPECT_STREQ(print_obj_as_json(obj), str);
}

// TEST(NonDetLog, NonDetLog_float)
// {
//     NonDetLog nondet;
//     nondet.Line = 1;
//     EXPECT_EQ(nondet.Line, 1);
//     nondet.Scope = 0;
//     EXPECT_EQ(nondet.Scope, 0);
//     nondet.Value = std::numeric_limits<float>::max();
//     EXPECT_TRUE(boost::get<float>(nondet.Value) ==
//     std::numeric_limits<float>::max()); EXPECT_EQ
//     (nondet.getTypeValue(nondet.Value), "float"); nondet.FunctionName =
//     "test"; EXPECT_EQ (nondet.FunctionName, "test");
// }

// TEST(NonDetLog, NonDetLog_char)
// {
//     NonDetLog nondet;
//     nondet.Line = 1;
//     EXPECT_EQ(nondet.Line, 1);
//     nondet.Scope = 0;
//     EXPECT_EQ(nondet.Scope, 0);
//     nondet.Value = std::numeric_limits<char>::max();
//     EXPECT_TRUE(boost::get<char>(nondet.Value) ==
//     std::numeric_limits<char>::max());
//     //EXPECT_EQ (nondet.getTypeValue(nondet.Value), "unsigned");
//     nondet.FunctionName = "test";
//     EXPECT_EQ (nondet.FunctionName, "test");
// }

// TEST(NonDetLog, NonDetLog_unsigned)
// {
//     NonDetLog nondet;
//     nondet.Line = 1;
//     EXPECT_EQ(nondet.Line, 1);
//     nondet.Scope = 0;
//     EXPECT_EQ(nondet.Scope, 0);
//     unsigned k = std::numeric_limits<unsigned>::max();
//     nondet.Value = k;
//     EXPECT_TRUE(boost::get<unsigned>(nondet.Value) == k);
//     EXPECT_EQ (nondet.getTypeValue(nondet.Value), "unsigned");
//     nondet.FunctionName = "test";
//     EXPECT_EQ (nondet.FunctionName, "test");
// }

// TEST(NonDetLog, NonDetLog_long)
// {
//     NonDetLog nondet;
//     nondet.Line = 1;
//     EXPECT_EQ(nondet.Line, 1);
//     nondet.Scope = 0;
//     EXPECT_EQ(nondet.Scope, 0);
//     nondet.Value = std::numeric_limits<long>::max();
//     EXPECT_TRUE(boost::get<long>(nondet.Value) ==
//     std::numeric_limits<long>::max());
//     //EXPECT_EQ (nondet.getTypeValue(nondet.Value), "unsigned");
//     nondet.FunctionName = "test";
//     EXPECT_EQ (nondet.FunctionName, "test");
// }
