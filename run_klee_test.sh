#!/bin/sh
cd build
  
# run
docker run --rm -v $(pwd):/home/src:Z --user $(id -u):$(id -g) klee/klee:2.2 /bin/bash -c "cd klee_build; klee --optimize --warnings-only-to-file --libc=uclibc --posix-runtime --external-calls=all -exit-on-error-type=Assert /home/src/fullprogram_2.bc"
#docker run --rm -v $(pwd):/home/src:Z --user $(id -u):$(id -g) klee/klee /bin/bash -c "cd klee_build; klee --optimize --warnings-only-to-file --libc=uclibc --posix-runtime --external-calls=all -exit-on-error-type=Assert /home/src/fullprogram_2.bc; cp result_map2check_json.json /home/src/"

# check result
docker run --rm -v $(pwd):/home/src:Z --user $(id -u):$(id -g) klee/klee:2.2 /bin/bash -c "cd klee_build; ktest-tool /home/src/klee-out-0/test000001.ktest | grep -c \"object 0: name:\" "
if [ $? -eq 0 ]; 
then
    echo "\e[32m>>> KLEE testing result: OKAY"
else
    echo "\e[32m>>> KLEE testing result: ERROR"
    exit 1
fi