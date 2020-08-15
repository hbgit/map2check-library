include_directories(../include)

# The file(GLOB...) allows for wildcard additions:
file(GLOB SOURCES "*.cpp")

# Generate the static library from the sources
add_library(map2check STATIC ${SOURCES})

install(
    FILES ${PROJECT_BINARY_DIR}/src/libmap2check.a
    DESTINATION lib
)