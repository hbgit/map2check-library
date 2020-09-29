#include "../include/CallerLibraryResult.hpp"

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

