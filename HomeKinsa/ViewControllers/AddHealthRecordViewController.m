//
//  AddHealthRecordViewController.m
//  HomeKinsa
//
//  Created by Zhang guangchun on 15/5/2.
//  Copyright (c) 2015年 Mikai. All rights reserved.
//

#import "AddHealthRecordViewController.h"
#import "GlobalData.h"
#import "UIImage+ImageEffects.h"
#import "AddRecordChooseTimeTableViewCell.h"
#import "AddRecordInputTemeratureTableViewCell.h"
#import "AddRecordChooseSymptonTableViewCell.h"
#import "AddRecordAddPhotoTableViewCell.h"
#import <HSDatePickerViewController/HSDatePickerViewController.h>
#import "AddSymptonViewController.h"
#import "AddPhotoViewController.h"
#import "AddRecordSubmitUITableViewCell.h"
#import "TTToolsHelper.h"
#import "TTNetworkHelper.h"
#import "UseHardwareCheckViewController.h"
#import "UIViewController+ProgressHUD.h"
#import <CoreLocation/CoreLocation.h>
#import "AFNetworking.h"
#import <SVProgressHUD.h>
#import "GetServerUrlViewController.h"
//引入数据库工具类
#import "DataBaseTool.h"
//引入网络请求类
#import "HttpTool.h"
//引入百度地图
#import <BaiduMapAPI/BMapKit.h>



@interface AddHealthRecordViewController ()<UITableViewDataSource, UITableViewDelegate, HSDatePickerViewControllerDelegate, UITextFieldDelegate, AddSymptonViewControllerDelegate, AddPhotoViewControllerDelegate,UITextFieldDelegate, UITextViewDelegate,CLLocationManagerDelegate,BMKLocationServiceDelegate>
{
    int uploadImageIdx;
    BOOL backFlag;
}


@property (weak, nonatomic) IBOutlet NSLayoutConstraint *buttomViewVerticalSpace;

@property (retain, nonatomic) UILabel *recordTime;
@property (retain, nonatomic) UITextField *recordTemperature;
@property (retain, nonatomic) UILabel *recordSympton;
@property (retain, nonatomic) UILabel *recordDesc;
@property (retain, nonatomic) UIButton *submitBtn;

@property (retain, nonatomic) NSNumber *recordTimeNumber;
@property (retain, nonatomic) NSArray *recordSymptons;
@property (retain, nonatomic) NSArray *uploadImageList;
@property (retain, nonatomic) NSString *descStr;
@property (weak, nonatomic) IBOutlet UITableView *addRecordTableView;
@property (weak, nonatomic) IBOutlet UITextField *tempField;

@property (nonatomic, assign) NSInteger keyboardHeight;
@property (nonatomic, assign) BOOL keyboardIsShowing;
@property (nonatomic, assign) CGFloat orgViewY;

@property (retain, nonatomic) NSMutableDictionary *nowCheckTemperatureInfo;

/**
 *  定位管理者
 */
@property (nonatomic,strong) CLLocationManager *locationManager;

/**
 *  经度
 */
@property (nonatomic,assign) CLLocationDegrees myLongitude;
/**
 *  纬度
 */
@property (nonatomic,assign) CLLocationDegrees myLatitude;
/**
 *  百度地图定位服务
 */
@property (nonatomic,strong) BMKLocationService *locService;
/**
 *  百度地图管理者
 */
@property (nonatomic,strong) BMKMapManager *mapManager;
@end
@implementation AddHealthRecordViewController

- (void) dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    /**
     *  2015-11-28 SoulJa
     *  添加textfield代理
     */
    self.recordTemperature.delegate = self;
    self.tempField.delegate = self;
    
    
    [self.navigationController.navigationBar setTranslucent:NO];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageWithColor:COLOR_NAV_BACKGROUND] forBarMetrics:UIBarMetricsDefault];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"login_back_icon"] style:UIBarButtonItemStylePlain target:self action:@selector(goBack)];
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    
    self.addRecordTableView.delegate = self;
    self.addRecordTableView.dataSource = self;
    [self.addRecordTableView reloadData];
    
    self.keyboardHeight = 0;
    [self setupLocationManager];
}

/**
 *  设置地图管理者
 */
