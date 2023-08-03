#!/bin/sh
cd build

# Libfuzzer testing
echo ""
echo "\e[32m>>> LibFuzzer testing"
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