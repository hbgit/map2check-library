project (TestLibrary)

include_directories(${PROJECT_SOURCE_DIR}/include)

add_executable(
  unit_tests  
  nondetlog_test.cpp
  containerNonDetLog_test.cpp
  containerTrackBbLog_test.cpp
  # containerMemoryTrackLog_test.cpp  
  AnalysisModeAssert_test.cpp
  AnalysisModeOverflow_test.cpp
)

target_link_libraries(
  unit_tests
  gtest_main
  ${CMAKE_BINARY_DIR}/src/libmap2check.a
)

add_test(
  NAME
    unit
  COMMAND
    ${CMAKE_BINARY_DIR}/${CMAKE_INSTALL_BINDIR}/unit_tests
  )