- (void)setupLocationManager
{
    self.locationManager = [[CLLocationManager alloc] init];
    //获取地图定位授权
    if ([[UIDevice currentDevice].systemVersion floatValue] > 7.9) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    
    if ([CLLocationManager locationServicesEnabled]) {
        self.locationManager.delegate = self;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
        self.locationManager.distanceFilter = 1000.0f;
        [self.locationManager startUpdatingLocation];
    }
}

#pragma mark - BMKLocationServiceDelegate
//处理位置坐标更新
- (void)didUpdateBMKUserLocation:(BMKUserLocation *)userLocation
{
    NSLog(@"didUpdateUserLocation lat %f,long %f",userLocation.location.coordinate.latitude,userLocation.location.coordinate.longitude);
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *location = [locations firstObject];
    CLLocationCoordinate2D coordinate = location.coordinate;
    /*转换为百度坐标开始*/
    //转换 google地图、soso地图、aliyun地图、mapabc地图和amap地图所用坐标至百度坐标
    NSDictionary* testdic = BMKConvertBaiduCoorFrom(coordinate,BMK_COORDTYPE_COMMON);
    NSLog(@"百度坐标:%@",testdic);
    //转换GPS坐标至百度坐标
    testdic = BMKConvertBaiduCoorFrom(coordinate,BMK_COORDTYPE_GPS);
    NSLog(@"百度坐标:x=%@,y=%@",[testdic objectForKey:@"x"],[testdic objectForKey:@"y"]);
    /*结束*/
    
    self.myLongitude = coordinate.longitude;
    self.myLatitude = coordinate.latitude;
    [self.locationManager stopUpdatingLocation];
}


- (void)onTapView:(id)sender{
    [self.recordTemperature resignFirstResponder];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getDiarySucceedDelegate:) name:@"GET_DIARY_SUCCEED" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addDiaryImageSuccess:) name:@"AddDiaryImageSuccess" object:nil];
    
    //监听添加成功记录的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addDiarySuccessNotification:) name:@"AddDiarySuccessNotification" object:nil];
}

- (void)addDiarySuccessNotification:(NSNotification *)note
{
    if (self.uploadImageList == nil || self.uploadImageList.count <=1) {
        /**
         *  2015-12-07 SoulJa
         *  直接DISMISS
         */
        UIStoryboard *board = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        UIViewController *vc = [board instantiateViewControllerWithIdentifier:@"MainTabBarViewController"];
        [self presentViewController:vc animated:YES completion:^{
            [SVProgressHUD dismiss];
        }];
    } else {
        /**
         *  SoulJa 2015-10-16
         *  修改图片上传
         */
        //[self uploadImages];

        NSString *diaryId = [NSString stringWithFormat:@"%@",note.userInfo[@"id"]];
        for (int i = 0; i < self.uploadImageList.count-1; i++) {
            [HttpTool uploadDiaryImageWithDiaryId:diaryId Image:self.uploadImageList[i] ImageName:[NSString stringWithFormat:@"%d",i]];
        }
    }
}

- (void)addDiaryImageSuccess:(NSNotification *)note
{
    NSString *imageName = [NSString stringWithFormat:@"%@", note.userInfo[@"imageName"]];
    if ([imageName isEqualToString:[NSString stringWithFormat:@"%d",((int)self.uploadImageList.count-2)]]) {
//        if ([HttpTool isConnectInternet]) {
//            /**
//             *  2015-12-07 SoulJa
//             *  图片上传
//             */
////            [DataBaseTool refreshDefaultMemberDiary:nil];
//            [DataBaseTool deleteDefaultMemberDiary];
//        }
        [DataBaseTool deleteDefaultMemberDiary];

        UIStoryboard *board = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        UIViewController *vc = [board instantiateViewControllerWithIdentifier:@"MainTabBarViewController"];
        [self presentViewController:vc animated:YES completion:^{
            [SVProgressHUD dismiss];
        }];
    } else {
        return;
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"AddDiarySuccessNotification" object:nil];
    //[[NSNotificationCenter defaultCenter] removeObserver:self name:@"AddDiaryImageSuccess" object:nil];
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
            self.addRecordTableView.frame = CGRectMake(self.addRecordTableView.frame.origin.x, -60, self.addRecordTableView.frame.size.width, self.addRecordTableView.frame.size.height);
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
            self.addRecordTableView.frame = CGRectMake(self.addRecordTableView.frame.origin.x, 0, self.addRecordTableView.frame.size.width, self.addRecordTableView.frame.size.height);
            } completion:^(BOOL finished) {}];
        }
    }
}

