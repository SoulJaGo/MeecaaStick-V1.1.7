//
//  HealthCheckMainViewController.m
//  HomeKinsa
//
//  Created by Zhang guangchun on 15/3/4.
//  Copyright (c) 2015年 Mikai. All rights reserved.
//

#import "HealthCheckMainViewController.h"
#import "CheckDayTableViewCell.h"
#import "CheckDayDetailTableViewCell.h"
#import "GlobalData.h"
#import "TTToolsHelper.h"
#import "INTUAnimationEngine.h"
#import "UIViewController+ProgressHUD.h"
#import "TTNetworkHelper.h"
#import "HealthDetailViewController.h"
#import "AFNetworking.h"
#import "GetServerUrlViewController.h"
#import "DataBaseTool.h"
#import "HttpTool.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import "SDWebImageManager.h"
#import "MJRefresh.h"
#import "UIImage+ImageEffects.h"
#import "DetailRecordNavigationController.h"
#import "Account.h"
#import <CoreLocation/CoreLocation.h>
#import "GlobalTool.h"

@interface HealthCheckMainViewController ()<UITableViewDataSource, UITableViewDelegate,CLLocationManagerDelegate>
@property (weak, nonatomic) IBOutlet UITableView *historyTableView;
@property (weak, nonatomic) IBOutlet UIImageView *checkTip;
@property (weak, nonatomic) IBOutlet UIView *noHistoryTip;
/**
 *  测温历史记录
 */
@property (retain, nonatomic) NSMutableArray *historyList;
@property (nonatomic,strong) NSMutableArray *diaryList;
- (IBAction)onClickCheckBtn;

@property (nonatomic,strong) CLLocationManager *locationManager;
@property (nonatomic,strong) CLGeocoder *geocoder;

/**
 *  本地页码数据
 */
@property (nonatomic,assign) int page;
@end

@implementation HealthCheckMainViewController

- (NSArray *)getSymptons:(NSNumber *)value{
    if (value==0) {
        return nil;
    }
    return [[TTToolsHelper shared] getFlagInIntergerPosition:value];
}

/*以前获取历史记录的方法
- (NSMutableArray *)getHistoryListFromServer:(NSArray *)list {
    NSMutableArray *showList = [NSMutableArray array];
    for (int i=0; i<list.count; i++) {
        NSDictionary *dayHistory = [list objectAtIndex:i];
        NSNumber *date = [dayHistory objectForKey:@"date"];
        NSNumber *tid = [dayHistory objectForKey:@"id"];
        NSNumber *member_id = [dayHistory objectForKey:@"member_id"];
        NSDate *dateValue = [NSDate dateWithTimeIntervalSince1970:[date longLongValue]];
        NSDateFormatter *dateFormater = [NSDateFormatter new];
        dateFormater.dateFormat = @"yyyy.M.d";
        NSString *dayStr = [dateFormater stringFromDate:dateValue];
        
        NSDateFormatter *timeFormater = [[NSDateFormatter alloc] init];
        timeFormater.locale=[[NSLocale alloc]initWithLocaleIdentifier:@"en_US"];
        [timeFormater setDateFormat:@"h:mm a"];
        NSString *timeStr = [timeFormater stringFromDate:dateValue];
        
        int photo_count = [[dayHistory objectForKey:@"photo_count"] intValue];
        
        NSMutableArray *dayDiary;
        for (int j=0; j<showList.count; j++) {
            NSDictionary *_dayDiary = [showList objectAtIndex:j];
            NSString *_dayStr = [_dayDiary objectForKey:@"day"];
            if ([_dayStr isEqualToString:dayStr]) {
                dayDiary = [_dayDiary objectForKey:@"detail"];
                break;
            }
        }
        if (dayDiary==nil) {
            dayDiary = [NSMutableArray array];
            NSMutableDictionary *showDict = [NSMutableDictionary dictionary];
            [showDict setObject:dayStr forKey:@"day"];
            [showDict setObject:dayDiary forKey:@"detail"];
            [showList addObject:showDict];
        }
        
        NSMutableDictionary *timeDiary = [NSMutableDictionary dictionary];
        NSString *temperature = [dayHistory objectForKey:@"temperature"];
        [timeDiary setObject:temperature forKey:@"value"];
        
        NSString *description = [dayHistory objectForKey:@"description"];
        
        NSString *symptonStr = @"";
        NSArray *symptons = [self getSymptons:[dayHistory objectForKey:@"symptoms"]];
        if (symptons==nil||symptons.count==0) {
            symptonStr = @"";
        }
        else{
            for (int i=0; i<symptons.count; i++) {
                NSNumber *tag = [symptons objectAtIndex:i];
                GlobalData *gd = [GlobalData sharedData];
                NSString *name = [gd getSymptonNameByTag:tag];
                symptonStr = [symptonStr stringByAppendingString:[NSString stringWithFormat:@"%@",name]];
                symptonStr = [symptonStr stringByAppendingString:@" "];
            }
        }
        [timeDiary setObject:symptonStr forKey:@"symbton"];
        [timeDiary setObject:timeStr forKey:@"time"];
        [timeDiary setObject:date forKey:@"date"];
        [timeDiary setObject:[NSNumber numberWithInt:photo_count] forKey:@"photo_count"];
        [timeDiary setObject:tid forKey:@"tid"];
        [timeDiary setObject:description forKey:@"desc"];
        [timeDiary setObject:member_id forKey:@"member_id"];
        [dayDiary addObject:timeDiary];
    }
    return showList;
}
 */

