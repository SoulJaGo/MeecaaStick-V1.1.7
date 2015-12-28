//
//  UseHardwareCheckViewController.m
//  HomeKinsa
//
//  Created by Zhang guangchun on 15/5/4.
//  Copyright (c) 2015年 Mikai. All rights reserved.
//

#import "UseHardwareCheckViewController.h"
/**
 *  音频所需库文件
 */
#import <AVFoundation/AVFoundation.h>
/**
 *  原有的解码文件
 */
#import "lib_decode.h"
/**
 *  原有的解码文件
 */
#import "temperature.h"
/**
 *  HUB的类扩展
 */
#import "UIViewController+ProgressHUD.h"
/**
 *  原有的网络请求类
 */
#import "TTToolsHelper.h"
/**
 *  进度条的第三方库
 */
#import "INTUAnimationEngine.h"
/**
 *  图像的类扩展
 */
#import "UIImage+ImageEffects.h"
/**
 *  添加温度记录
 */
#import "AddHealthRecordViewController.h"
/**
 *  重力加速器所需库
 */
#import <CoreMotion/CoreMotion.h>
/**
 *  控制音量所需库文件
 */
#import <MediaPlayer/MPVolumeView.h>
/**
 *  判断手机型号所用框架
 */
#import "sys/utsname.h"
/**
 *  网络框架
 */
#import "AFNetworking.h"
/**
 *  引入新的测温算法
 */
//#import "Function.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import "GlobalTool.h"
#import "AddHealthRecordNavigationController.h"
#import "GlobalData.h"
#import "TestDecoder.h"
#import "GlobalTool.h"
#import "HttpTool.h"
/**
 *  新版预测库算法
 *  2015-12-16 SoulJa
 */
#import "templib_ios_v531_151214.h"

@interface UseHardwareCheckViewController ()
{
    //录音器
    AVAudioRecorder *recorder;
    //播放器
    AVAudioPlayer *player;
    //录音参数设置
    NSDictionary *recorderSettingsDict;
    
    //定时器
    NSTimer *timer;
    //图片组
    NSMutableArray *volumImages;
    double lowPassResults;
    
    //录音名字
    NSString *playName;
    //录音计数器
    int recordCount;
    //测温类型
    int checkType;
    
    NSTimer *timer2;
    //音频播放器
    AVAudioPlayer *avAudioPlayer;
    //播放计数器
    int playCount;
    
    NSTimer *timer3; //    定时采样

    // float  timercount;
    //测温时间计数器
    int timercount;
    //温度保存记录临时字符串
    NSString *strStoreTemp;
    
    //初始化的温度值，用于给新算法记录温度
    //double temperature[20];
    double temperature[11];
    
    NSTimer *animTimer;
    
    double shakeX;
    
    int bcheck_count;
    BOOL bcheck_flag;
    float dT1;
    
}

@property (weak, nonatomic) IBOutlet UIView *messageView;
/*计时区域的Label*/
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
/*显示温度的Label*/
@property (weak, nonatomic) IBOutlet UILabel *temperatureLabel;
/*冒出气泡的View*/
@property (weak, nonatomic) IBOutlet UIView *bubbleView;
@property (retain, nonatomic) UIImageView *loadingBg;
@property (retain, nonatomic) UIImageView *lodingContent;
/*最后一次测温记录*/
@property (retain, nonatomic) NSString *lastTemperature;
/*核心运动的管理器*/
@property (strong,nonatomic) CMMotionManager *motionManager;
/*冒出气泡数组*/
@property (retain, nonatomic) NSMutableArray *bubbles;
//@property (weak, nonatomic) IBOutlet UILabel *resultLabel;
//@property (weak, nonatomic) IBOutlet UIButton *checkBtn;
/*测试使用的记录字符串*/
@property (nonatomic,copy) NSMutableString *dataString;
@property (nonatomic,assign) int quickTimeCount;
/**
 *  SoulJa 2015-11-11
 *  常规测温错误次数
 */
@property (nonatomic,assign) int normalErrorCount;
@property (nonatomic,copy) NSString *starttime;
@property (nonatomic,copy) NSString *lastTemp;
/**
 *  临时打印接受数组
 */
@property (weak, nonatomic) IBOutlet UILabel *temperatureArrayLabel;
@end

@implementation UseHardwareCheckViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    //友盟统计
    [MobClick event:@"cewen"];
    [[GlobalTool shared] setFromCheckToBackground:YES];
    
    
    self.starttime = [NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSince1970]];
    
    [[GlobalTool shared] setCheckStarttime:self.starttime];
    NSString *temperatureType = @"";
    if (checkType == 1) {
        temperatureType = @"1";
    } else if(checkType == 2 ) {
        temperatureType = @"0";
    }
    [[GlobalTool shared] setLastCheckType:temperatureType];
    
    /*设置navigationbar start*/
    [self.navigationController.navigationBar setTranslucent:NO];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageWithColor:COLOR_NAV_BACKGROUND] forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    self.navigationController.navigationBarHidden = NO;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"login_back_icon"] style:UIBarButtonItemStylePlain target:self action:@selector(goBack)];
    
//    self.quickTimeCount = 0;
    
//    float value = [UIScreen mainScreen].brightness;
//    [[UIScreen mainScreen] setBrightness:value];
    /*设置navigationbar end*/
    
    /*保持屏幕常亮*/
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    /**
     *  SoulJa 2015-11-11
     *  常规测温错误次数
     */
    self.normalErrorCount = 0;
    
    
     /*初始化快速测温temperature数组*/
