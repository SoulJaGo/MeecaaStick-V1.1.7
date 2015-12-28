//
//  HealthDetailViewController.m
//  HomeKinsa
//
//  Created by Zhang guangchun on 15/5/15.
//  Copyright (c) 2015年 Mikai. All rights reserved.
//

#import "HealthDetailViewController.h"
#import "DetailRecordPhotosTableViewCell.h"
#import "DetailRecordSymbolsTableViewCell.h"
#import "DetailRecordTemperatureTableViewCell.h"
#import "DetailRecordTimeTableViewCell.h"
#import "UIImage+ImageEffects.h"
#import "GlobalData.h"
#import "DataBaseTool.h"
#import <HSDatePickerViewController/HSDatePickerViewController.h>
#import "UpdateSymbolsViewController.h"
#import "HttpTool.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import "TTToolsHelper.h"

@interface HealthDetailViewController ()<UITableViewDataSource, UITableViewDelegate,DetailRecordTimeTableViewCellDelegate,HSDatePickerViewControllerDelegate,DetailRecordPhotosTableViewCellDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate,DetailRecordTemperatureTableViewCellDelegte,UITextViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic,strong) DetailRecordTimeTableViewCell *detailRecordTimeTableViewCell;
@property (nonatomic,strong) UIImagePickerController *ipc;
@property (nonatomic,weak) UIImageView *currentDidSelectImageView;
@property (nonatomic,strong) DetailRecordPhotosTableViewCell *detailRecordPhotosTableViewCell;
@property (nonatomic,strong) NSMutableArray *submitImages;
@property (nonatomic,strong) DetailRecordTemperatureTableViewCell *detailRecordTemperatureTableViewCell;
@end

@implementation HealthDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupNav];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDiarySuccessNotification) name:@"UpdateDiarySuccessNotification" object:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UpdateDiarySuccessNotification" object:nil];
}

- (void)updateDiarySuccessNotification
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"MainTabBarViewController"];
    [self presentViewController:vc animated:YES completion:^{
        [SVProgressHUD dismiss];
    }];
}

- (void)setupNav
{
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName:[UIColor whiteColor]};
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    self.navigationItem.title = @"温度记录详情";
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"login_back_icon"] style:UIBarButtonItemStyleDone target:self action:@selector(onClickBack)];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"保存" style:UIBarButtonItemStyleDone target:self action:@selector(onClickSave)];
}

