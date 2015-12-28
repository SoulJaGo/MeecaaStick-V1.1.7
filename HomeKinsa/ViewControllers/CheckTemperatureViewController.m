//
//  CheckTemperatureViewController.m
//  HomeKinsa
//
//  Created by Zhang guangchun on 15/3/28.
//  Copyright (c) 2015年 Mikai. All rights reserved.
//

#import "CheckTemperatureViewController.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "TTNetworkHelper.h"

#define QUEUE_BUFFER_SIZE 1 //队列缓冲个数
#define EVERY_READ_LENGTH 1000 //每次从文件读取的长度
#define MIN_SIZE_PER_FRAME 2000 //每侦最小数据长度

@interface CheckTemperatureViewController ()//<AVAudioPlayerDelegate>
{
    AudioStreamBasicDescription audioDescription;///音频参数
    AudioQueueRef audioQueue;//音频播放队列
    AudioQueueBufferRef audioQueueBuffers[QUEUE_BUFFER_SIZE];//音频缓存
    NSLock *synlock ;///同步控制
    short pcmDataBuffer[4096];
    
    //录音器
    AVAudioRecorder *recorder;
    //播放器
    AVAudioPlayer *player;
    NSDictionary *recorderSettingsDict;
    
    //定时器
//    NSTimer *timer;
    NSTimer *timer2;

    double lowPassResults;
    
    //录音名字
    NSString *playName;
    
    int timerCount;
    int playCount;
    
//    AVAudioPlayer *avAudioPlayer;
}

static void AudioPlayerAQInputCallback(void *input, AudioQueueRef inQ, AudioQueueBufferRef outQB);
-(void)initAudio;
-(void)readPCMAndPlay:(AudioQueueRef)outQ buffer:(AudioQueueBufferRef)outQB;
-(void)checkUsedQueueBuffer:(AudioQueueBufferRef) qbuf;
@end

@implementation CheckTemperatureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    timerCount = 0;
    playCount = 0;
    synlock = [[NSLock alloc] init];
    
    NSTimeInterval time = [[NSDate date] timeIntervalSince1970];
    long long int date = (long long int)time;
    
    
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    playName = [NSString stringWithFormat:@"%@/play_%lli.raw", docDir,date];
    //录音设置
    recorderSettingsDict =[[NSDictionary alloc] initWithObjectsAndKeys:
                           //                                         [NSNumber numberWithInt:kAudioFormatMPEG4AAC],AVFormatIDKey,
                           [NSNumber numberWithInt:kAudioFormatLinearPCM],AVFormatIDKey,
                           //                                         [NSNumber numberWithInt:1000.0],AVSampleRateKey,
                           [NSNumber numberWithInt:11025.0],AVSampleRateKey,
                           //                                         [NSNumber numberWithInt:2],AVNumberOfChannelsKey,
                           [NSNumber numberWithInt:1],AVNumberOfChannelsKey,
                           //                                         [NSNumber numberWithInt:8],AVLinearPCMBitDepthKey,
                           [NSNumber numberWithInt:16],AVLinearPCMBitDepthKey,
                           [NSNumber numberWithBool:NO],AVLinearPCMIsBigEndianKey,
                           [NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,
                           nil];
    
    
    /*NSString *string = [[NSBundle mainBundle] pathForResource:@"0410KHz" ofType:@"mp3"];
    NSURL *url = [NSURL fileURLWithPath:string];
    avAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    avAudioPlayer.delegate = self;
    avAudioPlayer.volume = 1;
    avAudioPlayer.numberOfLoops = 1;
    [avAudioPlayer prepareToPlay];*/
}

/*- (void)play{
    playCount = 0;
    timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(playTimer:) userInfo:nil repeats:YES];
    [avAudioPlayer play];
}

-(void)playTimer:(NSTimer*)timer_{
    playCount++;
    if (playCount>=1) {
        playCount = 0;
        [avAudioPlayer stop];
        [timer invalidate];
        timer = nil;
        
        [self downAction:nil];
    }
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    NSLog(@"audioPlayerDidFinishPlaying");
}*/

- (int)getPlayCount {
    return playCount;
}

