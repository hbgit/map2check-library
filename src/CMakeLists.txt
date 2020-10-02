include_directories(../include)

# The file(GLOB...) allows for wildcard additions:
file(GLOB SOURCES "*.cpp")

# Generate the static library from the sources
add_library(map2check STATIC ${SOURCES})

list(APPEND MAP2CHECK_C_LIB "")
list(APPEND MAP2CHECK_C_LIB "AnalysisModeAssert")
list(APPEND MAP2CHECK_C_LIB "AnalysisModeMemory")
list(APPEND MAP2CHECK_C_LIB "AnalysisModeOverflow")
list(APPEND MAP2CHECK_C_LIB "CallerLibraryCheckMemory")
list(APPEND MAP2CHECK_C_LIB "CallerLibraryCheckOverflow")
list(APPEND MAP2CHECK_C_LIB "CallerLibraryCheckReach")
list(APPEND MAP2CHECK_C_LIB "CallerLibraryMemoryTrackLog")
list(APPEND MAP2CHECK_C_LIB "CallerLibraryNonDetLogFuzzer")
list(APPEND MAP2CHECK_C_LIB "CallerLibraryNonDetLogKlee")
list(APPEND MAP2CHECK_C_LIB "CallerLibraryResult")
list(APPEND MAP2CHECK_C_LIB "CallerLibraryTrackBbLog")
list(APPEND MAP2CHECK_C_LIB "ContainerMemoryTrackLog")
list(APPEND MAP2CHECK_C_LIB "ContainerNonDetLog")
list(APPEND MAP2CHECK_C_LIB "ContainerTrackBbLog")
list(APPEND MAP2CHECK_C_LIB "JsonUtils")
list(APPEND MAP2CHECK_C_LIB "MemoryTrackLog")
list(APPEND MAP2CHECK_C_LIB "NonDetGenKlee")
list(APPEND MAP2CHECK_C_LIB "NonDetGenLibFuzzer")
list(APPEND MAP2CHECK_C_LIB "NondetLog")


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