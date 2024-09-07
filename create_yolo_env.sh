#!/bin/bash 

#enter app dir
if [ -z "$1" ]; then
    echo "未传入路径参数"
    exit 1
fi
if [ -d "$1" ]; then
    # 如果是有效的目录，进入该目录
    cd "$1" || exit 1
    echo "成功进入目录: $(pwd)"
else
    echo "传入的参数不是有效的目录"
    exit 1
fi


#create python venv
python -m venv  venv_yolo8

#active
source venv_yolo8/bin/activate

#install  pip install ultralytics
cd  third-part/yolov8
pip install  ultralytics
cd -
