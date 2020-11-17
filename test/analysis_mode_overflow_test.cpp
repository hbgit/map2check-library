#include "gtest/gtest.h"

extern "C" {
  #include "../include/caller/caller_lib_result.h"
  #include "../include/analysismode/analysis_overflow.h"
}

#include <climits>
#include <limits>

TEST(AnalysisModeOverflow, checkOverBinopAddInt)
{
    map2check_init();
    debug_overflow_set_only_test();

    map2check_binop_add_int(INT_MAX, INT_MAX, 12, 0, (char *)"foo");    
    EXPECT_EQ(get_current_property(), OVERFLOW);
    
    map2check_binop_add_int(4, 1728, 12, 0, (char *)"foo");    
    EXPECT_EQ(get_current_property(), NONE);
    map2check_success();
}

TEST(AnalysisModeOverflow, checkOverBinopSubInt)
{
    map2check_init();
    debug_overflow_set_only_test();
    map2check_binop_sub_int(INT_MIN, INT_MIN, 5, 1, (char *)"zeta");

    EXPECT_EQ(get_current_property(), OVERFLOW);
    
    map2check_binop_sub_int(4, 1728, 7, 1, (char *)"zeta");
    EXPECT_EQ(get_current_property(), NONE);
    map2check_success();
}

TEST(AnalysisModeOverflow, checkOverBinopMulInt)
{
    map2check_init();
    debug_overflow_set_only_test();
    map2check_binop_mul_int(INT_MAX, INT_MAX, 13, 5, (char *)"zeta");
    EXPECT_EQ(get_current_property(), OVERFLOW);
    
    map2check_binop_mul_int(4, 1728, 13, 5, (char *)"zeta");
    EXPECT_EQ(get_current_property(), NONE);
    map2check_success();
}

TEST(AnalysisModeOverflow, checkOverBinopDivInt)
{
    map2check_init();
    debug_overflow_set_only_test();
    map2check_binop_div_int(INT_MAX, 0, 13, 5, (char *)"zeta");
    EXPECT_EQ(get_current_property(), OVERFLOW);

    map2check_binop_div_int(1728, 12, 13, 5, (char *)"zeta");
    EXPECT_EQ(get_current_property(), NONE);
    map2check_success();
}

TEST(AnalysisModeOverflow, checkOverBinopShlInt)
{
    map2check_init();
    debug_overflow_set_only_test();
    map2check_binop_shl_int(1024, 30, 15, 2, (char *)"zeta");
    EXPECT_EQ(get_current_property(), OVERFLOW);

    map2check_binop_shl_int(12, 2, 15, 2, (char *)"zeta");
    EXPECT_EQ(get_current_property(), NONE);
    map2check_success();
}


TEST(AnalysisModeOverflow, checkOverBinopShRInt)
{
    map2check_init();
    debug_overflow_set_only_test();
    map2check_binop_shr_int(1024, 32, 15, 0, (char *)"zeta");
    EXPECT_EQ(get_current_property(), OVERFLOW);

    map2check_binop_shr_int(12, 2, 15, 0, (char *)"zeta");
    EXPECT_EQ(get_current_property(), NONE);
    map2check_success();
}


TEST(AnalysisModeOverflow, checkOverBinopNegInt)
{
    map2check_init();
    debug_overflow_set_only_test();
    map2check_binop_neg_int(INT_MIN, 0, 15, 0, (char *)"zeta");
    EXPECT_EQ(get_current_property(), OVERFLOW);

    map2check_binop_neg_int(12, 0, 15, 0, (char *)"zeta");
    EXPECT_EQ(get_current_property(), NONE);
    map2check_success();
}


TEST(AnalysisModeOverflow, checkOverBinopAddUint)
{
    map2check_init();
    debug_overflow_set_only_test();
    map2check_binop_add_unsigned(UINT_MAX, UINT_MAX, 15, 0, (char *)"zeta");
    EXPECT_EQ(get_current_property(), OVERFLOW);

    map2check_binop_add_unsigned((unsigned)12, (unsigned)2, 15, 0, (char *)"zeta");
    EXPECT_EQ(get_current_property(), NONE);
    map2check_success();
}


TEST(AnalysisModeOverflow, checkOverBinopSubUint)
{
    map2check_init();
    debug_overflow_set_only_test();
    map2check_binop_sub_unsigned((unsigned)8, UINT_MAX, 15, 0, (char *)"zeta");
    EXPECT_EQ(get_current_property(), OVERFLOW);

    map2check_binop_sub_unsigned((unsigned)12, (unsigned)2, 15, 0, (char *)"zeta");
    EXPECT_EQ(get_current_property(), NONE);
    map2check_success();
}


TEST(AnalysisModeOverflow, checkOverBinopMulUint)
{
    map2check_init();
    debug_overflow_set_only_test();
    map2check_binop_mul_unsigned((unsigned)UINT_MAX, (unsigned)UINT_MAX, 15, 0, (char *)"zeta");
    EXPECT_EQ(get_current_property(), OVERFLOW);

    map2check_binop_mul_unsigned((unsigned)12, (unsigned)2, 15, 0, (char *)"zeta");
    EXPECT_EQ(get_current_property(), NONE);
    map2check_success();
}

TEST(AnalysisModeOverflow, checkOverBinopDivUint)
{
    map2check_init();
    debug_overflow_set_only_test();
    map2check_binop_div_unsigned((unsigned)UINT_MAX, (unsigned)0, 15, 0, (char *)"zeta");
    EXPECT_EQ(get_current_property(), OVERFLOW);

    map2check_binop_div_unsigned((unsigned)12, (unsigned)2, 15, 0, (char *)"zeta");
    EXPECT_EQ(get_current_property(), NONE);
    map2check_success();
}


TEST(AnalysisModeOverflow, checkOverBinopShRUint)
{
    map2check_init();
    debug_overflow_set_only_test();
    map2check_binop_shr_unsigned((unsigned)UINT_MAX, (unsigned)32, 15, 0, (char *)"zeta");
    EXPECT_EQ(get_current_property(), OVERFLOW);

    map2check_binop_shr_unsigned((unsigned)12, (unsigned)2, 15, 0, (char *)"zeta");
    EXPECT_EQ(get_current_property(), NONE);
    map2check_success();
}