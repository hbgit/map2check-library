#!/bin/sh
cd build

docker run --rm -v $(pwd):/home/src:Z --user $(id -u):$(id -g) klee/klee /bin/bash -c "cd klee_build; klee --libc=uclibc --posix-runtime --external-calls=all -exit-on-error-type=Assert /home/src/fullprogram_2.bc; cp result_map2check_json.json /home/src/"
docker run --rm -v $(pwd):/home/src:Z --user $(id -u):$(id -g) klee/klee /bin/bash -c "cd klee_build; ktest-tool /home/src/klee-out-0/test000001.ktest | grep -c \"object 0: name:\" "
if [ $? -eq 0 ]; 
then
    echo ">>> KLEE OKAY"
else
    echo ">>> KLEE ERROR"
    exit 1
fi