- (void)viewDidLoad {
    [super viewDidLoad];
    //页面状态
    self.page = 1;
    
    self.diaryList = [NSMutableArray array];
    
    
    
    //异步加载数据
    if ([DataBaseTool getDefaultMember]) { //登陆状态
        if (![DataBaseTool getDefaultMemberLastDiary]) { //没有数据的时候
            self.historyTableView.hidden = YES;
            self.checkTip.hidden = NO;
            self.noHistoryTip.hidden = NO;
            //请求网络读取数据
            [HttpTool getDefaultMemberDiaryInfoByPage:1];
        } else { //数据库有数据的时候
            self.diaryList = [[DataBaseTool shared] getDefaultMemberDiaryFromPage:1];
            self.historyTableView.hidden = NO;
            self.checkTip.hidden = YES;
            self.noHistoryTip.hidden = YES;
        }
    } else { //未登录
        self.historyTableView.hidden = YES;
        self.checkTip.hidden = NO;
        self.noHistoryTip.hidden = NO;
    }
    
    //地理定位
    _locationManager = [[CLLocationManager alloc] init];
    
    if (![CLLocationManager locationServicesEnabled]) { //不允许地理定位
        [[GlobalTool shared] setCity:@""];
    }
    
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
        [_locationManager requestWhenInUseAuthorization];
    } else if ([CLLocationManager authorizationStatus]==kCLAuthorizationStatusAuthorizedWhenInUse) {
        //设置代理
        _locationManager.delegate=self;
        //设置定位精度
        _locationManager.desiredAccuracy=kCLLocationAccuracyBest;
        //定位频率,每隔多少米定位一次
        CLLocationDistance distance=10.0;//十米定位一次
        _locationManager.distanceFilter=distance;
        //启动跟踪定位
        [_locationManager startUpdatingLocation];
    } else {
        [[GlobalTool shared] setCity:@""];
    }

    //下拉刷新
//    MJRefreshNormalHeader *header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(loadNewData)];
//    header.stateLabel.textColor = [UIColor colorWithRed:194/255.0 green:194/255.0 blue:194/255.0 alpha:1.0];
//    header.lastUpdatedTimeLabel.textColor = [UIColor colorWithRed:194/255.0 green:194/255.0 blue:194/255.0 alpha:1.0];
//    self.historyTableView.header = header;
    
    //上拉加载
    MJRefreshAutoNormalFooter *footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMoreOldData)];
    footer.stateLabel.textColor = [UIColor colorWithRed:194/255.0 green:194/255.0 blue:194/255.0 alpha:1.0];
    self.historyTableView.footer = footer;
    
    
    self.historyTableView.delegate = self;
    self.historyTableView.dataSource = self;
