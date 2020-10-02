#include "../include/CallerLibraryResult.hpp"
#include "../include/CallerLibraryTrackBbLog.hpp"
#include "../include/CallerLibraryNonDetLog.hpp"


#include "gtest/gtest.h"
// using json = nlohmann::json;

// TEST(CallerLibraryResult, TrueResult)
// {
//     map2checkPrintJsonCheckResult(CNONE);
//     json j = json::parse(JsonFinalResult.c_str());    
//     cout << j.dump(4) << endl;
    
//     EXPECT_STREQ(j["VerificationResult"].get<std::string>().c_str(), "TRUE");
//     EXPECT_EQ(j.contains("MemoryTracked"), false);
    
//     EXPECT_TRUE(1);

// }

// TEST(CallerLibraryResult, TrueMEMResult)
// {
//     VerificationResult = TRUE;
    
//     map2checkPrintJsonCheckResult(CMEMSAFETY);    
//     //LineNumberOfPropertyChecked = 100;
//     json j = json::parse(JsonFinalResult.c_str());    
//     cout << j.dump(4) << endl;
    
//     EXPECT_STREQ(j["VerificationResult"].get<std::string>().c_str(), "TRUE");
//     EXPECT_EQ(j.contains("MemoryTracked"), true);
    
//     EXPECT_TRUE(1);

// }

// TEST(CallerLibraryResult, TrackBbLogResult)
// {
//     VerificationResult = TRUE;

//     map2checkAddInTrackedBb(2, "main");
//     map2checkAddInTrackedBb(12, "main");
//     map2checkAddInTrackedBb(20, "foo");

//     EXPECT_EQ(map2checkIsInTrackedBb(12), true);
    
//     map2checkPrintJsonCheckResult(CMEMSAFETY);    
//     json j = json::parse(JsonFinalResult.c_str());    
//     cout << j.dump(4) << endl;
    
//     EXPECT_STREQ(j["VerificationResult"].get<std::string>().c_str(), "TRUE");
//     EXPECT_EQ(j.contains("MemoryTracked"), true);

// }


// For the CallerLibraryNonDetLog test case
/* int __map2check_main__() {
    return 0;
}

extern "C" void klee_make_symbolic(void *addr, size_t nbytes, const char *name){

}

extern "C" void klee_assume(int){

}
 */
TEST(CallerLibraryResult, CallerLibraryNonDetLog)
{
    EXPECT_TRUE(1);
    // This test are executed a part from unit tests, 
    // because are need to run a third tool, in this case
    // KLEE and LibFuzzer with its main function
}

// TEST(CallerLibraryResult, MemoryTrackLog)
// {
//     VerificationResult = TRUE;

//     map2checkAddInTrackedBb(2, "main");
//     map2checkAddInTrackedBb(12, "main");
//     map2checkAddInTrackedBb(20, "foo");

//     EXPECT_EQ(map2checkIsInTrackedBb(12), true);
    
//     map2checkPrintJsonCheckResult(CMEMSAFETY);    
//     json j = json::parse(JsonFinalResult.c_str());    
//     cout << j.dump(4) << endl;
    
//     EXPECT_STREQ(j["VerificationResult"].get<std::string>().c_str(), "TRUE");
//     EXPECT_EQ(j.contains("MemoryTracked"), true);

// }