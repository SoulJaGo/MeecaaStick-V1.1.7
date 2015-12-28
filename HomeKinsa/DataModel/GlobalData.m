//
//  GlobalData.m
//  wkw
//
//  Created by Tice Tang on 15/12/14.
//  Copyright (c) 2014 Tice Tang. All rights reserved.
//

#import "GlobalData.h"
#import "TTToolsHelper.h"
#import "TTDeepCopy.h"
#import "AFNetworking.h"
#import "GetServerUrlViewController.h"

@implementation GlobalData

@synthesize secrectKey = _secrectKey;
@synthesize publicKey = _publicKey;

+ (id)sharedData {
    static GlobalData *sharedData = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (sharedData == nil){
            NSData *myEncodedObject = [[NSUserDefaults standardUserDefaults] objectForKey:@"global_data"];
            sharedData = [NSKeyedUnarchiver unarchiveObjectWithData: myEncodedObject];
            if (sharedData == nil){
                sharedData = [[self alloc] init];
            }
            [sharedData setupData];
        }
    });
    return sharedData;
}

- (NSString *)getSymptonNameByTag:(NSNumber *)tag{
    for (int i=0; i<self.symptonTemplateList.count; i++) {
        NSDictionary *symptonTemplate = [self.symptonTemplateList objectAtIndex:i];
        NSNumber *symptonTag = [symptonTemplate objectForKey:@"tag"];
        if ([symptonTag intValue]==[tag intValue]) {
            return [symptonTemplate objectForKey:@"name"];
        }
    }
    return @"";
}

- (void) setupData{
    self.isLogin = NO;
    self.secrectKey = [[TTToolsHelper shared] randomStringWithLength:16];
//    self.publicKey = [self getPublicKey];
    
    self.symptonTemplateList = @[
                                 @{
                                     @"tag":@1, @"name":@"咽痛",
                                     },
                                 @{
                                     @"tag":@2, @"name":@"咳嗽",
                                     },
                                 @{
                                     @"tag":@3, @"name":@"流涕",
                                     },
                                 @{
                                     @"tag":@4, @"name":@"气短",
                                     },
                                 @{
                                     @"tag":@5, @"name":@"腹痛",
                                     },
                                 @{
                                     @"tag":@6, @"name":@"腹泻",
                                     },
                                 @{
                                     @"tag":@7, @"name":@"呕吐",
                                     },
                                 @{
                                     @"tag":@8, @"name":@"乏力",
                                     },
                                 @{
                                     @"tag":@9, @"name":@"头痛",
                                     },
                                 @{
                                     @"tag":@10, @"name":@"耳痛",
                                     },
                                 @{
                                     @"tag":@11, @"name":@"体痛",
                                     },
                                 @{
                                     @"tag":@12, @"name":@"寒战",
                                     },
                                 @{
                                     @"tag":@13, @"name":@"关节痛",
                                     },
                                 @{
                                     @"tag":@14, @"name":@"尿痛",
                                     },
                                 @{
                                     @"tag":@15, @"name":@"一般不适",
                                     }
                                 ];
}

- (id)init {
    if (self = [super init]) {
        [self setupData];
    }
    return self;
}

- (void)dealloc {
    // Should never be called, but just here for clarity really.
}

- (SecKeyRef) getPublicKey{
    if(self.publicKey == nil){
        NSString *resourcePath = [[NSBundle mainBundle] pathForResource:@"rsaCert" ofType:@"der"];
        NSData *certificateData = [NSData dataWithContentsOfFile:resourcePath];
        SecCertificateRef myCertificate =  SecCertificateCreateWithData(kCFAllocatorDefault, (__bridge CFDataRef)certificateData);
        SecPolicyRef myPolicy = SecPolicyCreateBasicX509();
        SecTrustRef myTrust;
        OSStatus status = SecTrustCreateWithCertificates(myCertificate,myPolicy,&myTrust);
        SecTrustResultType trustResult;
        if (status == noErr) {
            status = SecTrustEvaluate(myTrust, &trustResult);
        }
        self.publicKey = SecTrustCopyPublicKey(myTrust);
        CFRelease(myCertificate);
        CFRelease(myPolicy);
        CFRelease(myTrust);
    }
    return self.publicKey;
}

- (void) saveData{
    NSData *archiveCarPriceData = [NSKeyedArchiver archivedDataWithRootObject:self];
    [[NSUserDefaults standardUserDefaults] setObject:archiveCarPriceData forKey:@"global_data"];
}

- (void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:_loginPhoneNumber forKey:@"loginPhoneNumber"];
    [aCoder encodeObject:_loginPwd forKey:@"loginPwd"];
    [aCoder encodeObject:_nowAccountId forKey:@"nowAccountId"];
    [aCoder encodeObject:_members forKey:@"members"];