//    for (int i=0; i<20; i++) {
//        temperature[i] = 0.0f;
//    }
    for (int i = 0; i < 11; i++) {
        temperature[i] = -55.0f;
    }
    
    //初始化温度显示Label的text
    self.temperatureLabel.text = @"";
    AVAudioSession *avSession = [AVAudioSession sharedInstance];
    if ([avSession respondsToSelector:@selector(requestRecordPermission:)]) {
    	[avSession requestRecordPermission:^(BOOL available) {
    		if(!available) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self stopCheck];
                    [self.navigationController popToRootViewControllerAnimated:YES];
                    [[TTToolsHelper shared] showNoticetMessage:@"请在“设置-隐私-麦克风”选项中允许体温棒访问您的麦克风" handler:^{
                        
                    }];
                });
            return;
    		}
    	}];
    }
 


    
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
                           /*设置录音格式*/
                           [NSNumber numberWithInt:kAudioFormatLinearPCM],AVFormatIDKey,                           //                                         [NSNumber numberWithInt:1000.0],AVSampleRateKey,
                           /*设置录音采样率*/
                           [NSNumber numberWithInt:44100.0],AVSampleRateKey,
                           //                                         [NSNumber numberWithInt:2],AVNumberOfChannelsKey,
                           /*通道的数目,1单声道,2立体声*/
                           [NSNumber numberWithInt:1],AVNumberOfChannelsKey,
                           //                                         [NSNumber numberWithInt:8],AVLinearPCMBitDepthKey,
                           /*每个采样点位数,分为8、16、24、32*/
                           [NSNumber numberWithInt:16],AVLinearPCMBitDepthKey,
                           [NSNumber numberWithBool:NO],AVLinearPCMIsBigEndianKey,
                           /*是否使用浮点数采样*/
                           [NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,
                           /*音频质量*/
                           [NSNumber numberWithInt: AVAudioQualityMedium],AVEncoderAudioQualityKey,
                           nil];
    
    /*播放本地音乐*/
//    NSString *string = [[NSBundle mainBundle] pathForResource:@"0410KHz" ofType:@"mp3"];
    
    //NSString *string = [[NSBundle mainBundle] pathForResource:@"once_200ms_on" ofType:@"mp3"];
    /**
     * 2015-09-24 SoulJa
     *  不停止音频播放
     */
    NSString *string = [[NSBundle mainBundle] pathForResource:@"once_100ms_on_100ms_off" ofType:@"mp3"];
    NSURL *url = [NSURL fileURLWithPath:string];
    avAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    avAudioPlayer.volume = 1;//设置音量最大
    avAudioPlayer.numberOfLoops = 1;//设置循环次数
    [avAudioPlayer prepareToPlay];//准备播放
    
    /*开始检测*/
    [self onClickCheck:nil];
    
    /**
     *  进度条界面
     */
    [self setLoading];
    [self startAnimation];
    
    if (checkType==1) { //如果为快速测温隐藏时间Label
        self.timeLabel.hidden = YES;
        self.messageView.hidden = NO;
    }
    else{ //如果为常规测温显示时间Label
        self.timeLabel.text = @"03:00";
        self.timeLabel.hidden = NO;
        self.messageView.hidden = YES;
    }
    
    self.motionManager = [[CMMotionManager alloc] init];//一般在viewDidLoad中进行
    self.motionManager.accelerometerUpdateInterval = .1;//加速仪更新频率，以秒为单位
    
    bcheck_count = 0;
    bcheck_flag = false;
    
    if ([[self deviceString] isEqualToString:@"iPhone 4S"]) { //如果是4S并且系统版本小于8.0调整音量为85%
        if ([[UIDevice currentDevice].systemVersion floatValue] < 8.0) {
            [self setPhoneVolume:0.85f];
        } else {
            [self setPhoneVolume:1.0f];
        }
    } else if ([GlobalTool isIPad])
    { //如果为iPad则将音量调整为85%
        [self setPhoneVolume:1.0f];
    } else {
        [self setPhoneVolume:1.0f];
    }
    
    /*测试Label开始*/
    if (checkType == 1) {
        [self.temperatureArrayLabel setHidden:YES];
        self.temperatureArrayLabel.numberOfLines = 0;
        [self.temperatureArrayLabel setTextColor:[UIColor blackColor]];
    } else {
        [self.temperatureArrayLabel setHidden:YES];
    }
    
    /*测试Label结束*/
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    /*加速计开始启动*/
    [self startAccelerometer];
    
    /**
     *  2015-09-23 SoulJa
     *  监听调节音量
     */
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(volumeChanged:) name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];
    
    /*监听拔出耳机*/
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(routeChange:) name:AVAudioSessionRouteChangeNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    //停止加速仪更新（很重要！）
    [self.motionManager stopAccelerometerUpdates];
    [self stopAnim];
    [self stopCheck];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionRouteChangeNotification object:nil];
}

/**
 *  获取设备型号
 */
- ( NSString *)deviceString
{
    // 需要#import "sys/utsname.h"
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceString = [ NSString stringWithCString:systemInfo.machine encoding: NSUTF8StringEncoding ];
    
    if ([deviceString isEqualToString:@ "iPhone1,1" ])     return @ "iPhone 1G" ;
    if ([deviceString isEqualToString:@ "iPhone1,2" ])     return @ "iPhone 3G" ;
    if ([deviceString isEqualToString:@ "iPhone2,1" ])     return @ "iPhone 3GS" ;
    if ([deviceString isEqualToString:@ "iPhone3,1" ])     return @ "iPhone 4" ;
    if ([deviceString isEqualToString:@ "iPhone4,1" ])     return @ "iPhone 4S" ;
    if ([deviceString isEqualToString:@ "iPhone5,2" ])     return @ "iPhone 5" ;
    if ([deviceString isEqualToString:@ "iPhone3,2" ])     return @ "Verizon iPhone 4" ;
    if ([deviceString isEqualToString:@ "iPod1,1" ])       return @ "iPod Touch 1G" ;
    if ([deviceString isEqualToString:@ "iPod2,1" ])       return @ "iPod Touch 2G" ;
    if ([deviceString isEqualToString:@ "iPod3,1" ])       return @ "iPod Touch 3G" ;
    if ([deviceString isEqualToString:@ "iPod4,1" ])       return @ "iPod Touch 4G" ;
    if ([deviceString isEqualToString:@ "iPad1,1" ])       return @ "iPad" ;
    if ([deviceString isEqualToString:@ "iPad2,1" ])       return @ "iPad 2 (WiFi)" ;
    if ([deviceString isEqualToString:@ "iPad2,2" ])       return @ "iPad 2 (GSM)" ;
    if ([deviceString isEqualToString:@ "iPad2,3" ])       return @ "iPad 2 (CDMA)" ;
    if ([deviceString isEqualToString:@ "i386" ])         return @ "Simulator" ;
    if ([deviceString isEqualToString:@ "x86_64" ])       return @ "Simulator" ;
    NSLog (@ "NOTE: Unknown device type: %@" , deviceString);
    return deviceString;
}

