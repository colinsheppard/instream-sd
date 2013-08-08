#!/bin/bash.exe
set -e

cd ..
make
cd ExampleInput/
../instream6-0.exe -b