//    if (self.diaryList== nil || self.diaryList.count == 0) {
//        self.historyTableView.hidden = YES;
//        self.checkTip.hidden = NO;
//        self.noHistoryTip.hidden = NO;
//    } else {
//        self.historyTableView.hidden = NO;
//        self.checkTip.hidden = YES;
//        self.noHistoryTip.hidden = YES;
//    }
    
    /*
    GlobalData *gd = [GlobalData sharedData];
    //重新设置diary
    //选取默认用户
    NSDictionary *selectedMemberInfoDict;
    for (NSDictionary *dict in gd.members) {
        NSString *isdefaultStr = [NSString stringWithFormat:@"%@",dict[@"isdefault"]];
        if ([isdefaultStr isEqualToString:@"1"]) {
            selectedMemberInfoDict = dict;
            break;
        }
    }
    if (selectedMemberInfoDict == nil) {
        selectedMemberInfoDict = gd.members[0];
    }
    NSString *host = [GetServerUrlViewController getServerUrl];
    NSString *urlStr = [NSString stringWithFormat:@"http://%@/api.php?m=open&c=member&a=record",host];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"mid"] = selectedMemberInfoDict[@"id"];
    AFHTTPRequestOperationManager *mgr = [AFHTTPRequestOperationManager manager];
    [mgr POST:urlStr parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([responseObject[@"status"] isEqual:[NSNumber numberWithInt:1]]) {
            gd.diary = responseObject[@"data"];
        } else {
            gd.diary = nil;
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@",error);
    }];
    */
    
//    [self.historyTableView registerClass:[CheckDayDetailTableViewCell class] forCellReuseIdentifier:@"CheckDayDetailTableViewCell"];
    
//    [self.historyTableView registerClass:[CheckDayTableViewCell class] forCellReuseIdentifier:@"CheckDayTableViewCell"];
}

/**
 *  加载旧的数据
 */
- (void)loadMoreOldData {
    self.page++;
//    if ([HttpTool isConnectInternet]) {
//        NSMutableArray *array = [[DataBaseTool shared] getDefaultMemberDiaryFromPage:self.page];
//        if (array == nil || array.count == 0) { //本地没有更多的数据了
//            [HttpTool getDefaultMemberDiaryInfoByPage:self.page];
//        } else { //本地有更多的数据
//            [self.diaryList addObjectsFromArray:array];
//            [self.historyTableView reloadData];
//            [self.historyTableView.footer endRefreshing];
//        }
//    } else {
//        NSMutableArray *array = [[DataBaseTool shared] getDefaultMemberDiaryFromPage:self.page];
//        if (array != nil) {
//            [self.diaryList addObjectsFromArray:array];
//            [self.historyTableView reloadData];
//            [self.historyTableView.footer endRefreshing];
//        } else {
//            [self.historyTableView.footer endRefreshing];
//        }
//
//        [SVProgressHUD showErrorWithStatus:@"网络不给力哦!"];
//        
//    }
    NSMutableArray *array = [[DataBaseTool shared] getDefaultMemberDiaryFromPage:self.page];
    if (array == nil || array.count == 0) { //本地没有更多的数据了
        [HttpTool getDefaultMemberDiaryInfoByPage:self.page];
    } else { //本地有更多的数据
        [self.diaryList addObjectsFromArray:array];
        [self.historyTableView reloadData];
        [self.historyTableView.footer endRefreshing];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations  {
    CLLocation *location=[locations firstObject];//取出第一个位置
    _geocoder = [[CLGeocoder alloc] init];
    [_geocoder reverseGeocodeLocation:location completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        CLPlacemark *placemark = [placemarks firstObject];
        [[GlobalTool shared] setCity:[placemark.addressDictionary objectForKey:@"City"]];
    }];
    //如果不需要实时定位，使用完即使关闭定位服务
    [_locationManager stopUpdatingLocation];
    
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeDiarySuccessNotification) name:@"RemoveDiarySuccessNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(initDiaryDataSuccessNotification) name:@"InitDiaryDataSuccessNotification" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(initDiaryDataEndSuccessNotification) name:@"InitDiaryDataEndSuccessNotification" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(initDiaryDataEndFailNotification) name:@"InitDiaryDataEndFailNotification" object:nil];
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"RemoveDiarySuccessNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"InitDiaryDataSuccessNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"InitDiaryDataEndSuccessNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"InitDiaryDataEndFailNotification" object:nil];
}