/**
 *  设置音量
 */
- (void)setPhoneVolume:(float)volume
{
    MPVolumeView *volumeView = [[MPVolumeView alloc] init];
    UISlider *volumeViewSlider = nil;
    for (UIView *view in [volumeView subviews]){
        if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
            volumeViewSlider = (UISlider*)view;
            break;
        }
    }
    
    // retrieve system volume
    float systemVolume = volumeViewSlider.value;
    
    // change system volume, the value is between 0.0f and 1.0f
    [volumeViewSlider setValue:volume animated:NO];
    
    // send UI control event to make the change effect right now.
    [volumeViewSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
}



- (void)setCheckType:(int)_type
{
    checkType = _type;
}

/**
 *  启动中立加速计
 */
-(void)startAccelerometer
{
    //以push的方式更新并在block中接收加速度
    [self.motionManager startAccelerometerUpdatesToQueue:[[NSOperationQueue alloc]init]
                                             withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
                                                 [self outputAccelertionData:accelerometerData.acceleration];
                                                 if (error) {
                                                     TTLog(@"motion error:%@",error);
                                                 }
                                             }];
}

-(void)outputAccelertionData:(CMAcceleration)acceleration
{
//    NSLog(@"%f %f %f",acceleration.x,acceleration.y,acceleration.z);
    shakeX = acceleration.x;
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    /*设置进度条的Frame*/
    float barWidth = self.view.frame.size.width*0.8;
    float barHeight = 25;
    float barX = (self.view.frame.size.width - barWidth)/2;
    float barY = 10;
    
    if (checkType==1) {
        /**
         *  loading初始化
         */
        self.loadingBg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"load_bg"]];
        [self.loadingBg setFrame:CGRectMake(barX, barY, barWidth, barHeight)];
        [self.view addSubview:self.loadingBg];
        
        self.lodingContent = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"load_content"]];
        [self.lodingContent setFrame:CGRectMake(barX, barY, 0, barHeight)];
        bcheck_flag = YES;
        [self.view addSubview:self.lodingContent];
    }
}

/**
 *  开始启动
 */
- (void)startAnimation
{
    self.bubbles = [NSMutableArray array];
    animTimer = [NSTimer scheduledTimerWithTimeInterval:0.03 target:self selector:@selector(createBubble:) userInfo:nil repeats:YES];
}

/**
 *  气泡上升所需要的时间
 */
- (float)getUpTimer
{
    int random = arc4random() % 5;
    if (random==0) {
        return 0.5;
    }
    else if (random==1){
        return 0.7;
    }
    else if (random==2){
        return 0.9;
    }
    else if (random==3){
        return 1.2;
    }
    else if (random==4){
        return 1.3;
    }
    else if (random==5){
        return 2;
    }
    else if (random==6){
        return 2.1;
    }
    else if (random==7){
        return 2.3;
    }
    else if (random==8){
        return 2.5;
    }
    else if (random==9){
        return 2.8;
    }
    return 3;
}

- (float)getBubbleAlpha
{
    float random = (float)(arc4random() % 10)/10.0;
    float value = random + 0.3;
    if (value>=1.0) {
        value = 1.0;
    }
    return value;
}

- (float)getBubbleScale
{
    float random = (float)(arc4random() % 10)/10.0;
    float value = random + 0.5;
    if (value>=1.0) {
        value = 1.0;
    }
    return value;
}

/**
 *  处理气泡
 */
- (void)handleBubble
{
    for (int i=0; i<self.bubbles.count; i++) {
        NSDictionary *bubbleObj = [self.bubbles objectAtIndex:i];
        UIImageView *bubblePng = (UIImageView *)[bubbleObj objectForKey:@"png"];
        float speed = [[bubbleObj objectForKey:@"speed"] floatValue];
        CGRect bubbleFrame = bubblePng.frame;
        [bubblePng setFrame:CGRectMake(bubbleFrame.origin.x-shakeX*5, bubbleFrame.origin.y-speed, bubbleFrame.size.width, bubbleFrame.size.height)];
    }
    for (int i=self.bubbles.count-1; i>=0; i--) {
        NSDictionary *bubbleObj = [self.bubbles objectAtIndex:i];
        UIImageView *bubblePng = (UIImageView *)[bubbleObj objectForKey:@"png"];
        CGRect bubbleFrame = bubblePng.frame;
        if (bubbleFrame.origin.y<=-bubblePng.frame.size.height) { //当气泡超出屏幕的时候
            [bubblePng removeFromSuperview];
            [self.bubbles removeObjectAtIndex:i];
        }
    }
}

/**
 *  创建气泡
 */
- (void)createBubble:(NSTimer*)timer_
{
    /*处理气泡*/
    [self handleBubble];
    
    int createRandom = arc4random()%10;
    if (createRandom==0&&self.bubbles.count<=20) { //随机数等于0并且气泡数量小于20
        UIImage *image = [UIImage imageNamed:@"hardware_bubble"];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        
        int viewWidth = self.view.frame.size.width;
        int viewHeight = self.view.frame.size.height;
        
        int posX = arc4random()%viewWidth;
        
        float scale = [self getBubbleScale];
        //    CGRect startRect = CGRectMake(posX, viewHeight-180, image.size.width*scale, image.size.height*scale);
        //    CGRect endRect = CGRectMake(posX, -40, image.size.width*scale, image.size.height*scale);
        [imageView setFrame:CGRectMake(posX, viewHeight, image.size.width*scale, image.size.height*scale)];
        imageView.alpha = [self getBubbleAlpha];
        
        [self.bubbleView addSubview:imageView];
        
        NSDictionary *bubbleObj = @{@"png":imageView,@"speed":[NSNumber numberWithDouble:[self getUpTimer]*4.5]};
        [self.bubbles addObject:bubbleObj];
    }
}

/**
 *  启动进度条
 */
- (void)setLoading {
    if (checkType==2||!bcheck_flag) {
        return;
    }
    CGRect startRect = self.lodingContent.frame;//开始时候的尺寸
    CGRect endRect = CGRectMake(self.loadingBg.frame.origin.x,
                                self.loadingBg.frame.origin.y,
                                self.loadingBg.frame.size.width*timercount/41,
                                self.loadingBg.frame.size.height);//结束时候的尺寸
    [INTUAnimationEngine animateWithDuration:1 delay:0 animations:^(CGFloat percentage) {
        [self.lodingContent setFrame:INTUInterpolateCGRect(startRect, endRect, percentage)];
    } completion:^(BOOL finished) {
        
    }];
}

