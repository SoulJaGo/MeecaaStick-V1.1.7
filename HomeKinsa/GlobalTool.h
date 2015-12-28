//
//  GlobalTool.h
//  HomeKinsa
//
//  Created by SoulJa on 15/10/10.
//  Copyright © 2015年 Mikai. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GlobalTool : NSObject
/**
 *  判断设备型号
 */
+ ( NSString *)deviceString;
/**
 *  判端是否为iPad
 */
+ (BOOL)isIPad;

+ (id)shared;
/**
 *  是否重新进入前台页面
 */
@property (nonatomic,assign) BOOL isFromBackground;
/**
 *  获取当前时间
 */
- (NSString *)getCurrentDate;
/**
 *  地理位置
 */
@property (nonatomic,copy) NSString *city;
@property (nonatomic,assign) BOOL FromCheckToBackground;
@property (nonatomic,copy) NSString *CheckStarttime;
@property (nonatomic,copy) NSString *LastCheckTemp;
@property (nonatomic,copy) NSString *LastCheckType;
@end
