//
//  UserSettingUIViewController.m
//  HomeKinsa
//
//  Created by Zhang guangchun on 15/5/8.
//  Copyright (c) 2015年 Mikai. All rights reserved.
//

#import "UserSettingUIViewController.h"
#import "UIImage+ImageEffects.h"
#import "GlobalData.h"
#import "SettingBirthUITableViewCell.h"
#import "SettingLocationUITableViewCell.h"
#import "SettingSexUITableViewCell.h"
#import "TTNetworkHelper.h"
#import "TTToolsHelper.h"
#import <UIImageView+WebCache.h>
#import "SettingHeadIconTableViewCell.h"
@interface UserSettingUIViewController ()

@end

@implementation UserSettingUIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.navigationController.navigationBar setTranslucent:NO];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageWithColor:COLOR_NAV_BACKGROUND] forBarMetrics:UIBarMetricsDefault];
    
    GlobalData *gd = [GlobalData sharedData];
    for (int i=0;i<gd.members.count;i++){
        NSDictionary *member = [gd.members objectAtIndex:i];
        int mid = [[member objectForKey:@"id"] intValue];
        if (mid==[gd.nowMemberId intValue]) {
            self.memberObj = member;
            break;
        }
    }
    
    //设置初始值
    [self setupInitUserInfo];
    
    self.profileImage = nil;
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView reloadData];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapView:)];
    [self.view addGestureRecognizer:tap];
    self.keyboardHeight = 0;
}

/**
 *  设置用户初始值
 */
- (void)setupInitUserInfo
{
    [self onClickMan:nil];
}

- (void)onTapView:(id)sender{
    [self.setLocation resignFirstResponder];
}

- (void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeUserInfoSucceedDelegate:) name:@"CHANGE_USEINFO_SUCCEED" object:nil];
}

- (void)changeUserInfoSucceedDelegate:(id)sender{
    if (self.profileImage==nil) {
        [[TTToolsHelper shared] showAlertMessage:@"保存信息成功！"];
    }
    else {
        [[TTNetworkHelper sharedSession] accountSetIcon:-1 image:self.profileImage dismissProgressView:YES];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onClickBack:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onClickSave:(id)sender {
    GlobalData *gd = [GlobalData sharedData];
    NSString *name = [self.memberObj objectForKey:@"name"];
    int sex = self.chooseManIcon.hidden?0:1;
    NSString *city = self.setLocation.text;
    NSString *birth = self.birth.text;

    for (int i=0; i<gd.members.count; i++) {
        NSMutableDictionary *member = [gd.members objectAtIndex:i];
        NSString *mid = [NSString stringWithFormat:@"%@",[member objectForKey:@"id"]];
        if ([mid isEqualToString:gd.nowMemberId]) {
            [member setObject:name forKey:@"name"];
            [member setObject:city forKey:@"city"];
            [member setObject:birth forKey:@"birth"];
            [member setObject:[NSNumber numberWithInt:sex] forKey:@"sex"];
            [gd saveData];
            break;
        }
    }
    
    [[TTNetworkHelper sharedSession] changeMemberInfo:gd.nowMemberId Name:name Sex:sex City:city Birth:birth dismissProgressView:YES];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 5;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section{
    return @"";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 61;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSUInteger section = [indexPath section];
    if (section==1) {
        SettingSexUITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[NSString stringWithFormat:@"setting%lu", (unsigned long)section]];
        int sex = [[self.memberObj objectForKey:@"sex"] intValue];
        cell.chooseManIcon.hidden = (sex!=1);
        cell.chooseWomanIcon.hidden = (sex==1);
        self.chooseManIcon = cell.chooseManIcon;
        self.chooseWoManIcon = cell.chooseWomanIcon;
        return cell;
    }
    else if (section==2){
        SettingBirthUITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[NSString stringWithFormat:@"setting%lu", (unsigned long)section]];
        cell.birthLabel.text = [self.memberObj objectForKey:@"birth"];
        self.birth = cell.birthLabel;
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onChooseBirthView:)];
        [cell.contentView addGestureRecognizer:tap];
        return cell;
    }
    else if (section==3){
        SettingLocationUITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[NSString stringWithFormat:@"setting%lu", (unsigned long)section]];
        cell.locationTextInput.text = [self.memberObj objectForKey:@"city"];
        cell.locationTextInput.delegate = self;
        self.setLocation = cell.locationTextInput;
        return cell;
    }
    else if (section==0){
        SettingHeadIconTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[NSString stringWithFormat:@"setting%lu", (unsigned long)section]];
        if (self.profileImage){
            cell.profileImage.image = self.profileImage;
        }else{
            GlobalData *gd = [GlobalData sharedData];
            NSString *url = [NSString stringWithFormat:@"http://%@/icons/%@.jpg",[gd connectUrl], gd.iconId];
            [cell.profileImage sd_setImageWithURL:[NSURL URLWithString:url] placeholderImage:[UIImage imageNamed:@"top_head_icon"]];
        }
        cell.previousController = self;
        return cell;
    }
    
    return [tableView dequeueReusableCellWithIdentifier:[NSString stringWithFormat:@"setting%lu", (unsigned long)section]];
}

