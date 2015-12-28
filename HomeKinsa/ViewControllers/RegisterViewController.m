//
//  RegisterViewController.m
//  HomeKinsa
//
//  Created by Zhang guangchun on 15/3/11.
//  Copyright (c) 2015年 Mikai. All rights reserved.
//

#import "RegisterViewController.h"
#import "TTNetworkHelper.h"
#import "UIViewController+ProgressHUD.h"
#import <SVProgressHUD.h>
#import "GlobalData.h"
#import "UIImage+ImageEffects.h"
#import "TTToolsHelper.h"
#import "HttpTool.h"

@interface RegisterViewController () <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UIView *winView;
@property (weak, nonatomic) IBOutlet UITextField *inputPhoneNum;
@property (weak, nonatomic) IBOutlet UITextField *inputCodeNum;
@property (weak, nonatomic) IBOutlet UITextField *inputNickName;
@property (weak, nonatomic) IBOutlet UITextField *inputPwd;
@end

@implementation RegisterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //监测网络状态
    [HttpTool getCurrentNetworkStatus];
    
    /**
     *  2015-11-28 SoulJa
     *  加入键盘监听事件
     */
    self.inputPhoneNum.delegate = self;
    self.inputCodeNum.delegate = self;
    self.inputNickName.delegate = self;
    self.inputPwd.delegate = self;
    
    [self setupNav];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapView:)];
    [self.view addGestureRecognizer:tap];
}

- (void)setupNav
{
    [self.navigationController.navigationBar setTranslucent:NO];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageWithColor:COLOR_NAV_BACKGROUND] forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"login_back_icon"] style:UIBarButtonItemStyleBordered target:self action:@selector(goBack)];
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
}

/**
 *  返回
 */
- (void)goBack
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewWillAppear:(BOOL)animated{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(registerSucceedNotification) name:@"RegisterSuccessNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getCodeSucceedDelegate:) name:@"GETCODE_SUCCEED" object:nil];
}

- (void)viewWillDisappear:(BOOL)animated{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"RegisterSuccessNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"GETCODE_SUCCEED" object:nil];
}

- (IBAction)onClickBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)getCodeSucceedDelegate:(id)sender{
    [[TTToolsHelper shared] showNoticetMessage:@"获取验证码成功，请5分钟内注册！" handler:^{
    }];
}


- (IBAction)onClickGetCode:(id)sender {
    [self onTapView:nil];
    if ([self.inputPhoneNum.text isEqualToString:@""]) {
        [[TTToolsHelper shared] showAlertMessage:@"请填写手机号码!"];
        return;
    }
    
    [HttpTool getRegistVerifyCode:self.inputPhoneNum.text];
    //原先获取验证码的方法
    /*
    [[TTNetworkHelper sharedSession] getAccountCodeByPhoneNumber:self.inputPhoneNum.text dismissProgressView:YES];*/
    
}

- (IBAction)onClickSure:(id)sender {
    [self.view endEditing:YES];
    
    if ([self.inputPhoneNum.text isEqualToString:@""]) {
        [[TTToolsHelper shared] showAlertMessage:@"请填写手机号码!"];
        return;
    }
    if (![[TTToolsHelper shared] isMobileNumberClassification:self.inputPhoneNum.text]) {
        [[TTToolsHelper shared] showAlertMessage:@"手机号码填写错误！"];
        return;
    }
    if ([[TTToolsHelper shared] isHaveIllegalChar:self.inputNickName.text]) {
        self.inputNickName.text = @"";
        [[TTToolsHelper shared] showAlertMessage:@"昵称包含非法字符，请重新填写！"];
        return;
    }
    if ([self.inputPwd.text isEqualToString:@""]) {
        [[TTToolsHelper shared] showAlertMessage:@"请填写密码！"];
        return;
    }
    if (self.inputPwd.text.length < 6) {
        [[TTToolsHelper shared] showAlertMessage:@"请填写密码！"];
        return;
    }
    if ([self.inputCodeNum.text isEqualToString:@""]) {
        [[TTToolsHelper shared] showAlertMessage:@"请填写验证码!"];
        return;
    }
    
    if ([self.inputNickName.text isEqualToString:@""]) {
        [[TTToolsHelper shared] showAlertMessage:@"请填写昵称！"];
        return;
    }
    [self onTapView:nil];
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
    [HttpTool registerAccountWithPhoneNumber:self.inputPhoneNum.text NickName:self.inputNickName.text Password:self.inputPwd.text registerCode:self.inputCodeNum.text];
    
    
}

- (void)onTapView:(id)sender{
    [self.inputPhoneNum resignFirstResponder];
    [self.inputCodeNum resignFirstResponder];
    [self.inputNickName resignFirstResponder];
    [self.inputPwd resignFirstResponder];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onClickUnregister:(id)sender {
    [[TTToolsHelper shared] showCodeUnavailableDialog:self];
}

#pragma mark - 新加入代码
- (void)registerSucceedNotification
{
    [[TTToolsHelper shared] showNoticetMessage:@"注册成功!" handler:^{
        UIStoryboard *board = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        UIViewController *vc = [board instantiateViewControllerWithIdentifier:@"MainTabBarViewController"];
        [self presentViewController:vc animated:YES completion:nil];
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

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}
@end
