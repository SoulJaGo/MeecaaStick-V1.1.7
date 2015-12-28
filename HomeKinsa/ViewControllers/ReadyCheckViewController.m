//
//  ReadyCheckViewController.m
//  HomeKinsa
//
//  Created by Zhang guangchun on 15/5/1.
//  Copyright (c) 2015年 Mikai. All rights reserved.
//

#import "ReadyCheckViewController.h"
#import <AudioToolbox/AudioToolbox.h>
#import "TTToolsHelper.h"
#import "INTUAnimationEngine.h"
#import "UIImage+ImageEffects.h"
#import "UseHardwareCheckViewController.h"
#import "sys/utsname.h"
#import "Account.h"

@import AVFoundation;

@interface ReadyCheckViewController ()
{
    NSTimer *timer;
}

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomSpace;
@end

@implementation ReadyCheckViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationController.navigationBar setTranslucent:NO];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageWithColor:COLOR_NAV_BACKGROUND] forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBarHidden = NO;
    
    //获取手机的型号
    NSString *deviceModel = [self getCurrentDeviceModel];
    if ([deviceModel isEqualToString:@"iPhone 4S"]) {
        self.bottomSpace.constant = 20;
    } else if ([deviceModel isEqualToString:@"iPhone 6 Plus"]) {
        self.bottomSpace.constant = 100;
    }

//    timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(playTimer:) userInfo:nil repeats:YES];

//    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapView:)];
//    [self.view addGestureRecognizer:tap];
}


-(void)playTimer:(NSTimer*)timer_{
    if ([self isHeadsetPluggedIn]) {
        [timer invalidate];
        timer = nil;
        [INTUAnimationEngine animateWithDuration:2
                                           delay:0
                                      animations:^(CGFloat percentage) {
                                          
                                      } completion:^(BOOL finished) {
                                          [self performSegueWithIdentifier:@"showCheckSegue" sender:nil];
                                      }];
    }
    else{
        
    }
}

- (BOOL)isHeadsetPluggedIn {
    AVAudioSessionRouteDescription* route = [[AVAudioSession sharedInstance] currentRoute];
    for (AVAudioSessionPortDescription* desc in [route outputs]) {
        if ([[desc portType] isEqualToString:AVAudioSessionPortHeadphones])
            return YES;
    }
    return NO;
}

- (IBAction)onClickUnderArm:(id)sender {
    //友盟统计
    [MobClick event:@"fastCheck"];
    
    if ([self isHeadsetPluggedIn]) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        UseHardwareCheckViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"UseHardwareCheckViewController"];
        [vc setCheckType:1];
        [self.navigationController pushViewController:vc animated:YES];
    }
    else {
        [[TTToolsHelper shared] showAlertMessage:@"请将体温棒连接手机！"];
    }
}

- (IBAction)onClickNormal:(id)sender {
    //友盟统计
    [MobClick event:@"normalCheck"];
    
    if ([self isHeadsetPluggedIn]) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        UseHardwareCheckViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"UseHardwareCheckViewController"];
        [vc setCheckType:2];
        [self.navigationController pushViewController:vc animated:YES];
    }
    else {
        [[TTToolsHelper shared] showAlertMessage:@"请将体温棒连接手机！"];
    }
}


- (void)onTapView:(id)sender{
    if ([self isHeadsetPluggedIn]) {
        [self performSegueWithIdentifier:@"showCheckSegue" sender:nil];
    }
    else{
        [[TTToolsHelper shared] showAlertMessage:@"请将体温棒连接手机！"];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)onClickBack:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

/**
 *  判断手机的型号
 */
- (NSString *)getCurrentDeviceModel
{
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceString = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    
    if ([deviceString isEqualToString:@"iPhone1,1"])    return @"iPhone 1G";
    if ([deviceString isEqualToString:@"iPhone1,2"])    return @"iPhone 3G";
    if ([deviceString isEqualToString:@"iPhone2,1"])    return @"iPhone 3GS";
    if ([deviceString isEqualToString:@"iPhone3,1"])    return @"iPhone 4";
    if ([deviceString isEqualToString:@"iPhone4,1"])    return @"iPhone 4S";
    if ([deviceString isEqualToString:@"iPhone5,2"])    return @"iPhone 5";
    if ([deviceString isEqualToString:@"iPhone6,2"])    return @"iPhone 5S";
    if ([deviceString isEqualToString:@"iPhone7,1"])    return @"iPhone 6 Plus";
    if ([deviceString isEqualToString:@"iPhone3,2"])    return @"Verizon iPhone 4";
    if ([deviceString isEqualToString:@"iPod1,1"])      return @"iPod Touch 1G";
    if ([deviceString isEqualToString:@"iPod2,1"])      return @"iPod Touch 2G";
    if ([deviceString isEqualToString:@"iPod3,1"])      return @"iPod Touch 3G";
    if ([deviceString isEqualToString:@"iPod4,1"])      return @"iPod Touch 4G";
    if ([deviceString isEqualToString:@"iPad1,1"])      return @"iPad";
    if ([deviceString isEqualToString:@"iPad2,1"])      return @"iPad 2 (WiFi)";
    if ([deviceString isEqualToString:@"iPad2,2"])      return @"iPad 2 (GSM)";
    if ([deviceString isEqualToString:@"iPad2,3"])      return @"iPad 2 (CDMA)";
    if ([deviceString isEqualToString:@"i386"])         return @"Simulator";
    if ([deviceString isEqualToString:@"x86_64"])       return @"Simulator";
    NSLog(@"NOTE: Unknown device type: %@", deviceString);
    return deviceString;
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
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
