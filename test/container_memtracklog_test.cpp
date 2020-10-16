#include "gtest/gtest.h"

extern "C" {
#include "../include/memtrack/container_memtracklog.h"
}

TEST(ContainerMemoryTrackLog, ContainerList)
{
    map2check_init_container_memtracklog();
    
    memtrack_log_t *obj = map2check_save_memtrack_log(
      0, 1, 0, 1728888, 0, false, false, "a",
      "none", 4, 4, false);

    map2check_save_in_tail_container_memtracklog(obj);

    EXPECT_TRUE(container_memtracklog.tqh_first->var_mem_address == 1728888);
}

TEST(ContainerMemoryTrackLog, JsonGen)
{
    map2check_init_container_memtracklog();
    
    memtrack_log_t *obj = map2check_save_memtrack_log(
      0, 1, 0, 1728888, 0, false, false, "a",
      "none", 4, 4, false);

    map2check_save_in_tail_container_memtracklog(obj);

    map2check_print_all_memtracklog_as_json();

    EXPECT_TRUE(container_memtracklog.tqh_first->var_mem_address == 1728888);
}


TEST(ContainerMemoryTrackLog, search_in_container_by_address)
{
    map2check_init_container_memtracklog();
    
    memtrack_log_t *obj = map2check_save_memtrack_log(
      0, 1, 0, 1728888, 0, false, false, "a",
      "none", 4, 4, false);

    map2check_save_in_tail_container_memtracklog(obj);
    
    EXPECT_EQ(search_in_container_by_address(1728888)->line, 1);
}


TEST(ContainerMemoryTrackLog, mapAlloca)
{
    map2check_init_container_memtracklog();
    
    int a;
    void * ptr = &a;
    map2check_map_alloca("a", ptr, 4, 4, 16, 0);
    
    EXPECT_EQ(search_in_container_by_address((long)ptr)->line, 16);
}


TEST(ContainerMemoryTrackLog, mapNonStaticAlloca)
{
    map2check_init_container_memtracklog();
    
    int a;
    void * ptr = &a;
    map2check_map_non_static_alloca("a", ptr, 4, 4, 16, 0);
    
    EXPECT_EQ(search_in_container_by_address((long)ptr)->line, 16);
}


TEST(ContainerMemoryTrackLog, mapFunctionAddress)
{
    map2check_init_container_memtracklog();
    
    int a;
    void * ptr = &a;
    map2check_map_funct_address("a", ptr);
    
    EXPECT_STREQ(search_in_container_by_address((long)ptr)->ptr_name, "a");
}


TEST(ContainerMemoryTrackLog, mapStorePointer)
{
    map2check_init_container_memtracklog();
    
    int a;
    void * ptr = &a;

    map2check_map_store_pointer(ptr, ptr, 0, "a", 4, "main");
    
    EXPECT_EQ(search_in_container_by_address((long)ptr)->ptr_name, "a");
}


TEST(ContainerMemoryTrackLog, map2check_map_free)
{
    map2check_init_container_memtracklog();
    
    int a;
    void * ptr = &a;

    map2check_map_free("ptr", ptr, 0, 4, "main");
    
    EXPECT_EQ(search_in_container_by_address((long)ptr)->is_free, true);
}

TEST(ContainerMemoryTrackLog, map2check_map_malloc)
{
    map2check_init_container_memtracklog();
    
    int a;
    void * ptr = &a;

    map2check_map_malloc(ptr, 4);
    
    EXPECT_EQ(search_in_container_by_address((long)ptr)->is_dynamic, true);
}

TEST(ContainerMemoryTrackLog, map2check_map_calloc)
{
    map2check_init_container_memtracklog();
    
    int a;
    void * ptr = &a;

    map2check_map_calloc(ptr, 4, 4);
    
    EXPECT_EQ(search_in_container_by_address((long)ptr)->size_destiny, 16);
}
