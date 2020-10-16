# include_directories(../include)

# The file(GLOB...) allows for wildcard additions:
set(CMAKE_C_FLAGS "-fprofile-instr-generate -fcoverage-mapping")
file(GLOB_RECURSE SOURCE_FILES *.c *.h ../lib/*.h ../lib/*.c)

# message(STATUS ${SOURCE_FILES})
# Generate the static library from the sources
add_library(map2check STATIC ${SOURCE_FILES})


set_target_properties(map2check PROPERTIES VERSION ${PROJECT_VERSION})
set_target_properties(map2check PROPERTIES PUBLIC_HEADER *.h)

# # Generate LLVM bc files
# set(CMAKE_C_FLAGS "-c -emit-llvm -O0 -Xclang -disable-O0-optnone")
# file(GLOB_RECURSE SOURCE_FILES_2 *.c ../lib/*.c)
# ADD_EXECUTABLE(map2check_bc ${SOURCE_FILES_2})

# Generating LLVM bc files
list(APPEND MAP2CHECK_BC_files "")

function(genBCFiles packageCode)    
    message(${packageCode})
    foreach(F ${MAP2CHECK_BC_files})
        add_custom_command(
            OUTPUT "${F}.bc"
            COMMAND ${CMAKE_C_COMPILER} -c -emit-llvm -O0 -Xclang -disable-O0-optnone ${CMAKE_CURRENT_LIST_DIR}/${packageCode}/${F}.c
            DEPENDS ${CMAKE_CURRENT_LIST_DIR}/${packageCode}/${F}.c
            COMMENT ">> Compiling ${F} to bytecode"
        )

        add_custom_target(
        ${F} ALL DEPENDS ${F}.bc
        )  
    endforeach()
endfunction()

# Generating LLVM bc for the < nondet > package
# < lib > package
message(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
list(APPEND MAP2CHECK_BC_files "json-maker")
message(${MAP2CHECK_BC_files})
genBCFiles("../lib")
# < to_string > package
set(MAP2CHECK_BC_files "")
list(APPEND MAP2CHECK_BC_files "ftoa")
message(${MAP2CHECK_BC_files})
genBCFiles("../lib/to_string")
# < nondet > package
set(MAP2CHECK_BC_files "")
list(APPEND MAP2CHECK_BC_files "nondetlog")
list(APPEND MAP2CHECK_BC_files "container_nondet")
message(${MAP2CHECK_BC_files})
genBCFiles("nondet")
# < bbtrack > package
set(MAP2CHECK_BC_files "")
list(APPEND MAP2CHECK_BC_files "trackbblog")
list(APPEND MAP2CHECK_BC_files "container_trackbb")
message(${MAP2CHECK_BC_files})
genBCFiles("bbtrack")
# < memtrack > package
set(MAP2CHECK_BC_files "")
list(APPEND MAP2CHECK_BC_files "memtracklog")
list(APPEND MAP2CHECK_BC_files "container_memtracklog")
message(${MAP2CHECK_BC_files})
genBCFiles("memtrack")










# INSTALL >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
# Install library
install(
    FILES ${PROJECT_BINARY_DIR}/src/libmap2check.a
    DESTINATION lib
)

# Install library headers
file(GLOB_RECURSE HEADERS ${CMAKE_CURRENT_SOURCE_DIR}/../include/*.h ${CMAKE_CURRENT_SOURCE_DIR}/../lib/*.h)
install(FILES ${HEADERS} DESTINATION lib)

# add_custom_command(OUTPUT ${MAP2CHECK_C_LIB}
#     COMMAND touch ${TEST_FILE}

#     # Display the given message before the commands are executed at build time
#     COMMENT "Creating bc file ${TEST_FILE}"
# )


# file(GLOB_RECURSE MAP2CHECK_C_LIB *.c ../lib/*.c)
# # Generating lib as bc to LLVM
# foreach(F ${MAP2CHECK_C_LIB})
#     add_custom_command(
#         OUTPUT "${F}.bc"
#         COMMAND ${CMAKE_CXX_COMPILER} -c -emit-llvm -O0 -Xclang -disable-O0-optnone ${F}
#         DEPENDS ${F}
#         COMMENT "Compiling ${F} to bytecode"
#     )

#     add_custom_target(
#       ${F} ALL DEPENDS ${F}.bc
#     )  
# endforeach()

# file(GLOB_RECURSE MAP2CHECK_C_LIB *.c ../lib/*.c)
# set(CMAKE_C_FLAGS "-c -emit-llvm -O0 -Xclang -disable-O0-optnone")
# add_library(map_bc OBJECT ${MAP2CHECK_C_LIB})