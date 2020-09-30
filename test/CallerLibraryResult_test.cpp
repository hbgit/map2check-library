#include "../include/CallerLibraryResult.hpp"
#include "../include/CallerLibraryTrackBbLog.hpp"


#include "gtest/gtest.h"
using json = nlohmann::json;

TEST(CallerLibraryResult, TrueResult)
{
    map2checkPrintJsonCheckResult(CNONE);
    json j = json::parse(JsonFinalResult.c_str());    
    cout << j.dump(4) << endl;
    
    EXPECT_STREQ(j["VerificationResult"].get<std::string>().c_str(), "TRUE");
    EXPECT_EQ(j.contains("MemoryTracked"), false);
    
    EXPECT_TRUE(1);

}

TEST(CallerLibraryResult, TrueMEMResult)
{
    VerificationResult = TRUE;
    
    map2checkPrintJsonCheckResult(CMEMSAFETY);    
    //LineNumberOfPropertyChecked = 100;
    json j = json::parse(JsonFinalResult.c_str());    
    cout << j.dump(4) << endl;
    
    EXPECT_STREQ(j["VerificationResult"].get<std::string>().c_str(), "TRUE");
    EXPECT_EQ(j.contains("MemoryTracked"), true);
    
    EXPECT_TRUE(1);

}

TEST(CallerLibraryResult, TrackBbLogResult)
{
    VerificationResult = TRUE;

    map2checkAddInTrackedBb(2, "main");
    map2checkAddInTrackedBb(12, "main");
    map2checkAddInTrackedBb(20, "foo");

    EXPECT_EQ(map2checkIsInTrackedBb(12), true);
    
    map2checkPrintJsonCheckResult(CMEMSAFETY);    
    json j = json::parse(JsonFinalResult.c_str());    
    cout << j.dump(4) << endl;
    
    EXPECT_STREQ(j["VerificationResult"].get<std::string>().c_str(), "TRUE");
    EXPECT_EQ(j.contains("MemoryTracked"), true);

}