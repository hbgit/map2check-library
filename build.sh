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

    echo ""
    echo "\e[32m>>> Generating LLVM BC library with KLEE"
    echo ""
    files_klee_bc=`ls src/*.bc | sed -e s'/src\/ftoa.bc//' | sed -e s'/src\/nondet_gen_libfuzzer.bc//'`
    llvm-link-8 ${files_klee_bc} -o libmap2check_klee.bc

    echo ""
    echo "\e[32m>>> Generating LLVM BC library with LibFuzzer"
    echo ""
    files_fuzzer_bc=`ls src/*.bc | sed -e s'/src\/ftoa.bc//'`
    llvm-link-8 ${files_fuzzer_bc} -o libmap2check_libfuzzer.bc

    # Unit Testing
    cd test
    LLVM_PROFILE_FILE="map2check.profraw" ./unit_tests
    llvm-profdata-8 merge -sparse map2check.profraw -o map2check.profdata
    llvm-cov-8 report ./unit_tests -instr-profile=map2check.profdata
    llvm-cov-8 export -format=lcov ./unit_tests -instr-profile=map2check.profdata > lcov.info

      
    if [ $istravis -eq 0 ]; then
	    echo "\e[32m>>> Travis build is OFF"
        cd ..
        # Here in build    
        # KLEE testing
        echo ""
        echo "\e[32m>>> KLEE testing ..."
        clang-8 -c -emit-llvm -O0 -Xclang -disable-O0-optnone ../test/codeklee_by_caller_test.c
        llvm-link-8 codeklee_by_caller_test.bc libmap2check_klee.bc > fullprogram_2.bc
        cd ..
         # Here in root folder 
        ./run_klee_test.sh

        # Libfuzzer testing
        echo ""
        echo "\e[32m>>> LibFuzzer testing"
        clang-8 test/codefuzz_by_caller_test.c -lm -fsanitize=address,fuzzer -g -fprofile-instr-generate -fcoverage-mapping build/libmap2check_libfuzzer.bc    
        ./a.out 2> out.fuzz 
        cat out.fuzz | grep ERROR
        if [ $? -eq 0 ]; 
        then
            echo "\e[32m>>> LibFuzzer testing result: OKAY"
        else
            echo "\e[32m>>> LibFuzzer testing result: ERROR"
            exit 1
        fi
        # clean up fuzzer test
        rm a.out out.fuzz crash-* default.profraw

    else
        echo "\e[32m>>> Travis build is ON"
        echo "\e[32m>>> KLEE testing skipped"
        echo "\e[32m>>> Libfuzzer testing skipped"
    fi
    

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