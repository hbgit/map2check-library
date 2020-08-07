#project (TestLibrary)

#For the static library:
set ( PROJECT_LINK_LIBS libmap2check.a )

message( STATUS ${PROJECT_BINARY_DIR}/lib )

link_directories( ${PROJECT_BINARY_DIR}/lib )

include_directories(${PROJECT_SOURCE_DIR}/header)

add_executable(callerlibtest callerlibtest.cpp)
target_link_libraries( callerlibtest ${PROJECT_LINK_LIBS} )

install(
    FILES ${PROJECT_BINARY_DIR}/CallerLibTest/callerlibtest
    PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ
    DESTINATION CallerLibTest    
)