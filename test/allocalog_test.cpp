#include "../include/AllocaLog.hpp"

#include "gtest/gtest.h"

TEST(AllocaLog, AllocaLog_attr)
{
    AllocaLog Allo;
    Allo.Address = 1234567895421;
    Allo.IsFree = true;
    Allo.SizeToDestiny = sizeof(Allo);

    EXPECT_EQ(Allo.Address, 1234567895421);
    EXPECT_EQ(Allo.IsFree, true);
    EXPECT_EQ(Allo.SizeToDestiny, sizeof(Allo));
}