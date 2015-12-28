//
//  DetailRecordNavigationController.m
//  HomeKinsa
//
//  Created by SoulJa on 15/10/13.
//  Copyright © 2015年 Mikai. All rights reserved.
//

#import "DetailRecordNavigationController.h"
#import "UIImage+ImageEffects.h"

@interface DetailRecordNavigationController ()

@end

@implementation DetailRecordNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.navigationBar setTranslucent:NO];
    [self.navigationBar setBackgroundImage:[UIImage imageWithColor:COLOR_NAV_BACKGROUND] forBarMetrics:UIBarMetricsDefault];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

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
