#include "gtest/gtest.h"

extern "C" {
#include "../include/bbtrack/trackbblog.h"
}

TEST(TrackBBLog, TrackBBLog) {
  bbtrack_log_t *obj = map2check_save_basic_block_log(1, 12, "foo");

  const char *str = "{\"step\":1,\"line\":12,\"function_name\":"
                    "\"foo\"}";

  EXPECT_STREQ(print_trackbb_as_json(obj), str);
}