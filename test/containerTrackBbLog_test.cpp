#include "../include/TrackBbLog.hpp"
#include "../include/ContainerTrackBbLog.hpp"

#include "gtest/gtest.h"

TEST(ContainerTrackBbLog, ContainerList)
{
    ContainerTrackBbLog CntrTrackBb;
    TrackBbLog MapTmp;
    CntrTrackBb.ContainerLog_.push_back(MapTmp);

    EXPECT_TRUE(CntrTrackBb.ContainerLog_.size() == 1);
}

TEST(ContainerTrackBbLog, JsonGen)
{
    ContainerTrackBbLog CntrTrackBb;
    TrackBbLog TrLog;
    TrLog.Line = 12;
    TrLog.FunctName = "foo";

    CntrTrackBb.ContainerLog_.push_back(TrLog);

    string JsonTxt = CntrTrackBb.printContainerAsJson();

    EXPECT_GE(JsonTxt.length(), 2);
}

TEST(ContainerTrackBbLog, CheckLine)
{
    ContainerTrackBbLog CntrTrackBb;
    TrackBbLog TrLog;
    TrLog.Line = 12;
    TrLog.FunctName = "foo";

    CntrTrackBb.ContainerLog_.push_back(TrLog);

    EXPECT_EQ(CntrTrackBb.isInTrackedBbLog(12), true);
}