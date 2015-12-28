//
//  TTErrorHelper.h
//  wkw
//
//  Created by Zhang guangchun on 15/2/18.
//  Copyright (c) 2015年 Tice Tang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TTErrorHelper : NSObject

+ (id)shared;

- (BOOL)handleError:(int)error;
@end
