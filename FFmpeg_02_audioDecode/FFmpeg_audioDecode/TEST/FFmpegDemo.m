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
    // 音频文件的地址
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
        return;
    }
    NSLog(@"打开文件成功");
    
    // 3.查找视频流---拿到视频信息
    /**
     * 参数一：封装视频的格式
     * 参数二：指定默认配置
     */
    int avformat_stream_info = avformat_find_stream_info(avformat_ctx, NULL);
    if (avformat_stream_info < 0) {
        NSLog(@"查找失败");
        return;
    }
    
    // 4.查找音频解码器
    // 4.1查找音频流索引的位置
    int av_stream_idx = -1;
    for (int i = 0; i < avformat_ctx->nb_streams; i++) {
        // 判断是否是音频流
        if (avformat_ctx->streams[i]->codec->codec_type == AVMEDIA_TYPE_AUDIO) {
            // 音频流
            av_stream_idx = i;
            break;
        }
    }
    // 4.2 根据音频流索引获取解码器上下文
    AVCodecContext *avcodec_ctx = avformat_ctx->streams[av_stream_idx]->codec;
    // 4.3 根据解码器上下文，获取解码器ID，然后查找解码器
    AVCodec *avdecodec = avcodec_find_decoder(avcodec_ctx->codec_id);
    if (avdecodec == NULL) {
        NSLog(@"查找音频解码器失败");
        return;
    }
    
    // 5. 打开音频解码器
    int open2_result = avcodec_open2(avcodec_ctx, avdecodec, NULL);
    if (open2_result != 0) {
        NSLog(@"打开音频解码器失败");
        return;
    }
    // 测试打印：解码器的名字
    NSLog(@"解码器名称:%s",avdecodec->name);
    
    // 6 读取音频压缩数据：循环读取
    // 6.1 音频压缩数据acc、mp3
    AVPacket *packet = (AVPacket *)av_malloc(sizeof(AVPacket));
    // 创建音频采样数据帧
    AVFrame *avframe = av_frame_alloc();
    //音频采样上下文->开辟了一快内存空间->pcm格式等..
    SwrContext *swr_ctx = swr_alloc();
    // 输出声音布局类型（立体声）
//    int64_t out_ch_layout = AV_CH_LAYOUT_STEREO;
    // out_sample_fmt：输出采样精度
    // 动态获取，保持一致
//    enum AVSampleFormat out_sample_fmt = avcodec_ctx->sample_fmt;
    // out_sample_rate->输出采样率(44100HZ)
//    int out_sample_rate = avcodec_ctx->sample_rate;
    // in_ch_layout 输入声道布局类型
    int64_t in_ch_layout = av_get_default_channel_layout(avcodec_ctx->channels);

    swr_alloc_set_opts(swr_ctx,
                       AV_CH_LAYOUT_STEREO,
                       AV_SAMPLE_FMT_S16,
                       avcodec_ctx->sample_rate,
                       in_ch_layout,
                       avcodec_ctx->sample_fmt,
                       avcodec_ctx->sample_rate,
                       0,
                       NULL);
    // 初始化音频采样数据上下文
    swr_init(swr_ctx);

    // 输出音频采样数据
    //缓冲区大小 = 采样率(44100HZ) * 采样精度(16位 = 2字节)
    int max_audio_size = 44100 * 2;
    uint8_t *out_buffer = (uint8_t *)av_malloc(max_audio_size);
    // 输出音道数量
    int out_nb_channels = av_get_channel_layout_nb_channels(AV_CH_LAYOUT_STEREO);

    // 打开文件
    const char *outPath = [outfilePath UTF8String];
    FILE *out_file_pcm = fopen(outPath, "wb+");
    if (out_file_pcm == NULL) {
        NSLog(@"打开音频输出文件失败");
        return;
    }
    int current_idx = 0;

    while (av_read_frame(avformat_ctx, packet) >= 0) {
        // 读取一帧音频压缩成功
        // 判读：音频流
        if (packet->stream_index == av_stream_idx) {
            // 7 音频解码
            // 7.1 发送一帧音频压缩数据包
            avcodec_send_packet(avcodec_ctx, packet);
            // 7.2 解码一帧音频数据包
            int result = avcodec_receive_frame(avcodec_ctx, avframe);
            if (result == 0) {
                // 解码成功
                // 7.3 类型转换pcm格式
                //swr_convert:表示音频采样数据类型格式转换器
                /**
                 * 参数一：音频采样数据上下文
                 * 参数二：输出音频采样数据
                 * 参数三：输出音频采样数据->大小
                 * 参数四：输入音频采样数据
                 * 参数五：输入音频采样数据->大小
                 */
                swr_convert(swr_ctx,
                            &out_buffer,
                            max_audio_size,
                            (const uint8_t **)avframe->data,
                            avframe->nb_samples);
                //7.4 获取缓存区存储大小
                int nb_samples = avframe->nb_samples;
                /**
                 * 参数一：行大小
                 * 参数二：输出声道数量
                 * 参数三：输入大小
                 * 参数四：输出音频采样数据格式
                 * 参数五：字节对齐方式
                 */
                int out_buffer_size = av_samples_get_buffer_size(NULL,
                                                                 out_nb_channels,
                                                                 nb_samples,
                                                                 avcodec_ctx->sample_fmt,
                                                                 1);
                // 7.5 写入文件
                fwrite(out_buffer, 1, out_buffer_size, out_file_pcm);
                current_idx++;
                NSLog(@"前音频解码第%d帧", current_idx);
            }
        }
    }
    //第八步：释放内存资源，关闭音频解码器
    fclose(out_file_pcm);
    av_packet_free(&packet);
    swr_free(&swr_ctx);
    av_free(out_buffer);
    av_frame_free(&avframe);
    avcodec_close(avcodec_ctx);
    avformat_close_input(&avformat_ctx);
}

@end
