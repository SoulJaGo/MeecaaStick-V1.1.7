//
//  LoginViewController.m
//  HomeKinsa
//
//  Created by Zhang guangchun on 15/5/1.
//  Copyright (c) 2015年 Mikai. All rights reserved.
//

#import "LoginViewController.h"
#import "TTNetworkHelper.h"
#import "TTToolsHelper.h"
#import "sys/utsname.h"

#import <ShareSDK/ShareSDK.h>
#import <TencentOpenAPI/sdkdef.h>
/*
#import <TencentOpenAPI/TencentMessageObject.h>
#import <TencentOpenAPI/QQApi.h>*/
#import <TencentOpenAPI/QQApiInterface.h>
#import <TencentOpenAPI/TencentOAuth.h>
//开启QQ和Facebook网页授权需要
#import <QZoneConnection/ISSQZoneApp.h>
#import <SVProgressHUD.h>
#import "WXApi.h"
//网络请求类
#import "HttpTool.h"
//数据库工具类
#import "DataBaseTool.h"
#import "GlobalTool.h"
#import "Account.h"

@interface LoginViewController () <UITextFieldDelegate>


@property (weak, nonatomic) IBOutlet UITextField *inputPhoneNum;
@property (weak, nonatomic) IBOutlet UITextField *inputPwd;
@property (nonatomic,strong) NSMutableArray *permissions;
@property (nonatomic,copy) NSString *thirdCreateMid;

/**第三方登陆UID*/
@property (nonatomic,copy) NSString *thirdLoginUid;
/**第三方登陆昵称*/
@property (nonatomic,copy) NSString *thirdLoginNickName;
/**第三方登陆platformID*/
@property (nonatomic,copy) NSString *thirdLoginPlatformID;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *LoginViewDistance;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *LoginButtonToForgetDistance;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *LogoImageTopDistance;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *LogoImageBottomDistance;
- (IBAction)goRegister;

/**
 *  QQ登陆按钮头像
 */
@property (weak, nonatomic) IBOutlet UIButton *QQBtn;

/**
 *  微信头像按钮
 */
@property (weak, nonatomic) IBOutlet UIButton *WeChatBtn;

/**
 *  QQ第三方登陆
 */
- (IBAction)loginQQ:(id)sender;
/**
 *  新浪微博第三方登陆
 */
- (IBAction)loginSinaWeibo:(id)sender;
/**
 *  微信第三方登陆
 */
- (IBAction)loginWechat:(id)sender;
/**
 *  随便逛逛
 */
- (IBAction)goMainView;

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //监测网络状态
    [HttpTool getCurrentNetworkStatus];
    
    /**
     * 2015-11-28 SoulJa
     * 键盘事件加入代理
     */
    self.inputPhoneNum.delegate = self;
    self.inputPwd.delegate = self;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapView:)];
    [self.view addGestureRecognizer:tap];
    
    
    
    if ([[self deviceString] isEqualToString:@"iPhone 4S"]) {
        self.LoginViewDistance.constant = 0;
        self.LoginButtonToForgetDistance.constant = 0;
        
        self.LogoImageTopDistance.constant = 15;
        self.LogoImageBottomDistance.constant = 20;
    }
    
    if ([GlobalTool isIPad]) {
        self.LoginViewDistance.constant = 0;
        self.LoginButtonToForgetDistance.constant = 0;
        
        self.LogoImageTopDistance.constant = 15;
        self.LogoImageBottomDistance.constant = 20;
    }
    
    //检测第三方登陆软件是否安装
    if (![WXApi isWXAppInstalled] && ![WXApi isWXAppSupportApi]) {
        self.WeChatBtn.hidden = YES;
    }
    
    if (![TencentOAuth iphoneQQInstalled]) {
        self.QQBtn.hidden = YES;
    }
    
    //监测是否手机号码登陆过
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *path = [docDir stringByAppendingPathComponent:@"account.archive"];
    Account *account = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    
    NSString *placeholderPhone = account.telephone;
    if (placeholderPhone != nil) {
        self.inputPhoneNum.text = placeholderPhone;
    }
    
}

/**
 *  判断手机型号
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
    return deviceString;
}

- (void)onTapView:(id)sender{
    [self.inputPhoneNum resignFirstResponder];
    [self.inputPwd resignFirstResponder];
}

- (void)viewWillAppear:(BOOL)animated{
    self.navigationController.navigationBarHidden = YES;
   //发出登陆成功的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginSuccessNotification) name:@"LoginSuccessNotification" object:nil];
}

- (void)viewWillDisappear:(BOOL)animated{
    //去除登陆通知
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"LoginSuccessNotification" object:nil];
}

/**
 *
 */
- (void)loginSucceedDelegate:(id)sender{
    GlobalData* gd = [GlobalData sharedData];
    gd.loginPhoneNumber = self.inputPhoneNum.text;
    gd.loginPwd = self.inputPwd.text;
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"MainTabBarViewController"];
    [self presentViewController:vc animated:YES completion:nil];
}


