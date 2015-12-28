//
//  MainTabBarViewController.m
//  HomeKinsa
//
//  Created by Zhang guangchun on 15/3/4.
//  Copyright (c) 2015年 Mikai. All rights reserved.
//

#import "MainTabBarViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "GlobalData.h"
#import "LoginViewController.h"
#import "UserNavigationController.h"
#import "UserListTableViewController.h"
#import "DataBaseTool.h"
#import "HttpTool.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import "MessageViewController.h"
#import "MessageNavigationController.h"
#import "GlobalTool.h"

@interface MainTabBarViewController () <UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UIButton *headIcon;
@property (nonatomic,weak) IBOutlet UILabel *nickNameLabel;
@property (retain, nonatomic) UIImageView *headImageView;
@property (nonatomic,strong) UIImageView *iconBtn;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *NickNameLabelLeftConstraint;
@end

@implementation MainTabBarViewController
/**
 *  第一次启动加载去登陆服务
 */
+ (void)initialize
{
    //判断是否有网络
    BOOL isConnectInternet = [HttpTool isConnectInternet];
    if (isConnectInternet) { // 可以连接网络
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            //友盟统计
            [MobClick event:@"startLogin"];
            [HttpTool validLogin];
        });
    } else {
        return;
    }
}


- (void)viewDidLoad {
    
    
    [super viewDidLoad];
    
    //监测网络状态
    if (![HttpTool isConnectInternet]) {
        [SVProgressHUD showInfoWithStatus:@"请检测您的网络状态!"];
    }
    
    //添加头像按钮
    UIImageView *iconBtn = [[UIImageView alloc] init];
    if ([[GlobalTool deviceString] isEqualToString:@"iPhone 6P"] || [[GlobalTool deviceString] isEqualToString:@"iPhone 6SP"]) {
        iconBtn.frame = CGRectMake(24, 23, 44, 44);
        self.NickNameLabelLeftConstraint.constant = 71;
    } else {
        iconBtn.frame = CGRectMake(3, 23, 44, 44);
    }
    
    UITapGestureRecognizer *recongnizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickIconBtn)];
    iconBtn.userInteractionEnabled = YES;
    [iconBtn addGestureRecognizer:recongnizer];
    [self.view addSubview:iconBtn];
    self.iconBtn = iconBtn;

//    UIButton *iconBtn = [UIButton buttonWithType:UIButtonTypeCustom];
//    if ([[GlobalTool deviceString] isEqualToString:@"iPhone 6P"] || [[GlobalTool deviceString] isEqualToString:@"iPhone 6SP"]) {
//        iconBtn.frame = CGRectMake(24, 23, 44, 44);
//        self.NickNameLabelLeftConstraint.constant = 71;
//    } else {
//        iconBtn.frame = CGRectMake(3, 23, 44, 44);
//    }
//    
//    [iconBtn addTarget:self action:@selector(clickIconBtn) forControlEvents:UIControlEventTouchUpInside];
//    [self.view addSubview:iconBtn];
//    self.iconBtn = iconBtn;
    //设置昵称
    [self setupNickNameAndIconBtn];
    
    //监听修改了默认成员的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setupNickNameAndIconBtn) name:@"UpdateDefaultMemberSuccessNotification" object:nil];
    
    /**
     *  2015-09-22 SoulJa
     *  添加一个推送按钮
     */
    //[self setupMsgBtn];
    
    /**
     *  2015-09-30 SoulJa
     *  监测更新
     */
    if ([HttpTool isConnectInternet]) {
        [HttpTool getVersion];
    }
    
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getVersionSuccessNotification:) name:@"GetVersionSuccessNotification" object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ValidPhoneNumberFailedNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"GetVersionSuccessNotification" object:nil];
}

/**
 *  2015-09-30 SoulJa
 *  监测更新
 */
- (void)getVersionSuccessNotification:(NSNotification *)note
{
    int NoNeedUpdate = [[[NSUserDefaults standardUserDefaults] objectForKey:@"NoNeedUpdate"] intValue];
    if ([HttpTool isConnectInternet] && NoNeedUpdate==0) {
        /* 2015-11-02 改为声明宏变量
        NSString *currentVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
         */
        NSString *currentVersion = VERSION;
        NSDictionary *versionInfoDict = note.userInfo;
        if ([versionInfoDict[@"status"] isEqual:@0]) {
            return;
        } else {
            if (![currentVersion isEqualToString:[NSString stringWithFormat:@"%@",versionInfoDict[@"version"]]]) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@",versionInfoDict[@"title"]] message:[NSString stringWithFormat:@"%@",versionInfoDict[@"message"]] delegate:self cancelButtonTitle:nil otherButtonTitles:@"前往更新",@"忽略此次更新", nil];
                [alertView show];
            } else {
                return;
            }
        }
        
    } else {
        return;
    }
}

