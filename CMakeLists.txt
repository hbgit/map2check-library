# mkdir build
# cd build
# --------------------
# # Testing
# cmake .. -DCMAKE_CXX_COMPILER=/usr/bin/clang++-8 -DCMAKE_INSTALL_PREFIX=../release-library/ -DENABLE_TEST=ON -DENABLE_COVCODE=OFF -DBUILD_DOC=OFF
# make
# --------------------
# # Releasing
# cmake .. -DCMAKE_CXX_COMPILER=`which clang++-8` -DCMAKE_INSTALL_PREFIX=../release-library/ -DENABLE_TEST=OFF -DENABLE_COVCODE=OFF -DBUILD_DOC=OFF
# make
# make install
# --------------------
# To Clangd vscode plugin
# cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=1  ..
# cp compile_commands.json ..


cmake_minimum_required(VERSION 3.16)
project(LibMap2Check)

set(CMAKE_BUILD_TYPE Release)

option(ENABLE_TEST "Build all tests" OFF)
option(ENABLE_COVCODE "Code coverage" OFF)
# Doxygen Build
option(BUILD_DOC "Build Documentation" OFF)

set(CMAKE_CXX_COMPILER "/usr/bin/clang++-8")
set(CMAKE_CXX_STANDARD 11)

if(ENABLE_COVCODE) 
  message(">> Enabling coverage code ")
  set(CXX_FLAGS "${CXX_FLAGS}  -fno-rtti -fprofile-instr-generate -fcoverage-mapping -g ")
  set(LDFLAGS "${LDFLAGS} -fprofile-instr-generate")
else()
  # BUG: If we do not set this flag opt will not work with our pass
  # even if it was the same build from llvm
  set(CXX_FLAGS "${CXX_FLAGS}  -fno-rtti ")
endif()

message(${CXX_FLAGS})

# The following folder will be included
#include_directories("${PROJECT_SOURCE_DIR}")

add_subdirectory(src) 

# Setting up to unit testing 
if(ENABLE_TEST)
  message(">> Enabling unit testing ")
  enable_testing()
  include(cmake/FindGTest.cmake)
  # message("Adding tests")
  add_subdirectory(test) # code to functional/unit test lib
endif()


if(BUILD_DOC)
  message(">> Enabling build documentation ")
  find_package(Doxygen)
  if(DOXYGEN_FOUND)
      set(BUILD_DOC_DIR ${CMAKE_SOURCE_DIR}/build/docs)
      
      if(NOT EXISTS ${BUILD_DOC_DIR})
          file(MAKE_DIRECTORY ${BUILD_DOC_DIR})
      endif()

      set(DOXYGEN_IN ${CMAKE_CURRENT_SOURCE_DIR}/docs/Doxyfile)
      set(DOXYGEN_OUT ${CMAKE_CURRENT_BINARY_DIR}/Doxyfile)
      configure_file(${DOXYGEN_IN} ${DOXYGEN_OUT} @ONLY)
      
      add_custom_target(Doxygen ALL
              COMMAND ${DOXYGEN_EXECUTABLE} ${DOXYGEN_OUT}
              WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
              COMMENT "Generating API documentation with Doxygen"
              VERBATIM)
  
  else(DOXYGEN_FOUND)
      message("Doxygen needs to be installed to generate the documentation.")
  endif(DOXYGEN_FOUND)

endif(BUILD_DOC)