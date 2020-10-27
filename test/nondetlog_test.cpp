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
  non_det_log_t *obj = map2check_save_nondet_log_int(12, 0, INT_ID, &v, "foo");

  const char *str = "{\"step\":1,\"line\":12,\"scope\":0,\"function_name\":"
                    "\"foo\",\"type\":0,\"value\":12}";

  
  EXPECT_STREQ(print_obj_as_json(obj), str);
}

TEST(NonDetLog, NonDetLog_uint) {
  //char p[] = {0x0c};
  unsigned v=UINT_MAX;
  //v = *(char *)p;
  non_det_log_t *obj = map2check_save_nondet_log_uint(12, 0, UNIT_ID, &v, "foo");

  const char *str = "{\"step\":2,\"line\":12,\"scope\":0,\"function_name\":"
                    "\"foo\",\"type\":1,\"value\":4294967295}";

  
  EXPECT_STREQ(print_obj_as_json(obj), str);
}

TEST(NonDetLog, NonDetLog_long) {
  //char p[] = {0x0c};
  long v=LONG_MAX;
  //v = *(char *)p;
  non_det_log_t *obj = map2check_save_nondet_log_long(12, 0, LONG_ID, &v, "foo");

  const char *str = "{\"step\":3,\"line\":12,\"scope\":0,\"function_name\":"
                    "\"foo\",\"type\":2,\"value\":9223372036854775807}";

  
  EXPECT_STREQ(print_obj_as_json(obj), str);
}

TEST(NonDetLog, NonDetLog_char) {
  //char p[] = {0x0c};
  char v='?';
  //v = *(char *)p;
  non_det_log_t *obj = map2check_save_nondet_log_char(12, 0, CHAR_ID, &v, "foo");

  const char *str = "{\"step\":4,\"line\":12,\"scope\":0,\"function_name\":"
                    "\"foo\",\"type\":3,\"value\":\"?\"}";

  
  EXPECT_STREQ(print_obj_as_json(obj), str);
}

TEST(NonDetLog, NonDetLog_float) {
  float d = FLT_MAX; 

  non_det_log_t *obj = map2check_save_nondet_log_float(12, 0, FLOAT_ID, &d, "foo");

  const char *str = "{\"step\":5,\"line\":12,\"scope\":0,\"function_name\":"
                    "\"foo\",\"type\":5,\"value\":3.40282e+38}";
  
  EXPECT_STREQ(print_obj_as_json(obj), str);
}

TEST(NonDetLog, NonDetLog_double) {
  double d = 1.256489; 

  non_det_log_t *obj = map2check_save_nondet_log_double(12, 0, DOUBLE_ID, &d, "foo");

  const char *str = "{\"step\":6,\"line\":12,\"scope\":0,\"function_name\":"
                    "\"foo\",\"type\":4,\"value\":1.25649}";
  
  EXPECT_STREQ(print_obj_as_json(obj), str);
}
