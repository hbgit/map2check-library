project (TestLibrary)

include_directories(${PROJECT_SOURCE_DIR}/include)

add_executable(
  unit_tests
  nondetlog_test.cpp
)

target_link_libraries(
  unit_tests
  gtest_main 
)

add_test(
  NAME
    unit
  COMMAND
    ${CMAKE_BINARY_DIR}/${CMAKE_INSTALL_BINDIR}/unit_tests
  )