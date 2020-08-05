#project (TestLibrary)

#For the static library:
set ( PROJECT_LINK_LIBS libhelloworld.a )

message( STATUS ${PROJECT_BINARY_DIR}/lib )

link_directories( ${PROJECT_BINARY_DIR}/lib )

include_directories(${PROJECT_SOURCE_DIR}/header)

add_executable(libtest libtest.cpp)
target_link_libraries( libtest ${PROJECT_LINK_LIBS} )

install(
    FILES ${PROJECT_BINARY_DIR}/test/libtest
    PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ
    DESTINATION test    
)