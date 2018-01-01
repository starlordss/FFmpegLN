//
//  FFmpegDemo.m
//  FFmpeg_01
//
//  Created by Zahi on 2017/12/17.
//  Copyright © 2017年 Zahi. All rights reserved.
//

#import "FFmpegDemo.h"


@implementation FFmpegDemo

+ (void)ffmpegConfigTest {
    // 获取视频编码配置
    const char *config = avcodec_configuration();
    NSLog(@"配置信息%s",config);
}

+ (void)ffmpegPlayVideoWithFile:(NSString *)filePath
{
    // 1. 注册组件
    av_register_all();

    // 2. 打开封装格：打开文件
    // 封装格式上下文
    AVFormatContext *avformat_ctx = avformat_alloc_context();
    // 视频文件的地址
    const char *path = [filePath UTF8String];
    /**
     * 参数一： 封装格式上下文的地址
     * 参数二： 视频路径
     * 参数三： 指定输入封装格式->默认格式
     * 参数四： 指定默认配置信息->默认配置
     */
    int res = avformat_open_input(&avformat_ctx, path, NULL, NULL);
    if (res != 0) { // 打开文件失败
        // 获取失败的信息
        NSLog(@"打开失败");
//        char *error_info = "open failed";
//        av_strerror(res, error_info, 1024);
        return;
    }
    
    // 3.查找视频流---拿到视频信息
    /**
     * 参数一：封装视频的格式
     * 参数二：指定默认配置
     */
    int avformat_stream_info = avformat_find_stream_info(avformat_ctx, NULL);
    if (avformat_stream_info < 0) {
        NSLog(@"查找失败");
    }
    
    // 4.查找视频解码器
    // 4.1查找视频流索引的位置
    int av_stream_idx = -1;
    for (int i = 0; i < avformat_ctx->nb_streams; i++) {
        // 判断流的类型：视频流、音频流、字幕流
        if (avformat_ctx->streams[i]->codec->codec_type == AVMEDIA_TYPE_VIDEO) {
            // 视频流
            av_stream_idx = i;
            break;
        }
        
    }
    // 4.2 根据视频流索引获取解码器上下文
    AVCodecContext *avcodec_ctx = avformat_ctx->streams[av_stream_idx]->codec;
    // 4.3 根据解码器上下文，获取解码器ID，然后查找解码器
    AVCodec *avdecodec = avcodec_find_decoder(avcodec_ctx->codec_id);
    
    // 5 打开解码器
    int open2_result = avcodec_open2(avcodec_ctx, avdecodec, NULL);
    if (open2_result != 0) {
        NSLog(@"打开解码器失败");
        return;
    }
    
    // 测试打印：解码器的名字
    NSLog(@"解码器名称:%s",avdecodec->name);
    
    // 6 读取视频压缩数据：循环读取
    // 6.1 数据包大小：字节对齐原则
    AVPacket *packet = (AVPacket *)av_malloc(sizeof(AVPacket));
    // 6.2 解码一帧视频压缩数据：进行解码（作用：用于解码操作）
    // 开辟一块内存控件
    AVFrame *avframe_in = av_frame_alloc();
    int decode_result = 0;
    
    // 6.3在这里我们不能够保证解码出来的一帧视频像素数据格式是yuv格式
    
    /**
     * 参数一: 源文件->原始视频像素数据格式宽
     * 参数二: 源文件->原始视频像素数据格式高
     * 参数三: 源文件->原始视频像素数据格式类型
     * 参数四: 目标文件->目标视频像素数据格式宽
     * 参数五：目标文件->目标视频像素数据格式高
     * 参数六：目标文件->目标视频像素数据格式类型
     */
    struct SwsContext *sws_ctx = sws_getContext(avcodec_ctx->width,
                   avcodec_ctx->height,
                   avcodec_ctx->pix_fmt,
                   avcodec_ctx->width,
                   avcodec_ctx->height,
                   AV_PIX_FMT_YUV420P,
                   SWS_BICUBIC,
                   NULL,
                   NULL,
                   NULL);
    
    // 创建一个yuv420视频像素数据格式缓存区
    AVFrame *avframe_yuv420p = av_frame_alloc();
    // 给缓冲区设置类型:yuv420p，获取缓存区大小
    
    /**
     * 参数一：视频像素数据格式类型->YUV420P格式
     * 参数二：一帧视频像素数据宽 = 视频宽
     * 参数三：一帧视频像素数据高 = 视频高
     * 参数四：字节对齐方式->默认对齐1
     */
    int buffer_size = av_image_get_buffer_size(AV_PIX_FMT_YUV420P,
                                               avcodec_ctx->width,
                                               avcodec_ctx->height,
                                               1);
    // 开辟一块内存空间
    
    uint8_t *out_buffer = (uint8_t *)av_malloc(buffer_size);
    // 向av_frame_yuv420p填充数据
    /**
     * 参数一：目标->填充数据(avframe_yuv420p)
     * 参数二：目标->每一行大小
     * 参数三：原始数据
     * 参数四：目标->格式类型
     * 参数五：宽
     * 参数四：高
     * 参数四：字节对齐方式->默认对齐1
     */
    av_image_fill_arrays(avframe_yuv420p->data,
                         avframe_yuv420p->linesize,
                         out_buffer,
                         AV_PIX_FMT_YUV420P,
                         avcodec_ctx->width,
                         avcodec_ctx->height,
                         1);
    int y_size, u_size, v_size;
    
    // 将yuv420p数据写入.yuv文件中
    // 打开文件
    const char *outfile = [filePath UTF8String];
    FILE *file_yuv420p = fopen(outfile, "wb+");
    if (file_yuv420p == NULL) {
        NSLog(@"输出文件打开失败");
        return;
    }
    int current_idxx = 0;
    
    
    
    
    
}

@end
