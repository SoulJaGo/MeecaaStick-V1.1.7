//
//  GlobalData.h
//  wkw
//
//  Created by Tice Tang on 15/12/14.
//  Copyright (c) 2014 Tice Tang. All rights reserved.
//

#import <Foundation/Foundation.h>

#define COLOR_NAV_BACKGROUND [UIColor colorWithRed:80/255.0 green:205/255.0 blue:216/255.0 alpha:1.0]
#define COLOR_VIEW_BACKGROUND [UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1.0]

@interface GlobalData : NSObject<NSCoding>

@property (retain, nonatomic) NSString *secrectKey;
@property (assign, nonatomic) SecKeyRef publicKey;
@property (assign, nonatomic) BOOL isLogin;
@property (assign, nonatomic) NSTimeInterval serverTimeDifference;

@property (retain, nonatomic) NSString *sid;
//////sympton template data
@property (retain, nonatomic) NSArray *symptonTemplateList;

//////record handle data
@property (copy, nonatomic) NSString *loginPhoneNumber;
@property (copy, nonatomic) NSString *loginPwd;

@property (retain, nonatomic) NSNumber *iconId;
/////record account data
@property (retain, nonatomic) NSString *nowAccountId;
@property (retain, nonatomic) NSMutableArray *members;

/////record member data
@property (retain, nonatomic) NSString *nowMemberId;
@property (retain, nonatomic) NSDictionary *nowMember;

/////record diary data
@property (retain, nonatomic) NSMutableArray *diary;
/////record group data
@property (retain, nonatomic) NSArray *groups;

@property (retain, nonatomic) NSNumber *temperatureType;

@property (retain, nonatomic) NSString *lastTimeCheckTemperature;

/**选中的成员昵称*/
@property (nonatomic,copy) NSString *nickName;
/**第三方登陆的账号*/
@property (nonatomic,copy) NSString *thirdLoginNickName;
/**第三方登陆的ID*/
@property (nonatomic,copy) NSString *thirdLoginUid;
/**第三方登陆platformID*/
@property (nonatomic,copy) NSString *thirdLoginPlatformID;

+ (id)sharedData;
- (SecKeyRef) getPublicKey;

- (NSString *)getSymptonNameByTag:(NSNumber *)tag;
- (BOOL)handleMsgs:(NSArray *)msgs;
- (void)setDefaultMember;

- (void) saveData;
- (NSString *)connectUrl;
- (void)emptyData;
@end