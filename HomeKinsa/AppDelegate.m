//
//  AppDelegate.m
//  HomeKinsa
//
//  Created by Zhang guangchun on 15/3/4.
//  Copyright (c) 2015年 Mikai. All rights reserved.
//

#import "AppDelegate.h"
//ShareSDK引入
#import <ShareSDK/ShareSDK.h>
/*
#import <TencentOpenAPI/QQApi.h>*/
#import <TencentOpenAPI/QQApiInterface.h>
#import <TencentOpenAPI/TencentOAuth.h>
//开启QQ和Facebook网页授权需要
#import <QZoneConnection/ISSQZoneApp.h>
#import "WXApi.h"
#import "WeiboSDK.h"
//开启微信授权
#import "WXApi.h"
#import "AFNetworking.h"
#import "AdViewController.h"
#import "GetServerUrlViewController.h"
#import "HttpTool.h"
#import "sys/utsname.h"
#import "DataBaseTool.h"
#import "GlobalTool.h"
//引入友盟统计
#import "MobClick.h"
#import "Account.h"

@interface AppDelegate ()

@end

#pragma -mark App代理方法
@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    //引入友盟统计
    [MobClick startWithAppkey:@"564d494067e58e880e001f7d" reportPolicy:BATCH channelId:nil];
    [MobClick setAppVersion:VERSION];
    
    //接入ShareSDK
    [ShareSDK registerApp:@"91389f1b1b22"];//字符串api20为您的ShareSDK的AppKey
    
    //开启QQ空间网页授权开关(optional)
    id<ISSQZoneApp> app =(id<ISSQZoneApp>)[ShareSDK getClientWithType:ShareTypeQQSpace];
    [app setIsAllowWebAuthorize:YES];
    
    //添加新浪微博应用 注册网址 http://open.weibo.com
    [ShareSDK connectSinaWeiboWithAppKey:@"2943436169"
                               appSecret:@"3f910962eb3218700508ecc9b2c24fdf"
                             redirectUri:@"http://www.sharesdk.cn"];
    
    //添加QQ空间应用  注册网址  http://connect.qq.com/intro/login/
    [ShareSDK connectQZoneWithAppKey:@"1104709573"
                           appSecret:@"A6yl1nhY2wUPpiSQ"
                   qqApiInterfaceCls:[QQApiInterface class]
                     tencentOAuthCls:[TencentOAuth class]];
    
    //添加QQ应用  注册网址  http://open.qq.com/
    [ShareSDK connectQQWithQZoneAppKey:@"1104709573"
                     qqApiInterfaceCls:[QQApiInterface class]
                       tencentOAuthCls:[TencentOAuth class]];
    
    //微信登陆应用
    [ShareSDK connectWeChatWithAppId:@"wxb3d63128c869c167" appSecret:@"275391a1930ff0e469427705b46b44f1" wechatCls:[WXApi class]];
    /**
     *  推送通知开始
     */
//    if ([[UIDevice currentDevice].systemVersion floatValue] >= 8.0) {
//        [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound categories:nil]];
//        [application registerForRemoteNotifications];
//    } else {
//         [[UIApplication sharedApplication] registerForRemoteNotificationTypes: UIRemoteNotificationTypeBadge |UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert];
//    }
    /**
     *  推送通知结束
     */
    [[GlobalTool shared] setFromCheckToBackground:NO];
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [self.window makeKeyAndVisible];
    /*
//    NSString *host = [GetServerUrlViewController getServerUrl];
//    NSString *urlStr = [NSString stringWithFormat:@"http://%@/api.php?m=open&c=ads&a=display",host];
//    NSURL *url = [NSURL URLWithString:urlStr];
//    NSURLRequest *request = [NSURLRequest requestWithURL:url];
//    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
//    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
//    if ([dict[@"status"] isEqual:[NSNumber numberWithInt:1]]) {
//        AdViewController *adVc = [[AdViewController alloc] init];
//        NSDictionary *responseDict = dict[@"data"];
//        adVc.adImageUrlStr = responseDict[@"url"];
//        self.window.rootViewController = adVc;
//    } else {
//        UIStoryboard *board = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
//        UIViewController *rootVc = [board instantiateInitialViewController];
//        self.window.rootViewController = rootVc;
//    }
     */
    //判断当前是否有网络
    BOOL isConnectInternet = [HttpTool isConnectInternet];
    if (isConnectInternet) {
        //查看是否拥有广告位图片
        NSDictionary *adDict = [[NSUserDefaults standardUserDefaults] objectForKey:@"ad"];
        if (adDict == nil) { //第一次打开时
            [HttpTool getAdDict];
            UIStoryboard *board = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            UIViewController *vc = [board instantiateViewControllerWithIdentifier:@"MainTabBarViewController"];
            self.window.rootViewController = vc;
        } else { //往后打开
            if ([[adDict objectForKey:@"status"] isEqual:@1]) {
                AdViewController *adVc = [[AdViewController alloc] init];
                adVc.adImageUrlStr = [[adDict objectForKey:@"data"] objectForKey:@"img"];
                self.window.rootViewController = adVc;
            } else {
                [HttpTool getAdDict];
                UIStoryboard *board = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                UIViewController *vc = [board instantiateViewControllerWithIdentifier:@"MainTabBarViewController"];
                self.window.rootViewController = vc;
            }
        }
    } else {
        UIStoryboard *board = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        UIViewController *vc = [board instantiateViewControllerWithIdentifier:@"MainTabBarViewController"];
        self.window.rootViewController = vc;
    }
    
    return YES;
}

