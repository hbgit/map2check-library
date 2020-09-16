#include "../include/TrackBbLog.hpp"

#include "gtest/gtest.h"
#include "../lib/json.hpp"

using json = nlohmann::json;

TEST(TrackBbLog, Object)
{
    TrackBbLog t;
    t.FunctName = "foo";
    t.Line = 12;
    EXPECT_STREQ(t.FunctName.c_str(), "foo");
    EXPECT_EQ(t.Line, 12);
}

TEST(TrackBbLog, JsonGen)
{
    TrackBbLog t;
    t.FunctName = "foo";
    t.Line = 12;

    json j = t;
    
    string json = j.dump().c_str();
    cout << json << endl;
    EXPECT_TRUE(json.size() > 2);
}
