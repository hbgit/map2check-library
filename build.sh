#!/bin/sh

if [ ! -d "build" ]; then
    mkdir build
fi

echo ""
echo "Building map2Check-library ... "
echo ""

cd build

usage()
{
    echo "usage: [-r | --release ] | [-d | --debug] | [-t | --travis] | [-h | --help]"
}

build_release()
{
    cmake .. -DCMAKE_INSTALL_PREFIX=../release-library/ -DENABLE_TEST=OFF -DENABLE_COVCODE=OFF -DBUILD_DOC=ON
    make
    make install
}

build_debug()
{
    cmake .. -DCMAKE_CXX_COMPILER=/usr/bin/clang++-8 -DCMAKE_INSTALL_PREFIX=../release-library/ -DENABLE_TEST=ON -DENABLE_COVCODE=ON -DBUILD_DOC=OFF
    cmake --build . -- VERBOSE=1    
    #klee
    clang++-8 -c -emit-llvm -O0 -Xclang -disable-O0-optnone ../test/codetest_klee.cpp
    llvm-link-8 codetest_klee.bc src/NonDetGenKlee.bc > fullprogram.bc
    docker run --rm -v $(pwd):/home/src:Z klee/klee /bin/bash -c "cd klee_build; klee --libcxx -exit-on-error-type=Abort /home/src/fullprogram.bc"
    docker run --rm -v $(pwd):/home/src:Z klee/klee /bin/bash -c "cd klee_build; ktest-tool /home/src/klee-out-0/test000001.ktest | grep -c \"object 0: name:\" "
    if [ $? -eq 0 ]; 
    then
        echo ">>> KLEE OKAY"
    else
        echo ">>> KLEE ERROR"
        exit 1
    fi
    #libfuzzer
    clang++-8 ../test/codetestfuzz.cpp -fsanitize=address,fuzzer -g -fprofile-instr-generate -fcoverage-mapping src/libmap2check.a    
    ./a.out 2> out.fuzz 
    cat out.fuzz | grep -c "a.out: ../test/codetestfuzz.cpp:52"
    if [ $? -eq 0 ]; 
    then
        echo ">>> LibFuzzer OKAY"
    else
        echo ">>> LibFuzzer ERROR"
        exit 1
    fi
    # Unit Testing
    cd test
    LLVM_PROFILE_FILE="map2check.profraw" ./unit_tests
    llvm-profdata-8 merge -sparse map2check.profraw -o map2check.profdata
    llvm-cov-8 report ./unit_tests -instr-profile=map2check.profdata
    llvm-cov-8 export -format=lcov ./unit_tests -instr-profile=map2check.profdata > lcov.info
}

build_simple()
{
    cmake .. -DCMAKE_INSTALL_PREFIX=../release-library/ -DENABLE_TEST=OFF -DENABLE_COVCODE=OFF -DBUILD_DOC=OFF
    make
}

##### Main

type_builds=""

while [ "$1" != "" ]; do
    case $1 in
        -r | --release )            shift
                                    type_builds="release"
                                ;;
        -d | --debug )              type_builds="debug"
                                ;;
        -s | --simple-build )       type_builds="simple"
                                ;;
        -h | --help )               usage
                                    exit
                                ;;
        * )                         usage
                                    exit 1
    esac
    shift
done


# Test code to verify command line processing
if [ "$type_builds" = "debug" ]; then
	echo ">> Debug build is on"
    build_debug
elif [ "$type_builds" = "debug" ]; then
	echo ">> Release build is on"
    build_release
elif [ "$type_builds" = "simple" ]; then
	echo ">> Simple build is on" 
    build_simple   
fi