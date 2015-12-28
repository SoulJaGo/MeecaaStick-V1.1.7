//
//  BaiduMapViewController.m
//  HomeKinsa
//
//  Created by SoulJa on 15/7/23.
//  Copyright (c) 2015年 Mikai. All rights reserved.
//

#import "BaiduMapViewController.h"
//引入百度地图
#import <BaiduMapAPI/BMapKit.h>

@interface BaiduMapViewController () <BMKMapViewDelegate,BMKLocationServiceDelegate>
/**
 *  百度地图视图
 */
@property (nonatomic,retain) BMKMapView *mapView;
/**
 *  地理位置服务
 */
@property (nonatomic,retain) BMKLocationService *locService;
@end

@implementation BaiduMapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //初始化地图视图
    [self setupMapView];
    
    //初始化地图定位
    [self setupLocService];
}

- (BMKMapView *)mapView
{
    if (_mapView == nil) {
        self.mapView = [[BMKMapView alloc] init];
    }
    return _mapView;
}

- (BMKLocationService *)locService
{
    if (_locService == nil) {
        self.locService = [[BMKLocationService alloc] init];
    }
    return _locService;
}

/**
 *  初始化地图视图
 */
- (void)setupMapView
{
    BMKMapView *mapView = [[BMKMapView alloc] init];
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    mapView.frame = CGRectMake(0, 90, screenSize.width, screenSize.height);
    mapView.showsUserLocation = YES;
    //地图比例
    mapView.zoomLevel = 18;
    mapView.isSelectedAnnotationViewFront = YES;
    self.mapView = mapView;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    _mapView.delegate = self;
}
/**
 *  初始化地图定位
 */
- (void)setupLocService
{
    //设置定位精确度
    [BMKLocationService setLocationDesiredAccuracy:kCLLocationAccuracyBest];
    //指定最小距离更新
    [BMKLocationService setLocationDistanceFilter:100.f];
    //初始化BMKLocationService
    self.locService = [[BMKLocationService alloc]init];
    self.locService.delegate = self;
    //启动LocationService
    [self.locService startUserLocationService];
}

//处理位置坐标更新
- (void)didUpdateBMKUserLocation:(BMKUserLocation *)userLocation
{
    [self.mapView updateLocationData:userLocation];
    //确定地图中心点
    CLLocationCoordinate2D loc2D;
    loc2D.latitude = userLocation.location.coordinate.latitude;
    loc2D.longitude = userLocation.location.coordinate.longitude;
    [self.mapView setCenterCoordinate:loc2D animated:YES];
    [self.view addSubview:self.mapView];
    
    NSLog(@"didUpdateUserLocation lat %f,long %f",userLocation.location.coordinate.latitude,userLocation.location.coordinate.longitude);
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [_mapView viewWillDisappear];
    self.mapView.delegate = nil;
    if (_locService) {
        [_locService stopUserLocationService];
    }
    _locService.delegate = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)dealloc
{
    if (_mapView) {
        _mapView = nil;
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
