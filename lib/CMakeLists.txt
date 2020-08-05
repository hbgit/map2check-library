set(CMAKE_CXX_COMPILER "clang++-8")

include_directories(../include)

#Can manually add the sources using the set command as follows:
#set(SOURCES src/mainapp.cpp src/Student.cpp)
 
#However, the file(GLOB...) allows for wildcard additions:
file(GLOB SOURCES "*.cpp")

# add_executable(hello ${SOURCES})
# Generate the shared library from the sources
add_library(helloworld STATIC ${SOURCES})

install(
    FILES ${PROJECT_BINARY_DIR}/lib/libhelloworld.a
    DESTINATION lib
)