#include "gtest/gtest.h"
#include <cstddef>

extern "C" {
    #include "../include/nondet/nondetlog.h"
    #include "../include/nondet/container_nondet.h"
}


TEST(ContainerNonDetLog, ContainerNonDetLog_init)
{
    non_det_log_t *obj = create_nondet(1, 12, 0,
                             INT_ID, "12",
                             "foo");
    
    init_container_nondet();
    insert_tail_container_nondet(obj);
    non_det_log_t *obj2 = create_nondet(2, 24, 0,
                             INT_ID, "144",
                             "foo");
    
    insert_tail_container_nondet(obj2);
    
    EXPECT_STREQ(print_all_nondet_as_json(), "asd");
}