- (void)getDiarySucceedDelegate:(id)sender{
}

- (void)createDiarySucceedDelegate:(id)sender{
    [self uploadImages];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"CREATE_DIARY_SUCCEED" object:nil];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    return 74;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSInteger section = [indexPath section];
    if (section==0) {
        AddRecordChooseTimeTableViewCell *cell = (AddRecordChooseTimeTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"AddRecordChooseTimeTableViewCell"];
        self.recordTime = cell.timeLabel;
        NSDateFormatter *dateFormater = [NSDateFormatter new];
        dateFormater.dateFormat = @"yyyy.M.d HH:mm";
        self.recordTime.text = [dateFormater stringFromDate:[NSDate date]];
        self.recordTimeNumber = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]];
        return cell;
    }
    else if (section==1){
        AddRecordInputTemeratureTableViewCell *cell = (AddRecordInputTemeratureTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"AddRecordInputTemeratureTableViewCell"];
        self.recordTemperature = cell.inputTemperature;
        
        /**
         *  type为1表示摄氏度
         *  type为2表示华氏度
         */
        GlobalData *gd = [GlobalData sharedData];
        int type = (gd.temperatureType!=nil&&[gd.temperatureType intValue]==2)?2:1;
        cell.temperatureTypeLable.text = (type==1?@"℃":@"℉");
        if (type == 2) {
            cell.inputTemperature.placeholder = @"89.6~111.2";
        }
        backFlag = false;
        
        if (gd.lastTimeCheckTemperature!=nil&&![gd.lastTimeCheckTemperature isEqualToString:@""]) {
            if (type==2) {
                float value = [gd.lastTimeCheckTemperature floatValue];
                float value1 = value*1.8+32;
                self.recordTemperature.text = [NSString stringWithFormat:@"%.1f",(value1+0.5)];
                
            }
            else{
                self.recordTemperature.text = gd.lastTimeCheckTemperature;
            }
            gd.lastTimeCheckTemperature = nil;
            backFlag = true;
        }
        self.recordTemperature.delegate = self;
        return cell;
    }
    else if (section==2){
        AddRecordChooseSymptonTableViewCell *cell = (AddRecordChooseSymptonTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"AddRecordChooseSymptonTableViewCell"];
        self.recordSympton = cell.symptonLabel;
        self.recordSympton.text = @"";
        return cell;
    }
    else if (section==4){
        AddRecordSubmitUITableViewCell *cell = (AddRecordSubmitUITableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"AddRecordSubmitUITableViewCell"];
        [cell.submitBtn addTarget:self action:@selector(onClickSubmit:) forControlEvents:UIControlEventTouchUpInside];
        self.submitBtn = cell.submitBtn;
        return cell;
    }
    AddRecordAddPhotoTableViewCell *cell = (AddRecordAddPhotoTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"AddRecordAddPhotoTableViewCell"];
    cell.descLabel.text = @"未描述";
    self.recordDesc = cell.descLabel;
    return cell;
}

