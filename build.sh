#!/bin/sh

if [ ! -d "build" ]; then
    mkdir build
fi

echo ""
echo "Building C map2Check-library ... "
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
    cmake .. -DCMAKE_C_COMPILER=/usr/bin/clang-8 -DCMAKE_CXX_COMPILER="/usr/bin/clang++-8" -DCMAKE_INSTALL_PREFIX=../release-library/ -DENABLE_TEST=ON -DENABLE_COVCODE=ON -DBUILD_DOC=OFF
    cmake --build . -- VERBOSE=1 

    echo ">>> Generating LLVM BC library with KLEE"
    files_klee_bc=`ls --ignore="ftoa.bc" src/*.bc`
    llvm-link-8 ${files_klee_bc} -o libmap2check_klee.bc

    # Unit Testing
    cd test
    LLVM_PROFILE_FILE="map2check.profraw" ./unit_tests
    llvm-profdata-8 merge -sparse map2check.profraw -o map2check.profdata
    llvm-cov-8 report ./unit_tests -instr-profile=map2check.profdata
    llvm-cov-8 export -format=lcov ./unit_tests -instr-profile=map2check.profdata > lcov.info

    # klee
    cd ..
    #ls -alh
    clang-8 -c -emit-llvm -O0 -Xclang -disable-O0-optnone ../test/codeklee_by_caller_test.c
    llvm-link-8 codeklee_by_caller_test.bc libmap2check_klee.bc > fullprogram_2.bc

    if [ $istravis -eq 0 ]; then
	    echo ">> Travis build is OFF"
        cd ..
        ./run_klee_test.sh
    else
        echo ">> Travis build is ON"
    fi

    # # libfuzzer test by using Caller
    # clang++-8 ../test/codefuzz_by_caller_test.cpp -fsanitize=address,fuzzer -g -fprofile-instr-generate -fcoverage-mapping src/libmap2check.a    
    # ./a.out 2> out.fuzz 
    # cat out.fuzz | grep ERROR
    # if [ $? -eq 0 ]; 
    # then
    #     echo ">>> LibFuzzer OKAY"
    # else
    #     echo ">>> LibFuzzer ERROR"
    #     exit 1
    # fi

}

build_simple()
{
    cmake .. -DCMAKE_INSTALL_PREFIX=../release-library/ -DENABLE_TEST=OFF -DENABLE_COVCODE=OFF -DBUILD_DOC=OFF
    make
}

##### Main

type_builds=""
istravis=0

while [ "$1" != "" ]; do
    case $1 in
        -r | --release )            shift
                                    type_builds="release"
                                ;;
        -d | --debug )              type_builds="debug"
                                ;;
        -t | --travis )             istravis=1
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