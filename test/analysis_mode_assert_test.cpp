#include "gtest/gtest.h"

extern "C" {
  #include "../include/caller/caller_lib_result.h"
  #include "../include/analysismode/analysis_assert.h"
}

TEST(AnalysisModeAssert, ExprFalse) {
  map2check_init();
  debug_assert_set_only_test();
  map2check_is_valid_assert(12, "foo", 144 <= 12);

  EXPECT_EQ(get_current_property(), REACHABILITY);
}

TEST(AnalysisModeAssert, ExprTrue) {
  map2check_init();
  
  debug_assert_set_only_test();
  debug_caller_result_set_only_test();
  
  map2check_is_valid_assert(12, "foo", 12 <= 12);

  EXPECT_EQ(get_current_property(), NONE);
  
  map2check_success();
}