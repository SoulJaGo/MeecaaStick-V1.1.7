//
//  TTToolsHelper.h
//  wkw
//
//  Created by Zhang guangchun on 15/1/21.
//  Copyright (c) 2015年 Tice Tang. All rights reserved.
//

#ifndef wkw_TTToolsHelper_h
#define wkw_TTToolsHelper_h

#import "GlobalData.h"
#import <MessageUI/MessageUI.h>

#define isPhone5 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640, 1136), [[UIScreen mainScreen] currentMode].size) : NO)
#define isPhone4 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640, 960), [[UIScreen mainScreen] currentMode].size) : NO)
#define IS_IOS7 (([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)? (YES):(NO))
#define IS_IOS6 (([[[UIDevice currentDevice] systemVersion] floatValue] >= 6.0)? (YES):(NO))

//检查系统版本
#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

//读取本地图片
#define LOADIMAGE(file,ext) [UIImage imageWithContentsOfFile:[[NSBundle mainBundle]pathForResource:file ofType:ext]]

//定义UIImage对象
#define IMAGE(imageName) [UIImage imageNamed:[NSString stringWithFormat:@"%@",imageName]]

// rgb颜色转换（16进制->10进制）
#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

// 获取RGB颜色
#define RGBA(r,g,b,a) [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:a]
#define RGB(r,g,b) RGBA(r,g,b,1.0f)

// 获取屏幕大小
#define kDeviceWidth [UIScreen mainScreen].bounds.size.width
#define KDeviceHeight [UIScreen mainScreen].bounds.size.height

typedef void(^noticeViewHandler)();

@interface TTToolsHelper : NSObject<MFMessageComposeViewControllerDelegate>

+ (id)shared;
- (NSMutableArray *) grabContactsByJsonWithAPhoneNumber;
- (BOOL) isMobileNumberClassification:(NSString *)phoneNum;
- (void) showAlertMessage:(NSString *)msg;
- (void) showNoticetMessage:(NSString *)msg handler:(noticeViewHandler)handler;
- (NSString *) getUUID;
- (NSString *) compareCurrentTime:(NSDate*) compareDate;
- (NSString *) getCurrentDateString:(NSString*) format;
- (NSDate *) getDateFromString:(NSString*)dateString format:(NSString *)format;
- (NSString *) getStringFromDate:(NSDate*)date format:(NSString*) format;
- (NSString *)getTimeFormat:(NSTimeInterval)interval;
- (NSTimeInterval) compareCurrentTimeWithSecond:(NSDate*) compareDate outString:(out NSString **)outString;
- (NSTimeInterval) compareCurrentTimeWithSecond:(NSDate*) compareDate outAttributedString:(out NSMutableAttributedString **)outString;
- (NSInteger) getESIDByEID:(NSInteger) eid;
- (NSString*) getExamSiteNamebyESID:(NSInteger) esid;
- (BOOL)isLeftDays:(int)days from:(NSDate *)date;
- (NSDate *) getCurrentTime;
- (NSString *) randomStringWithLength: (int) len;
- (BOOL)isHaveIllegalChar:(NSString *)str;
- (NSString *)toBinarySystemWithDecimalSystem:(NSString *)decimal;
- (NSNumber *)setFlagInIntergerPosition:(NSArray *)flags;
- (NSArray *)getFlagInIntergerPosition:(NSNumber *)value;
- (UIImage *)thumbnailWithImageWithoutScale:(UIImage *)image size:(CGSize)asize;
- (void) sendSMSMessage:(NSString*)mobile body:(NSString*)body viewController:(UIViewController*)viewController;
- (void) showCodeUnavailableDialog:(UIViewController*)viewContoller;
@end

#endif
