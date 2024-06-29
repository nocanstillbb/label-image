#!/bin/bash

#! /bin/bash
set -x
currentpath=$(pwd)


cd $currentpath/third-part/prism_all
./clear.sh
cd ..

rm -rf $currentpath/build
