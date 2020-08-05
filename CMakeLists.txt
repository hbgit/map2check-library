# mkdir build
# cp build
# cmake .. -DCMAKE_INSTALL_PREFIX=../release-library/
# make
# make install
# --------------------
# To Clangd vscode plugin
# cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=1  ..
# cp compile_commands.json ..


cmake_minimum_required(VERSION 3.5)
project(LibMap2Check)
set(CMAKE_BUILD_TYPE Release)
set(CMAKE_CXX_COMPILER "clang++-8")


set (CMAKE_CXX_STANDARD 11)

# BUG: If we do not set this flag opt will not work with our pass
# even if it was the same build from llvm
set(CXX_FLAGS "${CXX_FLAGS}  -fno-rtti ")

# The following folder will be included
include_directories("${PROJECT_SOURCE_DIR}")

add_subdirectory(lib)  

add_subdirectory(test) # code to functional/unit test lib