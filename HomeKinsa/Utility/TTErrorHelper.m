//
//  TTErrorHelper.m
//  wkw
//
//  Created by Zhang guangchun on 15/2/18.
//  Copyright (c) 2015年 Tice Tang. All rights reserved.
//

#import "TTErrorHelper.h"
//#import "TTSimpleDailogView.h"
#import <SVProgressHUD.h>

@implementation TTErrorHelper

+ (id)shared {
    static TTErrorHelper *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

- (id)init {
    if (self = [super init]) {
        
    }
    return self;
}

- (void)dealloc {
    // Should never be called, but just here for clarity really.
}

- (BOOL)handleError:(int)error {
    NSString *errorMessage = @"";
    if (error == 103) {
        errorMessage = @"账户已存在";
    }
    else if (error == 104) {
        errorMessage = @"账户不存在";
    }
    else if (error == 111) {
        errorMessage = @"密码错误";
    }
    
    if (![errorMessage isEqualToString:@""]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
//            TTSimpleDailogView *dialog = [[TTSimpleDailogView alloc] init];
//            [[dialog setMessage:@"提示" message:errorMessage confirmMessage:@"确认" cancelMessage:nil confirmBlock:^{
//            } cancelBlock:nil] show];
        });
        return true;
    }
    
    return false;
}

@end
