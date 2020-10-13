#include "gtest/gtest.h"
#include <cstddef>

extern "C" {
#include "../include/bbtrack/container_trackbb.h" 
}

TEST(ContainerTrackBbLog, ContainerTrackBbLog_init) {
  map2check_init_container_trackbb();

  bbtrack_log_t *obj = map2check_save_basic_block_log(1, 12, "foo");
  map2check_save_in_tail_container_trackbb(obj);
  
  bbtrack_log_t *obj1 = map2check_save_basic_block_log(1, 23, "foo");
  map2check_save_in_tail_container_trackbb(obj1);

  map2check_print_all_trackbblog_as_json();

  EXPECT_TRUE(1);
  //EXPECT_STREQ(print_all_nondet_as_json(), "asd");
}

TEST(ContainerTrackBbLog, ContainerTrackBbLog_search) {
  map2check_init_container_trackbb();

  bbtrack_log_t *obj = map2check_save_basic_block_log(1, 12, "foo");
  map2check_save_in_tail_container_trackbb(obj);
  
  bbtrack_log_t *obj1 = map2check_save_basic_block_log(1, 23, "foo");
  map2check_save_in_tail_container_trackbb(obj1);

  EXPECT_EQ(map2check_is_in_trackbb_container(12), 1);
  EXPECT_EQ(map2check_is_in_trackbb_container(144), 0);
  //EXPECT_STREQ(print_all_nondet_as_json(), "asd");
}