- (void)uploadImage:(int)imgIdx{
    /*原有取出默认成员的ID
    GlobalData *gd = [GlobalData sharedData];
    NSString *mid = gd.nowMemberId;
     */
    NSDictionary *defaultMember = [DataBaseTool getDefaultMember];
    NSString *mid = defaultMember[@"id"];
    ino64_t tt = (int)[self.recordTimeNumber doubleValue];
    NSNumber *time = [NSNumber numberWithLong:tt];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    [formatter setDateFormat:@"YYYY-MM-dd"];
    
    NSString *dayStr = [formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:[time doubleValue]]];
    NSDate *date = [formatter dateFromString:dayStr];
    
    @weakify(self);
    RACSignal *signal = [[TTNetworkHelper sharedSession] updateImage:[self.uploadImageList objectAtIndex:uploadImageIdx] InDate:[NSNumber numberWithInt:(int)[date timeIntervalSince1970]] WithName:[NSString stringWithFormat:@"%@_%@_%i.jpg",mid,time,uploadImageIdx]];
    [[signal deliverOn:RACScheduler.mainThreadScheduler]
     subscribeNext:^(NSDictionary *object){
         uploadImageIdx++;
         if (uploadImageIdx<=self.uploadImageList.count-2) {
             [self uploadImage:uploadImageIdx];
         }
         else{
             @strongify(self);
             //[self dismissProgressHUD];
//             [[TTToolsHelper shared] showNoticetMessage:@"保存记录成功！" handler:^{
////                 GlobalData *gd = [GlobalData sharedData];
////                 [gd.diary insertObject:self.nowCheckTemperatureInfo atIndex:0];
//                 self.uploadImageList = nil;
//                 [self onClickBack:nil];
//             }];
             self.uploadImageList = nil;
             
             //[self onClickBack:nil];
             UIStoryboard *board = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
             UIViewController *vc = [board instantiateViewControllerWithIdentifier:@"MainTabBarViewController"];
             [self presentViewController:vc animated:YES completion:nil];
         }
     }
     error:^(NSError *error){
//         @strongify(self);
//         [self dismissProgressHUD];
     }
     completed:^{
//         @strongify(self);
//         [self dismissProgressHUD];
     }];
}

- (void)uploadImages{
    if (self.uploadImageList.count<=1) {
//        [[TTToolsHelper shared] showNoticetMessage:@"保存记录成功！" handler:^{
////            GlobalData *gd = [GlobalData sharedData];
////            [gd.diary insertObject:self.nowCheckTemperatureInfo atIndex:0];
//            [self onClickBack:nil];
//        }];
        [self onClickBack:nil];
        return;
    }
    
    uploadImageIdx = 0;
    [self uploadImage:uploadImageIdx];
}