//    [aCoder encodeObject:_diary forKey:@"diary"];
    [aCoder encodeObject:_groups forKey:@"groups"];
    [aCoder encodeObject:_temperatureType forKey:@"temperatureType"];
    [aCoder encodeObject:_iconId forKey:@"headId"];
    /**第三方登陆*/
    [aCoder encodeObject:_thirdLoginNickName forKey:@"thirdLoginNickName"];
    [aCoder encodeObject:_thirdLoginUid forKey:@"thirdLoginUid"];
    [aCoder encodeObject:_thirdLoginPlatformID forKey:@"thirdLoginPlatformID"];
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    self = [super init];
    if (self){
        _loginPhoneNumber = [aDecoder decodeObjectForKey:@"loginPhoneNumber"];
        _loginPwd = [aDecoder decodeObjectForKey:@"loginPwd"];
        _nowAccountId = [aDecoder decodeObjectForKey:@"nowAccountId"];
        _members = [aDecoder decodeObjectForKey:@"members"];
//        _diary = [aDecoder decodeObjectForKey:@"diary"];
        _groups = [aDecoder decodeObjectForKey:@"groups"];
        _temperatureType = [aDecoder decodeObjectForKey:@"temperatureType"];
        _iconId = [aDecoder decodeObjectForKey:@"headId"];
        /**第三方登陆*/
        _thirdLoginUid = [aDecoder decodeObjectForKey:@"thirdLoginUid"];
        _thirdLoginNickName = [aDecoder decodeObjectForKey:@"thirdLoginNickName"];
        _thirdLoginPlatformID = [aDecoder decodeObjectForKey:@"thirdLoginPlatformID"];
    }
    return self;
}

- (void)setThirdLoginNickName:(NSString *)thirdLoginNickName
{
    _thirdLoginNickName = thirdLoginNickName;
    [self saveData];
}

- (void)setThirdLoginUid:(NSString *)thirdLoginUid
{
    _thirdLoginUid = thirdLoginUid;
    [self saveData];
}

- (void)setThirdLoginPlatformID:(NSString *)thirdLoginPlatformID
{
    _thirdLoginPlatformID = thirdLoginPlatformID;
    [self saveData];
}

- (void)setLoginPhoneNumber:(NSString *)loginPhoneNumber{
    _loginPhoneNumber = loginPhoneNumber;
    [self saveData];
}

- (void)setLoginPwd:(NSString *)loginPwd{
    _loginPwd = loginPwd;
    [self saveData];
}

- (void)setNowAccountId:(NSString *)nowAccountId{
    _nowAccountId = nowAccountId;
    [self saveData];
}

- (void)setIconId:(NSNumber *)iconId{
    _iconId = iconId;
    [self saveData];
}

- (void)setMembers:(NSArray *)members{
    _members = [members mutableDeepCopy];
    [self saveData];
}

- (void)setDiary:(NSMutableArray *)diary{
    _diary = diary;
//    [self saveData];
}

- (void)setGroups:(NSArray *)groups{
    _groups = groups;
    [self saveData];
}

- (void)setDefaultMember{
    if (self.members!=nil) {
        if (![self.members isKindOfClass:[NSNull class]]) {
            if (self.members.count>=1) {
                self.nowMember = [self.members objectAtIndex:0];
                self.nowMemberId = [NSString stringWithFormat:@"%@",[self.nowMember objectForKey:@"id"]];
            }
        }
    }
}

- (void)setTemperatureType:(NSNumber *)temperatureType{
    _temperatureType = temperatureType;
    [self saveData];
}

- (BOOL)handleMsgs:(NSArray *)msgs{
    BOOL flag = true;
    for (NSDictionary *msg in msgs){
        int msgId = [[msg objectForKey:@"_msg"] intValue];
        if (msgId==-1) {
            flag = false;
            NSString* errMsg = [msg objectForKey:@"content"];
            [[TTToolsHelper shared] showAlertMessage:errMsg];
        }
        else{
            //accountData:账号及成员数
            if (msgId == 1) {
                self.nowAccountId = [NSString stringWithFormat:@"%@",[msg objectForKey:@"account"]];
                if ([self.nowAccountId isEqualToString:@"-1"]) {
                    flag = false;
                    [[TTToolsHelper shared] showAlertMessage:@"账号密码错误！"];
                }
                else {
                    self.iconId = [msg objectForKey:@"icon"];
                    self.members = [msg objectForKey:@"members"];
                    self.sid = [msg objectForKey:@"sid"];
                }
            }
            //diary:温度记录列表
            else if (msgId == 2){
                if (self.diary==nil) {
                    self.diary = [NSMutableArray arrayWithArray:[msg objectForKey:@"diary"]];
                }
                else{
                    NSArray *tempDiary = [msg objectForKey:@"diary"];
                    for (int i=0; i<tempDiary.count; i++) {
                        [self.diary insertObject:[tempDiary objectAtIndex:i] atIndex:0];
                    }
                }
            }
            //groupInfo:群信息
            else if (msgId == 3){
                
            }
            //groupChat:群聊天信息
            else if (msgId == 4){
                
            }
            //groupList:相关群列表
            else if (msgId == 5){
                self.groups = [msg objectForKey:@"groups"];
            }
            //发送短信结果
            else if (msgId == 6){

            }
            else if (msgId == 8){
                self.iconId = [msg objectForKey:@"id"];
            }
        }
    }
    return flag;
}

- (NSString *)connectUrl {
    /*测试地址*/
    return @"120.24.174.207";
    /*正式服务器地址*/
//    return @"api.meecaa.cn";
//    return @"121.199.40.188";
}

- (void)emptyData
{
    [self setIsLogin:NO];
    [self setSid:nil];
    [self setLoginPhoneNumber:nil];
    [self setLoginPwd:nil];
    [self setIconId:nil];
    [self setNowAccountId:nil];
    [self setMembers:nil];
    [self setNowMemberId:nil];
    [self setNowMember:nil];
    [self setDiary:nil];
    [self setGroups:nil];
    [self setTemperatureType:nil];
    [self setLastTimeCheckTemperature:nil];
    [self setNickName:nil];
    [self setThirdLoginNickName:nil];
    [self setThirdLoginPlatformID:nil];
    [self setThirdLoginUid:nil];
}

@end