- (void)initDiaryDataSuccessNotification {
    NSMutableArray *array = [[DataBaseTool shared] getDefaultMemberDiaryFromPage:self.page];
    if (array == nil || array.count == 0) { //没有数据
        if (self.diaryList == nil || self.diaryList.count == 0) {
            self.historyTableView.hidden = YES;
            self.checkTip.hidden = NO;
            self.noHistoryTip.hidden = NO;
        }
    } else {
        self.historyTableView.hidden = NO;
        self.checkTip.hidden = YES;
        self.noHistoryTip.hidden = YES;
        [self.diaryList addObjectsFromArray:array];
        [self.historyTableView reloadData];
    }
    [self.historyTableView.footer endRefreshing];
}

- (void)initDiaryDataEndFailNotification {
    [self.historyTableView.footer endRefreshing];
}

- (void)initDiaryDataEndSuccessNotification {
    [self.historyTableView.footer endRefreshing];
}






/**
 *  2015-12-03 SoulJa
 *  加载数据
 */
//- (void)initDiaryData {
//    if ([DataBaseTool getDefaultMemberLastDiary] != nil) { //数据库存在数据
//        self.diaryList = [DataBaseTool getDefaultMemberDiaryInfo];
//        self.historyTableView.hidden = NO;
//        self.checkTip.hidden = YES;
//        self.noHistoryTip.hidden = YES;
//        [self.historyTableView reloadData];
//        return;
//    } else {
//        if ([HttpTool isConnectInternet]) {
////            [SVProgressHUD showWithStatus:@"正在加载..."];
//            [HttpTool getDefaultMemberDiaryInfo];
//        } else {
//            return;
//        }
//    }
//}

//- (void)loadNewData
//{
//    if ([HttpTool isConnectInternet]) {
//        if ([DataBaseTool getDefaultMemberLastDiary] != nil) { //如果数据库中没有最后一条记录
//            NSMutableArray *newDiaryArray = [HttpTool getAllDefaultMemberDiaryByLastDiaryId:[NSString stringWithFormat:@"%@",[[DataBaseTool getDefaultMemberLastDiary] objectForKey:@"id"]]];
//            if (newDiaryArray != nil || newDiaryArray.count != 0) { //有新的数据则刷新默认的数据
//                [DataBaseTool refreshDefaultMemberDiary:newDiaryArray];
//                [self.historyTableView reloadData];
//            }
//        } else  {
//            [SVProgressHUD show];
//            [HttpTool getDefaultMemberDiaryInfo];
//            [self.historyTableView reloadData];
//        }
//    }
//    [self.historyTableView.header endRefreshing];
//}

//+ (void)initialize
//{
//    if (![HttpTool isConnectInternet]) { //没有网络的情况下
//        [[self alloc] setDiaryList:[DataBaseTool getDefaultMemberDiaryInfo]];
//    } else { //有网络的情况下
//        if ([DataBaseTool getDefaultMemberDiaryInfo]== nil || [DataBaseTool getDefaultMemberDiaryInfo].count == 0) { //本地数据库为空得情况下
//            NSMutableArray *tempArray = [HttpTool getDefaultMemberDiaryInfo];
//            if (tempArray == nil || tempArray.count == 0) { //网络上数据为空
//                [[self alloc] setDiaryList:nil];
//            } else { //网络上数据不为空
//                for (NSMutableDictionary *tempDict in tempArray) {
//                    BOOL result = [DataBaseTool addDiary:tempDict];
//                    if (!result) {
//                        NSLog(@"添加记录失败");
//                        break;
//                    }
//                }
//                [[self alloc] setDiaryList:[DataBaseTool getDefaultMemberDiaryInfo]];
//            }
//        } else { //本地数据库不为空的情况下
//            NSMutableDictionary *lastDiaryInfo = [DataBaseTool getDefaultMemberLastDiary]; //取出最后的数据
//            //发送网络请求去获取最新的数据
//            NSMutableArray *newDiaryArray = [HttpTool getAllDefaultMemberDiaryByLastDiaryId:[NSString stringWithFormat:@"%@",lastDiaryInfo[@"id"]]];
//            if (newDiaryArray != nil || newDiaryArray.count != 0) { //有新的数据则刷新默认的数据
//                if ([DataBaseTool refreshDefaultMemberDiary:newDiaryArray]) {
//                    [[self alloc] setDiaryList: [DataBaseTool getDefaultMemberDiaryInfo]];
//                }
//            } else {
//                [[self alloc] setDiaryList:[DataBaseTool getDefaultMemberDiaryInfo]];
//            }
//        }
//    }
//}

