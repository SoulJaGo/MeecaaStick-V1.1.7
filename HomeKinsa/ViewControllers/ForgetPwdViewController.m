//
//  ForgetPwdViewController.m
//  HomeKinsa
//
//  Created by SoulJa on 15/8/2.
//  Copyright (c) 2015年 Mikai. All rights reserved.
//

#import "ForgetPwdViewController.h"
#import "TTToolsHelper.h"
#import "TTNetworkHelper.h"
#import "HttpTool.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import "UIImage+ImageEffects.h"

@interface ForgetPwdViewController () <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *PhoneNumberField;
@property (weak, nonatomic) IBOutlet UITextField *CodeField;
@property (weak, nonatomic) IBOutlet UITextField *PasswordField;
@property (weak, nonatomic) IBOutlet UITextField *RePasswordField;
- (IBAction)GetCode:(id)sender;
- (IBAction)UpdatePwd:(id)sender;
- (IBAction)GetNoCode:(id)sender;
@end

@implementation ForgetPwdViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //友盟统计
    [MobClick event:@"forgetpassword"];
    
    /**
     *  加入键盘监听事件
     */
    self.PhoneNumberField.delegate = self;
    self.CodeField.delegate = self;
    self.PasswordField.delegate = self;
    self.RePasswordField.delegate = self;
    
    [self setupNav];
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (void)viewWillAppear:(BOOL)animated{
    self.navigationController.navigationBarHidden = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getCodeSucceedDelegate:) name:@"GETCODE_SUCCEED" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePwdDelegate:) name:@"UPDATEPWD_SUCCEED" object:nil];
}

- (void)viewWillDisappear:(BOOL)animated{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"GETCODE_SUCCEED" object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UPDATEPWD_SUCCEED" object:nil];
}

- (IBAction)GetCode:(id)sender
{
    if ([self.PhoneNumberField.text isEqualToString:@""]) {
        [[TTToolsHelper shared] showNoticetMessage:@"请填写手机号码!" handler:^{
            
        }];
        return;
    }
    [HttpTool getResetPwdVerifyCode:self.PhoneNumberField.text];
    /*
    [[TTNetworkHelper sharedSession] accountRestPwdSMSByPhoneNumber:self.PhoneNumberField.text dismissProgressView:YES];
     */
}

- (void)getCodeSucceedDelegate:(id)sender{
    [[TTToolsHelper shared] showNoticetMessage:@"获取验证码成功，请5分钟内使用！" handler:^{
    }];
}

- (void)updatePwdDelegate:(id)sender
{
    [[TTToolsHelper shared] showNoticetMessage:@"密码修改成功，请重新登陆!" handler:^{
        [self dismissViewControllerAnimated:YES completion:^{
            [SVProgressHUD dismiss];
        }];
    }];
}

- (IBAction)UpdatePwd:(id)sender
{
    [self.view endEditing:YES];
    
    if ([self.PhoneNumberField.text isEqualToString:@""]) {
        [[TTToolsHelper shared] showNoticetMessage:@"此号码还没有注册!" handler:^{
        }];
    } else if (![[TTToolsHelper shared] isMobileNumberClassification:self.PhoneNumberField.text]) {
        [[TTToolsHelper shared] showAlertMessage:@"此号码还没有注册!"];
        return;
    } else if ([self.CodeField.text isEqualToString:@""]) {
        [[TTToolsHelper shared] showNoticetMessage:@"请填写验证码！" handler:^{
        }];
    } else if ([self.PasswordField.text isEqualToString:@""]) {
        [[TTToolsHelper shared] showNoticetMessage:@"请填写密码！" handler:^{
        }];
    } else if (self.PasswordField.text.length < 6) {
        [[TTToolsHelper shared] showNoticetMessage:@"请填写不少于6位的密码！" handler:^{
        }];
    } else if (![self.PasswordField.text isEqualToString:self.RePasswordField.text]) {
        NSLog(@"%@",self.PasswordField.text);
        NSLog(@"%@",self.RePasswordField.text);
        [[TTToolsHelper shared] showNoticetMessage:@"请填写两次相同的密码！" handler:^{
        }];
    } else {
        /*
        [[TTNetworkHelper sharedSession] accountRestPwdByPhoneNumber:self.PhoneNumberField.text newPwd:self.PasswordField.text code:self.CodeField.text dismissProgressView:YES];
         */
        [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
        [HttpTool resetAccountPasswordByPhoneNumber:self.PhoneNumberField.text NewPwd:self.PasswordField.text Code:self.CodeField.text];
        
    }
}


- (IBAction)GetNoCode:(id)sender
{
    [[TTToolsHelper shared] showCodeUnavailableDialog:self];
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

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}
@end
