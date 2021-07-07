#include "gtest/gtest.h"

extern "C" {
#include "../include/memtrack/memtracklog.h"
}

TEST(MemTrackLog, MemTrackLog_create_memtrack_object_log) {

  memtrack_log_t *obj = create_memtrack_object_log(12,
                            "v0",
                            (long)123, 
                            (long)9874561230,
                            0,
                            1, 
                            0, 
                            0,
                            "main", 
                            4,
                            4, 
                            1,
                            INST_ALLOCA);

  EXPECT_EQ(obj->line,12);
  EXPECT_EQ(obj->var_name,"v0");
  EXPECT_EQ(obj->var_mem_address,123);
  EXPECT_EQ(obj->mem_address_points_to,9874561230);
  EXPECT_EQ(obj->type_track,INST_ALLOCA);
  
}

TEST(MemTrackLog, MemTrackLog_print_memtrack_obj_as_json) {
  memtrack_log_t *obj = create_memtrack_object_log(12,
                            "v0",
                            (long)123, 
                            (long)9874561230,
                            0,
                            1, 
                            0, 
                            0,
                            "main", 
                            4,
                            4, 
                            1,
                            INST_ALLOCA);

  const char *str = "{\"step\":15,\"line\":12,\"ptr_name\":\"v0\",\"var_mem_address\":123,\"mem_address_points_to\":9874561230,\"scope_from_mem_address_points_to\":0,\"is_dynamic\":1,\"is_free\":0,\"scope\":0,\"function_name\":\"main\",\"size_destiny\":4,\"size_primitive\":4,\"is_ptr\":1,\"mem_type_track\":0}";
  EXPECT_STREQ(print_memtrack_obj_as_json(obj), str);
}

TEST(MemTrackLog, MemTrackLog_is_equal_memtrack_obj) {

  memtrack_log_t *obj = create_memtrack_object_log(12,
                            "v0",
                            (long)123, 
                            (long)9874561230,
                            0,
                            1, 
                            0, 
                            0,
                            "main", 
                            4,
                            4, 
                            1,
                            INST_ALLOCA);

  memtrack_log_t *obj1 = create_memtrack_object_log(12,
                            "v0",
                            (long)123, 
                            (long)9874561230,
                            0,
                            1, 
                            0, 
                            0,
                            "main", 
                            4,
                            4, 
                            1,
                            INST_ALLOCA);

  memtrack_log_t *obj3 = create_memtrack_object_log(12,
                            "v0",
                            (long)546, 
                            (long)9874561230,
                            0,
                            1, 
                            0, 
                            0,
                            "main", 
                            4,
                            4, 
                            1,
                            INST_ALLOCA);

  EXPECT_EQ(is_equal_memtrack_obj(obj, obj1), true);
  EXPECT_EQ(is_equal_memtrack_obj(obj, obj3), false);
}

TEST(MemTrackLog, MemTrackLog_set_malloc) {

  memtrack_log_t *obj = create_memtrack_object_log(12,
                            "v0",
                            (long)123, 
                            (long)9874561230,
                            0,
                            0, 
                            0, 
                            0,
                            "main", 
                            4,
                            4, 
                            1,
                            INST_ALLOCA);

  set_malloc(obj);

  EXPECT_EQ(obj->is_dynamic, true);
}

TEST(MemTrackLog, MemTrackLog_set_calloc) {

  memtrack_log_t *obj = create_memtrack_object_log(12,
                            "v0",
                            (long)123, 
                            (long)9874561230,
                            0,
                            0, 
                            0, 
                            0,
                            "main", 
                            4,
                            4, 
                            1,
                            INST_ALLOCA);

  int tmp = obj->size_destiny;
  set_calloc(4, obj);

  EXPECT_EQ(obj->is_dynamic, true);
  EXPECT_GE(obj->size_destiny, tmp);
}

TEST(MemTrackLog, MemTrackLog_set_free) {

  memtrack_log_t *obj = create_memtrack_object_log(12,
                            "v0",
                            (long)123, 
                            (long)9874561230,
                            0,
                            0, 
                            0, 
                            0,
                            "main", 
                            4,
                            4, 
                            1,
                            INST_ALLOCA);

  set_malloc(obj);
  EXPECT_EQ(obj->is_dynamic, true);

  set_free(obj);
  EXPECT_EQ(obj->is_free, true);
}
