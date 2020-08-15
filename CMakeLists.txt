# mkdir build
# cd build
# --------------------
# # Testing
# cmake .. -DCMAKE_CXX_COMPILER=`which clang++-8` -DCMAKE_INSTALL_PREFIX=../release-library/ -DENABLE_TEST=ON
# make
# --------------------
# # Releasing
# cmake .. -DCMAKE_CXX_COMPILER=`which clang++-8` -DCMAKE_INSTALL_PREFIX=../release-library/
# make
# make install
# --------------------
# To Clangd vscode plugin
# cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=1  ..
# cp compile_commands.json ..


cmake_minimum_required(VERSION 3.5)
project(LibMap2Check)
set(CMAKE_BUILD_TYPE Release)
option(ENABLE_TEST "Build all tests" OFF)

set(CMAKE_CXX_COMPILER "/usr/bin/clang++-8")
set(CMAKE_CXX_STANDARD 11)

# BUG: If we do not set this flag opt will not work with our pass
# even if it was the same build from llvm
set(CXX_FLAGS "${CXX_FLAGS}  -fno-rtti ")

# The following folder will be included
#include_directories("${PROJECT_SOURCE_DIR}")

add_subdirectory(src) 

# Setting up to unit testing 
if(ENABLE_TEST)
  enable_testing()
  include(cmake/FindGTest.cmake)
  # message("Adding tests")
  add_subdirectory(test) # code to functional/unit test lib
endif()