- (void)onClickBack
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)onClickSave
{
    [self.view endEditing:YES];
    NSString *tid = [NSString stringWithFormat:@"%@",self.detailRecordInfo[@"tid"]];
    NSString *date = [NSString stringWithFormat:@"%@",self.detailRecordInfo[@"date"]];
//    NSString *temperature = [NSString stringWithFormat:@"%@",self.detailRecordInfo[@"value"]];
    NSString *temperature = self.detailRecordTemperatureTableViewCell.TemperatureTextField.text;
    
    NSString *symbols = self.detailRecordInfo[@"symbton"];
    NSString *desc = self.detailRecordInfo[@"desc"];
    if(desc==nil || [desc isEqualToString:@""]){
        desc = @"未描述";
    }
    
    if (temperature==nil || [temperature isEqualToString:@""]) {
        [[TTToolsHelper shared] showAlertMessage:@"请填写温度！"];
        return;
    }
    
    GlobalData *gd = [GlobalData sharedData];
    
    int type = (gd.temperatureType!=nil&&[gd.temperatureType intValue]==2)?2:1;
    if (type == 1) {
        //判断填写的温度
        float tempFloat = [temperature floatValue];        if (tempFloat > 44.0 || tempFloat < 32.0) {
            [[TTToolsHelper shared] showAlertMessage:@"温度填写错误！"];
            return;
        }
        
    }
    
    if (type==2) {
        float tempFloat = [temperature floatValue];
        if (tempFloat < 89.6 || tempFloat > 111.2) {
            [[TTToolsHelper shared] showAlertMessage:@"温度填写错误！"];
            return;
        }
        tempFloat = (tempFloat-32)/1.8;
        if (tempFloat<0) {
            [[TTToolsHelper shared] showAlertMessage:@"温度填写错误！"];
            return;
        }
        temperature = [NSString stringWithFormat:@"%@",[NSNumber numberWithFloat:tempFloat]];
    }

    
    
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
    [HttpTool updateDiaryWithTid:tid Date:date Temperature:temperature Symbols:symbols Desc:desc];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    //[self.tableView reloadData];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 4;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section{
    return @"";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSUInteger section = [indexPath section];
    if (section==0) {
        return 64;
    }
    else if (section==1){
        return 63;
    }
    else if (section==2){
        return 119;
    }
    return 187;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSUInteger section = [indexPath section];
    if (section==0) {
        DetailRecordTimeTableViewCell *cell = (DetailRecordTimeTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"DetailRecordTimeTableViewCell"];
        cell.delegate = self;
        self.detailRecordTimeTableViewCell = cell;
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy.M.d HH:mm";
        NSTimeInterval time = [self.detailRecordInfo[@"date"] integerValue];
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:time];
        cell.timeLabel.text = [formatter stringFromDate:date];
        return cell;
    }
    else if (section==1){
        DetailRecordTemperatureTableViewCell *cell = (DetailRecordTemperatureTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"DetailRecordTemperatureTableViewCell"];
        cell.delegate = self;
        self.detailRecordTemperatureTableViewCell = cell;
        GlobalData *gd = [GlobalData sharedData];
        int type = (gd.temperatureType!=nil&&[gd.temperatureType intValue]==2)?2:1;
        NSNumber *value = [self.detailRecordInfo objectForKey:@"value"];
        if (type==2) {
            float tempFloat = [value floatValue];
            tempFloat = tempFloat*1.8+32;
            cell.TemperatureTextField.text = [NSString stringWithFormat:@"%.1f",tempFloat];
            cell.TemperatureTypeLable.text = @"℉";
        }
        else {
            cell.TemperatureTextField.text = [NSString stringWithFormat:@"%.1f",[[self.detailRecordInfo objectForKey:@"value"] floatValue]];
            cell.TemperatureTypeLable.text = @"℃";
        }
        
        return cell;
    }
    else if (section==2){
//        DetailRecordSymbolsTableViewCell *cell = (DetailRecordSymbolsTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"DetailRecordSymbolsTableViewCell"];
        DetailRecordSymbolsTableViewCell *cell = [[DetailRecordSymbolsTableViewCell alloc] init];
        cell.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width
, 118);
        //添加症状
        UILabel *statusLabel = [[UILabel alloc] init];
        statusLabel.text = @"症状";
        statusLabel.font = [UIFont boldSystemFontOfSize:17];
        statusLabel.textColor = [UIColor colorWithRed:80/255.0 green:204/255.0 blue:216/255.0 alpha:1.0];
        statusLabel.frame = CGRectMake(27, 20, 50, 30);
        [cell addSubview:statusLabel];
        
        UILabel *symbolsLabel = [[UILabel alloc] init];
        
        symbolsLabel.frame = CGRectMake(30, 55, [UIScreen mainScreen].bounds.size.width - 54, 60);
        symbolsLabel.font = [UIFont boldSystemFontOfSize:14.0];
        symbolsLabel.textColor = [UIColor colorWithRed:184/255.0 green:184/255.0 blue:184/255.0 alpha:1.0];
        symbolsLabel.text = [self.detailRecordInfo objectForKey:@"symbton"];
        symbolsLabel.numberOfLines = 0;
        [symbolsLabel setUserInteractionEnabled:YES];
        UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapSymbolsLabel)];
        [symbolsLabel addGestureRecognizer:recognizer];
        cell.symbolsLabel = symbolsLabel;
        [cell addSubview:symbolsLabel];
        return cell;
    }
    else if (section==3){
//        DetailRecordPhotosTableViewCell *cell = (DetailRecordPhotosTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"DetailRecordPhotosTableViewCell"];
//        cell.descLabel.text = [self.detailRecordInfo objectForKey:@"desc"];
//        cell.parentView = self.view;
//        int photo_count = [[self.detailRecordInfo objectForKey:@"photo_count"] intValue];
//        if (photo_count>0) {
//            /*
//            GlobalData *gd = [GlobalData sharedData];
//            [cell setImageList:gd.nowMemberId WithTime:[self.detailRecordInfo objectForKey:@"date"] WithCount:photo_count];
//             */
//            NSDictionary *defaultMember = [DataBaseTool getDefaultMember];
//            [cell setImageList:defaultMember[@"id"] WithTime:[self.detailRecordInfo objectForKey:@"date"] WithCount:photo_count];
//        }
        DetailRecordPhotosTableViewCell *cell = [[DetailRecordPhotosTableViewCell alloc] init];
        cell.delegate = self;
        cell.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 187);
        //添加症状
        UILabel *statusLabel = [[UILabel alloc] init];
        statusLabel.text = @"描述以及照片";
        statusLabel.font = [UIFont boldSystemFontOfSize:17];
        statusLabel.textColor = [UIColor colorWithRed:80/255.0 green:204/255.0 blue:216/255.0 alpha:1.0];
        statusLabel.frame = CGRectMake(27, 20, 102, 30);
        [cell addSubview:statusLabel];
        
        UITextView *descLabel = [[UITextView alloc] init];
        descLabel.delegate = self;
        descLabel.frame = CGRectMake(30, 55, [UIScreen mainScreen].bounds.size.width - 54, 60);
        descLabel.text = [self.detailRecordInfo objectForKey:@"desc"];
        descLabel.font = [UIFont boldSystemFontOfSize:14.0];
        descLabel.textColor = [UIColor colorWithRed:184/255.0 green:184/255.0 blue:184/255.0 alpha:1.0];
        descLabel.returnKeyType = UIReturnKeyDone;
        descLabel.delegate = self;
        [cell addSubview:descLabel];
        cell.descLabel = descLabel;
        
        int photo_count = [[self.detailRecordInfo objectForKey:@"photo_count"] intValue];
        if (photo_count>0) {
            /*  2015-10-19 SoulJa
            NSDictionary *defaultMember = [DataBaseTool getDefaultMember];
            [cell setImageList:defaultMember[@"id"] WithTime:[self.detailRecordInfo objectForKey:@"date"] WithCount:photo_count];
             */
            /**
             *  2015-10-19 SoulJa
             *  新的添加图片接口
             */
            NSArray *imageList = self.detailRecordInfo[@"pics"];
            [cell setImageListWithArray:(NSMutableArray *)imageList];
        }
        return cell;
    }
    return nil;
}

