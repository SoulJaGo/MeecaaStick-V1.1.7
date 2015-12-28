//
//  OnlineDoctorMainViewController.m
//  HomeKinsa
//
//  Created by Zhang guangchun on 15/3/4.
//  Copyright (c) 2015年 Mikai. All rights reserved.
//

#import "OnlineDoctorMainViewController.h"
#import "NSString+MyCategory.h"
#import <SVProgressHUD.h>
#import "GlobalData.h"
#import "HttpTool.h"
#import "DataBaseTool.h"
#import "Account.h"

@interface OnlineDoctorMainViewController ()<UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@end

@implementation OnlineDoctorMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //监测网络状态
    [HttpTool getCurrentNetworkStatus];
    
    //判断用户是否登录
    NSDictionary *defaultMember = [DataBaseTool getDefaultMember];
    if (defaultMember == nil) {
        [SVProgressHUD showInfoWithStatus:@"请您先登录" maskType:SVProgressHUDMaskTypeClear];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            UIStoryboard *board = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            UIViewController *vc = [board instantiateViewControllerWithIdentifier:@"LoginViewController"];
            [self presentViewController:vc animated:YES completion:nil];
        });
        return;
    }
    
    NSString *user_id = [NSString stringWithFormat:@"%@",defaultMember[@"id"]];
    
    // Do any additional setup after loading the view.
    NSString *appKey = @"bfac41d6e46684d019eac2a8486912aa";//@"654a94debc736517f06fb2438447e7d8";
    NSTimeInterval timestamp = [[NSDate date] timeIntervalSince1970];
    
    /*
     原来获取默认用户的ID
    GlobalData *gd = [GlobalData sharedData];
    NSString *user_id = gd.nowAccountId;
     */
    
    NSString *appKeyStr = [[NSString stringWithFormat:@"%@%f%@",appKey,timestamp,user_id] md5];
    NSString *appKeyParam = [appKeyStr substringWithRange:NSMakeRange((appKeyStr.length-16)/2, 16)];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    NSString *end_time = [formatter stringFromDate:[NSDate date]];
    
    NSString *start_time = [formatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:(- 3 * 24 * 60 * 60 )]];
    NSString *device_type = @"body_temperature";
    
    NSString *sex;
    if ([[NSString stringWithFormat:@"%@",defaultMember[@"sex"]] isEqualToString:@"0"]) {
        sex = @"1";
    } else {
        sex = @"0";
    }
    
    NSString *birthday;
    if (defaultMember[@"birth"] == nil || [defaultMember[@"birth"] isEqualToString:@""]) {
        birthday = @"1990-01-01";
    } else {
        birthday = defaultMember[@"birth"];
    }
    
    NSString *urlString = @"http://www.chunyuyisheng.com/ehr/ask_service/";//@"http://trunk.summer2.chunyu.me/";

    //appkey+timestamp +user_id做md5加密然后
    //取md5加密的中间16位
    NSString *urlStr = [NSString stringWithFormat:@"%@?app_key=%@&user_id=%@&timestamp=%f&start_time=%@&end_time=%@&device_type=%@&sex=%@",urlString,appKeyParam,user_id,timestamp,start_time,end_time,device_type,sex];
    
    [self loadWebPageWithString:[urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSLog(@"%@",[NSString stringWithFormat:@"%@?app_key=%@&user_id=%@&timestamp=%f&start_time=%@&end_time=%@&device_type=%@&sex=%@",urlString,appKeyParam,user_id,timestamp,start_time,end_time,device_type,sex]);
    
    [SVProgressHUD show];
}

- (void)loadWebPageWithString:(NSString*)urlString
{
    NSURL *url =[NSURL URLWithString:urlString];
    NSURLRequest *request =[NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:5.0];
    self.webView.delegate = self;
    [self.webView loadRequest:request];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView{
    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD dismiss];
    });
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    if (error !=nil) {
        NSLog(@"%@",error);
        [SVProgressHUD showErrorWithStatus:@"网络不给力哦!"];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [SVProgressHUD dismiss];
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

@end