- (void)onClickSubmit:(id)sender{
    [self.view endEditing:YES];
    
    //友盟统计
    [MobClick event:@"recordsave"];
    
    //取出默认用户
    NSDictionary *defaultMember = [DataBaseTool getDefaultMember];
    if (defaultMember == nil) {
        [SVProgressHUD showInfoWithStatus:@"请您先登录" maskType:SVProgressHUDMaskTypeClear];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            UIStoryboard *board = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            UIViewController *vc = [board instantiateViewControllerWithIdentifier:@"LoginViewController"];
            [self presentViewController:vc animated:YES completion:^{
                [SVProgressHUD dismiss];
            }];
        });
        return;
    }
    
    //取出默认用户的id
    NSString *defaultMemberId = [NSString stringWithFormat:@"%@",defaultMember[@"id"]];
    
    NSString *mid = defaultMemberId;
    
    
    //取出默认选中成员的ID
    /*
    NSString *selectedMemberId = defaultMember[@"id"];
    for (NSDictionary *dict in gd.members) {
        NSString *isdefaultStr = [NSString stringWithFormat:@"%@",dict[@"isdefault"]];
        if ([isdefaultStr isEqualToString:@"1"]) {
            selectedMemberId = [NSString stringWithFormat:@"%@",dict[@"id"] ];
            break;
        }
    }
    
    if (selectedMemberId != nil) {
        gd.nowMemberId = selectedMemberId;
    } else {
        gd.nowMemberId = [gd.members[0] objectForKey:@"id"];
    }
    
    NSString *mid = gd.nowMemberId;
     */
    GlobalData *gd = [GlobalData sharedData];
    
    ino64_t tt = (int)[self.recordTimeNumber doubleValue];
    NSNumber *time = [NSNumber numberWithLong:tt];
    int phototNum = (int)self.uploadImageList.count-1;
    NSNumberFormatter *numFormat = [[NSNumberFormatter alloc] init];
    NSNumber *temperature = [numFormat numberFromString:self.recordTemperature.text];
    NSNumber *symptoms = [[TTToolsHelper shared] setFlagInIntergerPosition:self.recordSymptons];
    NSString *desc = self.descStr;//self.recordDesc.text;
    if(desc==nil){
        desc = @"未描述";
    }
    
    if (temperature==nil) {
        [[TTToolsHelper shared] showAlertMessage:@"请填写温度！"];
        return;
    }
    
    
    self.submitBtn.enabled = false;
    self.nowCheckTemperatureInfo = [NSMutableDictionary dictionary];
    [self.nowCheckTemperatureInfo setObject:time forKey:@"date"];
    [self.nowCheckTemperatureInfo setObject:desc forKey:@"description"];
    [self.nowCheckTemperatureInfo setObject:mid forKey:@"member_id"];
    [self.nowCheckTemperatureInfo setObject:[NSNumber numberWithInt:phototNum] forKey:@"photo_count"];
    [self.nowCheckTemperatureInfo setObject:symptoms forKey:@"symptoms"];
    
    int type = (gd.temperatureType!=nil&&[gd.temperatureType intValue]==2)?2:1;
    if (type == 1) {
        //判断填写的温度
        float tempFloat = [temperature floatValue];        if (tempFloat > 44.0 || tempFloat < 32.0) {
            [[TTToolsHelper shared] showAlertMessage:@"超出体温范围！（请填写32.0~44.0）"];
            return;
        }

    }
    
    if (type==2) {
        float tempFloat = [temperature floatValue];
        if (tempFloat < 89.6 || tempFloat > 111.2) {
            [[TTToolsHelper shared] showAlertMessage:@"超出体温范围！（请填写89.6~111.2）"];
            return;
        }
        tempFloat = (tempFloat-32)/1.8;
        if (tempFloat<0) {
            [[TTToolsHelper shared] showAlertMessage:@"温度填写错误！"];
            return;
        }
        temperature = [NSNumber numberWithFloat:tempFloat];
    }
    [self.nowCheckTemperatureInfo setObject:[NSString stringWithFormat:@"%@",temperature] forKey:@"temperature"];
    [self.nowCheckTemperatureInfo setObject:@0 forKey:@"id"];
    
    //记录地理位置
    double myLongitude = self.myLongitude?self.myLongitude:0;
    NSString *mylongitudeStr = [NSString stringWithFormat:@"%f",myLongitude];
    
    double myLatitude = self.myLatitude?self.myLatitude:0;
    NSString *mylatitudeStr = [NSString stringWithFormat:@"%f",myLatitude];
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
    [HttpTool addDiaryWithDate:[NSString stringWithFormat:@"%@",time] Temperature:[NSString stringWithFormat:@"%@",temperature] Symptoms:[NSString stringWithFormat:@"%@",symptoms] Photo_count:[NSString stringWithFormat:@"%d",phototNum] Description:desc Member_id:mid Longitude:mylongitudeStr Latitude:mylatitudeStr];
    
    /**
     *  发起添加记录的请求
     */
    /*
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *host = [GetServerUrlViewController getServerUrl];
    NSString *urlStr = [NSString stringWithFormat:@"http://%@/Soulja/AddDiary.php",host];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"date"] = time;
    params[@"temperature"] = temperature;
    params[@"symptoms"] = symptoms;
    params[@"photo_count"] = [NSString stringWithFormat:@"%d",phototNum];
    params[@"description"] = desc;
    params[@"member_id"] = mid;
    params[@"longitude"] = mylongitudeStr;
    params[@"latitude"] = mylatitudeStr;
    [SVProgressHUD show];
    [manager GET:urlStr parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@",responseObject);
        [SVProgressHUD dismiss];
        if (responseObject[@"msg"]>0) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"CREATE_DIARY_SUCCEED" object:nil];
        } else {
            [SVProgressHUD showErrorWithStatus:responseObject[@"content"]];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@",error);
    }];
     */
    
    
//    [[TTNetworkHelper sharedSession] createDiaryByMid:mid Date:time Temperature:temperature Symptoms:symptoms Photo:phototNum Desc:desc Longitude:mylongitudeStr Latitude:mylatitudeStr dismissProgressView:YES];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    NSInteger section = [indexPath section];
    if (section!=1) {
        [self.recordTemperature resignFirstResponder];
    }
    
    if (section==0) {
        double version = [[UIDevice currentDevice].systemVersion doubleValue];
        if (version>=8.0) {
            HSDatePickerViewController *datePicker = [HSDatePickerViewController new];
            datePicker.delegate = self;
            [self presentViewController:datePicker animated:YES completion:nil];
        }
    }
    
    else if (section==2) {
        [self performSegueWithIdentifier:@"AddSymptonViewController" sender:nil];
    }
    else if (section==3) {
        [self performSegueWithIdentifier:@"AddPhotoViewController" sender:nil];
    }
    else if (section==4) {
        [self onClickSubmit:nil];
    }
}

