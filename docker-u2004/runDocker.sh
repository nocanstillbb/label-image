#!/bin/bash

#查看设备
#sudo docker run --rm --runtime=nvidia --gpus '"device=1"' u16_dv_learing:0.1 nvidia-smi

#选择设备
#https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/docker-specialized.html
#echo ${HOSTNAME}

display=${HOSTNAME}:0
#--gpus all
#--cap-add=SYS_RAWIO --cap-add=SYS_ADMIN
#--runtime=nvidia \

#--rm
runcmd="docker run \
--name  hbb
--privileged \
--device /dev/mem \
-p 2246:22 \
-e NVIDIA_VISIBLE_DEVICES=0 \
-e DISPLAY=$display \
-e LANG=zh_CN.UTF-8 \
-e XMODIFIERS=\"@im=ibus\" \
-e QT_IM_MODULE=\"ibus\" \
-e GTK_IM_MODULE=\"ibus\" \
-e GID=`id -g` \
-e UID=`id -u` \
-v /tmp/.X11-unix/:/tmp/.X11-unix  \
--entrypoint /bin/bash \
-it label-image:u2004 -c 'ibus-daemon -xrd && gedit'"

#-e AUDIO_GID=`getent group audio | cut -d: -f3` \

#-v /Users/hbb/source/repos/label-image/docker-u2004/.config/dconf:/root/.config/dconf \
#-v /Users/hbb/source/repos/label-image/docker-u2004/.config/ibus:/root/.config/ibus \

#echo $runcmd
eval $runcmd