- (void)addPlayCount {
    playCount++;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma mark player call back
/*
 试了下其实可以不用静态函数，但是c写法的函数内是无法调用[self ***]这种格式的写法，所以还是用静态函数通过void *input来获取原类指针
 这个回调存在的意义是为了重用缓冲buffer区，当通过AudioQueueEnqueueBuffer(outQ, outQB, 0, NULL);函数放入queue里面的音频文件播放完以后，通过这个函数通知
 调用者，这样可以重新再使用回调传回的AudioQueueBufferRef
 */
static void AudioPlayerAQInputCallback(void *input, AudioQueueRef outQ, AudioQueueBufferRef outQB)
{
    NSLog(@"AudioPlayerAQInputCallback");
    CheckTemperatureViewController *mainviewcontroller = (__bridge CheckTemperatureViewController *)input;
    
    if ([mainviewcontroller getPlayCount]>=50) {
        if ([[[UIDevice currentDevice] systemVersion] compare:@"7.0"] != NSOrderedAscending){
            //7.0第一次运行会提示，是否允许使用麦克风
            AVAudioSession *session = [AVAudioSession sharedInstance];
            NSError *sessionError;
            //AVAudioSessionCategoryPlayAndRecord用于录音和播放
            [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&sessionError];
            if(session == nil)
                NSLog(@"Error creating session: %@", [sessionError description]);
            else
                [session setActive:YES error:nil];
        }
        [mainviewcontroller downAction:nil];
        return;
    }
    [mainviewcontroller checkUsedQueueBuffer:outQB];
    [mainviewcontroller readPCMAndPlay:outQ buffer:outQB];
    
    [mainviewcontroller addPlayCount];
}

- (void)initAudio
{
    ///设置音频参数
    audioDescription.mSampleRate = 44100;//8000;//采样率
    audioDescription.mFormatID = kAudioFormatLinearPCM;
    audioDescription.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    audioDescription.mChannelsPerFrame = 1;///单声道
    audioDescription.mFramesPerPacket = 1;//每一个packet一侦数据
    audioDescription.mBitsPerChannel = 16;//每个采样点16bit量化
    audioDescription.mBytesPerFrame = 2;//(audioDescription.mBitsPerChannel/8) * audioDescription.mChannelsPerFrame;
    audioDescription.mBytesPerPacket = audioDescription.mBytesPerFrame ;
    ///创建一个新的从audioqueue到硬件层的通道
    //	AudioQueueNewOutput(&audioDescription, AudioPlayerAQInputCallback, self, CFRunLoopGetCurrent(), kCFRunLoopCommonModes, 0, &audioQueue);///使用当前线程播
    AudioQueueNewOutput(&audioDescription, AudioPlayerAQInputCallback, (__bridge void *)(self), nil, nil, 0, &audioQueue);//使用player的内部线程播
    ////添加buffer区
    for(int i=0;i<QUEUE_BUFFER_SIZE;i++)
    {
        int result =  AudioQueueAllocateBuffer(audioQueue, MIN_SIZE_PER_FRAME, &audioQueueBuffers[i]);///创建buffer区，MIN_SIZE_PER_FRAME为每一侦所需要的最小的大小，该大小应该比每次往buffer里写的最大的一次还大
        NSLog(@"AudioQueueAllocateBuffer i = %d,result = %d",i,result);
    }
}

- (IBAction)onClickCheck:(id)sender {
    /*timerCount = 0;
    playCount = 0;
    
    [self initAudio];
    AudioQueueSetParameter(audioQueue, kAudioQueueParam_Volume, 1.0);
    AudioQueueStart(audioQueue, NULL);
    for(int i=0;i<QUEUE_BUFFER_SIZE;i++)
    {
        [self readPCMAndPlay:audioQueue buffer:audioQueueBuffers[i]];
    }*/
    
//    [self play];
}

-(void)readPCMAndPlay:(AudioQueueRef)outQ buffer:(AudioQueueBufferRef)outQB
{
    [synlock lock];
    int readLength = 4096;
    NSLog(@"read raw data size = %d",readLength);
    outQB->mAudioDataByteSize = readLength;
    Byte *audiodata = (Byte *)outQB->mAudioData;
    for(int i=0;i<readLength;i++)
    {
        audiodata[i] = pcmDataBuffer[i];
    }
    /*
     将创建的buffer区添加到audioqueue里播放
     AudioQueueBufferRef用来缓存待播放的数据区，AudioQueueBufferRef有两个比较重要的参数，AudioQueueBufferRef->mAudioDataByteSize用来指示数据区大小，AudioQueueBufferRef->mAudioData用来保存数据区
     */
    AudioQueueEnqueueBuffer(outQ, outQB, 0, NULL);
    [synlock unlock];
}

-(void)checkUsedQueueBuffer:(AudioQueueBufferRef) qbuf
{
    if(qbuf == audioQueueBuffers[0])
    {
        NSLog(@"AudioPlayerAQInputCallback,bufferindex = 0");
    }
    /*if(qbuf == audioQueueBuffers[1])
    {
        NSLog(@"AudioPlayerAQInputCallback,bufferindex = 1");
    }
    if(qbuf == audioQueueBuffers[2])
    {
        NSLog(@"AudioPlayerAQInputCallback,bufferindex = 2");
    }
    if(qbuf == audioQueueBuffers[3])
    {
        NSLog(@"AudioPlayerAQInputCallback,bufferindex = 3");
    }*/
}

- (void)downAction:(id)sender {
    //按下录音
    if ([self canRecord]) {
        
        NSError *error = nil;
        //必须真机上测试,模拟器上可能会崩溃
        recorder = [[AVAudioRecorder alloc] initWithURL:[NSURL URLWithString:playName] settings:recorderSettingsDict error:&error];
        
        if (recorder) {
            NSLog(@"start recorder");
            recorder.meteringEnabled = YES;
            [recorder prepareToRecord];
            [recorder record];
            
            timerCount = 0;
            //启动定时器
            timer2 = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(levelTimer:) userInfo:nil repeats:YES];
            
        } else
        {
            int errorCode = CFSwapInt32HostToBig ([error code]);
            NSLog(@"Error: %@ [%4.4s])" , [error localizedDescription], (char*)&errorCode);
            
        }
    }
}