- (IBAction)onClickCheckBtn {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"HardwareNavigationController"];
    [self presentViewController:vc animated:YES completion:nil];
}



/*
- (void)selectedMemberChanged
{
    GlobalData *gd = [GlobalData sharedData];
    //重新设置diary
    //选取默认用户
    NSDictionary *selectedMemberInfoDict;
    for (NSDictionary *dict in gd.members) {
        NSString *isdefaultStr = [NSString stringWithFormat:@"%@",dict[@"isdefault"]];
        if ([isdefaultStr isEqualToString:@"1"]) {
            selectedMemberInfoDict = dict;
            break;
        }
    }
    NSString *host = [GetServerUrlViewController getServerUrl];
    NSString *urlStr = [NSString stringWithFormat:@"http://%@/api.php?m=open&c=member&a=record",host];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"mid"] = selectedMemberInfoDict[@"id"];
    AFHTTPRequestOperationManager *mgr = [AFHTTPRequestOperationManager manager];
    [mgr POST:urlStr parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([responseObject[@"status"] isEqual:[NSNumber numberWithInt:1]]) {
            gd.diary = responseObject[@"data"];
        } else {
            gd.diary = nil;
        }

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@",error);
    }];
    [self.historyTableView reloadData];
}
*/


- (void)removeDiarySuccessNotification
{
    self.diaryList = [[DataBaseTool shared] getDefaultMemberDiaryFromPage:1];
    self.page = 1;
    if (self.diaryList == nil || self.diaryList.count == 0) {
        self.historyTableView.hidden = YES;
        self.checkTip.hidden = NO;
        self.noHistoryTip.hidden = NO;
    } else {
        self.historyTableView.hidden = NO;
        self.checkTip.hidden = YES;
        self.noHistoryTip.hidden = YES;
        [self.historyTableView reloadData];
    }
    
    [SVProgressHUD showSuccessWithStatus:@"删除成功!" maskType:SVProgressHUDMaskTypeClear];
}



