project (TestLibrary)

include_directories(${PROJECT_SOURCE_DIR}/include/nondet)
#file(GLOB_RECURSE HEADER_FILES ${PROJECT_SOURCE_DIR}/include/*.h)

add_executable(
  unit_tests  
  test_lib.cpp
  nondetlog_test.cpp 
  container_nondet_test.cpp
  trackbblog_test.cpp
  container_trackbb_test.cpp
  memtracklog_test.cpp
  container_memtracklog_test.cpp
  caller_lib_result.cpp
  analysis_mode_assert_test.cpp
  analysis_mode_overflow_test.cpp
  #analysis_mode_memory_test.cpp
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