- (IBAction)onClickMan:(id)sender {
    self.chooseWoManIcon.hidden = YES;
    self.chooseManIcon.hidden = NO;
}

- (IBAction)onClickWoman:(id)sender {
    self.chooseWoManIcon.hidden = NO;
    self.chooseManIcon.hidden = YES;
}

- (void)onChooseBirthView:(id)sender{
    UIDatePicker *datePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height-214, 0, 0)];
    datePicker.tintColor = [UIColor whiteColor];
    datePicker.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.8];
    datePicker.datePickerMode = UIDatePickerModeDate;
    [datePicker addTarget:self action:@selector(dateChanged:) forControlEvents:UIControlEventValueChanged];
    UIView *maskView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    [maskView setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.868f]];
    [self.view addSubview:maskView];
    [maskView addSubview:datePicker];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onChooseBirthDate:)];
    [maskView addGestureRecognizer:tap];
}

-(void)dateChanged:(id)sender{
    UIDatePicker* control = (UIDatePicker*)sender;
    NSDate* _date = control.date;
    NSDateFormatter *dateFormater = [NSDateFormatter new];
    dateFormater.dateFormat = @"yyyy/MM/dd";
    self.birth.text = [dateFormater stringFromDate:_date];
}

- (void)onChooseBirthDate:(id)sender{
    UITapGestureRecognizer *tap = (UITapGestureRecognizer *)sender;
    [tap.view removeFromSuperview];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    NSInteger section = [indexPath section];
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (section==1) {
    }
    else if (section==2){
    }
    else if (section==3){
        
    }
    else if (section==4){
        
    }
}

- (void)hsDatePickerWillDismissWithQuitMethod:(HSDatePickerQuitMethod)method{
    
}

- (void)hsDatePickerDidDismissWithQuitMethod:(HSDatePickerQuitMethod)method{
    
}

- (void)hsDatePickerPickedDate:(NSDate *)date{
    NSDateFormatter *dateFormater = [NSDateFormatter new];
    dateFormater.dateFormat = @"yyyy.M.d";
    self.birth.text = [dateFormater stringFromDate:date];
}

#pragma mark - Keyboard delegate

-(void) keyboardWillShow:(NSNotification *)note{
    CGRect keyboardBounds;
    [[note.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue: &keyboardBounds];
    //    if (self.keyboardHeight > keyboardBounds.size.height) return;
    self.keyboardHeight = keyboardBounds.size.height;
    self.keyboardIsShowing = YES;
    if ([UIScreen mainScreen].bounds.size.height<=480) {
        if (self.keyboardIsShowing == NO) {
            self.orgViewY = 0;//parentView.frame.origin.y;
            self.keyboardIsShowing = YES;
        }
        
        [UIView animateWithDuration:0.5f animations:^{
            UIView *parentView = self.navigationController.view;
            parentView.frame = CGRectMake(parentView.frame.origin.x, self.orgViewY - self.keyboardHeight, parentView.frame.size.width, parentView.frame.size.height);
        } completion:^(BOOL finished) {
            [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
        }];
    }
    else {
        //    if (self.keyboardIsShowing == NO) {
        [UIView animateWithDuration:0.5f animations:^{
            /*UIView *parentView = self.createNewAnswerView;//self.view;
             parentView.frame = CGRectMake(parentView.frame.origin.x, parentView.frame.origin.y - self.keyboardHeight, parentView.frame.size.width, parentView.frame.size.height);*/
            //            self.buttomViewVerticalSpace.constant =self.keyboardHeight;
            self.tableView.frame = CGRectMake(self.tableView.frame.origin.x, -60, self.tableView.frame.size.width, self.tableView.frame.size.height);
        } completion:^(BOOL finished) {}];
        //    }
    }
}

- (void)keyboardWillHide:(NSNotification*)notification {
    if (!self.keyboardIsShowing) {
        return;
    }
    if (self.keyboardIsShowing == YES){
        self.keyboardIsShowing = NO;
        if ([UIScreen mainScreen].bounds.size.height<=480) {
            [UIView animateWithDuration:0.25f animations:^{
                UIView *parentView = self.navigationController.view;
                parentView.frame = CGRectMake(parentView.frame.origin.x, self.orgViewY, parentView.frame.size.width, parentView.frame.size.height);
            } completion:^(BOOL finished) {
                [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
            }];
        }
        else {
            [UIView animateWithDuration:0.5f animations:^{
                /*UIView *parentView = self.createNewAnswerView;//self.view;
                 parentView.frame = CGRectMake(parentView.frame.origin.x, parentView.frame.origin.y + self.keyboardHeight, parentView.frame.size.width, parentView.frame.size.height);*/
                //                self.buttomViewVerticalSpace.constant = 0;//-=self.keyboardHeight;
                self.keyboardHeight = 0;
                self.tableView.frame = CGRectMake(self.tableView.frame.origin.x, 0, self.tableView.frame.size.width, self.tableView.frame.size.height);
            } completion:^(BOOL finished) {}];
        }
    }
}

@end
