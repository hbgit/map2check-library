#!/bin/sh
cd build 

docker run --rm -v $(pwd):/home/src:Z klee/klee /bin/bash -c "cd klee_build; klee --libcxx -exit-on-error-type=Abort /home/src/fullprogram.bc"
docker run --rm -v $(pwd):/home/src:Z klee/klee /bin/bash -c "cd klee_build; ktest-tool /home/src/klee-out-0/test000001.ktest | grep -c \"object 0: name:\" "
if [ $? -eq 0 ]; 
then
    echo ">>> KLEE OKAY"
else
    echo ">>> KLEE ERROR"
    exit 1
fi