/**
 *  2015-09-22 SoulJa
 *  设置推送按钮
 */
- (void)setupMsgBtn
{
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setBackgroundImage:[UIImage imageNamed:@"message_icon"] forState:UIControlStateNormal];
    [self.view addSubview:btn];
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    [btn addTarget:self action:@selector(onClickMsgBtn) forControlEvents:UIControlEventTouchUpInside];
    NSArray *constraints1 = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[btn(==29)]-15-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(btn)];
    NSArray *constraints2 = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-32-[btn(==27)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(btn)];
    [self.view addConstraints:constraints1];
    [self.view addConstraints:constraints2];
}

/**
 *  2015-09-22 SoulJa
 *  点击消息按钮
 */
- (void)onClickMsgBtn
{
    if ([DataBaseTool getDefaultMember] == nil) { // 没有默认用户
        [SVProgressHUD showInfoWithStatus:@"请您先登录!"];
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        UIViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
        [self presentViewController:vc animated:YES completion:nil];
    } else {
    [self presentViewController:[[MessageNavigationController alloc] initWithRootViewController:[[MessageViewController alloc] init]] animated:YES completion:nil];
    }
}

/**
 *  设置昵称
 */
- (void)setupNickNameAndIconBtn
{
    if ([DataBaseTool getDefaultMember] != nil) { //获取数据库中的默认成员
        self.nickNameLabel.text = [[DataBaseTool getDefaultMember] objectForKey:@"name"];
        if ([[[DataBaseTool getDefaultMember] objectForKey:@"avatar"] isEqualToString:@""] || [[DataBaseTool getDefaultMember] objectForKey:@"avatar"] == nil || [[[DataBaseTool getDefaultMember] objectForKey:@"avatar"] isEqualToString:[HOST stringByAppendingString:@"Uploads/Picture/"]]) { //没有头像地址的时候
//            [self.iconBtn setImage:[UIImage imageNamed:@"top_head_button"] forState:UIControlStateNormal];
            [self.iconBtn setImage:[UIImage imageNamed:@"top_head_button"]];
        } else { //有头像地址的时候
            if ([HttpTool isConnectInternet]) {
//                NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:[[DataBaseTool getDefaultMember] objectForKey:@"avatar"]]];
//                if (data == nil) {
//                    [self.iconBtn setImage:[UIImage imageNamed:@"top_head_button"] forState:UIControlStateNormal];
//                } else {
//                    [self.iconBtn setImage:[UIImage imageWithData:data] forState:UIControlStateNormal];
//                }
                [self.iconBtn sd_setImageWithURL:[NSURL URLWithString:[[DataBaseTool getDefaultMember] objectForKey:@"avatar"]] placeholderImage:[UIImage imageNamed:@"top_head_button"]];
            } else {
//                [self.iconBtn setImage:[UIImage imageNamed:@"top_head_button"] forState:UIControlStateNormal];
                [self.iconBtn setImage:[UIImage imageNamed:@"top_head_button"]];
            }
            [self.iconBtn.layer setCornerRadius:22];
            [self.iconBtn.layer setMasksToBounds:YES];
            [self.iconBtn.layer setBorderColor:[UIColor whiteColor].CGColor];
        }
    } else { //数据库中没有默认成员
        self.nickNameLabel.text = @"";
//        [self.iconBtn setImage:[UIImage imageNamed:@"top_head_button"] forState:UIControlStateNormal];
        [self.iconBtn setImage:[UIImage imageNamed:@"top_head_button"]];
    }
}

/**
 *  点击头像按钮
 */
- (void)clickIconBtn
{
    //友盟统计
    [MobClick event:@"userlist"];
    if ([DataBaseTool getDefaultMember] != nil) { //获取数据库中的默认成员
        [self presentViewController:[[UserNavigationController alloc] initWithRootViewController:[[UserListTableViewController alloc] init]] animated:YES completion:nil];
    } else { //数据库中没有默认成员
        [SVProgressHUD showInfoWithStatus:@"请您先登录" maskType:SVProgressHUDMaskTypeClear];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            UIStoryboard *board = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            UIViewController *vc = [board instantiateViewControllerWithIdentifier:@"LoginViewController"];
            [self presentViewController:vc animated:YES completion:nil];
        });
    }
}

