//
//  AdViewController.m
//  HomeKinsa
//
//  Created by SoulJa on 15/9/1.
//  Copyright (c) 2015年 Mikai. All rights reserved.
//

#import "AdViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "HttpTool.h"

@interface AdViewController ()

@end

@implementation AdViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if (self.adImageUrlStr) {
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.frame = self.view.bounds;
        [self.view addSubview:imageView];
        [imageView sd_setImageWithURL:[NSURL URLWithString:self.adImageUrlStr] placeholderImage:[UIImage imageNamed:@"ad_background"]];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            UIStoryboard *board = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            UIViewController *vc =[board instantiateViewControllerWithIdentifier:@"MainTabBarViewController"];
            [self presentViewController:vc animated:NO completion:^{
                [HttpTool getAdDict];
            }];
        });
    } else {
        UIStoryboard *board = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        UIViewController *vc =[board instantiateViewControllerWithIdentifier:@"MainTabBarViewController"];
        [self presentViewController:vc animated:NO completion:^{
            [HttpTool getAdDict];
        }];
    }
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
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
