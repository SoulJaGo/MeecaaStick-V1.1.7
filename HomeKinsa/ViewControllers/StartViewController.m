//
//  StartViewController.m
//  HomeKinsa
//
//  Created by Zhang guangchun on 15/3/11.
//  Copyright (c) 2015年 Mikai. All rights reserved.
//

#import "StartViewController.h"
#import "INTUAnimationEngine.h"
#import "GlobalData.h"
#import "TTNetworkHelper.h"
#import "TTToolsHelper.h"

@interface StartViewController ()

@property (weak, nonatomic) IBOutlet UIButton *startBtn;
@end

@implementation StartViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
}



- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginSucceedDelegate:) name:@"LOGIN_SUCCEED" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkLoginDelegate:) name:@"CHECK_VER" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(realLoginDelegate:) name:@"REALLY_VER" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginThirdSuccessDelegate:) name:@"LOGINTHIRD_SUCCEED" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(NetworkErrorDelegate:) name:@"NETWORK_ERROR" object:nil];
    /*NSString *appVer = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey];
    int count = 0;
    for (int i = 0; i<[appVer length]; i++) {
        //截取字符串中的每一个字符
        NSString *s = [appVer substringWithRange:NSMakeRange(i, 1)];
        if ([s isEqualToString:@"."]) {
            if (count>0) {
                NSRange range = NSMakeRange(i, 1);
                appVer = [appVer stringByReplacingCharactersInRange:range withString:@""];
            }
            count++;
        }
    }
    NSLog(@"%@",appVer);
    [[TTNetworkHelper sharedSession] checkVer:appVer dismissProgressView:YES];*/
    
    [self intoApp:nil];
}

- (void)NetworkErrorDelegate:(id)sender{
}

- (IBAction)intoApp:(id)sender {
    GlobalData *gd = [GlobalData sharedData];
    if (gd.loginPhoneNumber!=nil&&![gd.loginPhoneNumber isEqualToString:@""]) {
        [[TTNetworkHelper sharedSession] accountLoginByPhoneNumber:gd.loginPhoneNumber Password:gd.loginPwd Mid:@"-1" dismissProgressView:YES];
    } else if (![gd.thirdLoginUid isEqualToString:@""]  && ![gd.thirdLoginNickName isEqualToString:@""] && ![gd.thirdLoginPlatformID isEqualToString:@""] && gd.thirdLoginUid != nil && gd.thirdLoginNickName != nil && gd.thirdLoginPlatformID != nil) {
        [[TTNetworkHelper sharedSession] accountLoginPByOpenId:gd.thirdLoginUid token:@"1" platformID:gd.thirdLoginPlatformID mid:@"-1" dismissProgressView:YES];
    }
    else{
        [self performSegueWithIdentifier:@"registerSegue" sender:nil];
    }
}

- (void)checkLoginDelegate:(id)sender{
    NSLog(@"checkLoginDelegate");
    GlobalData *gd = [GlobalData sharedData];
    gd.loginPhoneNumber = @"18521532503";
    gd.loginPwd = @"123";
    [self intoApp:nil];
}

- (void)realLoginDelegate:(id)sender{
    NSLog(@"realLoginDelegate");
    GlobalData *gd = [GlobalData sharedData];
    if (gd.loginPhoneNumber!=nil&&![gd.loginPhoneNumber isEqualToString:@""]) {
        self.startBtn.hidden = YES;
        [INTUAnimationEngine animateWithDuration:0.8
                                           delay:0
                                      animations:^(CGFloat percentage) {
                                          
                                      } completion:^(BOOL finished) {
                                          [self intoApp:nil];
                                      }];
    }
    else{
//        self.startBtn.hidden = NO;
        self.startBtn.hidden = YES;
        [self intoApp:nil];
    }
}

- (void)loginSucceedDelegate:(id)sender{
    GlobalData *gd = [GlobalData sharedData];
    [gd setDefaultMember];
    [self performSegueWithIdentifier:@"mainSegue" sender:nil];
}

- (void)loginThirdSuccessDelegate:(id)sender
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"MainTabBarViewController"];
    [self presentViewController:vc animated:YES completion:nil];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"LOGIN_SUCCEED" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"CHECK_VER" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"REALLY_VER" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"LOGINTHIRD_SUCCEED" object:nil];
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