/**
 *  使用电话号码和密码登陆
 */
- (IBAction)onClickLogin:(id)sender {
    //友盟统计
    [MobClick event:@"login"];
    
    [self.view endEditing:YES];
    
    //输入的电话号码不能为空
    if ([self.inputPhoneNum.text isEqualToString:@""]) {
        [[TTToolsHelper shared] showAlertMessage:@"用户名或密码错误!"];
        return;
    }
    
    //输入的密码不能为空
    if ([self.inputPwd.text isEqualToString:@""]) {
        [[TTToolsHelper shared] showAlertMessage:@"用户名或密码错误!"];
        return;
    }
    //生成HUB
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
    //判断网络状态
    [HttpTool getCurrentNetworkStatus];
    
    [HttpTool LoginWithPhoneNumber:self.inputPhoneNum.text Password:self.inputPwd.text];
}

/**
 *  SoulJa 2015-10-12
 *  显示状态栏
 */
- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

/**
 *  QQ第三方登陆
 */
- (IBAction)loginQQ:(id)sender
{
    //友盟统计
    [MobClick event:@"qqdenglu"];

    
    //生成HUB
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
    //判断网络状态
    [HttpTool getCurrentNetworkStatus];
    id<ISSAuthOptions> authOptions = [ShareSDK authOptionsWithAutoAuth:YES allowCallback:YES authViewStyle:SSAuthViewStyleFullScreenPopup viewDelegate:nil authManagerViewDelegate:nil];
    [ShareSDK getUserInfoWithType:ShareTypeQQSpace authOptions:authOptions result:^(BOOL result, id<ISSPlatformUser> userInfo, id<ICMErrorInfo> error) {
        if (error) {
            NSLog(@"%@",error);
        }
        if (result) {
            [HttpTool loginThirdPartyWithOpenId:[userInfo uid] NickName:[userInfo nickname] PlatForm:@"2" Avatar:[userInfo profileImage]];
        } else {
                [SVProgressHUD dismiss];
                [[TTToolsHelper shared] showAlertMessage:@"QQ授权失败!"];
        }
    }];
}

/**
 *  新浪微博登陆
 */
- (IBAction)loginSinaWeibo:(id)sender {
    //友盟统计
    [MobClick event:@"weibodenglu"];
    
    //生成HUB
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
    //判断网络状态
    [HttpTool getCurrentNetworkStatus];
    [ShareSDK getUserInfoWithType:ShareTypeSinaWeibo authOptions:nil result:^(BOOL result, id<ISSPlatformUser> userInfo, id<ICMErrorInfo> error) {
        if (result) {
            [HttpTool loginThirdPartyWithOpenId:[userInfo uid] NickName:[userInfo nickname] PlatForm:@"1" Avatar:[userInfo profileImage]];
        } else {
            [SVProgressHUD dismiss];
            [[TTToolsHelper shared] showAlertMessage:[error errorDescription]];
        }
    }];
}

/**
 *  微信第三方登陆
 */
- (IBAction)loginWechat:(id)sender {
    //友盟统计
    [MobClick event:@"weixinlu"];
    
    [SVProgressHUD show];
    id<ISSAuthOptions> authOptions = [ShareSDK authOptionsWithAutoAuth:YES allowCallback:YES authViewStyle:SSAuthViewStyleFullScreenPopup viewDelegate:nil authManagerViewDelegate:nil];
    [ShareSDK getUserInfoWithType:ShareTypeWeixiSession authOptions:authOptions result:^(BOOL result, id<ISSPlatformUser> userInfo, id<ICMErrorInfo> error) {
        if (result) {
            [HttpTool loginThirdPartyWithOpenId:[userInfo uid] NickName:[userInfo nickname] PlatForm:@"3" Avatar:[userInfo profileImage]];
        } else {
            [SVProgressHUD dismiss];
            [[TTToolsHelper shared] showAlertMessage:@"微信授权失败!"];
        }
    }];
}

/**
 *  SoulJa 2015-10-12
 *  随便逛逛
 */
- (IBAction)goMainView {
    //友盟统计
    [MobClick event:@"suibian"];
    
    UIStoryboard *board = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *vc = [board instantiateViewControllerWithIdentifier:@"MainTabBarViewController"];
    [self presentViewController:vc animated:YES completion:nil];
}

/**
 *  获取手机序列号
 */
- (NSString *)getCurrentDeviceIdentifierNumber
{
    return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
}



#pragma mark ---1.4.8代码
/**
 *  测试使用电话号码和密码登陆
 */
- (void)loginSuccessNotification
{
    UIStoryboard *board = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *vc = [board instantiateViewControllerWithIdentifier:@"MainTabBarViewController"];
    [self presentViewController:vc animated:YES completion:^{
        [SVProgressHUD dismiss];
    }];
}
- (IBAction)goRegister {
    //友盟统计
    [MobClick event:@"register"];
}

/**
 *  2015-11-28 SoulJa
 */
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}
@end
