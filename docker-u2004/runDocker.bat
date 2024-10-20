@echo off

set display=host.docker.internal:0

set runcmd=docker run ^
--name hbb ^
--privileged ^
-p 2246:22 ^
--gpus all ^
--runtime=nvidia ^
-e DISPLAY=%display% ^
-v D:/Downloads/WildFire_Smoke_Dataset_YOLO:/imges
-e LANG=zh_CN.UTF-8 ^
-e XMODIFIERS="@im=ibus" ^
-e QT_IM_MODULE=ibus ^
-e GTK_IM_MODULE=ibus ^
--entrypoint /bin/bash ^
-e GID=%NUMBER_OF_PROCESSORS% ^
-e UID=%USERNAME% ^
-it u2004:nvidia -c "ibus-daemon -xrd && bash"

%runcmd%