#pragma mark - 2015-10-12 新加代码
/**
 *  SoulJa 2015-10-12
 *  显示状态栏
 */
- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

/**
 *  停止检测
 */
- (void)stopCheck {
    /*消除所有定时器*/
    if (timer) {
        [timer invalidate];
        timer = nil;
    }
    
    if (timer2) {
        [timer2 invalidate];
        timer2 = nil;
    }
    
    if (timer3) {
        [timer3 invalidate];
        timer3 = nil;
    }
    
    if ([avAudioPlayer isPlaying]) {
        [avAudioPlayer stop];
    }
}

/**
 *  停止位移
 */
- (void)stopAnim{
    if (animTimer) {
        [animTimer invalidate];
        animTimer = nil;
    }
}

/**
 *  点击返回
 */
- (IBAction)onClickBack:(id)sender {
//    [self dismissProgressHUD];
    [self stopAnim];
    [self stopCheck];
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/**
 *  删除录音文件
 */
- (void)deleteTempFiles{
    NSString *extension = @"raw";
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:documentsDirectory error:NULL];//获取到documents下所有文件及文件夹的数组
    NSEnumerator *e = [contents objectEnumerator];
    NSString *filename;
    while ((filename = [e nextObject])) {
        if ([[filename pathExtension] isEqualToString:extension]) { //判断后缀是否为raw
            [fileManager removeItemAtPath:[documentsDirectory stringByAppendingPathComponent:filename] error:NULL];//删除后缀为raw的文件
        }
    }
}

/**
 *  获取录音数据
 */
- (IBAction)onClickCut:(id)sender {
    /*获取录音文件*/
    //NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    /*将录音文件转换为byte*/
//    NSData *myData = [[NSData alloc] initWithContentsOfFile:playName];
//    
//    Byte *bytes = (Byte *)[myData bytes];
//    Byte* _bytes = malloc(2 * sizeof(Byte));
//    
//    BOOL flag = false;
//    int idx = 0;
//    
//    Byte *result = malloc(7*1024*sizeof(Byte));
//    
//    
//    for (int i=200; i<myData.length; i+=2) {
//        _bytes[0] = bytes[i];
//        _bytes[1] = bytes[i+1];
//        NSData* data = [NSData dataWithBytes:_bytes length:2];
//        short number = 0;
//        [data getBytes:&number];
//        
//        if (flag) {
//            idx+=2;
//            if (abs(number)>2000||idx>50) {
//                if (idx>=7*1024) {
//                    break;
//                }
//                result[idx] = bytes[i];
//                result[idx+1] = bytes[i+1];
//            }
//            else {
//                flag = false;
//                idx = 0;
//            }
//        }
//        else {
//            if (abs(number)>2000) {
//                flag = true;
//                idx = 0;
//                result[idx] = bytes[i];
//                result[idx+1] = bytes[i+1];
//            }
//        }
//    }
//    free(_bytes);
//    
//    /*将解析出来的result转存到test.raw中*/
//    [[NSFileManager defaultManager] createFileAtPath:[NSString stringWithFormat:@"%@/test.raw", docDir] contents:[NSData dataWithBytes:result length:7*1024] attributes:nil];
//    
    [self onClickRead:nil];
    
}

//0520-mean120_13_931.C
/**
 *  读取数据
 */
