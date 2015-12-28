//
//  HealthMapMainViewController.m
//  HomeKinsa
//
//  Created by Zhang guangchun on 15/3/4.
//  Copyright (c) 2015年 Mikai. All rights reserved.
//

#import "HealthMapMainViewController.h"
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "MyAnnotation.h"
#import "TTNetworkHelper.h"
#import "GlobalData.h"
#import "LocationExchange.h"
#import "DataBaseTool.h"
#import "HttpTool.h"
#import "Account.h"

@interface HealthMapMainViewController ()<CLLocationManagerDelegate, MKMapViewDelegate, MKAnnotation>
{
}
@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@property (strong, nonatomic) CLLocationManager* locationManager;
/**
 *  最近的体温
 */
@property (nonatomic,copy) NSString *temperatureStr;
/**
 *  添加锚点的flag
 */
@property (nonatomic,assign) BOOL addAnnotation;
@end

@implementation HealthMapMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.mapView.mapType = MKMapTypeStandard;
    self.mapView.delegate = self;
    self.mapView.showsUserLocation = YES;
    self.mapView.userTrackingMode = MKUserTrackingModeNone;
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.distanceFilter = 1000.0f;
    if ([[[UIDevice currentDevice] systemVersion] doubleValue] > 8.0)
    {
        //设置定位权限 仅ios8有意义
        [self.locationManager requestWhenInUseAuthorization];// 前台定位
        
        //[self.locationManager requestAlwaysAuthorization];// 前后台同时定位
    }
    [self.locationManager startUpdatingLocation];
    
    self.addAnnotation = YES;
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"error:%@", error);
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    NSString *temperatureStr = @"";
    /*
     原有获取最近温度
    GlobalData *gd = [GlobalData sharedData];
    if (gd.diary!=nil &&gd.diary.count>0) {
        NSDictionary *data = [gd.diary objectAtIndex:0];
        
        int type = (gd.temperatureType!=nil&&[gd.temperatureType intValue]==2)?2:1;
        NSNumber *value = [data objectForKey:@"temperature"];
        if (type==2) {
            float tempFloat = [value floatValue];
            tempFloat = tempFloat*1.8+32;
            temperatureStr = [NSString stringWithFormat:@"您最新的体温:%.1f℉",tempFloat];
        }
        else {
            temperatureStr = [NSString stringWithFormat:@"您最新的体温:%@℃",[data objectForKey:@"temperature"]];
        }
    }
    else{
        temperatureStr = @"最近未测温";
    }
     */
    //获取最近的温度
    NSMutableDictionary *lastDiary = [DataBaseTool getDefaultMemberLastDiary];
    if (lastDiary != nil) {
        GlobalData *gd = [GlobalData sharedData];
        int type = (gd.temperatureType!=nil&&[gd.temperatureType intValue]==2)?2:1;
        NSNumber *value = [lastDiary objectForKey:@"temperature"];
        if (type==2) {
            float tempFloat = [value floatValue];
            tempFloat = tempFloat*1.8+32;
            temperatureStr = [NSString stringWithFormat:@"您最新的体温:%.1f℉",tempFloat];
        }
        else {
            temperatureStr = [NSString stringWithFormat:@"您最新的体温:%@℃",[lastDiary objectForKey:@"temperature"]];
        }

    } else {
        temperatureStr = @"最近未测温";
    }
    self.temperatureStr = temperatureStr;
    [self.locationManager stopUpdatingLocation];
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    CLLocationCoordinate2D loc = [userLocation coordinate];
    NSLog(@"%f---%f",loc.latitude,loc.longitude);
    //放大地图到自身的经纬度位置。
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(loc, 250, 250);
    [self.mapView setRegion:region animated:YES];
    if (self.addAnnotation) {
        //判断是否有温度记录
        GlobalData *gd = [GlobalData sharedData];
        if(gd.diary.count>0 && gd.diary!=nil) {
            for (NSDictionary *tempDict in gd.diary) {
                double longitude = [tempDict[@"longitude"] doubleValue];
                double latitude = [tempDict[@"latitude"] doubleValue];
                double time = [tempDict[@"date"] doubleValue];
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
                NSDate *date = [[NSDate alloc] initWithTimeIntervalSince1970:time];
                NSString *timeStr = [formatter stringFromDate:date];
                if ((int)longitude!=0 && (int)latitude!=0) {
                    CLLocationCoordinate2D location = CLLocationCoordinate2DMake(latitude, longitude);
                    int type = (gd.temperatureType!=nil&&[gd.temperatureType intValue]==2)?2:1;
                    NSNumber *value = [tempDict objectForKey:@"temperature"];
                    NSString *temperatureStr = @"";
                    if (type==2) {
                        float tempFloat = [value floatValue];
                        tempFloat = tempFloat*1.8+32;
                        temperatureStr = [NSString stringWithFormat:@"测量体温:%.1f℉",tempFloat];
                    }
                    else {
                        temperatureStr = [NSString stringWithFormat:@"测量体温:%@℃",[tempDict objectForKey:@"temperature"]];
                    }
                    MyAnnotation *anno = [[MyAnnotation alloc] initWithCoordinates:location title:temperatureStr subTitle:timeStr];
                    [self.mapView addAnnotation:anno];
                    [self.mapView selectedAnnotations];
                    
                }
            }
            MyAnnotation *lastAnno = [[MyAnnotation alloc] initWithCoordinates:loc title:@"您的位置" subTitle:self.temperatureStr];
            [self.mapView addAnnotation:lastAnno];
            [self.mapView selectAnnotation:lastAnno animated:YES];
        } else {
            MyAnnotation *anno = [[MyAnnotation alloc] initWithCoordinates:loc title:@"您的位置" subTitle:self.temperatureStr];
            [self.mapView addAnnotation:anno];
            [self.mapView selectAnnotation:anno animated:YES];
        }
        self.addAnnotation = false;
    }
    self.mapView.showsUserLocation = NO;
    [self.locationManager stopUpdatingLocation];
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

@end
