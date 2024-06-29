#!/bin/bash

cd third-part/prism_all
./build.sh $@

if [ $? -ne 0 ]; then
exit 1
fi


cd ../..
rm -rf build
mkdir build 
cd build 
cmake .. $@
cmake --build . --target label-image --config release

