//
//  TTToolsHelper.m
//  wkw
//
//  Created by Zhang guangchun on 15/1/21.
//  Copyright (c) 2015年 Tice Tang. All rights reserved.
//

#import "TTToolsHelper.h"
#import <AddressBook/AddressBook.h>
#import <CRToast/CRToast.h>
#import "SSKeychain.h"
#import <SIAlertView/SIAlertView.h>
//#import "TTSimpleDailogView.h"

@implementation TTToolsHelper

+ (id)shared {
    static TTToolsHelper *shared = nil;
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

- (NSMutableArray *) grabContactsByJsonWithAPhoneNumber {
    NSMutableArray *resultsArray = [[NSMutableArray alloc]init];
    
    CFErrorRef error = nil;
    ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, &error);
    if (!addressBookRef)
    {
        NSLog(@"error: %@", error);
        return nil; // bail
    }
    
    //等待同意后向下执行
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    ABAddressBookRequestAccessWithCompletion(addressBookRef, ^(bool granted, CFErrorRef error){
        dispatch_semaphore_signal(sema);
    });
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    
    CFArrayRef results = ABAddressBookCopyArrayOfAllPeople(addressBookRef);
    for(int i = 0; i < CFArrayGetCount(results); i++) {
        ABRecordRef thisContact = CFArrayGetValueAtIndex(results, i);
        ABMultiValueRef mvr = ABRecordCopyValue(thisContact, kABPersonPhoneProperty);
        
        //check for phone number existence - if the record does have a phone number, push to our array
        int phoneNumbersCount = (int) ABMultiValueGetCount(mvr);
        if (phoneNumbersCount > 0) {
            NSString *name;
            NSMutableDictionary *dicInfoLocal = [NSMutableDictionary dictionaryWithCapacity:0];
            NSString *first = (NSString*)CFBridgingRelease(ABRecordCopyValue(thisContact, kABPersonFirstNameProperty));
            if (first==nil) {
                first = @"";
            }
            NSString *last = (NSString *)CFBridgingRelease(ABRecordCopyValue(thisContact, kABPersonLastNameProperty));
            if (last == nil) {
                last = @"";
            }
            name = [NSString stringWithFormat:@"%@%@", last, first];
            if (name.length == 0){
                name = (NSString *)CFBridgingRelease(ABRecordCopyValue(thisContact, kABPersonOrganizationProperty));
                if (name == nil) {
                    name = @"";
                }
            }
            [dicInfoLocal setObject:name forKey:@"name"];
            
            ABMultiValueRef tmlphone =  ABRecordCopyValue(thisContact, kABPersonPhoneProperty);
            NSMutableArray *telphones = [NSMutableArray array];
            for (int j = 0; j< phoneNumbersCount; j++){
                NSString* telphone = (NSString*)CFBridgingRelease(ABMultiValueCopyValueAtIndex(tmlphone, j));
                if (telphone == nil) {
                    telphone = @"";
                }
                telphone = [telphone stringByReplacingOccurrencesOfString:@"-" withString:@""];
                telphone = [telphone stringByReplacingOccurrencesOfString:@"*" withString:@""];
                telphone = [telphone stringByReplacingOccurrencesOfString:@"+" withString:@""];
                telphone = [telphone stringByReplacingOccurrencesOfString:@"#" withString:@""];
                telphone = [telphone stringByReplacingOccurrencesOfString:@" " withString:@""];
                telphone = [telphone stringByReplacingOccurrencesOfString:@"(" withString:@""];
                telphone = [telphone stringByReplacingOccurrencesOfString:@")" withString:@""];
                telphone = [telphone stringByReplacingOccurrencesOfString:@" " withString:@""];
                [telphones addObject:telphone];
            }
            [dicInfoLocal setObject:telphones forKey:@"tel"];
            [dicInfoLocal setObject:@(1) forKey:@"type"];
            [resultsArray addObject:dicInfoLocal];
        }
    }
    
//    NSString *jsonString;
//    NSError *jsonError;
//    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:resultsArray options:kNilOptions error:&jsonError];
//    if (! jsonData) {
//        NSLog(@"Got an error: %@", error);
//    } else {
//        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
//    }
    
    return resultsArray;
    
    //NSLog(@"jsonString:%@", jsonString);
    /*self.savedArrayOfContactsWithPhoneNumbers = resultsArray;
     
     NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:@"firstName" ascending:true];
     NSArray *sortDescriptors = [NSArray arrayWithObject:sorter];
     [self.savedArrayOfContactsWithPhoneNumbers sortUsingDescriptors:sortDescriptors];
     
     dispatch_async(dispatch_get_main_queue(), ^{
     [self.delegate didFinishGrabbingContactsFromAddressBook];
     });*/
    
}

