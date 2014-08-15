#!/bin/bash.exe
set -e

cd ..
#make clean
make
cd ExampleInput/
../instream6-0.exe -b
