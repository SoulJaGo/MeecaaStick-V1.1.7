//
//  UserListTableViewController.m
//  HomeKinsa
//
//  Created by SoulJa on 15/7/27.
//  Copyright (c) 2015年 Mikai. All rights reserved.
//

#import "UserListTableViewController.h"
#import "GlobalData.h"
#import "addUserViewController.h"
#import "UserUpdateViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "AFNetworking.h"
#import <SVProgressHUD.h>
#import "TTToolsHelper.h"
#import "GetServerUrlViewController.h"
#import "HttpTool.h"
#import "DataBaseTool.h"

@interface UserListTableViewController () <UITableViewDataSource,UITableViewDelegate,UIActionSheetDelegate>
@property (nonatomic,strong) NSMutableArray *members;
@property (nonatomic,copy) NSString *willRemoveMemberId;
@end

@implementation UserListTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //监测当前网络状态
    [HttpTool getCurrentNetworkStatus];
    [self setupNav];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    //如果获取的成员数量为0活着不存在则需要登陆
    if (self.members == nil || self.members.count == 0) {
        UIStoryboard *board = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        UIViewController *vc = [board instantiateViewControllerWithIdentifier:@"LoginViewController"];
        [self presentViewController:vc animated:YES completion:nil];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //监听删除成员的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeMemberSuccessNotification) name:@"RemoveMemberSuccessNotification" object:nil];
    //监听设置默认成员成功的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setDefaultMemberSuccessNotification) name:@"SetDefaultMemberSuccessNotification" object:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    //移除删除成员的通知
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"RemoveMemberSuccessNotification" object:nil];
    //移除设置默认成员成功的通知
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"SetDefaultMemberSuccessNotification" object:nil];
}

- (void)removeMemberSuccessNotification
{
    [self.tableView reloadData];
}

- (void)setDefaultMemberSuccessNotification
{
    [self.tableView reloadData];
    UIStoryboard *board = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *vc = [board instantiateViewControllerWithIdentifier:@"MainTabBarViewController"];
    [self presentViewController:vc animated:YES completion:^{
        [SVProgressHUD dismiss];
    }];
}

/**
 *  设置NavigationBar
 */
- (void)setupNav
{
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName:[UIColor whiteColor]};
    self.title = @"家庭成员信息";
    [self.navigationController.navigationBar setTranslucent:NO];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"login_back_icon"] style:UIBarButtonItemStyleBordered target:self action:@selector(goBack)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"add_user"] style:UIBarButtonItemStyleDone target:self action:@selector(addUser)];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
}

