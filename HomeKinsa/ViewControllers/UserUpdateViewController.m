//
//  UserUpdateViewController.m
//  HomeKinsa
//
//  Created by SoulJa on 15/8/1.
//  Copyright (c) 2015年 Mikai. All rights reserved.
//

#import "UserUpdateViewController.h"
#import "TTToolsHelper.h"
#import "TTNetworkHelper.h"
#import <SVProgressHUD.h>
#import "UserListTableViewController.h"
#import "AFNetworking.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "GetServerUrlViewController.h"
#import "HttpTool.h"
#import "DataBaseTool.h"

@interface UserUpdateViewController () <UIActionSheetDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate,UIPickerViewDelegate,UITextFieldDelegate>
/**昵称*/
@property (weak, nonatomic) IBOutlet UITextField *nickNameField;
/**男性头像按钮*/
@property (weak, nonatomic) IBOutlet UIButton *maleBtn;
/**女性头像按钮*/
@property (weak, nonatomic) IBOutlet UIButton *femaleBtn;
/**点击男性头像按钮*/
- (IBAction)clickMaleBtn:(id)sender;
/**点击女性头像按钮*/
- (IBAction)clickFemaleBtn:(id)sender;
/**出生日期*/
@property (weak, nonatomic) IBOutlet UILabel *birthLabel;
/**城市*/
@property (weak, nonatomic) IBOutlet UITextField *cityField;
/**添加按钮*/
@property (weak, nonatomic) IBOutlet UIButton *addBtn;
/**UIImagePickerController*/
@property (nonatomic,strong) UIImagePickerController *ipc;
/**现在的iconImage*/
@property (nonatomic,weak) UIImage *currentIconImage;
/**头像的imageView*/
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
/**选择的性别按钮*/
@property (nonatomic,weak) UIButton *selectedBtn;
/**男性选择图像*/
@property (nonatomic,weak) UIImageView *maleImageView;
/**女性选择图像*/
@property (nonatomic,weak) UIImageView *femaleImageView;
/**生日*/
@property (nonatomic,strong) UIDatePicker *datePicker;
/**
 *  生日上方的选择按钮
 */
@property (nonatomic,strong) UIView *datePickerHeaderView;
- (IBAction)clickSaveBtn:(id)sender;
@end

@implementation UserUpdateViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    /**
     *  2015-11-28 SoulJa
     *  textfield添加代理时间
     */
    self.cityField.delegate = self;
    self.nickNameField.delegate = self;
    
    [self setupNav];
    [self setupChooseBtn];
    [self setupInitUserInfo];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //监听修改成员的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateMemberSuccessNotification) name:@"UpdateMemberSuccessNotification" object:nil];
}

- (void)updateMemberSuccessNotification
{
    UIStoryboard *board = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *vc = [board instantiateViewControllerWithIdentifier:@"UserListTableViewController"];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UpdateMemberSuccessNotification" object:nil];
}

- (void)setupInitUserInfo
{
    self.nickNameField.text = self.memberInfoDict[@"name"];
    if ([self.memberInfoDict[@"sex"] isEqualToString:@"0"]) {
        [self clickMaleBtn:self.maleBtn];
    } else {
        [self clickFemaleBtn:self.femaleBtn];
    }
    self.birthLabel.text = self.memberInfoDict[@"birth"];
    self.cityField.text = self.memberInfoDict[@"city"];
    
    if (self.memberInfoDict[@"avatar"]) {
        [self.iconImageView sd_setImageWithURL:[NSURL URLWithString:self.memberInfoDict[@"avatar"]] placeholderImage:[UIImage imageNamed:@"user_icon_button"]];
    } else {
        [self.iconImageView setImage:[UIImage imageNamed:@"user_icon_button"]];
    }
    
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickIconImageView)];
    self.iconImageView.userInteractionEnabled = YES;
    [self.iconImageView.layer setMasksToBounds:YES];
    [self.iconImageView.layer setCornerRadius:22];
    [self.iconImageView addGestureRecognizer:gestureRecognizer];
}

- (void)setupNav
{
    self.title = @"修改成员信息";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"login_back_icon"] style:UIBarButtonItemStyleDone target:self action:@selector(goBack)];
}