- (IBAction)onClickUpdate:(id)sender {
    NSLog(@"update %@", playName);
    NSData *videoData = [[NSFileManager defaultManager] contentsAtPath:playName];
    NSDictionary *paramdict = @{@"app":@"test",
                                @"uid":@"1",
                                @"key":@"1",
                                @"itemid":@"1",
                                @"photo":@"2",
                                @"caption":@"test"
                                };
    RACSignal *signal = [[TTNetworkHelper sharedSession] updateVideo:paramdict video:videoData];
    [[signal deliverOn:RACScheduler.mainThreadScheduler]
     subscribeNext:^(NSDictionary *object){
         NSLog(@"update finish");
     }
     error:^(NSError *error){
         NSLog(@"update error");
     }
     completed:^{
         NSLog(@"update complete");
     }];
}


-(void)levelTimer:(NSTimer*)timer_
{
//    NSLog(@"level timer %i", timerCount);
    /*timerCount++;
    if (timerCount>200) {
        [self upAction:nil];
    }*/
    
    [recorder updateMeters];
    const double ALPHA = 0.05;
    double peakPowerForChannel = pow(10, (0.05 * [recorder peakPowerForChannel:0]));
    lowPassResults = ALPHA * peakPowerForChannel + (1.0 - ALPHA) * lowPassResults;
    
    NSLog(@"Average input: %f Peak input: %f Low pass results: %f", [recorder averagePowerForChannel:0], [recorder peakPowerForChannel:0], lowPassResults);
}

- (IBAction)upAction:(id)sender {
    //松开 结束录音
    
    //录音停止
    [recorder stop];
    recorder = nil;
    //结束定时器
    [timer2 invalidate];
    timer2 = nil;
    
    NSLog(@"finish record");
}

- (IBAction)onPlayClick:(id)sender {
    NSError *playerError;
    
    //播放
    player = nil;
    player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL URLWithString:playName] error:&playerError];
    
    if (player == nil)
    {
        NSLog(@"ERror creating player: %@", [playerError description]);
    }else{
        [player play];
    }
}

//判断是否允许使用麦克风7.0新增的方法requestRecordPermission
-(BOOL)canRecord
{
    __block BOOL bCanRecord = YES;
    if ([[[UIDevice currentDevice] systemVersion] compare:@"7.0"] != NSOrderedAscending)
    {
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        if ([audioSession respondsToSelector:@selector(requestRecordPermission:)]) {
            [audioSession performSelector:@selector(requestRecordPermission:) withObject:^(BOOL granted) {
                if (granted) {
                    bCanRecord = YES;
                }
                else {
                    bCanRecord = NO;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[[UIAlertView alloc] initWithTitle:nil
                                                    message:@"app需要访问您的麦克风。\n请启用麦克风-设置/隐私/麦克风"
                                                   delegate:nil
                                          cancelButtonTitle:@"关闭"
                                          otherButtonTitles:nil] show];
                    });
                }
            }];
        }
    }
    
    return bCanRecord;
}

- (IBAction)onClickDelete:(id)sender {
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