- (void)getChoosePhotos:(NSArray *)photos AndDesc:(NSString *)desc{
    self.uploadImageList = photos;
    self.descStr = desc;
    if (self.descStr!=nil&&![self.descStr isEqualToString:@""]) {
        self.recordDesc.text = @"已描述";
    }
    else{
        self.recordDesc.text = @"未描述";
    }
}

- (void)getChooseSymptons:(NSArray *)symptons{
    GlobalData *gd = [GlobalData sharedData];
    NSString *chooseSymptons = @"";
    for (int i=0; i<symptons.count; i++) {
        if (i<=3) {
            chooseSymptons = [chooseSymptons stringByAppendingString:[gd getSymptonNameByTag:[symptons objectAtIndex:i]]];
            chooseSymptons = [chooseSymptons stringByAppendingString:@" "];
        }
    }
    self.recordSympton.text = chooseSymptons;
    self.recordSymptons = symptons;
}

- (IBAction)onClickBack:(id)sender {
//    [self dismissViewControllerAnimated:YES completion:nil];
    UIViewController* presentingViewController = self.presentingViewController;
    if (backFlag) {
        [self dismissViewControllerAnimated:NO completion:^{
            [presentingViewController dismissViewControllerAnimated:YES completion:^{
                [SVProgressHUD dismiss];
            }];
        }];
    }
    else {
        [self dismissViewControllerAnimated:YES completion:^{
            [SVProgressHUD dismiss];
        }];
    }
}

- (BOOL)validatePoint:(NSString*)point {
    BOOL res = YES;
    NSCharacterSet* tmpSet = [NSCharacterSet characterSetWithCharactersInString:@"."];
    int i = 0;
    while (i< point.length) {
        NSString * string = [point substringWithRange:NSMakeRange(i, 1)];
        NSRange range = [string rangeOfCharacterFromSet:tmpSet];
        if (range.length == 0) {
            res = NO;
            break;
        }
        i++;
    }
    return res;
}

- (BOOL)validateNumber:(NSString*)number {
    BOOL res = YES;
    NSCharacterSet* tmpSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789."];
    int i = 0;
    while (i< number.length) {
        NSString * string = [number substringWithRange:NSMakeRange(i, 1)];
        NSRange range = [string rangeOfCharacterFromSet:tmpSet];
        if (range.length == 0) {
            res = NO;
            break;
        }
        i++;
    }
    return res;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    NSArray *points = [textField.text componentsSeparatedByString:@"."];
    if (points.count>=2&&[string isEqualToString:@"."]) {
        return NO;
    }
    // Check for total length
    NSUInteger proposedNewLength = textField.text.length - range.length + string.length;
    //限制温度输入长度
    if (proposedNewLength > 5){
        return NO;//限制长度
    }
    return [self validateNumber:string];
}

- (void)hsDatePickerWillDismissWithQuitMethod:(HSDatePickerQuitMethod)method{
    
}

- (void)hsDatePickerDidDismissWithQuitMethod:(HSDatePickerQuitMethod)method{
    
}

- (void)hsDatePickerPickedDate:(NSDate *)date{
    NSDateFormatter *dateFormater = [NSDateFormatter new];
    dateFormater.dateFormat = @"yyyy.M.d HH:mm";
    self.recordTime.text = [dateFormater stringFromDate:date];
    self.recordTimeNumber = [NSNumber numberWithDouble:[date timeIntervalSince1970]];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if ([segue.identifier isEqualToString:@"AddSymptonViewController"]) {
        AddSymptonViewController *addSymptonView = [segue destinationViewController];
        addSymptonView.beforeSymptons = self.recordSymptons;
        addSymptonView.delegate = self;
    }
    else if ([segue.identifier isEqualToString:@"AddPhotoViewController"]){
        AddPhotoViewController *addPhotoView = [segue destinationViewController];
        addPhotoView.beforeImageList = self.uploadImageList;
        addPhotoView.desc = self.descStr;
        addPhotoView.addDelegate = self;
    }
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

- (void)goBack
{
    if (self.PresentFromCheck) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        UIViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"MainTabBarViewController"];
        [self presentViewController:vc animated:YES completion:nil];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}
@end
