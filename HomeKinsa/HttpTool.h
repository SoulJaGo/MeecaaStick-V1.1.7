//
//  HttpTool.h
//  HomeKinsa
//
//  Created by SoulJa on 15/9/8.
//  Copyright (c) 2015年 Mikai. All rights reserved.
//

#import <Foundation/Foundation.h>
@interface HttpTool : UIViewController
/**
 *  使用手机号和密码登陆
 */
+ (void)LoginWithPhoneNumber:(NSString *)phoneNumber Password:(NSString *)password;
/**
 *  获取现在的网络状态
 */
+ (void)getCurrentNetworkStatus;
/**
 *  第三方登陆
 */
+ (void)loginThirdPartyWithOpenId:(NSString *)openId NickName:(NSString *)nickName PlatForm:(NSString *)platForm Avatar:(NSString *)avatar;
/**
 *  用户注册
 */
+ (void)registerAccountWithPhoneNumber:(NSString *)phoneNumber NickName:(NSString *)nickName Password:(NSString *)password registerCode:(NSString *)code;
/**
 *  设置初始默认用户的所有测温记录
 */
+ (void)getDefaultMemberDiaryInfo;
/**
 *  添加成员的方法
 */
+ (void)addMemberWithName:(NSString *)name Sex:(NSString *)sex City:(NSString *)city Birth:(NSString *)birth Addr:(NSString *)addr Acc_id:(NSString *)acc_id;
/**
 *  添加带图像成员的方法
 */
+ (void)addMemberWithName:(NSString *)name Sex:(NSString *)sex City:(NSString *)city Birth:(NSString *)birth Addr:(NSString *)addr Acc_id:(NSString *)acc_id IconImage:(UIImage *)iconImage;
/**
 *  删除一个成员
 */
+ (void)removeMember:(NSString *)mid;
/**
 *  设置为选中的成员
 */
+ (void)setDefaultMemberWithAcc_id:(NSString *)acc_id Mid:(NSString *)mid;
/**
 *  修改不带图片的成员
 */
+ (void)updateMemberWithMid:(NSString *)mid Name:(NSString *)name Sex:(NSString *)sex Birth:(NSString *)birth City:(NSString *)city;
/**
 *  修改带图片的成员
 */
+ (void)updateMemberWithMid:(NSString *)mid Name:(NSString *)name Sex:(NSString *)sex Birth:(NSString *)birth City:(NSString *)city IconImage:(UIImage *)iconImage;
/**
 *  发起添加记录的请求
 */
+ (void)addDiaryWithDate:(NSString *)date Temperature:(NSString *)temperature Symptoms:(NSString *)symptoms Photo_count:(NSString *)photo_count Description:(NSString *)description Member_id:(NSString *)member_id Longitude:(NSString *)longitude Latitude:(NSString *)latitude;
/**
 *  删除一条记录
 */
+ (void)removeDiary:(NSString *)diaryId;
/**
 *  通过最大得温度记录ID获取最新的温度记录
 */
+ (NSMutableArray *)getAllDefaultMemberDiaryByLastDiaryId:(NSString *)lastDiaryId;
/**
 *  判断当前是否能够上网
 */
+ (BOOL)isConnectInternet;
/**
 *  注册的时候接收验证码
 */
+ (void)getRegistVerifyCode:(NSString *)phone;
/**
 *  修改密码接收验证码
 */
+ (void)getResetPwdVerifyCode:(NSString *)phone;
/**
 *  修改用户密码
 */
+ (void)resetAccountPasswordByPhoneNumber:(NSString *)phoneNumber NewPwd:(NSString *)newPwd Code:(NSString *)code;
/**
 *  获取服务器上最新版本
 */
+ (void)getVersion;
/**
 *  获取广告页图片数据
 */
+ (void)getAdDict;
/**
 *  上传温度记录图片
 */
+ (void)uploadDiaryImageWithDiaryId:(NSString *)diaryId Image:(UIImage *)image ImageName:(NSString *)imageName;
/**
 *  修改温度记录
 */
+ (void)updateDiaryWithTid:(NSString *)tid Date:(NSString *)date Temperature:(NSString *)temperature Symbols:(NSString *)symbols Desc:(NSString *)desc;

/**
 *  进入主页后验证登陆
 */
+ (void)validLogin;

/**
 *  测温统计
 */
+ (void)checkCountWithStartTime:(NSString *)starttime Temperature:(NSString *)temperature TemperatureType:(NSString *)type OperateType:(NSString *)operateType;
/**
 *  获取默认用户的所有测温记录
 */
+ (void)getDefaultMemberDiaryInfoByPage:(int)page;
@end