- (NSString *) getUUID{
    NSString *retrieveuuid = [SSKeychain passwordForService:@"com.zhigen.wkw" account:@"wkw-uuid"];
    
    if ( retrieveuuid == nil || [retrieveuuid isEqualToString:@""]){
        CFUUIDRef uuid = CFUUIDCreate(NULL);
        assert(uuid != NULL);
        CFStringRef uuidStr = CFUUIDCreateString(NULL, uuid);
        retrieveuuid = [NSString stringWithFormat:@"%@", uuidStr];
        [SSKeychain setPassword:retrieveuuid forService:@"com.zhigen.wkw" account:@"wkw-uuid"];
    }
    
    return retrieveuuid;
}

- (NSString *) compareCurrentTime:(NSDate*) compareDate{
    NSTimeInterval  timeInterval = [compareDate timeIntervalSinceNow];
    long temp = 0;
    NSString *result;
    if (timeInterval < 60) {
        result = [NSString stringWithFormat:@"刚刚"];
    }
    else if((temp = timeInterval/60) <60){
        result = [NSString stringWithFormat:@"%ld分钟",temp];
    }
    
    else if((temp = temp/60) <24){
        result = [NSString stringWithFormat:@"%ld小时",temp];
    }
    
    else if((temp = temp/24)){
        result = [NSString stringWithFormat:@"%ld天",temp];
    }
//    else if((temp = temp/30) <12){
//        result = [NSString stringWithFormat:@"%ld月",temp];
//    }
//    else{
//        temp = temp/12;
//        result = [NSString stringWithFormat:@"%ld年",temp];
//    }
    
    return  result;
}

- (UIImage*) createImageWithColor: (UIColor*) color size:(CGSize) size{
    CGRect rect=CGRectMake(0.0f, 0.0f, size.width, size.height);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return theImage;
}

- (NSString *) getStringFromDate:(NSDate*)date format:(NSString*) format{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:format];//@"MM月dd日"
    
    return [dateFormatter stringFromDate:date];
}

- (NSString *) getCurrentDateString:(NSString*) format{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:format];//@"MM月dd日"
    
    NSDate *localeDate = [self getCurrentTime];
//    NSTimeZone *zone = [NSTimeZone systemTimeZone];
//    NSInteger interval = [zone secondsFromGMTForDate: date];
//    NSDate *localeDate = [date  dateByAddingTimeInterval: interval];
    
    return [dateFormatter stringFromDate:localeDate];
}

- (NSDate *) getDateFromString:(NSString*)dateString format:(NSString *)format{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:format];
    return [dateFormatter dateFromString:dateString];
}

- (BOOL) isMobileNumberClassification:(NSString *)phoneNum{
    if (phoneNum.length==11&&[[phoneNum substringToIndex:1] isEqualToString:@"1"]) {
        return YES;
    }
    return NO;
    
    
    /**
     * 手机号码
     * 移动：134[0-8],135,136,137,138,139,150,151,157,158,159,182,187,188,1705
     * 联通：130,131,132,152,155,156,185,186,1709
     * 电信：133,1349,153,180,189,1700
     */
    //    NSString * MOBILE = @"^1((3//d|5[0-35-9]|8[025-9])//d|70[059])\\d{7}$";//总况
    
    /**®
     10         * 中国移动：China Mobile
     11         * 134[0-8],135,136,137,138,139,150,151,157,158,159,182,187,188，1705
     12         */
//    NSString * CM = @"^1(34[0-8]|(3[5-9]|5[017-9]|8[278])\\d|705)\\d{7}$";
    /**
     15         * 中国联通：China Unicom
     16         * 130,131,132,152,155,156,185,186,1709
     17         */
//    NSString * CU = @"^1((3[0-2]|5[256]|8[56])\\d|709)\\d{7}$";
    /**
     20         * 中国电信：China Telecom
     21         * 133,1349,153,180,189,1700
     22         */
//    NSString * CT = @"^1((33|53|8[09])\\d|349|700)\\d{7}$";
    
    /**
     25         * 大陆地区固话及小灵通
     26         * 区号：010,020,021,022,023,024,025,027,028,029
     27         * 号码：七位或八位
     28         */
//    NSString * PHS = @"^0(10|2[0-5789]|\\d{3})\\d{7,8}$";
    
    /*
    //    NSPredicate *regextestmobile = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", MOBILE];
    NSPredicate *regextestcm = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", CM];
    NSPredicate *regextestcu = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", CU];
    NSPredicate *regextestct = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", CT];
    NSPredicate *regextestphs = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",PHS];
    
    if (([regextestcm evaluateWithObject:phoneNum] == YES)
        || ([regextestct evaluateWithObject:phoneNum] == YES)
        || ([regextestcu evaluateWithObject:phoneNum] == YES)
        || ([regextestphs evaluateWithObject:phoneNum] == YES))
    {
        return YES;
    }
    else
    {
        return NO;
    }*/
}

