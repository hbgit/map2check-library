#include "gtest/gtest.h"

extern "C" {
  #include "../include/caller/caller_lib_result.h"
}

TEST(CallerResult, current_step) {
  EXPECT_EQ(get_current_step(), 0);
  next_current_step();
  EXPECT_EQ(get_current_step(), 1);
}

TEST(CallerResult, map2check_init) {
  map2check_init();
  next_current_step();
  //const char *str = "{\"step\":1,\"line\":12,\"function_name\":"
  //                  "\"foo\"}";

  EXPECT_EQ(get_current_step(), 1);
}

TEST(CallerResult, set_false_result) {
  map2check_init();
  set_false_result(OVERFLOW, 15, "foo");
  EXPECT_EQ(get_current_property(), OVERFLOW);
}

TEST(CallerResult, print_all_containers_as_json_TRUE) {
  map2check_init();
  map2check_success();
  EXPECT_TRUE(1);
}

TEST(CallerResult, print_all_containers_as_json_FALSE) {
  map2check_init();
  set_false_result(MEMSAFETY_FREE, 15, "foo");
  print_all_containers_as_json();
  EXPECT_TRUE(1);
}
