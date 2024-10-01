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
python3 -m venv  venv_yolo8

#active
source venv_yolo8/bin/activate

#install  pip install ultralytics
pip install  ultralytics
wget https://github.com/ultralytics/assets/releases/download/v8.2.0/yolov8n.pt
wget https://github.com/ultralytics/assets/releases/download/v8.2.0/yolov8s.pt
wget https://github.com/ultralytics/assets/releases/download/v8.2.0/yolov8m.pt
wget https://github.com/ultralytics/assets/releases/download/v8.2.0/yolov8l.pt
cd -

