#!/bin/bash

#create python venv
python -m venv  venv_yolo8

#active
source venv_yolo8/bin/activate

#install  pip install ultralytics
cd  third-part/yolov8
pip install  ultralytics
cd -