- (void) showNoticetMessage:(NSString *)msg handler:(noticeViewHandler)handler{
//    dispatch_async(dispatch_get_main_queue(), ^{
//        SIAlertView *alertView = [[SIAlertView alloc] initWithTitle:@"提醒" andMessage:msg];
//        [alertView addButtonWithTitle:@"确定"
//                                 type:SIAlertViewButtonTypeDefault
//                              handler:^(SIAlertView *alert) {
//                                  handler();
//                              }];
//        alertView.transitionStyle = SIAlertViewTransitionStyleBounce;
//        [alertView show];
//    });    
    SIAlertView *alertView = [[SIAlertView alloc] initWithTitle:@"提醒" andMessage:msg];
    [alertView addButtonWithTitle:@"确定"
                             type:SIAlertViewButtonTypeDefault
                          handler:^(SIAlertView *alert) {
                              handler();
                          }];
    alertView.transitionStyle = SIAlertViewTransitionStyleBounce;
    [alertView show];
}

- (void) showAlertMessage:(NSString *)msg{
    dispatch_async(dispatch_get_main_queue(), ^{
        SIAlertView *alertView = [[SIAlertView alloc] initWithTitle:@"提醒" andMessage:msg];
        [alertView addButtonWithTitle:@"确定"
                                 type:SIAlertViewButtonTypeDefault
                              handler:^(SIAlertView *alert) {
                              }];
        alertView.transitionStyle = SIAlertViewTransitionStyleBounce;
        [alertView show];
    });
}

- (NSString *)getTimeFormat:(NSTimeInterval)interval
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
    NSDate *dd = [NSDate dateWithTimeIntervalSince1970:interval];
    return [formatter stringFromDate:dd];
}

- (BOOL)isLeftDays:(int)days from:(NSDate *)date
{
    NSDate *nowDate = [self getCurrentTime];
    NSTimeInterval oneDay = 24*60*60;
    NSDate *theDate = [nowDate initWithTimeIntervalSinceNow:-oneDay*days];
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSUInteger unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
    NSDateComponents *theDateComponent = [calendar components:unitFlags fromDate:theDate];
    NSDateComponents *lastPrayDateComponent = [calendar components:unitFlags fromDate:date];
    if ([theDateComponent year]==[lastPrayDateComponent year]
        &&[theDateComponent month]==[lastPrayDateComponent month]
        &&[theDateComponent day]==[lastPrayDateComponent day]) {
        return true;
    }
    return false;
}

- (NSDate *) getCurrentTime{
    GlobalData *gd = [GlobalData sharedData];
    NSDate *now = [[NSDate date] dateByAddingTimeInterval:gd.serverTimeDifference];
    return now;
}


-(NSString *) randomStringWithLength: (int) len {
    
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
    
    for (int i=0; i<len; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random() % [letters length]]];
    }
    
    return randomString;
}

- (BOOL)isHaveIllegalChar:(NSString *)str{
    NSCharacterSet *doNotWant = [NSCharacterSet characterSetWithCharactersInString:@"[]{}（#%-*+=_）\\|~(＜＞$%^&*)_+ "];
    NSRange range = [str rangeOfCharacterFromSet:doNotWant];
    return range.location<str.length;
}

- (NSString *)toBinarySystemWithDecimalSystem:(NSString *)decimal
{
    int num = [decimal intValue];
    int remainder = 0;      //余数
    int divisor = 0;        //除数
    
    NSString * prepare = @"";
    
    while (true)
    {
        remainder = num%2;
        divisor = num/2;
        num = divisor;
        prepare = [prepare stringByAppendingFormat:@"%d",remainder];
        
        if (divisor == 0)
        {
            break;
        }
    }
    
    NSString * result = @"";
    for (int i = prepare.length - 1; i >= 0; i --)
    {
        result = [result stringByAppendingFormat:@"%@",
                  [prepare substringWithRange:NSMakeRange(i , 1)]];
    }
    
    return result;
}

