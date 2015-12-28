//
//  UIViewController+ProgressHUD.m
//  R2Lik
//
//  Created by Zhang guangchun on 15/1/21.
//  Copyright (c) 2015年 R2Digital. All rights reserved.
//

#import "UIViewController+ProgressHUD.h"
#import <SVProgressHUD.h>

@implementation UIViewController (ProgressHUD)

- (void) showProgressHUD{
    [SVProgressHUD show];
}

- (void) dismissProgressHUD{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD dismiss];
    });
}

@end
