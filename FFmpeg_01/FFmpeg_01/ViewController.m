//
//  ViewController.m
//  FFmpeg_01
//
//  Created by Zahi on 2017/12/17.
//  Copyright © 2017年 Zahi. All rights reserved.
//

#import "ViewController.h"
#import "FFmpegDemo.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // 测试ffmpeg配置信息
//    [FFmpegDemo ffmpegConfigTest];
    
    // 打开视频文件
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Test.mov" ofType:nil];
    [FFmpegDemo ffmpegPlayVideoWithFile:path];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
