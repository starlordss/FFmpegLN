# FFmpegLN

### FFmpeg-视频解码
**第一步：组册组件**

例如：编码器、解码器等等…

```c
  av_register_all()
```

**第二步：打开封装格式->打开文件**

例如：.mp4、.mov、.wmv文件等等...

```c
  avformat_open_input();
```
**第三步：查找视频流**

如果是视频解码，那么查找视频流，如果是音频解码，那么就查找音频流

```c
avformat_find_stream_info();
```
**第四步：查找视频解码器**

1、查找视频流索引位置
    
2、根据视频流索引，获取解码器上下文
    
3、根据解码器上下文，获得解码器ID，然后查找解码器

```c
avcodec_find_decoder()
```

**第五步：打开解码器**

```c
avcodec_open2();
```
**第六步：读取视频压缩数据->循环读取**

读取一帧数据，立马解码一帧数据

```c
 while (av_read_frame() >= 0) {
 	 // decode
 }

```

**第七步：视频解码->播放视频->得到视频像素数据**

```c
avcodec_send_packet()
avcodec_receive_frame()
sws_scale()
```

**第八步：关闭解码器->解码完成**

```c
av_packet_free(&packet);
fclose(file_yuv420p);
av_frame_free(&avframe_in);
av_frame_free(&avframe_yuv420p);
free(out_buffer);
avcodec_close(avcodec_ctx);
avformat_free_context(avformat_ctx);
```
