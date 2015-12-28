//
//  MessageNavigationController.m
//  HomeKinsa
//
//  Created by SoulJa on 15/9/22.
//  Copyright © 2015年 Mikai. All rights reserved.
//

#import "MessageNavigationController.h"
#import "UIImage+ImageEffects.h"

@interface MessageNavigationController ()

@end

@implementation MessageNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"消息中心";
    self.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName:[UIColor whiteColor]};
    [self.navigationBar setTranslucent:NO];
    [self.navigationBar setBackgroundImage:[UIImage imageWithColor:COLOR_NAV_BACKGROUND] forBarMetrics:UIBarMetricsDefault];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
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
