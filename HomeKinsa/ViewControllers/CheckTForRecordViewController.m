//
//  CheckTForRecordViewController.m
//  HomeKinsa
//
//  Created by Zhang guangchun on 15/3/30.
//  Copyright (c) 2015年 Mikai. All rights reserved.
//

#import "CheckTForRecordViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "TTNetworkHelper.h"
#import "lib_decode.h"
#import "UIViewController+ProgressHUD.h"
#import <SIAlertView/SIAlertView.h>

@interface CheckTForRecordViewController ()<UITableViewDataSource, UITableViewDelegate>
{
    //录音器
    AVAudioRecorder *recorder;
    //播放器
    AVAudioPlayer *player;
    NSDictionary *recorderSettingsDict;
    
    //定时器
    NSTimer *timer;
    //图片组
    NSMutableArray *volumImages;
    double lowPassResults;
    
    //录音名字
    NSString *playName;
    int recordCount;
    
    /////////////////////
    NSTimer *timer2;
    AVAudioPlayer *avAudioPlayer;
    int playCount;
    
    NSTimeInterval startCheckTime;
    
    NSTimeInterval allCheckTime;
}
@property (weak, nonatomic) IBOutlet UIButton *checkBtn;
@property (weak, nonatomic) IBOutlet UITableView *checkTableView;
@property (retain, nonatomic) NSMutableArray *checkList;

@end