/**
 *  返回
 */
- (void)goBack
{
    UserListTableViewController *userListVc = [[UserListTableViewController alloc] init];
    [self.navigationController pushViewController:userListVc animated:YES];
}


- (void)setupChooseBtn
{
    //男性头像的tag
    self.maleBtn.tag = 0;
    //女性头像的tag
    self.femaleBtn.tag = 1;
    
    
    UIImageView *maleImageView = [[UIImageView alloc] init];
    maleImageView.image = [UIImage imageNamed:@"check_choose_icon"];
    maleImageView.frame = CGRectMake(self.maleBtn.frame.size.width - 20, self.maleBtn.frame.size.height - 20, 20, 20);
    maleImageView.hidden = YES;
    [self.maleBtn addSubview:maleImageView];
    self.maleImageView = maleImageView;
    
    UIImageView *femaleImageView = [[UIImageView alloc] init];
    femaleImageView.image = [UIImage imageNamed:@"check_choose_icon"];
    femaleImageView.frame = CGRectMake(self.femaleBtn.frame.size.width - 20, self.femaleBtn.frame.size.height - 20, 20, 20);
    femaleImageView.hidden = YES;
    [self.femaleBtn addSubview:femaleImageView];
    self.femaleImageView = femaleImageView;
    
    //初始化默认选择男性
    [self clickMaleBtn:self.maleBtn];
    
    //点击生日
    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickBirthLabel:)];
    self.birthLabel.userInteractionEnabled = YES;
    [self.birthLabel addGestureRecognizer:recognizer];
}

- (UIDatePicker *)datePicker
{
    if (_datePicker == nil) {
        self.datePicker = [[UIDatePicker alloc] init];
        self.datePicker.datePickerMode = UIDatePickerModeDate;
        self.datePicker.minimumDate = [[NSDate alloc] initWithTimeIntervalSince1970:0];
        [self.datePicker setBackgroundColor:[UIColor whiteColor]];
    }
    return _datePicker;
}

- (IBAction)clickSaveBtn:(UIButton *)sender
{
    [self.view endEditing:YES];
    //友盟统计
    [MobClick event:@"saveuserinfo"];
    
    if ([self.nickNameField.text isEqualToString:@""]) {
        [[TTToolsHelper shared] showNoticetMessage:@"请填写昵称" handler:^{}];
        return;
    } else if (self.nickNameField.text.length > 10) {
        [[TTToolsHelper shared] showNoticetMessage:@"昵称不能超过10个字符" handler:^{}];
        return;
    } else if ([self.birthLabel.text isEqualToString:@""]) {
        [[TTToolsHelper shared] showNoticetMessage:@"请选择生日" handler:^{}];
        return;
    } else if ([self.cityField.text isEqualToString:@""]) {
        [[TTToolsHelper shared] showNoticetMessage:@"请填写所在城市" handler:^{}];
        return;
    }
    
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
    
    
    //获取用户的mid
    NSString *mid = self.memberInfoDict[@"id"];
    //是否更换了图片
    BOOL isChangeIconImage;
    
    NSData *currentData = UIImagePNGRepresentation(self.currentIconImage);

    if (currentData == nil) { //表示没有新的选择的图形
        isChangeIconImage = NO;
    } else { //选择过头像
        isChangeIconImage = YES;
    }

    
    if (isChangeIconImage) { //如果用户头像和以前的头像不同了
        [HttpTool updateMemberWithMid:mid Name:self.nickNameField.text Sex:[NSString stringWithFormat:@"%d",(int)self.selectedBtn.tag] Birth:self.birthLabel.text City:self.cityField.text IconImage:self.iconImageView.image];
            } else {
        [HttpTool updateMemberWithMid:mid Name:self.nickNameField.text Sex:[NSString stringWithFormat:@"%d",(int)self.selectedBtn.tag] Birth:self.birthLabel.text City:self.cityField.text];
    }
         
}

