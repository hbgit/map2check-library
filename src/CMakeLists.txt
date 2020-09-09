include_directories(../include)

# The file(GLOB...) allows for wildcard additions:
file(GLOB SOURCES "*.cpp")

# Generate the static library from the sources
add_library(map2check STATIC ${SOURCES})

list(APPEND MAP2CHECK_C_LIB "")
#list(APPEND MAP2CHECK_C_LIB "ContainerAllocaLog")
#list(APPEND MAP2CHECK_C_LIB "ContainerHeapLog")
list(APPEND MAP2CHECK_C_LIB "ContainerMemoryTrackLog")
list(APPEND MAP2CHECK_C_LIB "ContainerNonDetLog")
list(APPEND MAP2CHECK_C_LIB "ContainerTrackBbLog")
list(APPEND MAP2CHECK_C_LIB "NonDetGenKlee")
list(APPEND MAP2CHECK_C_LIB "NonDetGenLibFuzzer")
list(APPEND MAP2CHECK_C_LIB "NondetLog")
list(APPEND MAP2CHECK_C_LIB "AnalysisModeAssert")
list(APPEND MAP2CHECK_C_LIB "AnalysisModeOverflow")
list(APPEND MAP2CHECK_C_LIB "AnalysisModeMemory")


# Generating lib as bc to LLVM
foreach(F ${MAP2CHECK_C_LIB})
    add_custom_command(
        OUTPUT "${F}.bc"
        COMMAND ${CMAKE_CXX_COMPILER} -c -emit-llvm ${CMAKE_CURRENT_LIST_DIR}/${F}.cpp
        DEPENDS ${CMAKE_CURRENT_LIST_DIR}/${F}.cpp
        COMMENT "Compiling ${F} to bytecode"
    )

    add_custom_target(
      ${F} ALL DEPENDS ${F}.bc
    )  
endforeach()

# Install library
install(
    FILES ${PROJECT_BINARY_DIR}/src/libmap2check.a
    DESTINATION lib
)