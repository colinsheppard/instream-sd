#!/bin/bash.exe
set -e

cd ..
#make clean
make
cd ExampleInput/
../instream6-1.exe -b
