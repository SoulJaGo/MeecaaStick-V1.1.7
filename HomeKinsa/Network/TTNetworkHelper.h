//
//  TTNetworkHelper.h
//  HomeKinsa
//
//  Created by Zhang guangchun on 15/3/4.
//  Copyright (c) 2015年 Mikai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Motis.h>

typedef void (^RetryBlock)(void);

@interface TTNetworkHelper : NSObject{
    NSURLSessionConfiguration *_sessionConfiguration;
    NSInteger _requestId;
}

@property (nonatomic, retain) RetryBlock retryBlock;

+ (id)sharedSession;
- (RACSignal *) fetchDictionaryFromJSON:(NSDictionary*)bodyDict encrypt:(BOOL)encrypt;

- (void)getAccountCodeByPhoneNumber:(NSString *)phoneNumber dismissProgressView:(BOOL)dismissProgressView;
- (void)accountRegisterByPhoneNumber:(NSString *)phoneNumber Password:(NSString *)pwd Code:(NSString *)code Name:(NSString *)name Sex:(int)sex City:(NSString *)city Birth:(NSString *)birth Addr:(NSString *)addr dismissProgressView:(BOOL)dismissProgressView;
- (void)accountLoginByPhoneNumber:(NSString *)phoneNumber Password:(NSString *)pwd Mid:(NSString *)mid dismissProgressView:(BOOL)dismissProgressView;
- (void)createMemberByName:(NSString *)name Sex:(int)sex City:(NSString *)city Birth:(NSString *)birth Addr:(NSString *)addr  dismissProgressView:(BOOL)dismissProgressView;
- (void)changeMemberInfo:(NSString *)mId Name:(NSString *)name Sex:(int)sex City:(NSString *)city Birth:(NSString *)birth  dismissProgressView:(BOOL)dismissProgressView;
- (void)createDiaryByMid:(NSString *)mid Date:(NSNumber *)date Temperature:(NSNumber *)svalue Symptoms:(NSNumber *)tvalue Photo:(int)pvalue Desc:(NSString *)desc Longitude:(NSString *)longitude Latitude:(NSString *)latitude dismissProgressView:(BOOL)dismissProgressView;
- (void)getDiaryByMid:(NSString *)mid Ids:(NSString *)did Count:(int)value dismissProgressView:(BOOL)dismissProgressView;
- (void)deleteDiary:(NSString *)mid Id:(NSString *)tid dismissProgressView:(BOOL)dismissProgressView;

- (void)accountSetIcon:(int)iconId image:(UIImage *)image dismissProgressView:(BOOL)dismissProgressView;
- (void)getDiaryLastRecords:(NSNumber *)pos Range:(NSNumber *)range MId:(NSString *)mid dismissProgressView:(BOOL)dismissProgressView;

- (void)checkVer:(NSString *)ver dismissProgressView:(BOOL)dismissProgressView;
- (void)createGroup:(NSString *)groupName dismissProgressView:(BOOL)dismissProgressView;
- (void)enterGroup:(int)gid dismissProgressView:(BOOL)dismissProgressView;
- (void)addGroup:(int)gid dismissProgressView:(BOOL)dismissProgressView;
- (void)chatGroup:(int)gid Msg:(NSString *)content dismissProgressView:(BOOL)dismissProgressView;
- (RACSignal *) updateVideo:(NSDictionary *)postParams video:(NSData *)data;
- (RACSignal *) updateImage:(UIImage *)image InDate:(NSNumber *)date WithName:(NSString *)fileName;
/**
 *  获取验证码
 */
- (void)accountRestPwdSMSByPhoneNumber:(NSString *)PhoneNumber dismissProgressView:(BOOL)dismissProgressView;
/**
 *  更改密码
 */
- (void)accountRestPwdByPhoneNumber:(NSString *)PhoneNumber newPwd:(NSString *)newPwd code:(NSString *)code dismissProgressView:(BOOL)dismissProgressView;
/**
 *  第三方登陆
 platformID: 新浪微博--1 QQ--2
 */
- (void)accountRegisterPByOpenId:(NSString *)OpenId token:(NSString *)token platformID:(NSString *)platformID Name:(NSString *)name Sex:(int)sex City:(NSString *)city Birth:(NSString *)birth Addr:(NSString *)addr  dismissProgressView:(BOOL)dismissProgressView;
- (void)accountLoginPByOpenId:(NSString *)OpenId token:(NSString *)token platformID:(NSString *)platformID mid:(NSString *)mid dismissProgressView:(BOOL)dismissProgressView;
@end