- (NSArray *)getFlagInIntergerPosition:(NSNumber *)value{
    NSString *str = [self toBinarySystemWithDecimalSystem:[NSString stringWithFormat:@"%@",value]];
    NSMutableArray *positions = [NSMutableArray array];
    for (int i=0; i<str.length; i++) {
        NSString *tmp = [str substringWithRange:NSMakeRange(i, 1)];
        if ([tmp isEqualToString:@"1"]) {
            [positions addObject:[NSNumber numberWithInt:(str.length-i-1)]];
        }
    }
    return positions;
}

- (NSNumber *)setFlagInIntergerPosition:(NSArray *)flags{
    int64_t value = 0;
    for (int i = 0; i<flags.count; i++) {
        int pos = [[flags objectAtIndex:i] intValue];
        int64_t temp = (1<<pos)&0xffffffff;
        value = value | temp;
    }
    return [NSNumber numberWithLong:value];
}

- (UIImage *)thumbnailWithImageWithoutScale:(UIImage *)image size:(CGSize)asize{
    
    UIImage *newimage;
    if (nil == image) {
        newimage = nil;
    }else{
        CGSize oldsize = image.size;
        CGRect rect;
        if (asize.width/asize.height > oldsize.width/oldsize.height) {
            rect.size.width = asize.height*oldsize.width/oldsize.height;
            rect.size.height = asize.height;
            rect.origin.x = (asize.width - rect.size.width)/2;
            rect.origin.y = 0;
        }else{
            rect.size.width = asize.width;
            rect.size.height = asize.width*oldsize.height/oldsize.width;
            rect.origin.x = 0;
            rect.origin.y = (asize.height - rect.size.height)/2;
        }
        
        UIGraphicsBeginImageContext(asize);
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetFillColorWithColor(context, [[UIColor clearColor] CGColor]);
        UIRectFill(CGRectMake(0, 0, asize.width, asize.height));//clear background
        [image drawInRect:rect];
        newimage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    return newimage;
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    
    switch (result)
    {
        case MessageComposeResultCancelled:
            TTLog(@"Result: SMS sending canceled");
            break;
        case MessageComposeResultSent:
            TTLog(@"Result: SMS sent");
            break;
        case MessageComposeResultFailed: {
            [[TTToolsHelper shared] showAlertMessage:@"发送短信错误"];
        }
            break;
        default:
            TTLog(@"Result: SMS not sent");
            break;
    }
    [controller dismissViewControllerAnimated:YES completion:nil];
}


-(void)displaySMSComposerSheet:(NSString*)mobile body:(NSString*)body viewController:(UIViewController*)viewController {
    MFMessageComposeViewController *picker = [[MFMessageComposeViewController alloc] init];
    picker.messageComposeDelegate = self;
    picker.body = body;
    picker.recipients = @[mobile];
    [viewController presentViewController:picker animated:YES completion:nil];
}

- (void) sendSMSMessage:(NSString*)mobile body:(NSString*)body viewController:(UIViewController*)viewController{
    Class messageClass = (NSClassFromString(@"MFMessageComposeViewController"));
    
    if (messageClass != nil) {
        // Check whether the current device is configured for sending SMS messages
        if ([MFMessageComposeViewController canSendText]) {
            [self displaySMSComposerSheet:mobile body:body viewController:viewController];
        }
        else {
            [[TTToolsHelper shared] showAlertMessage:@"打开短信错误"];
        }
    }
    else {
        [[TTToolsHelper shared] showAlertMessage:@"打开短信错误"];
    }
}

- (void) showCodeUnavailableDialog:(UIViewController*)viewContoller{
    dispatch_async(dispatch_get_main_queue(), ^{
        /*[[TTToolsHelper shared] showNoticetMessage:@"长时间收不到动态码？请编辑短信一个字“码”到：13918147454，客服会尽快发给您可用的动态码！" handler:^{
            [[TTToolsHelper shared] sendSMSMessage:@"13918147454" body:@"码" viewController:viewContoller];
        }];*/
        [[TTToolsHelper shared] showAlertMessage:@"请拨打40009-365-12服务热线获取验证码，谢谢！"];
    });
}

@end