@implementation CheckTForRecordViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    if ([[[UIDevice currentDevice] systemVersion] compare:@"7.0"] != NSOrderedAscending)
    {
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
    
    //录音设置
    recorderSettingsDict =[[NSDictionary alloc] initWithObjectsAndKeys:
                           //                                         [NSNumber numberWithInt:kAudioFormatMPEG4AAC],AVFormatIDKey,
                           [NSNumber numberWithInt:kAudioFormatLinearPCM],AVFormatIDKey,
                           //                                         [NSNumber numberWithInt:1000.0],AVSampleRateKey,
                           [NSNumber numberWithInt:22050],AVSampleRateKey,
                           //                                         [NSNumber numberWithInt:2],AVNumberOfChannelsKey,
                           [NSNumber numberWithInt:1],AVNumberOfChannelsKey,
                           //                                         [NSNumber numberWithInt:8],AVLinearPCMBitDepthKey,
                           [NSNumber numberWithInt:16],AVLinearPCMBitDepthKey,
                           [NSNumber numberWithBool:NO],AVLinearPCMIsBigEndianKey,
                           [NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,
                           nil];
    
    
///////////////////
    NSString *string = [[NSBundle mainBundle] pathForResource:@"0410KHz" ofType:@"mp3"];
    NSURL *url = [NSURL fileURLWithPath:string];
    avAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    avAudioPlayer.volume = 1;
    avAudioPlayer.numberOfLoops = 1;
    [avAudioPlayer prepareToPlay];
    
    allCheckTime = 3*60;
    
    self.checkTableView.delegate = self;
    self.checkTableView.dataSource = self;
    [self.checkTableView reloadData];
    
    self.checkTableView.hidden = YES;
    self.checkBtn.hidden = NO;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section{
    return @"";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.checkList.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 43;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
//    CheckMainHistoryRecordTableViewCell *cell = (CheckMainHistoryRecordTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"CheckMainHistoryRecordTableViewCell"];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"checkTableView"];
    UILabel *label = [cell.contentView.subviews objectAtIndex:0];
    label.text = [self.checkList objectAtIndex:[indexPath row]];
    return cell;
}

- (IBAction)onClickCut:(id)sender {
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
//    long long int date = 1428216211;
//    NSString *binaryFile = [NSString stringWithFormat:@"%@/play_%lli.raw", docDir, date];
    NSData *myData = [[NSData alloc] initWithContentsOfFile:playName];//binaryFile];
//    NSLog(@"%@", myData);
    
    Byte *bytes = (Byte *)[myData bytes];
    Byte* _bytes = malloc(2 * sizeof(Byte));
    
    BOOL flag = false;
    int idx = 0;
    
    Byte *result = malloc(4*1024*sizeof(Byte));
    
    for (int i=200; i<myData.length; i+=2) {
        _bytes[0] = bytes[i];
        _bytes[1] = bytes[i+1];
        NSData* data = [NSData dataWithBytes:_bytes length:2];
        short number = 0;
        [data getBytes:&number];
        
        if (flag) {
            idx+=2;
            if (abs(number)>2000||idx>50) {
                if (idx>=4*1024) {
                    break;
                }
                result[idx] = bytes[i];
                result[idx+1] = bytes[i+1];
            }
            else {
                flag = false;
                idx = 0;
            }
        }
        else {
            if (abs(number)>2000) {
//                printf("**************************start i:%d \n", i);
                flag = true;
                idx = 0;
                result[idx] = bytes[i];
                result[idx+1] = bytes[i+1];
            }
        }
//        NSLog(@"the number is %d, hex form: %x", number, number);
    }
    free(_bytes);
    
    [[NSFileManager defaultManager] createFileAtPath:[NSString stringWithFormat:@"%@/test.raw", docDir] contents:[NSData dataWithBytes:result length:4*1024] attributes:nil];
    
    if (false) {
        NSData *videoData = [[NSFileManager defaultManager] contentsAtPath:[NSString stringWithFormat:@"%@/test.raw", docDir]];
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
    
    [self onClickRead:nil];
}

- (IBAction)onClickRead:(id)sender {
//    NSString *binaryFile = @"/var/mobile/Containers/Data/Application/C839F17D-2679-4CBB-8FD6-D7E1CF8C8278/Documents/play_1427730752.raw";
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
//    long long int date = 1427730752;
//    NSString *binaryFile = [NSString stringWithFormat:@"%@/play_%lli.raw", docDir, date];
    NSString *binaryFile = [NSString stringWithFormat:@"%@/test.raw", docDir];
    
    NSData *myData = [[NSData alloc] initWithContentsOfFile:binaryFile];
//    NSLog(@"%@", myData);
    
    Byte *bytes = (Byte *)[myData bytes];
    Byte* _bytes = malloc(2 * sizeof(Byte));
    
    BOOL flag = false;
    int idx = 0;
    
    short *result = malloc((2*1024+512)*sizeof(short));
//    Byte *result = malloc(2*1024*sizeof(Byte));
    
    for (int i=0; i<myData.length; i+=2) {
        _bytes[0] = bytes[i];
        _bytes[1] = bytes[i+1];
        NSData* data = [NSData dataWithBytes:_bytes length:2];
        short number = 0;
        [data getBytes:&number];

        if (flag) {
            idx++;
            if (idx>=2*1024+512) {
                break;
            }
//            result[idx] = bytes[i];
//            result[idx+1] = bytes[i+1];
            result[idx] = number;
        }
        else {
            if (abs(number)>2000) {
                flag = true;
                idx = 0;
                result[idx] = number;
//                result[idx] = bytes[i];
//                result[idx+1] = bytes[i+1];
            }
        }
//        NSLog(@"the number is %d, hex form: %x", number, number);
    }
    free(_bytes);
   // short tempdata[2*1024+512];
    
  //  memcpy((short*)tempdata, (short*)result,2*1024+512);
  //  mk_calc1(tempdata,0,2*1024+512);
   // printf("result %i",mk_calc1(result,0,2*1024+512));
    int bytelen;
    unsigned char pdestdata[10];
    
    memset(pdestdata,0,10);
    mk_AudioFormat(22050, 1000, 1, 0, 0, 0, 0);
    printf("result %i",mk_Data1(result, 2*1024+512, pdestdata, &bytelen));
//    printf("run here!!!\n");
//  if(bytelen == 0)
//  printf("result %i",mk_Data(result, 2*1024+512, pdestdata, &bytelen));
//    for(int k = 0; k < 5;k++)
//    {
//        printf("pdestdata%d: %d\n",k,pdestdata[k]);
//    }
//    printf("you are sucess!!\n");
   // self.label1.text = @"test";
    char ctemp[40];
    for(int n = 0; n < 40;n++)
    {
        ctemp[n] = 0;
    }
    byteToHexStr2(pdestdata, 5,ctemp);
        NSString *str=[NSString stringWithCString :ctemp encoding:NSUTF8StringEncoding];
//    self.label1.text= str;
    int itemp = (pdestdata[2]<< 8)+ pdestdata[1];
    float ftemp = (float)(itemp /100.0);
    NSString *str1 = [NSString stringWithFormat:@"%2f℃",ftemp];
    
    NSString *resultStr = @"";
    //if(((pdestdata[1] + pdestdata[2]) & 0xFF)==pdestdata[3])
    if (0xcc==pdestdata[2])
    {
        resultStr = [NSString stringWithFormat:@"结果 %@", str1];
//        self.label2.text =str1;
    }
    else
    {
        resultStr = [NSString stringWithFormat:@"错误 %@", str];
    }
    
    /*SIAlertView *alertView = [[SIAlertView alloc] initWithTitle:@"提醒" andMessage:resultStr];
    [alertView addButtonWithTitle:@"确定"
                             type:SIAlertViewButtonTypeDefault
                          handler:^(SIAlertView *alert) {
                          }];
    alertView.transitionStyle = SIAlertViewTransitionStyleBounce;
    [alertView show];*/
    
    NSTimeInterval nowTime = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval dTime = nowTime - startCheckTime;
    [self.checkList addObject:[NSString stringWithFormat:@"%f: %@", dTime, resultStr]];
    [self.checkTableView reloadData];
    
    //[self dismissProgressHUD];
    
    if (dTime<allCheckTime) {
        [self checkOneTime:nowTime];
    }
    else{
        SIAlertView *alertView = [[SIAlertView alloc] initWithTitle:@"提醒" andMessage:@"结束测试"];
        [alertView addButtonWithTitle:@"确定"
                                 type:SIAlertViewButtonTypeDefault
                              handler:^(SIAlertView *alert) {
                                  self.checkBtn.hidden = NO;
                                  self.checkTableView.hidden = YES;
                              }];
        alertView.transitionStyle = SIAlertViewTransitionStyleBounce;
        [alertView show];
    }
    
//    NSLog(@"the number is %d, hex form: %x", result[0], result[1]);
    
    /*[[NSFileManager defaultManager] createFileAtPath:[NSString stringWithFormat:@"%@/test.raw", docDir] contents:[NSData dataWithBytes:result length:2*1024] attributes:nil];
    
    NSData *videoData = [[NSFileManager defaultManager] contentsAtPath:[NSString stringWithFormat:@"%@/test.raw", docDir]];
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
     }];*/
    
    /*FILE *_binaryFileHandle = NULL;
    _binaryFileHandle = fopen([binaryFile UTF8String], "rb");
    if (_binaryFileHandle != NULL) {
        long idxPos = 20;
        fseek(_binaryFileHandle, idxPos, SEEK_SET);
        short *buff[1024*5];
        fread(buff, 0, 1024*5, _binaryFileHandle);
        fclose(_binaryFileHandle);
    }*/
}

- (IBAction)onClickCheck:(id)sender {
    self.checkBtn.hidden = YES;
    self.checkTableView.hidden = NO;
    if (self.checkList) {
        [self.checkList removeAllObjects];
    }
    self.checkList = [NSMutableArray array];
    
    NSTimeInterval time = [[NSDate date] timeIntervalSince1970];
    
//    NSDate* dat = [NSDate dateWithTimeIntervalSinceNow:0];
//    startCheckTime = [dat timeIntervalSince1970]*1000;
    startCheckTime = time;
    NSLog(@"%f", startCheckTime);
    
    [self checkOneTime:time];
}

- (void)checkOneTime:(NSTimeInterval)time{
    [self deleteTempFiles];
//    [self showProgressHUD];
    
    long long int date = (long long int)time;
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    playName = [NSString stringWithFormat:@"%@/play_%lli.raw", docDir,date];
    
    [self play];
}

- (void)deleteTempFiles{
    NSString *extension = @"raw";
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:documentsDirectory error:NULL];
    NSEnumerator *e = [contents objectEnumerator];
    NSString *filename;
    while ((filename = [e nextObject])) {
        if ([[filename pathExtension] isEqualToString:extension]) {
            [fileManager removeItemAtPath:[documentsDirectory stringByAppendingPathComponent:filename] error:NULL];
        }
    }
}

- (void)play{
    NSLog(@"play");
    playCount = 0;
    timer2 = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(playTimer:) userInfo:nil repeats:YES];
    [avAudioPlayer play];
}
 
-(void)playTimer:(NSTimer*)timer_{
    playCount++;
    if (playCount>=8) {   //这个是播放时间的 先不要改动
        playCount = 0;
        [avAudioPlayer stop];
        [timer2 invalidate];
        timer2 = nil;
        [self downAction:nil];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)downAction:(id)sender {
    NSLog(@"downAction");
    //按下录音
    if ([self canRecord]) {
        
        NSError *error = nil;
        //必须真机上测试,模拟器上可能会崩溃
        recorder = [[AVAudioRecorder alloc] initWithURL:[NSURL URLWithString:playName] settings:recorderSettingsDict error:&error];
        
        if (recorder) {
            recordCount = 0;
            recorder.meteringEnabled = YES;
            [recorder prepareToRecord];
            [recorder record];
            
            //启动定时器
            timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(levelTimer:) userInfo:nil repeats:YES];
            
        } else
        {
            int errorCode = CFSwapInt32HostToBig ([error code]);
            NSLog(@"Error: %@ [%4.4s])" , [error localizedDescription], (char*)&errorCode);
            
        }
    }
    
}

- (IBAction)upAction:(id)sender {
    //松开 结束录音
    
    //录音停止
    [recorder stop];
    recorder = nil;
    //结束定时器
    [timer invalidate];//移除定时器
    timer = nil;
    
    NSLog(@"upAction");
    
    [self onClickCut:nil];
}

- (IBAction)playAction:(id)sender {
    
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

-(void)levelTimer:(NSTimer*)timer_
{
    //call to refresh meter values刷新平均和峰值功率,此计数是以对数刻度计量的,-160表示完全安静，0表示最大输入值
    [recorder updateMeters];
    const double ALPHA = 0.05;
    double peakPowerForChannel = pow(10, (0.05 * [recorder peakPowerForChannel:0]));
    lowPassResults = ALPHA * peakPowerForChannel + (1.0 - ALPHA) * lowPassResults;
    
//    NSLog(@"Average input: %f Peak input: %f Low pass results: %f", [recorder averagePowerForChannel:0], [recorder peakPowerForChannel:0], lowPassResults);
    
//    NSLog(@"%i", recordCount);
    /*录音技术大于2*/
    if (recordCount>=2) {   //修改了此处加大了录音部分
        recordCount = 0;
        /*停止录音*/
        [self upAction:nil];
    }
    recordCount++;
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
