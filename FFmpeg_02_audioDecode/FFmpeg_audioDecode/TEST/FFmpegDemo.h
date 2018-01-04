//
//  FFmpegDemo.h
//  FFmpeg_01
//
//  Created by Zahi on 2017/12/17.
//  Copyright © 2017年 Zahi. All rights reserved.
//

#import <Foundation/Foundation.h>
// 核心库->音视频编解码库
#import <libavcodec/avcodec.h>
// 导入封装格式库
#import <libavformat/avformat.h>
//音频采样数据格式库
#include <libswresample/swresample.h>
//工具库
#import <libavutil/imgutils.h>

@interface FFmpegDemo : NSObject
+ (void)ffmpegConfigTest;

+ (void)ffmpegPlayVideoWithFile:(NSString *)filePath outfile:(NSString *)outfilePath;
@end
