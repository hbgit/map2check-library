#project (TestLibrary)

#For the static library:
# set ( PROJECT_LINK_LIBS libmap2check.a )

# message( STATUS ${PROJECT_BINARY_DIR}/lib )

# link_directories( ${PROJECT_BINARY_DIR}/lib )

# include_directories(${PROJECT_SOURCE_DIR}/header)

# add_executable(libtest libtest.cpp)
# target_link_libraries( libtest ${PROJECT_LINK_LIBS} )

# install(
#     FILES ${PROJECT_BINARY_DIR}/test/libtest
#     PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ
#     DESTINATION test    
# )

add_executable(
    unit_tests
    example.cpp
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