- (void)goBack
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)addUser
{
    UIStoryboard *board = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *addVc = [board instantiateViewControllerWithIdentifier:@"AddUserViewController"];
    [self.navigationController pushViewController:addVc animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.members.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    NSDictionary *memberInfoDict = self.members[indexPath.section];
    UILabel *nickNameLabel = [[UILabel alloc] init];
    nickNameLabel.frame = CGRectMake(70, 0, 150, 60);
    nickNameLabel.textColor = [UIColor lightGrayColor];
    if (memberInfoDict[@"name"]) {
        nickNameLabel.text = memberInfoDict[@"name"];
    } else {
        nickNameLabel.text = @"";
    }
    [cell.contentView addSubview:nickNameLabel];
    
    //设置头像
    UIImageView *iconImageView = [[UIImageView alloc] init];
    iconImageView.frame = CGRectMake(15, 8, 44, 44);
    [iconImageView.layer setCornerRadius:22];
    [iconImageView.layer setMasksToBounds:YES];
    if ([memberInfoDict[@"avatar"] isEqualToString:@""] || memberInfoDict[@"avatar"] == nil) { //如果没有头像
        [iconImageView setImage:[UIImage imageNamed:@"user_icon_button"]];
    } else {
        [iconImageView sd_setImageWithURL:[NSURL URLWithString:memberInfoDict[@"avatar"]] placeholderImage:[UIImage imageNamed:@"user_icon_button"]];
    }
    [cell.contentView addSubview:iconImageView];
    
    //取出选中的成员
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(0, 0, 44, 44);
    btn.tag = indexPath.section;
    cell.accessoryView = btn;
    NSString *isdefaultStr = [NSString stringWithFormat:@"%@",[memberInfoDict objectForKey:@"isdefault"]];
    if ([isdefaultStr isEqualToString:@"1"]) { //如果是被选中的成员
        [btn setImage:[UIImage imageNamed:@"check_choose_icon"] forState:UIControlStateNormal];
        btn.userInteractionEnabled = NO;
    } else { //如果不是被选中的成员
        [btn  setImage:[UIImage imageNamed:@"003-01"] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(chooseSelectedMember:) forControlEvents:UIControlEventTouchUpInside];
    }
    return cell;
}

/**
 *  设置选中成员
 */
- (void)chooseSelectedMember:(UIButton *)btn
{
    //读取被选中的成员
    NSDictionary *nowSelectedMemberInfoDict = self.members[(int)btn.tag];
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
    NSString *acc_id = [NSString stringWithFormat:@"%@",nowSelectedMemberInfoDict[@"acc_id"]];
    NSString *mid = [NSString stringWithFormat:@"%@",nowSelectedMemberInfoDict[@"id"]];
    [HttpTool setDefaultMemberWithAcc_id:acc_id Mid:mid];
    //发送网络请求
    /*
    NSString *host = [GetServerUrlViewController getServerUrl];
    NSString *urlStr = [NSString stringWithFormat:@"http://%@/api.php?m=open&c=member&a=defaultSet",host];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"acc_id"] = nowSelectedMemberInfoDict[@"acc_id"];
    params[@"mid"] = nowSelectedMemberInfoDict[@"id"];
    AFHTTPRequestOperationManager *mgr = [AFHTTPRequestOperationManager manager];
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
    [mgr POST:urlStr parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        GlobalData *gd = [GlobalData sharedData];
        for (int i = 0; i < gd.members.count;i++) {
            if (i == (int)btn.tag) {
                gd.members[i] = responseObject[@"data"];
            } else {
                NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:gd.members[i]];
                dict[@"isdefault"] = @"0";
                gd.members[i] = dict;
            }
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SELECTED_MEMBER_CHANGED" object:nil];
        [self.tableView reloadData];
        UIStoryboard *board = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        UIViewController *vc = [board instantiateViewControllerWithIdentifier:@"MainTabBarViewController"];
        [self presentViewController:vc animated:YES completion:^{
            [SVProgressHUD dismiss];
        }];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@",error);
    }];
    */
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *memberInfoDict = self.members[indexPath.section];
    UIStoryboard *board = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UserUpdateViewController *vc = [board instantiateViewControllerWithIdentifier:@"UserUpdateViewController"];
    vc.memberInfoDict = memberInfoDict;
    vc.section = (int)indexPath.section;
    [self.navigationController pushViewController:vc animated:YES];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //获取默认选中用户
    NSDictionary *dict = self.members[indexPath.section];
    NSString *isdefaultStr = [NSString stringWithFormat:@"%@",dict[@"isdefault"]];
    if ([isdefaultStr isEqualToString:@"1"]) {
        return UITableViewCellEditingStyleNone;
    } else {
        return UITableViewCellEditingStyleDelete;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        //取出需要删除成员的信息
        NSDictionary *memberInfo = self.members[indexPath.section];
        NSString *member_id = [NSString stringWithFormat:@"%@",memberInfo[@"id"]];
        self.willRemoveMemberId = member_id;
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"删除家庭成员?" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:@"确定" otherButtonTitles:nil];
        [actionSheet showInView:self.view];
    }
}

#pragma mark - 新加入代码
- (NSMutableArray *)members
{
    //从数据库中获取所有成员
    return [DataBaseTool getAllMembers];
}

#pragma mark - 2015-10-12 新加代码
/**
 *  SoulJa 2015-10-12
 *  显示状态栏
 */
- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}

#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) { //确定删除
        if (self.willRemoveMemberId != nil) {
            [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
            [HttpTool removeMember:self.willRemoveMemberId];
        }
    } else {
        return;
    }
}
@end