- (void)clickBirthLabel:(UILabel *)label
{
    //去除键盘
    [self.view endEditing:YES];
    
    [self.view addSubview:self.datePickerHeaderView];
    
    self.datePicker.frame = CGRectMake(0, self.view.frame.size.height - 216, self.view.frame.size.width, 216);
    [self.view addSubview:self.datePicker];
}

/**
 *  懒加载datePickerHeaderView
 */
- (UIView *)datePickerHeaderView
{
    if (_datePickerHeaderView == nil) {
        _datePickerHeaderView = [[UIView alloc] init];
        _datePickerHeaderView.frame = CGRectMake(0, self.view.bounds.size.height - 260, self.view.bounds.size.width, 44);
        _datePickerHeaderView.backgroundColor = COLOR_NAV_BACKGROUND;
        UIButton *cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        cancelBtn.frame = CGRectMake(0, 0, 100, 44);
        [cancelBtn setTitle:@"取消" forState:UIControlStateNormal];
        cancelBtn.titleLabel.font = [UIFont systemFontOfSize:18 weight:18];
        [cancelBtn addTarget:self action:@selector(cancelSelectBirth) forControlEvents:UIControlEventTouchUpInside];
        [_datePickerHeaderView addSubview:cancelBtn];
        
        UIButton *selectBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        selectBtn.frame = CGRectMake(_datePickerHeaderView.bounds.size.width-100, 0, 100, 44);
        [selectBtn setTitle:@"完成" forState:UIControlStateNormal];
        selectBtn.titleLabel.font = [UIFont systemFontOfSize:18 weight:18];
        [selectBtn addTarget:self action:@selector(dataChange) forControlEvents:UIControlEventTouchUpInside];
        [_datePickerHeaderView addSubview:selectBtn];
    }
    return _datePickerHeaderView;
}

/**
 *  点击取消按钮
 */
- (void)cancelSelectBirth
{
    [_datePicker removeFromSuperview];
    [_datePickerHeaderView removeFromSuperview];
}

- (void)dataChange
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"YYYY-MM-dd";
    NSString *birthStr = [formatter stringFromDate:[self.datePicker date]];
    self.birthLabel.text = birthStr;
    [self.datePicker removeFromSuperview];
    [self.datePickerHeaderView removeFromSuperview];
    
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
    if (self.datePicker) {
        [self.datePicker removeFromSuperview];
    }
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
 *  点击头像按钮
 */
- (void)clickIconImageView
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"请选择" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:@"相册" otherButtonTitles:@"拍照", nil];
    [actionSheet showInView:self.view];
}

/**
 *  点击男性按钮
 */
- (IBAction)clickMaleBtn:(UIButton *)sender
{
    self.selectedBtn = sender;
    self.maleImageView.hidden = NO;
    self.femaleImageView.hidden = YES;
}

- (IBAction)clickFemaleBtn:(UIButton *)sender
{
    self.selectedBtn = sender;
    self.femaleImageView.hidden = NO;
    self.maleImageView.hidden = YES;
}

#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    //相册
    if (buttonIndex == 0) {
        [self showPhoto];
    }
    //拍照
    if (buttonIndex == 1) {
        [self showCamera];
    }
}

/**
 *  从相册中选取
 */
- (void)showPhoto
{
    UIImagePickerController *ipc = [[UIImagePickerController alloc] init];
    ipc.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [ipc.navigationBar setTintColor:[UIColor blackColor]];
    ipc.delegate = self;
    self.ipc = ipc;
    [self presentViewController:self.ipc animated:YES completion:nil];
}

/**
 *  从照相机选取
 */
- (void)showCamera
{
    UIImagePickerController *ipc = [[UIImagePickerController alloc] init];
    ipc.sourceType = UIImagePickerControllerSourceTypeCamera;
    ipc.allowsEditing = YES;
    ipc.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
    self.modalPresentationStyle = UIModalPresentationCurrentContext;
    ipc.delegate = self;
    self.ipc = ipc;
    [self presentViewController:self.ipc animated:YES completion:nil];
    
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [self.iconImageView setImage:info[UIImagePickerControllerOriginalImage]];
    self.currentIconImage = info[UIImagePickerControllerOriginalImage];
    [picker dismissViewControllerAnimated:YES completion:^{
        
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
