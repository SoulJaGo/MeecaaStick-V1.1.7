//
//  SettingsMainViewController.m
//  HomeKinsa
//
//  Created by Zhang guangchun on 15/3/4.
//  Copyright (c) 2015年 Mikai. All rights reserved.
//

#import "SettingsMainViewController.h"
#import "GlobalData.h"
#import "UIImage+ImageEffects.h"
#import "SettingsMainSetTableViewCell.h"
#import "LoginViewController.h"
#import "changshiViewController.h"

//ShareSDK引入
#import <ShareSDK/ShareSDK.h>
/*
#import <TencentOpenAPI/QQApi.h>*/
#import <TencentOpenAPI/QQApiInterface.h>
#import <TencentOpenAPI/TencentOAuth.h>
#import <QZoneConnection/ISSQZoneApp.h>
#import "WXApi.h"
#import "WeiboSDK.h"
#import "DataBaseTool.h"
#import "Account.h"

typedef enum
{
    CurrentLoginStatusPhoneNumber=0,
    CurrentLoginStatusSinaWeiBo = 1,
    CurrentLoginStatusQQ = 2,
    CurrentLoginStatusWeiXin = 3,
    CurrentLoginStatusNone = 4
}CurrentLoginStatus;

@interface SettingsMainViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *settingTableView;
@end

@implementation SettingsMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationController.navigationBar setTranslucent:NO];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageWithColor:COLOR_NAV_BACKGROUND] forBarMetrics:UIBarMetricsDefault];
    
    self.settingTableView.delegate = self;
    self.settingTableView.dataSource = self;
}




- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.settingTableView reloadData];
}

- (IBAction)onClickBack:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 8;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section{
    return @"";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if ([indexPath section]==0||[indexPath section]==2||[indexPath section]==4||[indexPath section]==6) {
        return 16;
    }
    return 66;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSUInteger section = [indexPath section];
    if (section==1) {
        SettingsMainSetTableViewCell *cell = (SettingsMainSetTableViewCell *)[tableView dequeueReusableCellWithIdentifier:[NSString stringWithFormat:@"setting%lu", (unsigned long)section]];
        GlobalData *gd = [GlobalData sharedData];
        int type = (gd.temperatureType!=nil&&[gd.temperatureType intValue]==2)?2:1;
        cell.temperatureLabel.text = (type==1?@"摄氏度":@"华氏度");
        return cell;
    }
    
    return [tableView dequeueReusableCellWithIdentifier:[NSString stringWithFormat:@"setting%lu", (unsigned long)section]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    NSInteger section = [indexPath section];
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (section==1) {
        [self performSegueWithIdentifier:@"goSetSegue" sender:nil];
    }
//    else if (section==3){
//        [self performSegueWithIdentifier:@"goVerSegue" sender:nil];
//    }
    else if (section==3){
        //友盟统计
        [MobClick event:@"aboutus"];
        [self performSegueWithIdentifier:@"goAboutSegue" sender:nil];
    }
    
    //点击体温小常识
    else if (section == 5) {
        //友盟统计
        [MobClick event:@"knowledge"];
        changshiViewController *changshiVc = [[changshiViewController alloc] init];
        [self.navigationController pushViewController:changshiVc animated:YES];
    }
    

    //点击退出登录
    else if (section == 7) {
        //友盟统计
        [MobClick event:@"logout"];
        [self logout];
    }
}

/**
 *  退出登陆
 */
- (void)logout
{
    UIStoryboard *board = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *loginVc = [board instantiateViewControllerWithIdentifier:@"LoginViewController"];
    [self presentViewController:loginVc animated:YES completion:^{
        //取消第三方登陆的授权信息
//        [ShareSDK cancelAuthWithType:ShareTypeSinaWeibo];
//        [ShareSDK cancelAuthWithType:ShareTypeQQSpace];
//        [ShareSDK cancelAuthWithType:ShareTypeWeixiSession];
        
        //清空用户记录
        [[GlobalData sharedData] emptyData];
        
        /*
        //清空默认选择的用户
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setInteger:0 forKey:@"selectedMember"];
        [defaults synchronize];
         */
        NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        NSString *path = [docDir stringByAppendingPathComponent:@"account.archive"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            Account *account = [[Account alloc] init];
            if (account.platForm == CurrentLoginStatusQQ) {
                [ShareSDK cancelAuthWithType:ShareTypeQQSpace];
            } else if (account.platForm == CurrentLoginStatusSinaWeiBo) {
                [ShareSDK cancelAuthWithType:ShareTypeSinaWeibo];
            } else if (account.platForm == CurrentLoginStatusWeiXin) {
                [ShareSDK cancelAuthWithType:ShareTypeWeixiSession];
            }
            account.telephone = @"";
            account.password = @"";
            account.openID = @"";
            account.platForm = CurrentLoginStatusNone;
            [NSKeyedArchiver archiveRootObject:account toFile:path];
        }
        //清空数据库
        BOOL result = [DataBaseTool emptyDataBase];
        if (!result) {
            NSLog(@"清空数据失败!");
        }
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