#pragma mark - DetailRecordTimeTableViewCellDelegate
- (void)DetailRecordTimeTableViewCellDidTapTimeLabel:(UILabel *)label
{
    //判断系统版本
    double version = [[[UIDevice currentDevice] systemVersion] doubleValue];
    if (version >= 8.0) {
        HSDatePickerViewController *datePicker = [HSDatePickerViewController new];
        datePicker.delegate = self;
        [self presentViewController:datePicker animated:YES completion:nil];
    }
}

- (void)hsDatePickerWillDismissWithQuitMethod:(HSDatePickerQuitMethod)method{
    
}

- (void)hsDatePickerDidDismissWithQuitMethod:(HSDatePickerQuitMethod)method{
    
}

- (void)hsDatePickerPickedDate:(NSDate *)date{
    NSDateFormatter *dateFormater = [NSDateFormatter new];
    dateFormater.dateFormat = @"yyyy.M.d HH:mm";
    self.detailRecordTimeTableViewCell.timeLabel.text = [dateFormater stringFromDate:date];
    NSMutableDictionary *tempDict = [NSMutableDictionary dictionaryWithDictionary:self.detailRecordInfo];
    tempDict[@"date"] = [NSNumber numberWithDouble:[date timeIntervalSince1970]];
    self.detailRecordInfo = tempDict;
//    self.recordTime.text = [dateFormater stringFromDate:date];
//    self.recordTimeNumber = [NSNumber numberWithDouble:[date timeIntervalSince1970]];
}

/**
 *  SoulJa 2015-10-19
 */
- (void)tapSymbolsLabel
{
    UpdateSymbolsViewController *vc = [[UpdateSymbolsViewController alloc] init];
    vc.detailRecordInfo = [NSMutableDictionary dictionaryWithDictionary:self.detailRecordInfo];
    vc.dayInfo = self.dayInfo;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)DetailRecordPhotosTableViewCellWithImageList:(NSMutableArray *)imageList TapImageView:(UIImageView *)imageView
{
    self.currentDidSelectImageView = imageView;
    UIImagePickerController *ipc = [[UIImagePickerController alloc] init];
    ipc.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [ipc.navigationBar setTintColor:[UIColor blackColor]];
    ipc.delegate = self;
    self.ipc = ipc;
    [self presentViewController:self.ipc animated:YES completion:nil];
    
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    [picker dismissViewControllerAnimated:YES completion:^{
        [self.currentDidSelectImageView setImage:info[UIImagePickerControllerOriginalImage]];
        
    }];
}

#pragma mark - DetailRecordTemperatureTableViewCellDelegate
- (void)DetailRecordTemperatureTableViewCellDidEndEditTextField:(double)temperature
{
    NSMutableDictionary *tempDict = [NSMutableDictionary dictionaryWithDictionary:self.detailRecordInfo];
    tempDict[@"value"] = [NSNumber numberWithDouble:temperature];
    self.detailRecordInfo = tempDict;
}


#pragma mark -UITextViewDelegate
- (void)textViewDidEndEditing:(UITextView *)textView
{
    NSMutableDictionary *tempDict = [NSMutableDictionary dictionaryWithDictionary:self.detailRecordInfo];
    tempDict[@"desc"] = textView.text;
    self.detailRecordInfo = tempDict;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    } else {
        return YES;
    }
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
