#!/bin/bash
source='ffmpeg-3.4'
if [ ! -r $source ]
then
    # 没有下载，那么执行下载操作
    echo "没有FFmpeg库，我们需要下载..."
    # -x ：解压文件类型 -j 是否解压
    # 如果解压失败 退出程序
    curl http://ffmpeg.org/releases/${source}.tar.bz2 | tar xj || exit 1
fi
