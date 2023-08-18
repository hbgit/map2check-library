#include "gtest/gtest.h"

extern "C" {
#include "../include/memtrack/container_memtracklog.h"
}

TEST(ContainerMemoryTrackLog, ContainerList)
{
    map2check_init_container_memtracklog();
    
    memtrack_log_t *obj = map2check_save_memtrack_log(
      1, 0, 1728888, 0, false, false, "a",
      "none", 4, 4, false);

    map2check_save_in_tail_container_memtracklog(obj);

    EXPECT_TRUE(container_memtracklog.tqh_first->var_mem_address == 1728888);
}

TEST(ContainerMemoryTrackLog, JsonGen)
{
    map2check_init_container_memtracklog();
    
    memtrack_log_t *obj = map2check_save_memtrack_log(
      1, 0, 1728888, 0, false, false, "a",
      "none", 4, 4, false);

    map2check_save_in_tail_container_memtracklog(obj);

    map2check_print_all_memtracklog_as_json();

    EXPECT_TRUE(container_memtracklog.tqh_first->var_mem_address == 1728888);
}


TEST(ContainerMemoryTrackLog, search_in_container_by_address)
{
    map2check_init_container_memtracklog();
    
    memtrack_log_t *obj = map2check_save_memtrack_log(
      1, 0, 1728888, 0, false, false, "a",
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

//
// VCCs for memory safety
//

TEST(ContainerMemoryTrackLog, is_addr_a_invalid_free_in_cntr_true)
{
    map2check_init_container_memtracklog();
    
    int a;
    void * ptr = &a;
    map2check_map_malloc(ptr, 4);
    map2check_map_free("ptr", ptr, 0, 4, "main");

    EXPECT_EQ(is_addr_a_invalid_free_in_cntr((long)ptr), true); // VCC violated
    EXPECT_EQ(is_addr_a_invalid_free_in_cntr((long)12345), true); // VCC violated
}

TEST(ContainerMemoryTrackLog, is_addr_a_invalid_free_in_cntr_false)
{
    map2check_init_container_memtracklog();

    memtrack_log_t *obj = map2check_save_memtrack_log(
      1, 0, 1728888, 12, true, false, "a", "none", 4, 4, false);
    map2check_save_in_tail_container_memtracklog(obj);    
    map2check_map_malloc((void *)12, 4);

    map2check_print_all_memtracklog_as_json();
    EXPECT_EQ(is_addr_a_invalid_free_in_cntr((long)12), false);
}

TEST(ContainerMemoryTrackLog, is_addr_a_deref_error_in_cntr_false)
{
    map2check_init_container_memtracklog();
    
    memtrack_log_t *obj = map2check_save_memtrack_log(
      1, 0, 1728888, 12, true, false, "a", "none", 4, 4, false);
    map2check_save_in_tail_container_memtracklog(obj);    
    
    EXPECT_EQ(is_addr_a_deref_error_in_cntr((long)1728888), false);

    memtrack_log_t *obj1 = map2check_save_memtrack_log(
      1, 0, 8888, 12, true, false, "a", "none", 4, 4, false);
    map2check_save_in_tail_container_memtracklog(obj1);    
    
    EXPECT_EQ(is_addr_a_deref_error_in_cntr(12), false);
}

TEST(ContainerMemoryTrackLog, is_addr_a_deref_error_in_cntr_true)
{
    map2check_init_container_memtracklog();
    
    memtrack_log_t *obj = map2check_save_memtrack_log(
      1, 0, 1728888, 12, true, false, "a", "none", 4, 4, false);
    map2check_save_in_tail_container_memtracklog(obj);    
    
    EXPECT_EQ(is_addr_a_deref_error_in_cntr(2003), true);

    memtrack_log_t *obj1 = map2check_save_memtrack_log(
      1, 0, 8888, 12, false, true, "a", "none", 4, 4, false);
    map2check_save_in_tail_container_memtracklog(obj1);    
    
    EXPECT_EQ(is_addr_a_deref_error_in_cntr(12), true);
}

TEST(ContainerMemoryTrackLog, has_a_memcleanup_error_in_cntr_true)
{
    map2check_init_container_memtracklog();
    
    memtrack_log_t *obj = map2check_save_memtrack_log(
      1, 0, 12, 12, true, false, "a", "none", 4, 4, false);
    map2check_save_in_tail_container_memtracklog(obj);   
    
    //map2check_print_all_memtracklog_as_json();
    EXPECT_EQ(has_a_memcleanup_error_in_cntr(), true);
}

TEST(ContainerMemoryTrackLog, is_a_invalid_address_in_cntr_false)
{
    map2check_init_container_memtracklog();
    
    memtrack_log_t *obj = map2check_save_memtrack_log(
      1, 0, 12, 15, true, false, "a", "none", 4, 4, false);
    map2check_save_in_tail_container_memtracklog(obj);   

    EXPECT_EQ(is_a_invalid_address_in_cntr(14400000,4), false);
}

TEST(ContainerMemoryTrackLog, is_a_invalid_address_in_cntr_false2)
{
    map2check_init_container_memtracklog();
    
    memtrack_log_t *obj = map2check_save_memtrack_log(
      1, 0, 12, 15, false, true, "a", "none", 4, 4, false);
    map2check_save_in_tail_container_memtracklog(obj);   

    EXPECT_EQ(is_a_invalid_address_in_cntr(6,4), false);
}

TEST(ContainerMemoryTrackLog, is_a_invalid_address_in_cntr_true)
{
    map2check_init_container_memtracklog();
    
    memtrack_log_t *obj = map2check_save_memtrack_log(
      1, 0, 12, 15, false, false, "a", "none", 4, 4, false);
    map2check_save_in_tail_container_memtracklog(obj);   

    EXPECT_EQ(is_a_invalid_address_in_cntr(12,4), true);
}