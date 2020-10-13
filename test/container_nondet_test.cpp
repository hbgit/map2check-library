#include "gtest/gtest.h"
#include <cstddef>

extern "C" {
#include "../include/nondet/container_nondet.h"
#include "../include/nondet/nondetlog.h"
}

TEST(ContainerNonDetLog, ContainerNonDetLog_init) {
  int v = 12;
  non_det_log_t *obj =
      map2check_save_nondet_log_int(1, 12, 0, INT_ID, &v, "foo");

  map2check_init_container_nondet();
  map2check_save_in_tail_container_nondet(obj);
  
  int v1 = 12;
  non_det_log_t *obj1 =
      map2check_save_nondet_log_int(1, 12, 0, INT_ID, &v1, "foo");

  map2check_save_in_tail_container_nondet(obj1);

  map2check_print_all_nondetlog_as_json();

  EXPECT_TRUE(1);
  //EXPECT_STREQ(print_all_nondet_as_json(), "asd");
}