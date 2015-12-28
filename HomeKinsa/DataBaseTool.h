//
//  DataBaseTool.h
//  HomeKinsa
//
//  Created by SoulJa on 15/9/8.
//  Copyright (c) 2015年 Mikai. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DataBaseTool : NSObject
/**
 *  取出默认的成员
 */
+ (NSMutableDictionary *)getDefaultMember;
/**
 *  将获取的会员数据存入到数据库
 */
+ (BOOL)insertInitMembers:(NSArray *)members;
/**
 *  取出所有成员
 */
+ (NSMutableArray *)getAllMembers;
/**
 *  添加一个成员
 */
+ (BOOL)addMember:(NSDictionary *)member;
/**
 *  删除一个成员
 */
+ (BOOL)removeMember:(NSString *)mid;
/**
 *  设置为选中的成员
 */
+ (BOOL)setDefaultMemberWithAcc_id:(NSString *)acc_id Mid:(NSString *)mid;
/**
 *  修改成员
 */
+ (BOOL)updateMember:(NSDictionary *)member;
/**
 *  添加一个温度记录到数据库
 */
+ (BOOL)addDiary:(NSMutableDictionary *)diary;
/**
 *  获取默认成员的温度记录
 */
+ (NSMutableArray *)getDefaultMemberDiaryInfo;
/**
 *  删除一条记录
 */
+ (BOOL)removeDiary:(NSString *)diaryId;

/**
 *  清空数据库
 */
+ (BOOL)emptyDataBase;
/**
 *  获取默认成员的最新一条温度记录
 */
+ (NSMutableDictionary *)getDefaultMemberLastDiary;

/**
 *  刷新默认成员的温度数据
 */
+ (BOOL)refreshDefaultMemberDiary:(NSArray *)newDiaryArray;

/**
 *  取出数据库的消息
 */
+ (NSMutableArray *)getAllMessages;

/**
 *  添加数据库的消息
 */
+ (BOOL)addMessage:(NSDictionary *)dict;

/**
 *  删除数据库的消息
 */
+ (BOOL)removeMessage:(NSString *)msgid;
/**
 *  数据库版本更新
 */
+ (void)refreshDataBase;
/**
 *  修改温度记录
 */
+ (BOOL)updateDiaryWithTid:(NSString *)tid Date:(NSString *)date Temperature:(NSString *)temperature Symbols:(NSString *)symbols Desc:(NSString *)desc;
/**
 *  删除原有默认成员测温记录
 */
+ (BOOL)deleteDefaultMemberDiary;

/**
 *  添加温度记录数组
 */
+ (BOOL)addDiaryWithArray:(NSArray *)array;
/**
 *  单例
 */
+ (id)shared;
@property (nonatomic,strong) NSMutableArray *defaultMemberDiaryArray;
/**
 *  获取温度记录数据
 */
- (NSMutableArray *)getDefaultMemberDiaryFromPage:(int)page;
/**
 *  获取最后一个温度记录的ID
 */
- (NSMutableDictionary *)getDefaultMemberOldDiary;

/**
 *  通过ID取出一条记录
 */
+ (NSMutableDictionary *)getDefaultMemberDiaryById:(NSString *)diaryId;
@end