-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath row]==0) {
        return UITableViewCellEditingStyleNone;
    }
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath row]==0) {
        return;
    }
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSInteger section = indexPath.section;
        NSInteger row = indexPath.row;

        NSMutableDictionary *dayDict = [self.historyList objectAtIndex:section];
        NSMutableArray *detail = [dayDict objectForKey:@"detail"];
        NSDictionary *oneDetail = [detail objectAtIndex:row-1];
        NSNumber *tid = [oneDetail objectForKey:@"tid"];
        [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
        [HttpTool removeDiary:[NSString stringWithFormat:@"%@",tid]];
        /*
        [detail removeObjectAtIndex:row-1];
        if (detail.count<=0) {
            [self.historyList removeObjectAtIndex:section];
        }
        [self.historyTableView reloadData];
        
        GlobalData *gd = [GlobalData sharedData];
        for (int i=0; i<gd.diary.count; i++) {
            NSDictionary *oneDiary = [gd.diary objectAtIndex:i];
            NSNumber *_tid = [oneDiary objectForKey:@"id"];
            if ([tid intValue]==[_tid intValue]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"DeleteDiaryNotification" object:nil];
                break;
            }
        }
        
        //取出选中的成员
        NSString *mid;
        for (NSDictionary *dict in gd.members) {
            NSString *isdefaultStr = [NSString stringWithFormat:@"%@",dict[@"isdefault"]];
            if ([isdefaultStr isEqualToString:@"1"]) {
                mid = [NSString stringWithFormat:@"%@",dict[@"id"]];
                break;
            }
        }
        gd.nowMemberId = mid;
        
        
        [[TTNetworkHelper sharedSession] deleteDiary:gd.nowMemberId Id:[NSString stringWithFormat:@"%@",tid] dismissProgressView:YES];
        */
        
//        [_objects removeObjectAtIndex:indexPath.row];
//        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else {
//        NSLog(@"Unhandled editing style! %d", editingStyle);
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [[SDWebImageManager sharedManager].imageCache cleanDisk];
    self.historyTableView.delegate = nil;
    self.locationManager.delegate = nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return self.historyList.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section{
    return @"";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    NSDictionary *detailInfo = [self.historyList objectAtIndex:section];
    NSArray *infoList = [detailInfo objectForKey:@"detail"];
    return infoList.count+1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSUInteger section = [indexPath section];
    NSInteger row = [indexPath row];
    if (row==0) {
        return 43;
    }
    NSDictionary *detailInfo = [self.historyList objectAtIndex:section];
    NSArray *infoList = [detailInfo objectForKey:@"detail"];
    NSDictionary *dayDetailInfo = [infoList objectAtIndex:(row-1)];
    int photo_count = [[dayDetailInfo objectForKey:@"photo_count"] intValue];
    if (photo_count>0) {
        return 103;
    }
    return 103;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSUInteger section = [indexPath section];
    NSInteger row = [indexPath row];
    NSDictionary *detailInfo = [self.historyList objectAtIndex:section];
    NSString *dayInfo = [detailInfo objectForKey:@"day"];
    NSArray *infoList = [detailInfo objectForKey:@"detail"];
    
    if (row==0) {
        CheckDayTableViewCell *cell =[tableView dequeueReusableCellWithIdentifier:@"CheckDayTableViewCell"];
        cell.dayLabel.text = dayInfo;
        return cell;
    } else {
        NSDictionary *dayDetailInfo = [infoList objectAtIndex:(row-1)];
        CheckDayDetailTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CheckDayDetailTableViewCell"];
        cell.timeLabel.text = [dayDetailInfo objectForKey:@"time"];
        cell.symptomLabel.text = [dayDetailInfo objectForKey:@"symbton"];
        
        GlobalData *gd = [GlobalData sharedData];
        int type = (gd.temperatureType!=nil&&[gd.temperatureType intValue]==2)?2:1;
        NSNumber *value = [dayDetailInfo objectForKey:@"value"];
        if (type==2) {
            float tempFloat = [value floatValue];
            tempFloat = tempFloat*1.8+32;
            cell.temperatureLabel.text = [NSString stringWithFormat:@"%.1f℉",tempFloat];
        }
        else {
            cell.temperatureLabel.text = [NSString stringWithFormat:@"%.1f℃",[[dayDetailInfo objectForKey:@"value"] floatValue]];
        }
        int photo_count = [[dayDetailInfo objectForKey:@"photo_count"] intValue];
        if (photo_count>0) {
            //GlobalData *gd = [GlobalData sharedData];
            //[cell setImageList:gd.nowMemberId WithTime:[dayDetailInfo objectForKey:@"date"] WithCount:photo_count];
            NSArray *pics = dayDetailInfo[@"pics"];
            [cell setImageListWithPics:pics];
        }
        else{
            [cell clearImageList];
        }
        
        //获取当前row的member_id
        NSNumber *member_id = [dayDetailInfo objectForKey:@"member_id"];
        NSString *nickName = @"";
        for (NSDictionary *memberInfoDict in gd.members) {
            if ([[memberInfoDict objectForKey:@"id"] integerValue] == [member_id integerValue]) {
                nickName = [memberInfoDict objectForKey:@"name"];
            }
        }
        cell.nickNameLabel.text = nickName;
        return cell;

    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    NSUInteger section = [indexPath section];
    NSInteger row = [indexPath row];
    if (row==0) {
        return;
    }
    NSDictionary *detailInfo = [self.historyList objectAtIndex:section];
    NSString *dayInfo = [detailInfo objectForKey:@"day"];
    NSArray *infoList = [detailInfo objectForKey:@"detail"];
    
    NSDictionary *dayDetailInfo = [infoList objectAtIndex:(row-1)];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    HealthDetailViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"HealthDetailViewController"];
    vc.detailRecordInfo = dayDetailInfo;
    vc.dayInfo = dayInfo;
    
    DetailRecordNavigationController *nav = [[DetailRecordNavigationController alloc] initWithRootViewController:vc];
    
    NSLog(@"dayDetailInfo=%@",dayDetailInfo);
    NSLog(@"dayInfo=%@",dayInfo);
    
    
    [self presentViewController:nav animated:YES completion:nil];
}

#pragma mark - 后续加入代码


- (NSMutableArray *)historyList
{
    //先判断数据库中是否存在测温记录
    NSMutableArray *list = self.diaryList;
    NSMutableArray *showList = [NSMutableArray array];
    for (int i=0; i<list.count; i++) {
        NSDictionary *dayHistory = [list objectAtIndex:i];
        NSNumber *date = [dayHistory objectForKey:@"date"];
        NSNumber *tid = [dayHistory objectForKey:@"id"];
        NSNumber *member_id = [dayHistory objectForKey:@"member_id"];
        NSArray *pics = [dayHistory objectForKey:@"pics"];
        NSDate *dateValue = [NSDate dateWithTimeIntervalSince1970:[date longLongValue]];
        NSDateFormatter *dateFormater = [NSDateFormatter new];
        dateFormater.dateFormat = @"yyyy.M.d";
        NSString *dayStr = [dateFormater stringFromDate:dateValue];
        
        NSDateFormatter *timeFormater = [[NSDateFormatter alloc] init];
        timeFormater.locale=[[NSLocale alloc]initWithLocaleIdentifier:@"en_US"];
        [timeFormater setDateFormat:@"h:mm a"];
        NSString *timeStr = [timeFormater stringFromDate:dateValue];
        
        int photo_count = [[dayHistory objectForKey:@"photo_count"] intValue];
        
        NSMutableArray *dayDiary;
        for (int j=0; j<showList.count; j++) {
            NSDictionary *_dayDiary = [showList objectAtIndex:j];
            NSString *_dayStr = [_dayDiary objectForKey:@"day"];
            if ([_dayStr isEqualToString:dayStr]) {
                dayDiary = [_dayDiary objectForKey:@"detail"];
                break;
            }
        }
        if (dayDiary==nil) {
            dayDiary = [NSMutableArray array];
            NSMutableDictionary *showDict = [NSMutableDictionary dictionary];
            [showDict setObject:dayStr forKey:@"day"];
            [showDict setObject:dayDiary forKey:@"detail"];
            [showList addObject:showDict];
        }
        
        NSMutableDictionary *timeDiary = [NSMutableDictionary dictionary];
        NSString *temperature = [dayHistory objectForKey:@"temperature"];
        [timeDiary setObject:temperature forKey:@"value"];
        
        NSString *description = [dayHistory objectForKey:@"description"];
        
        NSString *symptonStr = @"";
        NSArray *symptons = [self getSymptons:[dayHistory objectForKey:@"symptoms"]];
        if (symptons==nil||symptons.count==0) {
            symptonStr = @"";
        }
        else{
            for (int i=0; i<symptons.count; i++) {
                NSNumber *tag = [symptons objectAtIndex:i];
                GlobalData *gd = [GlobalData sharedData];
                NSString *name = [gd getSymptonNameByTag:tag];
                symptonStr = [symptonStr stringByAppendingString:[NSString stringWithFormat:@"%@",name]];
                symptonStr = [symptonStr stringByAppendingString:@" "];
            }
        }
        [timeDiary setObject:symptonStr forKey:@"symbton"];
        [timeDiary setObject:timeStr forKey:@"time"];
        [timeDiary setObject:date forKey:@"date"];
        [timeDiary setObject:[NSNumber numberWithInt:photo_count] forKey:@"photo_count"];
        [timeDiary setObject:tid forKey:@"tid"];
        [timeDiary setObject:description forKey:@"desc"];
        [timeDiary setObject:member_id forKey:@"member_id"];
        [timeDiary setObject:pics forKey:@"pics"];
        [dayDiary addObject:timeDiary];
    }
    
    _historyList = showList;
    return _historyList;
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