-(UIImage*) circleImage:(UIImage*) image withParam:(CGFloat) inset {
    
    UIGraphicsBeginImageContext(image.size);
    
    CGContextRef context =UIGraphicsGetCurrentContext();
    
    //圆的边框宽度为2，颜色为红色
    
    CGContextSetLineWidth(context,2);
    
    CGContextSetStrokeColorWithColor(context, [UIColor clearColor].CGColor);
    
    CGRect rect = CGRectMake(inset, inset, image.size.width - inset *2.0f, image.size.height - inset *2.0f);
    
    CGContextAddEllipseInRect(context, rect);
    
    CGContextClip(context);
    
    //在圆区域内画出image原图
    
    [image drawInRect:rect];
    
    CGContextAddEllipseInRect(context, rect);
    
    CGContextStrokePath(context);
    
    //生成新的image
    
    UIImage *newimg = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return newimg;
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.headImageView==nil
        &&self.headImageView.superview!=nil) {
        [self.headImageView removeFromSuperview];
    }
    CGRect frame = self.headIcon.frame;
    self.headImageView = [[UIImageView alloc] initWithFrame:CGRectMake(frame.origin.x,
                                                                               frame.origin.y,
                                                                               frame.size.width,
                                                                               frame.size.height)];
    
    GlobalData *gd = [GlobalData sharedData];
    
//    if (![gd.iconId isEqual:@"-1"]) {
    if ([gd.iconId intValue] > 10000) {
        NSString *url = [NSString stringWithFormat:@"http://%@/icons/%@.jpg",[gd connectUrl],gd.iconId];
        NSLog(@"url:%@",url);
        [self.headImageView sd_setImageWithURL:[NSURL URLWithString:url] placeholderImage:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            //        NSLog(@"%f %f",image.size.width,image.size.height);
            [self.headIcon setImage:[self circleImage:image withParam:0] forState:UIControlStateNormal];
        }];
    }
    
    self.headImageView.layer.masksToBounds = YES;
    self.headImageView.layer.cornerRadius =  50;
    [self.view addSubview:self.headImageView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        //友盟统计
        [MobClick event:@"checkupdate"];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms-apps://itunes.apple.com/cn/app/ti-wen-bang/id993497682?l=en&mt=8"]];
    } else if (buttonIndex == 1) {
        [[NSUserDefaults standardUserDefaults] setObject:@1 forKey:@"NoNeedUpdate"];
        return;
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}


/*
- (void)hideRealTabBar{
    for(UIView *view in self.view.subviews){
        if([view isKindOfClass:[UITabBar class]]){
            view.hidden = YES;
            break;
        }
    }
}

- (void)customTabBar{
    UIView *bgView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height-50, self.view.frame.size.width, 50)];
    bgView.backgroundColor = [UIColor grayColor];
    [self.view addSubview:bgView];
    
    NSInteger viewCount = self.viewControllers.count;
    self.buttons = [NSMutableArray arrayWithCapacity:viewCount];
    
    float _width = self.view.frame.size.width / viewCount;
    
    for (int i = 0; i<viewCount; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *btnSelectedImg = [UIImage imageNamed:[NSString stringWithFormat:@"btnMainTab%i-2", i]];
        [btn setBackgroundImage:btnSelectedImg forState:UIControlStateSelected];
        UIImage *btnNormalImg = [UIImage imageNamed:[NSString stringWithFormat:@"btnMainTab%i-1", i]];
        [btn setBackgroundImage:btnNormalImg forState:UIControlStateNormal];
        [btn setFrame:CGRectMake(_width*i+_width/2-btnNormalImg.size.width/2,
                                 self.view.frame.size.height-btnNormalImg.size.height,
                                 btnNormalImg.size.width, btnNormalImg.size.height)];
        [btn addTarget:self action:@selector(selectedTab:) forControlEvents:UIControlEventTouchDown];
        btn.tag = i;
        [self.buttons addObject:btn];
        [self.view addSubview:btn];
    }
}

- (void)selectedTab:(UIButton *)button{
    UIButton * btn = (UIButton *)[self.buttons objectAtIndex:self.currentSelectedIndex];
    btn.selected = false;
    
    button.selected = true;
    if (self.currentSelectedIndex == button.tag) {
        return;
    }
    self.currentSelectedIndex = button.tag;
    self.selectedIndex = self.currentSelectedIndex;
}*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
@end
