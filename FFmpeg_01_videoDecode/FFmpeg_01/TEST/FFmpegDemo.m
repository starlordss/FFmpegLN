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

+ (void)ffmpegPlayVideoWithFile:(NSString *)filePath outfile:(NSString *)outfilePath
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
    
    // 5. 打开解码器
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
     * 参数六：高
     * 参数七：字节对齐方式->默认对齐1
     */
    av_image_fill_arrays(avframe_yuv420p->data,
                         avframe_yuv420p->linesize,
                         out_buffer,
                         AV_PIX_FMT_YUV420P,
                         avcodec_ctx->width,
                         avcodec_ctx->height,
                         1);
    int y_size, u_size, v_size;
    
    // 5.2 将yuv420p数据写入.yuv文件中
    // 打开文件
    const char *outfile = [outfilePath UTF8String];
    NSLog(@"%s",outfile);
    //wb+ 以读/写方式打开或建立一个二进制文件，允许读和写。
    FILE *file_yuv420p = fopen(outfile, "wb+");
    if (file_yuv420p == NULL) {
        NSLog(@"输出文件打开失败");
        return;
    }
    int current_idx = 0;
    
    while (av_read_frame(avformat_ctx, packet) >= 0) {
        //是否是我们的视频流
        if (packet->stream_index == av_stream_idx) {
            // 7 解码(解码一帧压缩数据->得到视频像素数据->yuv格式)
            // 发送一帧压缩数据
            avcodec_send_packet(avcodec_ctx, packet);
            // 解码一帧视频压缩数据
            decode_result = avcodec_receive_frame(avcodec_ctx, avframe_in);
            if (decode_result == 0) { // 解码成功
                // 进行类型转换:将解码出来的视频像素点数据格式->统一转类型为yuv420P
                /**
                 * 参数一：视频像素数据格式上下文
                 * 参数二：原来的视频像素数据格式->输入数据
                 * 参数三：原来的视频像素数据格式->输入画面每一行大小
                 * 参数四：原来的视频像素数据格式->输入画面每一行开始位置(填写：0->表示从原点开始读取)
                 * 参数五：原来的视频像素数据格式->输入数据行数
                 * 参数六：转换类型后视频像素数据格式->输出数据
                 * 参数七：转换类型后视频像素数据格式->输出画面每一行大小
                 */
                sws_scale(sws_ctx,
                          (const uint8_t *const *)avframe_in->data,
                          avframe_in->linesize,
                          0,
                          avcodec_ctx->height,
                          avframe_yuv420p->data,
                          avframe_yuv420p->linesize);
                // 方式一：直接显示视频上
                // 方式二：写入yuv文件格式
                // 将yun420p数据写入.yuv文件中:Y- 亮度 UV- 色度
                // YUV420P格式规范一：Y结构表示一个像素(一个像素对应一个Y)
                // YUV420P格式规范二：4个像素点对应一个(U和V: 4Y = U = V)
                y_size = avcodec_ctx->width * avcodec_ctx->height;
                u_size = y_size / 4;
                v_size = y_size / 4;
                // 写入
                fwrite(avframe_yuv420p->data[0], 1, y_size, file_yuv420p);
                fwrite(avframe_yuv420p->data[1], 1, y_size, file_yuv420p);
                fwrite(avframe_yuv420p->data[2], 1, y_size, file_yuv420p);
                
                current_idx++;
                NSLog(@"当前解码第%d帧", current_idx);
            }
        }
    }
    // 8 释放内存资源，关闭解码器
    av_packet_free(&packet);
    fclose(file_yuv420p);
    av_frame_free(&avframe_in);
    av_frame_free(&avframe_yuv420p);
    free(out_buffer);
    avcodec_close(avcodec_ctx);
    avformat_free_context(avformat_ctx);
    
    
    
    
    
}

@end
