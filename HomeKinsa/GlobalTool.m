//
//  GlobalTool.m
//  HomeKinsa
//
//  Created by SoulJa on 15/10/10.
//  Copyright © 2015年 Mikai. All rights reserved.
//

#import "GlobalTool.h"
#import "sys/utsname.h"

@implementation GlobalTool

/**
 *  判断设备型号
 */
+ ( NSString *)deviceString
{
    // 需要#import "sys/utsname.h"
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceString = [ NSString stringWithCString:systemInfo.machine encoding: NSUTF8StringEncoding ];
    
    if ([deviceString isEqualToString:@ "iPhone1,1" ])     return @ "iPhone 1G" ;
    if ([deviceString isEqualToString:@ "iPhone1,2" ])     return @ "iPhone 3G" ;
    if ([deviceString isEqualToString:@ "iPhone2,1" ])     return @ "iPhone 3GS" ;
    if ([deviceString isEqualToString:@ "iPhone3,1" ])     return @ "iPhone 4" ;
    if ([deviceString isEqualToString:@ "iPhone4,1" ])     return @ "iPhone 4S" ;
    if ([deviceString isEqualToString:@ "iPhone5,2" ])     return @ "iPhone 5" ;
    if ([deviceString isEqualToString:@ "iPhone5,3" ])     return @ "iPhone 5C" ;
    if ([deviceString isEqualToString:@ "iPhone6,2" ])     return @ "iPhone 5S" ;
    if ([deviceString isEqualToString:@ "iPhone7,1" ])     return @ "iPhone 6 Plus" ;
    if ([deviceString isEqualToString:@ "iPhone7,2" ])     return @ "iPhone 6" ;
    if ([deviceString isEqualToString:@ "iPhone8,1" ])     return @ "iPhone 6S" ;
    if ([deviceString isEqualToString:@ "iPhone8,2" ])     return @ "iPhone 6S Plus" ;
    if ([deviceString isEqualToString:@ "iPhone3,2" ])     return @ "Verizon iPhone 4" ;
    if ([deviceString isEqualToString:@ "iPod1,1" ])       return @ "iPod Touch 1G" ;
    if ([deviceString isEqualToString:@ "iPod2,1" ])       return @ "iPod Touch 2G" ;
    if ([deviceString isEqualToString:@ "iPod3,1" ])       return @ "iPod Touch 3G" ;
    if ([deviceString isEqualToString:@ "iPod4,1" ])       return @ "iPod Touch 4G" ;
    if ([deviceString isEqualToString:@ "iPad1,1" ])       return @ "iPad" ;
    if ([deviceString isEqualToString:@ "iPad2,1" ])       return @ "iPad 2 (WiFi)" ;
    if ([deviceString isEqualToString:@ "iPad2,2" ])       return @ "iPad 2 (GSM)" ;
    if ([deviceString isEqualToString:@ "iPad2,3" ])       return @ "iPad 2 (CDMA)" ;
    if ([deviceString isEqualToString:@ "iPad4,4" ])       return @ "iPad Mini" ;
    if ([deviceString isEqualToString:@ "i386" ])         return @ "Simulator" ;
    if ([deviceString isEqualToString:@ "x86_64" ])       return @ "Simulator" ;
    NSLog (@ "NOTE: Unknown device type: %@" , deviceString);
    return deviceString;
}

/**
 *  判端是否为iPad
 */
+ (BOOL)isIPad{
    NSString *deviceString = [self deviceString];
    return [deviceString hasPrefix:@"iPad"];
}

+ (id)shared
{
    static GlobalTool *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (sharedInstance == nil) {
            sharedInstance = [[self alloc] init];
        }
    });
    return sharedInstance;
}

/**
 *  获取当前时间
 */
- (NSString *)getCurrentDate {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *dateStr = [formatter stringFromDate:[NSDate date]];
    return dateStr;
}

@end
