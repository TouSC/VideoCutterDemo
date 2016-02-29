//
//  ViewController.m
//  VideoCutterDemo
//
//  Created by 范茂羽 on 16/2/26.
//  Copyright © 2016年 范茂羽. All rights reserved.
//

#import "ViewController.h"
#import "MBProgressHUD.h"
#import "ffmpeg.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

@interface ViewController ()
{
    NSString *_inputPath;
    NSString *_outputPath;
}
@property (weak, nonatomic) IBOutlet UITextField *beginTimeTextField;
@property (weak, nonatomic) IBOutlet UITextField *endTimeTextField;
@property (weak, nonatomic) IBOutlet UIButton *beginCutBtn;
@property (weak, nonatomic) IBOutlet UIButton *playBtn;

@end

@implementation ViewController

//裁剪视频函数, 命令行如下:
//ffmpeg -i input.mp4 -ss **START_TIME** -t **STOP_TIME** -acodec copy -vcodec copy output.mp4
- (void)cutInputVideoPath:(char*)inputPath outPutVideoPath:(char*)outputPath startTime:(char*)startTime endTime:(char*)endTime
{
    
    int argc = 12;
    char **arguments = calloc(argc, sizeof(char*));
    if(arguments != NULL)
    {
        arguments[0] = "ffmpeg";
        arguments[1] = "-i";
        arguments[2] = inputPath;
        arguments[3] = "-ss";
        arguments[4] = startTime;
        arguments[5] = "-t";
        arguments[6] = endTime;
        arguments[7] = "-acodec";
        arguments[8] = "copy";
        arguments[9] = "-vcodec";
        arguments[10]= "copy";
        arguments[11]= outputPath;
        
        ffmpeg_main(argc, arguments);
    }
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _inputPath = [[NSBundle mainBundle]pathForResource:@"input" ofType:@"mp4"];
    _outputPath= [NSString stringWithFormat:@"%@/tmp/%@", NSHomeDirectory(), @"output.mp4"];
    NSLog(@"inputPath = %@", _inputPath);
    NSLog(@"outputPath = %@", _outputPath);
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [self.playBtn setHidden:![[NSFileManager defaultManager]fileExistsAtPath:_outputPath]];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(threadWillExit) name:NSThreadWillExitNotification object:nil];
   
}

//ffmpeg命令行线程将要结束时调用
-(void)threadWillExit
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.playBtn setHidden:NO];
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    });
}

//开始裁剪按钮
- (IBAction)beginCutAction:(id)sender
{
    [self.view endEditing:YES];
    
    if(self.beginTimeTextField.text.length == 0 || self.endTimeTextField.text.length == 0)
    {
        NSLog(@"参数不能为空");
        return;
    }
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];

    [NSThread detachNewThreadSelector:@selector(working) toTarget:self withObject:nil];

}

-(void)working
{
    if([[NSFileManager defaultManager]fileExistsAtPath:_outputPath])
    {
        [[NSFileManager defaultManager]removeItemAtPath:_outputPath error:nil];
        NSLog(@"删除成功");
    }
    
    [self cutInputVideoPath:(char*)[_inputPath UTF8String] outPutVideoPath:(char*)[_outputPath UTF8String] startTime:(char*)[self.beginTimeTextField.text UTF8String] endTime:(char*)[self.endTimeTextField.text UTF8String]];


}

//一分为二裁剪
- (IBAction)halfCutAction:(id)sender
{
    [self.view endEditing:YES];

    if([[NSFileManager defaultManager]fileExistsAtPath:_outputPath])
    {
        [[NSFileManager defaultManager]removeItemAtPath:_outputPath error:nil];
        NSLog(@"删除成功");
    }
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    [NSThread detachNewThreadSelector:@selector(halfCutWorking) toTarget:self withObject:nil];
    
}

-(void)halfCutWorking
{
    //获取视频总时长
    AVAsset *aset = [AVAsset assetWithURL:[NSURL fileURLWithPath:_inputPath]];
    CMTimeValue duration = aset.duration.value / aset.duration.timescale;
    
    NSString *endTimeStr = [NSString stringWithFormat:@"%lld", duration/2];
    
    [self cutInputVideoPath:(char*)[_inputPath UTF8String] outPutVideoPath:(char*)[_outputPath UTF8String] startTime:(char*)[@"0" UTF8String] endTime:(char*)[endTimeStr UTF8String]];

}

//播放
- (IBAction)playAction:(id)sender
{

    MPMoviePlayerViewController  *movie = [[MPMoviePlayerViewController alloc]initWithContentURL:[NSURL fileURLWithPath:_outputPath]];
    [movie.moviePlayer setControlStyle:MPMovieControlStyleFullscreen];
    [movie.moviePlayer prepareToPlay];
    [self presentMoviePlayerViewControllerAnimated:movie];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