- (void)onClickRead:(id)sender {
//    /*读取上一步函数中转存的音频文件*/
//    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
//    NSString *binaryFile = [NSString stringWithFormat:@"%@/test.raw", docDir];
//    
//    NSData *myData = [[NSData alloc] initWithContentsOfFile:binaryFile];
//    
//    Byte *bytes = (Byte *)[myData bytes];
//    Byte* _bytes = malloc(2 * sizeof(Byte));
//    
//    BOOL flag = false;
//    int idx = 0;
//    
//    short *result = malloc((5*1024)*sizeof(short));
//    
//    for (int i=0; i<myData.length; i+=2) {
//        _bytes[0] = bytes[i];
//        _bytes[1] = bytes[i+1];
//        NSData* data = [NSData dataWithBytes:_bytes length:2];
//        short number = 0;
//        [data getBytes:&number];
//        
//        if (flag) {
//            idx++;
//            if (idx>=5*1024) {
//                break;
//            }
//            result[idx] = number;
//        }
//        else {
//            if (abs(number)>2000) {
//                flag = true;
//                idx = 0;
//                result[idx] = number;
//            }
//        }
//    }
//    free(_bytes);
//    int bytelen;
//    unsigned char pdestdata[10];
//    
//    memset(pdestdata,0,10);
//    mk_AudioFormat(44100.0, 2000, 1, 0, 0, 0, 0);
//    printf("result %i",mk_Data1(result, 2*1024+512, pdestdata, &bytelen));
//    char ctemp[40];
//    for(int n = 0; n < 40;n++)
//    {
//        ctemp[n] = 0;
//    }
//    byteToHexStr2(pdestdata, 5,ctemp);
//    int itemp = (pdestdata[1]<< 8)+ pdestdata[0];
//    float ftemp = (float)(itemp /100.00f);
//    
//    //判断是4S手机并且是小于8.0的系统
//    if ([[self deviceString] isEqualToString:@"iPhone 4S"] && [[UIDevice currentDevice].systemVersion floatValue] < 8.0 ) {
//        if (ftemp < 1.0 && timercount == 0) {
//            [self setPhoneVolume:1.0f];
//            temperature[0] = 32.5;
//            return;
//        }
//    }
//    
//    
//    
//    if(((pdestdata[0] + pdestdata[1]) & 0xFF)==pdestdata[2])
//    {
//        if (checkType ==2) {
//            GlobalData *gd = [GlobalData sharedData];
//            int type = (gd.temperatureType!=nil&&[gd.temperatureType intValue]==2)?2:1;
//            /*
//            if (!ftemp) { //当没有接受到转换的温度或者温度为0时
//                [self stopCheck];
//                [[TTToolsHelper shared] showNoticetMessage:@"请连接手机！" handler:^{
//                    [self stopAnim];
//                    [self dismissViewControllerAnimated:YES completion:nil];
//                }];
//                return;
//            }
//             */
//            
//            if (itemp==0) { //当没有接受到转换的温度或者温度为0时
//                [self stopCheck];
//                [self stopAnim];
//                [[TTToolsHelper shared] showNoticetMessage:@"请重新测温!" handler:^{
//                    [self dismissViewControllerAnimated:YES completion:nil];
//                }];
//                return;
//            } else if (itemp>5000) { //当测量温度大于50时
//                if (bcheck_count>=10) {
//                    NSString *errMsg = @"";
//                    if (itemp == 7777) {
//                        errMsg = @"请重新测温!";
//                    } else if(itemp == 9999) {
//                        errMsg = @"超出测温范围!";
//                    } else{
//                        errMsg = @"超出测温范围!";
//                    }
//                    [self stopCheck];
//                    [self stopAnim];
//                    [[TTToolsHelper shared] showNoticetMessage:errMsg handler:^{
//                        [self dismissViewControllerAnimated:YES completion:nil];
//                    }];
//                    return;
//                }
//                bcheck_count++;
//            } else if (itemp == -9999) {
//                [self stopCheck];
//                [self stopAnim];
//                [[TTToolsHelper shared] showNoticetMessage:@"超出测温范围!"handler:^{
//                    [self dismissViewControllerAnimated:YES completion:nil];
//                }];
//                return;
//            } else{
//                self.lastTemperature = [NSString stringWithFormat:@"%.1f℃",ftemp];
//                if (type==1) {
//                    self.temperatureLabel.text = [NSString stringWithFormat:@"%.1f℃", ftemp];
//                }
//                else{
//                    float value1 = ftemp*1.8+32;
//                    self.temperatureLabel.text = [NSString stringWithFormat:@"%.1f℉",value1];
//                }
//            }
//            return;
//        }
//        temperature[timercount] = ftemp;
//        
//        [self setLoading];
//        
//        /**
//         *  新版程序的执行方案
//         */
//        double resultTemp = judge(temperature);
//        NSLog(@"timercount:%d-resultTemp:%f",timercount,resultTemp);
//        
//        if ((int)resultTemp == 0) {
//            [self stopAnim];
//            [self stopCheck];
//            [[TTToolsHelper shared] showNoticetMessage:@"请重新测温！" handler:^{
//                [self.navigationController popToRootViewControllerAnimated:YES];
//            }];
//            return;
//        }
//        
//        //返回结果如果为-1表示继续传入温度值
//        if (resultTemp == -1) {
//            /*广淳哥原来的测温异常处理方案
//            //            1、t1>0
//            //            2、t1<=t2<=t3
//            //            3、(t2-t1)≥(t3-t2)
//            
//            if (checkType==1) {
//                if (timercount==2) {
//                    float t1 = temperature[0];
//                    float t2 = temperature[1];
//                    float t3 = temperature[2];
//                    dT1 = t2 - t1;
//                    float dT2 = t3 - t2;
//                    
//                    if (t1>0
//                        &&t1<t2
//                        &&t2<t3
//                        &&dT1>=dT2) {
//                        bcheck_flag = true;
//                    }
//                    else {
//                        if (bcheck_count>=10) {
//                            NSString *errorMsg = @"";
//                            if (t1==0&&t2==0&&t3==0) {
//                                errorMsg = @"请将耳机音量调到最大";
//                            }
//                            else{
//                                errorMsg = @"请确认体温棒位置，或使用'常规测温'";
//                            }
//                            [self stopCheck];
//                            [[TTToolsHelper shared] showNoticetMessage:errorMsg handler:^{
//                                [self stopAnim];
//                                [self dismissViewControllerAnimated:YES completion:nil];
//                            }];
//                            return;
//                        }
//                        
//                        temperature[0] = t2;
//                        temperature[1] = t3;
//                        timercount = 1;
//                        
//                        bcheck_count++;
//                    }
//                }
//                else if (timercount>2){
//                    float tn = temperature[timercount];
//                    float tn_1 = temperature[timercount-1];
//                    float tn_2 = temperature[timercount-2];
//                    float dt1 = tn_1 - tn_2;
//                    float dt2 = tn - tn_1;
//                    if ((dt1<dt2-0.08)||(tn<tn_1-0.05)) {
//                        NSLog(@"timerCount:%i tn:%f tn_1:%f tn_2:%f",timercount,temperature[timercount],temperature[timercount-1],temperature[timercount-2]);
//                        [self stopCheck];
//                        [[TTToolsHelper shared] showNoticetMessage:@"请确认体温棒位置，或使用'常规测温'" handler:^{
//                            [self stopAnim];
//                            [self dismissViewControllerAnimated:YES completion:nil];
//                        }];
//                        return;
//                    }
//                }
//            }
//            */
//            if (checkType == 1) {//判断为快速测温模式
//                if (itemp == 0) { //没有解析到数据
//                    [self stopAnim];
//                    [self stopCheck];
//                    [[TTToolsHelper shared] showNoticetMessage:@"请重新测温!" handler:^{
//                        [self.navigationController popToRootViewControllerAnimated:YES];
//                    }];
//                    return;
//                } else if (itemp == -9999) {
//                    [self stopAnim];
//                    [self stopCheck];
//                    [[TTToolsHelper shared] showNoticetMessage:@"超出测温范围!" handler:^{
//                        [self.navigationController popToRootViewControllerAnimated:YES];
//                    }];
//                    return;
//                } else if (itemp > 5000) {
//                    NSString *errMsg = @"";
//                    if (itemp==7777) {
//                        errMsg = @"请重新测温!";
//                    } else if (itemp == 9999) {
//                        errMsg = @"超出测温范围!";
//                    }
//                    else{
//                        errMsg = @"超出测温范围!";
//                    }
//                    [self stopAnim];
//                    [self stopCheck];
//                    [[TTToolsHelper shared] showNoticetMessage:errMsg handler:^{
//                        [self.navigationController popToRootViewControllerAnimated:YES];
//                    }];
//                    return;
//                }
//                
//            }
//            return;
//        }
//        
//        //返回结果-2或者timercount大于20表示溢出
//        if (resultTemp == -2 || timercount > 20) {
//            [self stopCheck];
//            [self stopAnim];
//            [[TTToolsHelper shared] showNoticetMessage:@"体温棒放好了吗？" handler:^{
//                [self.navigationController popToRootViewControllerAnimated:YES];
//                return;
//            }];
//            return;
//        }
//        
//        //返回结果大于0时表示监测出来温度
//        if (resultTemp > 0 && checkType ==1 ) {
//            [timer3 invalidate];//消除定时器timer3
//            timer3 = nil;
//            timercount = 0;
//            bcheck_flag = NO;
//            double finalTemperature = resultTemp;
//
//            NSString *temperatureStr = [NSString stringWithFormat:@"%.1lf", finalTemperature];
//            GlobalData *gd = [GlobalData sharedData];
//            gd.lastTimeCheckTemperature = temperatureStr;
//                
//                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
//            AddHealthRecordViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"AddHealthRecordViewController"];
//            vc.PresentFromCheck = YES;
//            AddHealthRecordNavigationController *nav = [[AddHealthRecordNavigationController alloc] initWithRootViewController:vc];
//            [nav.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
//            [self presentViewController:nav animated:YES completion:nil];
//            [self dismissProgressHUD];
//            return;
//        }
//    } else {
//        NSString *str=[NSString stringWithCString :ctemp encoding:NSUTF8StringEncoding];
//        NSLog(@" bbb%@",[NSString stringWithFormat:@"错误：%@", str]);
//        [self stopCheck];
//        [self stopAnim];
//        [[TTToolsHelper shared] showNoticetMessage:@"请重新测温！" handler:^{
//            [self.navigationController popToRootViewControllerAnimated:YES];
//        }];
//        return;
//    }
//    NSLog(@"finishing...");
    NSMutableDictionary *resultDict = [[TestDecoder sharedTestDecoder] TestDecoderWithPath:playName];
    
    int resultINT = [[resultDict objectForKey:@"returnINT"] intValue];
    int itemp = [[resultDict objectForKey:@"temperature"] intValue];
    float ftemp = (float)(itemp /100.00f);
    self.lastTemp = [NSString stringWithFormat:@"%f",ftemp];
    [[GlobalTool shared] setLastCheckTemp:self.lastTemp];
    NSLog(@"返回值:%d--返回温度:%d",resultINT,itemp);
    
    NSString *temperatureType = @"";
    if (checkType == 1) {
        temperatureType = @"1";
    } else if(checkType == 2 ) {
        temperatureType = @"0";
    }
    if (resultINT == 0) {
        /**
         *  SoulJa 2015-11-11
         *  常规测温错误次数
         */
        if (self.normalErrorCount > 0) {
            self.normalErrorCount = 0;
        }
        
                
        if (itemp == 9999 || itemp == - 9999) {
            [self stopCheck];
            [self stopAnim];
            [HttpTool checkCountWithStartTime:self.starttime Temperature:[NSString stringWithFormat:@"%f",ftemp] TemperatureType:temperatureType OperateType:@"4"];
            [[TTToolsHelper shared] showNoticetMessage:@"超出测温范围!" handler:^{
                [self.navigationController popToRootViewControllerAnimated:YES];
            }];
            return;
        } else if (itemp == 7777) {
            [self stopCheck];
            [self stopAnim];
            [HttpTool checkCountWithStartTime:self.starttime Temperature:[NSString stringWithFormat:@"%f",ftemp] TemperatureType:temperatureType OperateType:@"4"];
            [[TTToolsHelper shared] showNoticetMessage:@"请联系客服!" handler:^{
                [self.navigationController popToRootViewControllerAnimated:YES];
            }];
            return;
        }
        
        if (checkType ==2) {
            GlobalData *gd = [GlobalData sharedData];
            int type = (gd.temperatureType!=nil&&[gd.temperatureType intValue]==2)?2:1;
            self.lastTemperature = [NSString stringWithFormat:@"%.1f℃",ftemp];
            if (type==1) {
                self.temperatureLabel.text = [NSString stringWithFormat:@"%.1f℃", ftemp];
            }
            else {
                float value1 = ftemp*1.8+32;
                self.temperatureLabel.text = [NSString stringWithFormat:@"%.1f℉",value1];
            }
            
        } else { //快速测温
            //temperature[self.quickTimeCount] = ftemp;
            for (int i = 0; i<10; i++) {
                temperature[i] = temperature[i+1];
            }
            temperature[10] = ftemp;
//            self.quickTimeCount++;
            /*测试Label开始*/
            NSString *temperatureStr = [NSString string];
            temperatureStr = [temperatureStr stringByAppendingString:[NSString stringWithFormat:@"总次数:%d\r\n",timercount]];
            for (int i=0; i<11; i++) {
                temperatureStr = [temperatureStr stringByAppendingString:[NSString stringWithFormat:@"%d=%.2f\r\n",i,temperature[i]]];
            }
            self.temperatureArrayLabel.numberOfLines = 0;
            self.temperatureArrayLabel.text = temperatureStr;
            /*测试Label结束*/
            [self setLoading];
            if (timercount > 40/*self.quickTimeCount > 20*/) {
                [[TTToolsHelper shared] showNoticetMessage:@"体温棒放好了吗？请重新测温!" handler:^{
                    [self.navigationController popToRootViewControllerAnimated:YES];
                }];
                [HttpTool checkCountWithStartTime:self.starttime Temperature:[NSString stringWithFormat:@"%f",ftemp] TemperatureType:temperatureType OperateType:@"4"];
                [self stopCheck];
                [self stopAnim];
                return;    
            }
            
            /**
             *  新版程序的执行方案
             */
            NSLog(@"Before-----");
            double resultTemp = judge(temperature);
            NSLog(@"After-----");
            NSLog(@"TimeCount:%d-resultTemp:%f",timercount,resultTemp);
            if (resultTemp == -66/*resultTemp == -1*/) { //返回结果如果为-1表示继续传入温度值
                return;
            } /*else if (resultTemp == -2 ) { //返回结果-2或者timercount大于20表示溢出
                [self stopCheck];
                [self stopAnim];
                [HttpTool checkCountWithStartTime:self.starttime Temperature:[NSString stringWithFormat:@"%f",ftemp] TemperatureType:temperatureType OperateType:@"4"];
                [[TTToolsHelper shared] showNoticetMessage:@"体温棒放好了吗？请重新测温!" handler:^{
                    [self.navigationController popToRootViewControllerAnimated:YES];
                }];
                return;
            }*/
            else  { //返回结果不等于-66时
                [self stopAnim];
                [self stopCheck];
                timercount = 0;
                bcheck_flag = NO;
                double finalTemperature = resultTemp;
                
                NSString *temperatureStr = [NSString stringWithFormat:@"%.1lf", finalTemperature];
                GlobalData *gd = [GlobalData sharedData];
                gd.lastTimeCheckTemperature = temperatureStr;
                
                /*2015-12-22 测试开始*/
                NSString *docDirPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                [formatter setDateFormat:@"YYYY-MM-dd-HH:mm:ss"];
                NSString *nowTimeStr = [formatter stringFromDate:[NSDate date]];
                NSString *txtPath = [docDirPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_%@.txt",nowTimeStr,temperatureStr]];
                NSString *txtStr = [NSString string];
                for (int i=0; i<11; i++) {
                    txtStr = [txtStr stringByAppendingString:[NSString stringWithFormat:@"%.2f\r\n",temperature[i]]];
                }
                [txtStr writeToFile:txtPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
                /*2015-12-22 测试结束*/
                
                [HttpTool checkCountWithStartTime:self.starttime Temperature:[NSString stringWithFormat:@"%f",ftemp] TemperatureType:temperatureType OperateType:@"0"];
                
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                AddHealthRecordViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"AddHealthRecordViewController"];
                vc.PresentFromCheck = YES;
                AddHealthRecordNavigationController *nav = [[AddHealthRecordNavigationController alloc] initWithRootViewController:vc];
                [nav.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
                
                [self presentViewController:nav animated:YES completion:^{
                    
                }];
                return;
                
            } /*else {
                [self stopCheck];
                [self stopAnim];
                [HttpTool checkCountWithStartTime:self.starttime Temperature:[NSString stringWithFormat:@"%f",ftemp] TemperatureType:temperatureType OperateType:@"4"];
                [[TTToolsHelper shared] showNoticetMessage:@"体温棒放好了吗？请重新测温!" handler:^{
                    [self.navigationController popToRootViewControllerAnimated:YES];
                }];
                return;
            }*/
        }
    } else {
        /**
         *  SoulJa 2015-11-11
         *  修改报错机制
         */
        if (checkType == 1) { /*快速测温开始*/
            if (timercount < 3) {
                for (int i = 0; i<10; i++) {
                    temperature[i] = temperature[i+1];
                }
                temperature[10] = ftemp;
                return;
            } else {
                [self stopCheck];
                [self stopAnim];
                [HttpTool checkCountWithStartTime:self.starttime Temperature:[NSString stringWithFormat:@"%f",ftemp] TemperatureType:temperatureType OperateType:@"4"];
                [[TTToolsHelper shared] showNoticetMessage:@"请重新连接耳机孔，再次测温。" handler:^{
                    [self.navigationController popToRootViewControllerAnimated:YES];
                }];
                return;
            }
        } /*快速测温结束*/
        else { /*常规测温开始*/
            self.normalErrorCount++;
            if (self.normalErrorCount > 3) {
                [self stopCheck];
                [self stopAnim];
                [HttpTool checkCountWithStartTime:self.starttime Temperature:[NSString stringWithFormat:@"%f",ftemp] TemperatureType:temperatureType OperateType:@"4"];
                [[TTToolsHelper shared] showNoticetMessage:@"请重新连接耳机孔，再次测温。" handler:^{
                    [self.navigationController popToRootViewControllerAnimated:YES];
                }];
                return;
            }
        } /*常规测温结束*/
    }
}

/**
 *  开始检测
 */
- (IBAction)onClickCheck:(id)sender {
    /*删除原有的raw文件*/
    [self deleteTempFiles];
    NSTimeInterval time = [[NSDate date] timeIntervalSince1970];
    long long int date = (long long int)time;
    timercount = 0;
    strStoreTemp=@"";
    
    /*每隔一秒执行一次*/
    timer3 = [NSTimer scheduledTimerWithTimeInterval: 1
                                              target: self
                                            selector: @selector(handleTimer:)
                                            userInfo: nil
                                             repeats: YES];
    
    
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    playName = [NSString stringWithFormat:@"%@/play_%lli.raw", docDir,date];//创建录音文件
    [self play];
}

- (NSString *)getTimeStr:(int)value
{
    if (value<10) {
        return [NSString stringWithFormat:@"0%i",value];
    }
    return [NSString stringWithFormat:@"%i",value];
}

/**
 *  处理定时器Timer3
 */
- (void) handleTimer: (NSTimer *) timer3
{
    timercount++;//时间计数自增
    
    /*开始播放*/
    [self play];

    if (checkType==2) { //常规测温 计数180秒
        int leftSec = 180 -timercount;
        int min = leftSec%60;
        int sec = leftSec/60;
        self.timeLabel.text = [NSString stringWithFormat:@"%@:%@",[self getTimeStr:sec], [self getTimeStr:min]];
    }
    
    if(timercount >= 180)
    { //时间如果超过180秒
        [self stopAnim];
        [self stopCheck];
        
        timercount = 0;//重置计时器为0
        
        if (checkType==2) { //常规测温
            NSString *temperatureType = @"";
            if (checkType == 1) {
                temperatureType = @"1";
            } else if(checkType == 2 ) {
                temperatureType = @"0";
            }
            NSString *temperatureStr = [NSString stringWithFormat:@"%.1lf", [self.lastTemperature floatValue]];
            GlobalData *gd = [GlobalData sharedData];
            gd.lastTimeCheckTemperature = temperatureStr;//保存测温记录到全局变量
            [HttpTool checkCountWithStartTime:self.starttime Temperature:temperatureStr TemperatureType:temperatureType OperateType:@"0"];
            /*跳转到添加测温页面*/
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            AddHealthRecordViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"AddHealthRecordViewController"];
            vc.PresentFromCheck = YES;
            AddHealthRecordNavigationController *nav = [[AddHealthRecordNavigationController alloc] initWithRootViewController:vc];
            [nav.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
            [self presentViewController:nav animated:YES completion:nil];
            return;
        }
    }

}

/**
 *  开始播放
 */
- (void)play{
    /*播放计数*/
    playCount = 0;
    
    /*每0.1秒执行一次*/
    timer2 = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(playTimer:) userInfo:nil repeats:YES];
    
    /*播放音乐*/
    [avAudioPlayer play];
}

-(void)playTimer:(NSTimer*)timer_{
    /*播放计数*/
    playCount++;
    /*计数两次之后停止播放音乐开始录音*/
    if (playCount>=2) {   //这个是播放时间的 先不要改动
        playCount = 0;
        /**
         * 2015-09-24 SoulJa
         *  不停止音频播放
         */
        //[avAudioPlayer stop];
        [timer2 invalidate];//移除定时器timer2
        timer2 = nil;
        [self downAction:nil];
    }
}

- (IBAction)onclickstop:(id)sender {
    [timer3 invalidate];
    timer3 = nil;
    timercount = 0;
    NSTimeInterval time = [[NSDate date] timeIntervalSince1970];
    NSDateFormatter *nsdf2=[[NSDateFormatter alloc] init];
    [nsdf2 setDateStyle:NSDateFormatterShortStyle];
    [nsdf2 setDateFormat:@"YYYY-MM-dd_HH:mm"];
    NSString *strdate=[nsdf2 stringFromDate:[NSDate date]];
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    NSString *path =[NSString stringWithFormat:@"%@/temp_%@.txt", docDir,strdate];
    
    // NSString *path = [NSDocumentDirectory stringByAppendingPathComponent:@"fileName"];
    //  [[NSFileManager defaultManager] createFileAtPath:[NSString stringWithFormat:@"%@/temp.txt", docDir] contents:nil attributes:nil];
    //   NSString *temp = @"Hello world";
    
    int a=1;
    
    //创建数据缓冲
    
    NSMutableData *writer = [[NSMutableData alloc] init];
    
    //将字符串添加到缓冲中
    
    [writer appendData:[strStoreTemp dataUsingEncoding:NSUTF8StringEncoding]];
    
    //将其他数据添加到缓冲中
    
    [writer appendBytes:&a length:sizeof(a)];
    
    //将缓冲的数据写入到文件中
    
    [writer writeToFile:path atomically:YES];
    strStoreTemp=@"";
}


/**
 *  按下录音按键
 */
- (IBAction)downAction:(id)sender {
    //按下录音
    if ([self canRecord]) {
        
        NSError *error = nil;
        //必须真机上测试,模拟器上可能会崩溃
        recorder = [[AVAudioRecorder alloc] initWithURL:[NSURL URLWithString:playName] settings:recorderSettingsDict error:&error];
        
        if (recorder) {
            /*录音计数器*/
            recordCount = 0;
            /*是否启用音频测量*/
            recorder.meteringEnabled = YES;
            
            /*准备录音*/
            [recorder prepareToRecord];
            /*开始录音*/
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
    [timer invalidate];
    timer = nil;
    
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

/**
 *  处理录音时间
 */
-(void)levelTimer:(NSTimer*)timer_
{
    //call to refresh meter values刷新平均和峰值功率,此计数是以对数刻度计量的,-160表示完全安静，0表示最大输入值
    [recorder updateMeters];
    const double ALPHA = 0.05;
    double peakPowerForChannel = pow(10, (0.05 * [recorder peakPowerForChannel:0]));
    lowPassResults = ALPHA * peakPowerForChannel + (1.0 - ALPHA) * lowPassResults;
    
    //    NSLog(@"Average input: %f Peak input: %f Low pass results: %f", [recorder averagePowerForChannel:0], [recorder peakPowerForChannel:0], lowPassResults);
    /*录音计数大于2时*/
    if (recordCount>=2) {   //修改了此处加大了录音部分
        recordCount = 0;
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

/**
 *  判断耳机是否被拔出
 */
-(void)routeChange:(NSNotification *)notification{
    NSString *temperatureType = @"";
    if (checkType == 1) {
        temperatureType = @"1";
    } else if(checkType == 2 ) {
        temperatureType = @"0";
    }
    
    NSDictionary *dic=notification.userInfo;
    int changeReason= [dic[AVAudioSessionRouteChangeReasonKey] intValue];
    //等于AVAudioSessionRouteChangeReasonOldDeviceUnavailable表示旧输出不可用
    if (changeReason==AVAudioSessionRouteChangeReasonOldDeviceUnavailable) {
        AVAudioSessionRouteDescription *routeDescription=dic[AVAudioSessionRouteChangePreviousRouteKey];
        AVAudioSessionPortDescription *portDescription= [routeDescription.outputs firstObject];
        //原设备为耳机则暂停
        if ([portDescription.portType isEqualToString:@"Headphones"]) {
            [self stopAnim];
            [self stopCheck];
            [HttpTool checkCountWithStartTime:self.starttime Temperature:self.lastTemp TemperatureType:temperatureType OperateType:@"3"];
            [[NSNotificationCenter defaultCenter] removeObserver:self name:AVAudioSessionRouteChangeNotification object:nil];
            [self.navigationController popToRootViewControllerAnimated:YES];
            [SVProgressHUD showInfoWithStatus:@"体温棒已拔出，请重新测温。"];
            return;
        }
    }
    
}

/**
 *  2015-09-23 SoulJa
 *  监听音量调节
 */
- (void)volumeChanged:(NSNotification *)notification
{
    // service logic here.
    CGFloat volume = [notification.userInfo[@"AVSystemController_AudioVolumeNotificationParameter"] floatValue];
    
    if (volume < 1.0 || ![GlobalTool isIPad]) {
        [self stopAnim];
        [self stopCheck];
        [self.navigationController popToRootViewControllerAnimated:YES];
        if ([[GlobalTool shared] isFromBackground]) {
            [[GlobalTool shared] setIsFromBackground:NO];
            return;
        } else {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [SVProgressHUD showInfoWithStatus:@"请将音量调到最大"];
            });
            return;
        }
    }
}

- (void)goBack
{
    [self stopCheck];
    [self stopAnim];
    NSString *temperatureType = @"";
    if (checkType == 1) {
        temperatureType = @"1";
    } else if(checkType == 2 ) {
        temperatureType = @"0";
    }
    [HttpTool checkCountWithStartTime:self.starttime Temperature:self.lastTemp TemperatureType:temperatureType OperateType:@"2"];
    [self.navigationController popToRootViewControllerAnimated:YES];
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
