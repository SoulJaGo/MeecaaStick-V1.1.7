//
//  SettingAboutViewController.m
//  HomeKinsa
//
//  Created by Zhang guangchun on 15/5/3.
//  Copyright (c) 2015年 Mikai. All rights reserved.
//

#import "SettingAboutViewController.h"
#import "sys/utsname.h"

@interface SettingAboutViewController ()
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *logoToTOp;

@end

@implementation SettingAboutViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    if ([[self deviceString] isEqualToString:@"iPhone 4S"]) {
        self.logoToTOp.constant = 30;
    }
    
    /**
     *  2015-11-02 SoulJa
     *  初始化系统版本号
     */
    self.versionLabel.text = [@"V " stringByAppendingString:VERSION];
}

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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onClickBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
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
