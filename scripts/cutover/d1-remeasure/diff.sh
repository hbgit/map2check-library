#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-only
# Runs both type programs on every input; prints the diff (empty = same).
cd /bench
mkdir -p inputs out
if [ ! -e inputs/one ]; then
  printf A > inputs/one; printf '\x01\x02' > inputs/two
  printf '\x2a\x00\x00\x00' > inputs/four; printf '\x01\x02\x03\x04\x05\x06\x07' > inputs/seven
  printf '\x05\x00\x00\x00hey' > inputs/pchar5
  for n in 37 64 200; do head -c $n /dev/urandom > inputs/rand$n; done
fi
for f in inputs/*; do
  ./build-v1/types_b2 < $f > out/$(basename $f).b2
  ./build-v1/types_b1 $f > out/$(basename $f).b1
  if cmp -s out/$(basename $f).b1 out/$(basename $f).b2; then echo "$(basename $f) ($(stat -c %s $f) bytes): identical"; else echo "$(basename $f): DIFFER"; diff out/$(basename $f).b1 out/$(basename $f).b2; fi
done
