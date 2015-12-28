//
//  AddUserViewController.m
//  HomeKinsa
//
//  Created by SoulJa on 15/7/30.
//  Copyright (c) 2015年 Mikai. All rights reserved.
//

#import "AddUserViewController.h"
#import "UserListTableViewController.h"
#import "GlobalData.h"
#import "TTNetworkHelper.h"
#import <SVProgressHUD.h>
#import "TTToolsHelper.h"
#import "AFNetworking.h"
#import "GetServerUrlViewController.h"
#import "HttpTool.h"
#import "DataBaseTool.h"

@interface AddUserViewController () <UIActionSheetDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate,UIPickerViewDelegate,UIScrollViewDelegate,UITextFieldDelegate>
/**昵称*/
@property (weak, nonatomic) IBOutlet UITextField *nickNameField;
/**头像按钮*/
@property (weak, nonatomic) IBOutlet UIButton *iconBtn;
/**点击头像按钮*/
- (IBAction)clickIconBtn:(id)sender;
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
/**点击添加按钮*/
- (IBAction)clickAddBtn:(id)sender;
/**UIImagePickerController*/
@property (nonatomic,strong) UIImagePickerController *ipc;
/**头像的image*/
@property (nonatomic,weak) UIImage *iconImage;
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
/**
 *  当前账号的id
 */
@property (nonatomic,copy) NSString *acc_id;
/**
 *  是否添加了头像
 */
@property (nonatomic,assign) BOOL isAddIconImage;
@end

@implementation AddUserViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //监测当前网络状态
    [HttpTool getCurrentNetworkStatus];
    
    /**
     *  2015-11-28 SoulJa
     *  添加textfield代理
     */
    self.nickNameField.delegate = self;
    self.cityField.delegate = self;
    
    self.navigationItem.title = @"添加家庭成员";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"login_back_icon"] style:UIBarButtonItemStyleBordered target:self action:@selector(goBack)];
    [self setupChooseBtn];
    
    //初始化isAddIconImage
    self.isAddIconImage = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //监听添加用户成功
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addMemberSuccessNotification) name:@"AddMemberSuccessNotification" object:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"AddMemberSuccessNotification" object:nil];
}

- (void)addMemberSuccessNotification
{
    UIStoryboard *board = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UserListTableViewController *userListVc = [board instantiateViewControllerWithIdentifier:@"UserListTableViewController"];
    [self.navigationController pushViewController:userListVc animated:YES];
}

/**
 *  懒加载acc_id
 */
- (NSString *)acc_id
{
    if (_acc_id == nil) {
        NSDictionary *dict = [DataBaseTool getDefaultMember];
        self.acc_id = dict[@"acc_id"];
    }
    return _acc_id;
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
}

/**
 *  返回
 */
- (void)goBack
{
    UIViewController *userListVc = [[UserListTableViewController alloc] init];
    [self.navigationController pushViewController:userListVc animated:YES];
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
- (IBAction)clickIconBtn:(id)sender
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"请选择" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:@"相册" otherButtonTitles:@"拍照", nil];
    [actionSheet showInView:self.view];
}



- (IBAction)clickAddBtn:(UIButton *)sender
{
    [self.view endEditing:YES];
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
//    //保存按钮不能点击
//    sender.enabled = NO;
    
    /**
     *  添加成员需要分为两种情况
     *  1.一种是没有添加头像的
     *  2.一种是添加了头像的
     */
    
    if (!self.isAddIconImage || self.isAddIconImage == NO) { //添加的头像为系统默认头像
        [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
            [HttpTool addMemberWithName:self.nickNameField.text Sex:[NSString stringWithFormat:@"%d",(int)self.selectedBtn.tag] City:self.cityField.text Birth:self.birthLabel.text Addr:self.cityField.text Acc_id:self.acc_id];
    } else { //有头像的时候
        [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
        [HttpTool addMemberWithName:self.nickNameField.text Sex:[NSString stringWithFormat:@"%d",(int)self.selectedBtn.tag] City:self.cityField.text Birth:self.birthLabel.text Addr:self.cityField.text Acc_id:self.acc_id IconImage:[self.iconBtn backgroundImageForState:UIControlStateNormal]];
    }
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
    ipc.navigationBar.tintColor = [UIColor blackColor];
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
    ;
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
    [picker dismissViewControllerAnimated:YES completion:^{
        [self.iconBtn setBackgroundImage:info[UIImagePickerControllerOriginalImage] forState:UIControlStateNormal];
        self.iconImage = info[UIImagePickerControllerOriginalImage];
        self.isAddIconImage = YES;
    }];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.view endEditing:YES];
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