//-(void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken{
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    [defaults setObject:deviceToken forKey:@"deviceToken"];
//}

#pragma mark 获取device token失败后
//-(void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error{
//    NSLog(@"didFailToRegisterForRemoteNotificationsWithError:%@",error.localizedDescription);
//}

#pragma mark 接收到推送通知之后
//-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo{
////    {
////        aps =     {
////            "account_id" = 1;
////            addtime = 1443405999;
////            alert = "\U8fd9\U662f\U4e00\U4e2a\U4e34\U65f6\U63cf\U8ff0";
////            badge = 1;
////            content = "\U8fd9\U662f\U4e00\U4e2a\U4e34\U65f6\U63cf\U8ff0";
////            ischecked = 0;
////            msgid = 33;
////            sound = default;
////            title = Example;
////        };
////    }
//    application.applicationIconBadgeNumber = 0;
//    NSDictionary *apsDict = userInfo[@"aps"];
//    NSMutableDictionary *msgInfoDict = [NSMutableDictionary dictionary];
//    [msgInfoDict setValue:[NSString stringWithFormat:@"%@",[apsDict objectForKey:@"account_id"]] forKey:@"acc_id"];
//    [msgInfoDict setValue:[NSString stringWithFormat:@"%@",[apsDict objectForKey:@"addtime"]] forKey:@"addtime"];
//    [msgInfoDict setValue:[NSString stringWithFormat:@"%@",[apsDict objectForKey:@"msgid"]] forKey:@"msgid"];
//    [msgInfoDict setValue:[NSString stringWithFormat:@"%@",[apsDict objectForKey:@"title"]] forKey:@"title"];
//    [msgInfoDict setValue:[NSString stringWithFormat:@"%@",[apsDict objectForKey:@"content"]] forKey:@"content"];
//    [msgInfoDict setValue:[NSString stringWithFormat:@"%@",[apsDict objectForKey:@"ischecked"]] forKey:@"isread"];
//    BOOL addResult = [DataBaseTool addMessage:msgInfoDict];
//    if (addResult) {
//        NSLog(@"插入数据成功!");
//    }
//}



- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    if ([[GlobalTool shared] FromCheckToBackground]) {
        [HttpTool checkCountWithStartTime:[[GlobalTool shared] CheckStarttime] Temperature:[[GlobalTool shared] LastCheckTemp] TemperatureType:[[GlobalTool shared] LastCheckType] OperateType:@"1"];
    }
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    return [ShareSDK handleOpenURL:url wxDelegate:self];
}

- (BOOL)application: (UIApplication *)application
            openURL: (NSURL *)url
  sourceApplication: (NSString *)sourceApplication
         annotation: (id)annotation
{
    return [ShareSDK handleOpenURL: url
                 sourceApplication:sourceApplication
                        annotation: annotation
                        wxDelegate: self];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    //后台开启任务让程序保持运行状态
    [[GlobalTool shared] setIsFromBackground:YES];
    if ([[GlobalTool shared] FromCheckToBackground]) {
        [HttpTool checkCountWithStartTime:[[GlobalTool shared] CheckStarttime] Temperature:[[GlobalTool shared] LastCheckTemp] TemperatureType:[[GlobalTool shared] LastCheckType] OperateType:@"1"];
    }

}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [[NSUserDefaults standardUserDefaults] setObject:@0 forKey:@"NoNeedUpdate"];
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
    if ([deviceString isEqualToString:@ "iPhone5,4" ])     return @ "iPhone 5C" ;
    if ([deviceString isEqualToString:@ "iPhone6,2" ])     return @ "iPhone 5S" ;
    if ([deviceString isEqualToString:@ "iPhone7,1" ])     return @ "iPhone 6P" ;
    if ([deviceString isEqualToString:@ "iPhone7,2" ])     return @ "iPhone 6" ;
    if ([deviceString isEqualToString:@ "iPhone3,2" ])     return @ "Verizon iPhone 4" ;
    if ([deviceString isEqualToString:@ "iPod1,1" ])       return @ "iPod Touch 1G" ;
    if ([deviceString isEqualToString:@ "iPod2,1" ])       return @ "iPod Touch 2G" ;
    if ([deviceString isEqualToString:@ "iPod3,1" ])       return @ "iPod Touch 3G" ;
    if ([deviceString isEqualToString:@ "iPod4,1" ])       return @ "iPod Touch 4G" ;
    if ([deviceString isEqualToString:@ "iPad1,1" ])       return @ "iPad" ;
    if ([deviceString isEqualToString:@ "iPad2,1" ])       return @ "iPad 2 (WiFi)" ;
    if ([deviceString isEqualToString:@ "iPad2,2" ])       return @ "iPad 2 (GSM)" ;
    if ([deviceString isEqualToString:@ "iPad2,3" ])       return @ "iPad 2 (CDMA)" ;
    if ([deviceString isEqualToString:@ "iPad4,4" ])       return @ "iPad Mini" ;
    if ([deviceString isEqualToString:@ "i386" ])         return @ "Simulator" ;
    if ([deviceString isEqualToString:@ "x86_64" ])       return @ "Simulator" ;
    NSLog (@ "NOTE: Unknown device type: %@" , deviceString);
    return deviceString;
}

@end
