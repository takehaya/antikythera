#!/bin/sh

for f in testcase/*.s; do
  base=$(basename "$f" .s)
  ./mips2hex.sh "$f" > "testcase/${base}.dat"
done
