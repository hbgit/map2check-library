#include "../include/TrackBbLog.hpp"
#include "../include/ContainerTrackBbLog.hpp"

#include "gtest/gtest.h"

TEST(ContainerTrackBbLog, ContainerList)
{
    ContainerTrackBbLog CntrTrackBb;
    map<long, TrackBbLog> MapTmp;
    CntrTrackBb.ContainerLog_.push_back(MapTmp);

    EXPECT_TRUE(CntrTrackBb.ContainerLog_.size() == 1);
}

TEST(ContainerTrackBbLog, JsonGen)
{
    ContainerTrackBbLog CntrTrackBb;
    TrackBbLog TrLog;
    TrLog.Line = 12;
    TrLog.FunctName = "foo";

    map<long, TrackBbLog> MapTmp;
    MapTmp.insert(pair<long, TrackBbLog>(2,TrLog));
    CntrTrackBb.ContainerLog_.push_back(MapTmp);

    string JsonTxt = CntrTrackBb.printJsonObj(TrLog);

    EXPECT_GE(JsonTxt.length(), 2);
}

TEST(ContainerTrackBbLog, CheckLine)
{
    ContainerTrackBbLog CntrTrackBb;
    TrackBbLog TrLog;
    TrLog.Line = 12;
    TrLog.FunctName = "foo";

    map<long, TrackBbLog> MapTmp;
    MapTmp.insert(pair<long, TrackBbLog>(2,TrLog));
    CntrTrackBb.ContainerLog_.push_back(MapTmp);

    EXPECT_EQ(CntrTrackBb.isInTrackedBbLog(12), true);
}