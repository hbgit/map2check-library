#include "gtest/gtest.h"

extern "C" {
#include "../include/memtrack/memtracklog.h"
}

TEST(MemTrackLog, MemTrackLog_init) {

  memtrack_log_t *obj = map2check_save_memtrack_log(1, 12, 2, 1441728, 144, 0,
                                                    0, "v", "foo", 4, 4, 1);

  const char *str =
      "{\"step\":1,\"line\":12,\"scope\":2,\"var_mem_address\":1441728,\"mem_"
      "address_points_to\":144,\"is_dynamic\":0,\"is_free\":0,\"ptr_name\":"
      "\"v\",\"function_name\":\"foo\",\"size_destiny\":4,\"size_primitive\":4,"
      "\"is_null_valid\":1}";

  EXPECT_STREQ(print_memtrack_obj_as_json(obj), str);
}

TEST(MemTrackLog, MemTrackLog_Obj_Equal) {

  memtrack_log_t *obj = map2check_save_memtrack_log(1, 12, 2, 1441728, 144, 0,
                                                    0, "v", "foo", 4, 4, 1);

  memtrack_log_t *obj1 = map2check_save_memtrack_log(1, 12, 2, 1441728, 144, 0,
                                                     0, "v", "foo", 4, 4, 1);

  memtrack_log_t *obj2 = map2check_save_memtrack_log(1, 13, 2, 1441728, 144, 0,
                                                     0, "v", "foo", 4, 4, 1);

  EXPECT_EQ(is_equal_memtrack_obj(obj, obj1), true);
  EXPECT_EQ(is_equal_memtrack_obj(obj, obj2), false);
}

TEST(MemTrackLog, MemTrackLog_set_malloc) {

  memtrack_log_t *obj = map2check_save_memtrack_log(1, 12, 2, 1441728, 144, 0,
                                                    0, "v", "foo", 4, 4, 1);

  set_malloc(obj);

  EXPECT_EQ(obj->is_dynamic, true);
}

TEST(MemTrackLog, MemTrackLog_set_calloc) {

  memtrack_log_t *obj = map2check_save_memtrack_log(1, 12, 2, 1441728, 144, 0,
                                                    0, "v", "foo", 4, 4, 1);

  int tmp = obj->size_destiny;
  set_calloc(4, obj);

  EXPECT_EQ(obj->is_dynamic, true);
  EXPECT_GE(obj->size_destiny, tmp);
}

TEST(MemTrackLog, MemTrackLog_set_free) {

  memtrack_log_t *obj = map2check_save_memtrack_log(1, 12, 2, 1441728, 144, 0,
                                                    0, "v", "foo", 4, 4, 1);

  set_malloc(obj);
  EXPECT_EQ(obj->is_dynamic, true);

  set_free(obj);
  EXPECT_EQ(obj->is_free, true);
}
