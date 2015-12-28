//
//  HttpTool.m
//  HomeKinsa
//
//  Created by SoulJa on 15/9/8.
//  Copyright (c) 2015年 Mikai. All rights reserved.
//

/**
 *  域名
 */
#define APPKEY @"!@#$%meecaa.com"
#define TIMEOUT 5

#import "HttpTool.h"
#import "AFNetworking.h"
#import "CommonCrypto/CommonDigest.h"
#import "TTToolsHelper.h"
#import <SVProgressHUD/SVProgressHUD.h>
#import "DataBaseTool.h"
#import "Reachability.h"
#import "Account.h"
#import "GlobalTool.h"
/*声明最近登录状态*/
typedef enum
{
    CurrentLoginStatusPhoneNumber=0,
    CurrentLoginStatusSinaWeiBo = 1,
    CurrentLoginStatusQQ = 2,
    CurrentLoginStatusWeiXin = 3,
    CurrentLoginStatusNone = 4
}CurrentLoginStatus;
@interface HttpTool ()
/**
 *  网络请求管理者
 */
@property (nonatomic,strong) AFHTTPRequestOperationManager *manager;
@end
@implementation HttpTool
- (AFHTTPRequestOperationManager *)manager{
    if (_manager == nil) {
        self.manager = [AFHTTPRequestOperationManager manager];
        self.manager.requestSerializer.timeoutInterval = TIMEOUT;
    }
    return _manager;
}

/**
 *  MD5加密算法
 */
- (NSString *)md5:(NSString *)str
{
    const char *cStr = [str UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, strlen(cStr), result);
    
    return [[NSString stringWithFormat:@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
             result[0], result[1], result[2], result[3],
             result[4], result[5], result[6], result[7],
             result[8], result[9], result[10], result[11],
             result[12], result[13], result[14], result[15]
             ] lowercaseString];
}

/**
 *  使用手机号和密码登陆
 */
+ (void)LoginWithPhoneNumber:(NSString *)phoneNumber Password:(NSString *)password
{
    //发送请求数据
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"phone"] = phoneNumber;
    params[@"password"] = password;
    params[@"devicetype"] = @"ios";
    params[@"timestamp"] = [NSString stringWithFormat:@"%d",(int)[[NSDate date] timeIntervalSince1970]];
    params[@"uuid"] = [[self alloc] getCurrentDeviceIdentifierNumber];
    params[@"version"] = VERSION;
    params[@"sign"] = [[self alloc] getLoginSignWithPhoneNumber:phoneNumber Password:password Timestamp:params[@"timestamp"]];
    //取出用户的DeviceToken
    NSData *deviceTokenData = [[NSUserDefaults standardUserDefaults] objectForKey:@"deviceToken"];
    params[@"devicetoken"] = [NSString stringWithFormat:@"%@",deviceTokenData];
    params[@"devicetoken"] = [params[@"devicetoken"] stringByReplacingOccurrencesOfString:@"<" withString:@""];
    params[@"devicetoken"] = [params[@"devicetoken"] stringByReplacingOccurrencesOfString:@">" withString:@""];
    params[@"devicetoken"] = [params[@"devicetoken"] stringByReplacingOccurrencesOfString:@" " withString:@""];
    params[@"device_brand"] = @"apple";
    params[@"device_model"] = [GlobalTool deviceString];
    params[@"device_system"] = @"ios";
    params[@"device_version"] = [NSString stringWithFormat:@"%.1f",[[UIDevice currentDevice].systemVersion floatValue]];
    

    //请求地址
    NSString *urlStr = [HOST stringByAppendingString:@"api.php?m=open&c=account&a=login"];
    
    [[[self alloc] manager] POST:urlStr parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (responseObject[@"status"] == [NSNumber numberWithInteger:1]) {
            //将数据写入FMDB
            BOOL result = [DataBaseTool insertInitMembers:responseObject[@"data"]];
            if (!result) {
                NSLog(@"数据写入失败!");
                [[TTToolsHelper shared] showAlertMessage:@"用户名或密码错误!"];
            } else {
                //记录登陆的手机账号以及密码以及最近登录
//                [[NSUserDefaults standardUserDefaults] setObject:phoneNumber forKey:@"phonenumber"];
//                [[NSUserDefaults standardUserDefaults] setObject:password forKey:@"password"];
//                [[NSUserDefaults standardUserDefaults] setInteger:CurrentLoginStatusPhoneNumber forKey:@"currentloginstatus"];
//                [[NSUserDefaults standardUserDefaults] synchronize];
                
                //记录账号密码信息到沙盒
                Account *account = [[Account alloc] init];
                account.telephone = phoneNumber;
                account.password = password;
                account.openID = @"";
                account.platForm = CurrentLoginStatusPhoneNumber;
                NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
                NSString *path = [docDir stringByAppendingPathComponent:@"account.archive"];
                BOOL isArchive = [NSKeyedArchiver archiveRootObject:account toFile:path];
                
                if (!isArchive) {
                    NSLog(@"本地存储账号密码失败!");
                }
                
                //发出登陆成功的通知
                [[NSNotificationCenter defaultCenter] postNotificationName:@"LoginSuccessNotification" object:nil];
            }
        } else {
            [SVProgressHUD dismiss];
            [[TTToolsHelper shared] showAlertMessage:responseObject[@"msg"]];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@",error);
//        [[TTToolsHelper shared] showAlertMessage:@"网络不给力哦！"];
        [SVProgressHUD showErrorWithStatus:@"网络不给力哦！"];
    }];
}

/**
 *  拼接login的Sign
 */
- (NSString *)getLoginSignWithPhoneNumber:(NSString *)phoneNumber Password:(NSString *)password Timestamp:(NSString *)timestamp
{
    NSString *sign = [[[phoneNumber stringByAppendingString:password] stringByAppendingString:timestamp] stringByAppendingString:APPKEY];
    NSString *signMd5 = [self md5:sign];
    return signMd5;
}

/**
 *  获取手机的UUID
 */
- (NSString *)getCurrentDeviceIdentifierNumber
{
    return [[[UIDevice currentDevice] identifierForVendor] UUIDString];
}

/**
 *  获取手机的build版本
 */
- (NSString *)getCurrentDeviceBuildVersion
{
    NSString *versionStr = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    return versionStr;
}

/**
 *  获取网络状态
 */
+ (void)getCurrentNetworkStatus
{
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        if (status == AFNetworkReachabilityStatusUnknown) {
            [SVProgressHUD showErrorWithStatus:@"网络不给力哦！"];
        } else if (status == AFNetworkReachabilityStatusNotReachable) {
            [SVProgressHUD showErrorWithStatus:@"网络不给力哦！"];
        }
    }];
    
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
}

/**
 *  第三方登陆
 */
+ (void)loginThirdPartyWithOpenId:(NSString *)openId NickName:(NSString *)nickName PlatForm:(NSString *)platForm Avatar:(NSString *)avatar
{
    //发送请求数据
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"openid"] = openId;
    params[@"nickname"] = nickName;
    params[@"platform"] = platForm;
    params[@"avatar"] = avatar;
    params[@"timestamp"] = [NSString stringWithFormat:@"%d",(int)[[NSDate date] timeIntervalSince1970]];
    params[@"devicetype"] = @"ios";
    params[@"version"] = VERSION;
    params[@"uuid"] = [[self alloc] getCurrentDeviceIdentifierNumber];
    params[@"sign"] = [[self alloc] getLoginThirdPartySignWithOpenId:openId PlatForm:platForm Timestamp:params[@"timestamp"]];
    params[@"device_brand"] = @"apple";
    params[@"device_model"] = [GlobalTool deviceString];
    params[@"device_system"] = @"ios";
    params[@"device_version"] = [NSString stringWithFormat:@"%.1f",[[UIDevice currentDevice].systemVersion floatValue]];
    
    //取出用户的DeviceToken
//    NSData *deviceTokenData = [[NSUserDefaults standardUserDefaults] objectForKey:@"deviceToken"];
//    params[@"devicetoken"] = [NSString stringWithFormat:@"%@",deviceTokenData];
//    params[@"devicetoken"] = [params[@"devicetoken"] stringByReplacingOccurrencesOfString:@"<" withString:@""];
//    params[@"devicetoken"] = [params[@"devicetoken"] stringByReplacingOccurrencesOfString:@">" withString:@""];
//    params[@"devicetoken"] = [params[@"devicetoken"] stringByReplacingOccurrencesOfString:@" " withString:@""];
   
    NSString *urlStr = [HOST stringByAppendingString:@"api.php?m=open&c=account&a=oauth"];
    [[[self alloc] manager] POST:urlStr parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (responseObject[@"status"] == [NSNumber numberWithInteger:1]) {
            //将数据写入FMDB
            BOOL result = [DataBaseTool insertInitMembers:responseObject[@"data"]];
            if (!result) {
                NSLog(@"数据写入失败!");
                [[TTToolsHelper shared] showAlertMessage:@"授权失败,请尝试重新登陆!"];
            } else {
                //记录第三方登陆时候的记录
//                [[NSUserDefaults standardUserDefaults] setObject:openId forKey:@"openid"];
//                switch ([platForm intValue]) {
//                    case 1:
//                        [[NSUserDefaults standardUserDefaults] setInteger:CurrentLoginStatusSinaWeiBo forKey:@"currentloginstatus"];
//                        break;
//                    case 2:
//                        [[NSUserDefaults standardUserDefaults] setInteger:CurrentLoginStatusQQ forKey:@"currentloginstatus"];
//                        break;
//                    case 3:
//                        [[NSUserDefaults standardUserDefaults] setInteger:CurrentLoginStatusWeiXin forKey:@"currentloginstatus"];
//                        break;
//                    default:
//                        [[NSUserDefaults standardUserDefaults] setInteger:CurrentLoginStatusNone forKey:@"currentloginstatus"];
//                        break;
//                }
//                [[NSUserDefaults standardUserDefaults] synchronize];
                NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
                NSString *path = [docDir stringByAppendingPathComponent:@"account.archive"];
                Account *account = [[Account alloc] init];
                account.telephone = @"";
                account.password = @"";
                account.openID = openId;
                switch ([platForm intValue]) {
                    case 1:
                        account.platForm = CurrentLoginStatusSinaWeiBo;
                        break;
                    case 2:
                        account.platForm = CurrentLoginStatusQQ;
                        break;
                    case 3:
                        account.platForm = CurrentLoginStatusWeiXin;
                        break;
                    default:
                        account.platForm = CurrentLoginStatusNone;
                        break;
                }
                
                BOOL isArchive = [NSKeyedArchiver archiveRootObject:account toFile:path];
                if (!isArchive) {
                    NSLog(@"第三方登陆压缩失败");
                }
                
                //发出登陆成功的通知
                [[NSNotificationCenter defaultCenter] postNotificationName:@"LoginSuccessNotification" object:nil];
            }

        } else {
            [SVProgressHUD dismiss];
            [[TTToolsHelper shared] showAlertMessage:@"授权失败,请尝试重新登陆!"];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [SVProgressHUD dismiss];
        NSLog(@"%@",error);
//        [[TTToolsHelper shared] showAlertMessage:@"网络不给力哦！!"];
        [SVProgressHUD showErrorWithStatus:@"网络不给力哦！"];
    }];
}

/**
 *  获取第三方登陆的sign
 */
- (NSString *)getLoginThirdPartySignWithOpenId:(NSString *)openId PlatForm:(NSString *)platForm Timestamp:(NSString *)timestamp
{
    NSString *sign = [[[openId stringByAppendingString:platForm] stringByAppendingString:timestamp] stringByAppendingString:APPKEY];
    NSString *signMd5 = [self md5:sign];
    return signMd5;
}

/**
 *  注册用户
 */
+ (void)registerAccountWithPhoneNumber:(NSString *)phoneNumber NickName:(NSString *)nickName Password:(NSString *)password registerCode:(NSString *)code
{
    //发送请求数据
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"phone"] = phoneNumber;
    params[@"nickname"] = nickName;
    params[@"password"] = password;
    params[@"code"] = code;
    params[@"devicetype"] = @"ios";
    params[@"timestamp"] = [NSString stringWithFormat:@"%d",(int)[[NSDate date] timeIntervalSince1970]];
    params[@"sign"] = [[self alloc] getRegisterAccountSignWithPhoneNumber:phoneNumber NickName:nickName Password:password Timestamp:params[@"timestamp"]];
    NSString *urlStr = [HOST stringByAppendingString:@"api.php?m=open&c=account&a=register"];
    [[[self alloc] manager] POST:urlStr parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [SVProgressHUD dismiss];
        if (responseObject[@"status"] == [NSNumber numberWithInteger:1]) {
            BOOL result = [DataBaseTool insertInitMembers:responseObject[@"data"]];
            if (!result) {
                NSLog(@"数据写入失败!");
//                [[TTToolsHelper shared] showAlertMessage:@"网络不给力哦！"];
                [SVProgressHUD showErrorWithStatus:@"网络不给力哦！"];
            } else {
                //发出登陆成功的通知
                [[NSNotificationCenter defaultCenter] postNotificationName:@"RegisterSuccessNotification" object:nil];
            }
        } else {
            [[TTToolsHelper shared] showAlertMessage:responseObject[@"msg"]];
            return;
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@",error);
//        [[TTToolsHelper shared] showAlertMessage:@"网络不给力哦！"];
        [SVProgressHUD showErrorWithStatus:@"网络不给力哦！"];
    }];
}

/**
 *  获取用户注册的sign
 */
- (NSString *)getRegisterAccountSignWithPhoneNumber:(NSString *)phoneNumber NickName:(NSString *)nickName Password:(NSString *)password Timestamp:(NSString *)timestamp
{
    NSString *sign = [[[[phoneNumber stringByAppendingString:nickName] stringByAppendingString:password] stringByAppendingString:timestamp] stringByAppendingString:APPKEY];
    NSString *signMd5 = [self md5:sign];
    return signMd5;
}

/**
 *  获取默认用户的所有测温记录
 */
+ (void)getDefaultMemberDiaryInfo
{
    //发送请求数据
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    //去除默认用户的id
    NSDictionary *defaultMemberInfo = [DataBaseTool getDefaultMember];
    params[@"mid"] = [NSString stringWithFormat:@"%@",defaultMemberInfo[@"id"]];
    NSString *urlStr = [HOST stringByAppendingString:@"api.php?m=open&c=member&a=record"];
    
    [[[self alloc] manager] POST:urlStr parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (responseObject[@"status"] == [NSNumber numberWithInteger:1]) {
            NSArray *diaryArray = responseObject[@"data"];
            if (diaryArray != nil || diaryArray.count != 0) {
//                for (NSMutableDictionary *dict in diaryArray) {
//                    BOOL result = [DataBaseTool addDiary:dict];
//                    NSLog(@"result");
//                    if (!result) {
//                        NSLog(@"插入数据失败!");
//                    }
//                }
                [SVProgressHUD showWithStatus:@"正在加载数据"];
                BOOL result = [DataBaseTool addDiaryWithArray:diaryArray];
                if (!result) {
                    NSLog(@"插入数据库失败!");
                }
                [[NSNotificationCenter defaultCenter] postNotificationName:@"InitDiaryDataSuccessNotification" object:nil];
                
            } else {
                [SVProgressHUD dismiss];
                return;
            }
            
        } else {
            [SVProgressHUD dismiss];
            return;
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@",error);
//        [[TTToolsHelper shared] showAlertMessage:@"网络不给力哦！"];
        [SVProgressHUD showErrorWithStatus:@"网络不给力哦！"];
    }];
}

/**
 *  添加成员的方法
 */
+ (void)addMemberWithName:(NSString *)name Sex:(NSString *)sex City:(NSString *)city Birth:(NSString *)birth Addr:(NSString *)addr Acc_id:(NSString *)acc_id;
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"name"] = name;
    params[@"sex"] = sex;
    params[@"city"] = city;
    params[@"birth"] = birth;
    params[@"addr"] = addr;
    params[@"acc_id"] = acc_id;
    NSString *urlStr = [HOST stringByAppendingString:@"api.php?m=open&c=member&a=setting"];
    [[[self alloc] manager] POST:urlStr parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [SVProgressHUD dismiss];
        if (responseObject[@"status"] == [NSNumber numberWithInteger:1]) {
            BOOL result = [DataBaseTool addMember:responseObject[@"data"]];
            if (!result) {
                [[TTToolsHelper shared] showAlertMessage:@"添加成员失败!"];
            } else {
                //添加成功发出通知
                [[NSNotificationCenter defaultCenter] postNotificationName:@"AddMemberSuccessNotification" object:nil];
            }
        } else {
            [[TTToolsHelper shared] showAlertMessage:@"添加成员失败!"];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@",error);
//        [[TTToolsHelper shared] showAlertMessage:@"网络不给力哦！"];
        [SVProgressHUD showErrorWithStatus:@"网络不给力哦！"];
    }];
}

/**
 *  添加带图像成员的方法
 */
+ (void)addMemberWithName:(NSString *)name Sex:(NSString *)sex City:(NSString *)city Birth:(NSString *)birth Addr:(NSString *)addr Acc_id:(NSString *)acc_id IconImage:(UIImage *)iconImage
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"name"] = name;
    params[@"sex"] = sex;
    params[@"city"] = city;
    params[@"birth"] = birth;
    params[@"addr"] = addr;
    params[@"acc_id"] = acc_id;
    NSString *urlStr = [HOST stringByAppendingString:@"api.php?m=open&c=member&a=setting"];
    [[[self alloc] manager] POST:urlStr parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileData:UIImageJPEGRepresentation(iconImage,0.5) name:@"img" fileName:@"img.jpg" mimeType:@"image/jpeg"];
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [SVProgressHUD dismiss];
        if (responseObject[@"status"] == [NSNumber numberWithInteger:1]) {
            BOOL result = [DataBaseTool addMember:responseObject[@"data"]];
            if (!result) {
                [[TTToolsHelper shared] showAlertMessage:@"添加成员失败!"];
            } else {
                //添加成功发出通知
                [[NSNotificationCenter defaultCenter] postNotificationName:@"AddMemberSuccessNotification" object:nil];
            }
        } else {
            [[TTToolsHelper shared] showAlertMessage:@"添加成员失败!"];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@",error);
//        [[TTToolsHelper shared] showAlertMessage:@"网络不给力哦！"];
        [SVProgressHUD showErrorWithStatus:@"网络不给力哦！"];
    }];
}

/**
 *  删除一个成员
 */
+ (void)removeMember:(NSString *)mid
{
    //发送请求数据
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"member_id"] = mid;
    NSString *urlStr = [HOST stringByAppendingString:@"api.php?m=open&c=member&a=del"];
    [[[self alloc] manager] POST:urlStr parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [SVProgressHUD dismiss];
        if ([[NSString stringWithFormat:@"%@",responseObject[@"status"]] isEqualToString:@"1"]) { //表示删除成功
            BOOL result = [DataBaseTool removeMember:mid];
            if (!result) {
                [[TTToolsHelper shared] showAlertMessage:@"删除成员失败!"];
            } else {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"RemoveMemberSuccessNotification" object:nil];
            }
        } else {
            [[TTToolsHelper shared] showAlertMessage:@"删除成员失败!"];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@",error);
//        [[TTToolsHelper shared] showAlertMessage:@"网络不给力哦！"];
        [SVProgressHUD showErrorWithStatus:@"网络不给力哦！"];
    }];
    
}

/**
 *  设置为选中的成员
 */
+ (void)setDefaultMemberWithAcc_id:(NSString *)acc_id Mid:(NSString *)mid
{
    //发送请求数据
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"acc_id"] = acc_id;
    params[@"mid"] = mid;
    NSString *urlStr = [HOST stringByAppendingString:@"api.php?m=open&c=member&a=defaultSet"];
    [[[self alloc] manager] POST:urlStr parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (responseObject[@"status"] == [NSNumber numberWithInteger:1]) {
            BOOL result = [DataBaseTool setDefaultMemberWithAcc_id:acc_id Mid:mid];
            if (!result) {
                [SVProgressHUD dismiss];
                [[TTToolsHelper shared] showAlertMessage:@"设置默认成员失败!"];
            } else {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"SetDefaultMemberSuccessNotification" object:nil];
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@",error);
//        [[TTToolsHelper shared] showAlertMessage:@"网络不给力哦！"];
        [SVProgressHUD showErrorWithStatus:@"网络不给力哦！"];
    }];
}

+ (void)updateMemberWithMid:(NSString *)mid Name:(NSString *)name Sex:(NSString *)sex Birth:(NSString *)birth City:(NSString *)city
{
    //发送请求数据
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"mid"] = mid;
    params[@"name"] = name;
    params[@"sex"] = sex;
    params[@"birth"] = birth;
    params[@"city"] = city;
    
    NSString *urlStr = [HOST stringByAppendingString:@"api.php?m=open&c=member&a=setting"];
    
    [[[self alloc] manager] POST:urlStr parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [SVProgressHUD dismiss];
        if (responseObject[@"status"] == [NSNumber numberWithInteger:1]) {
            BOOL result = [DataBaseTool updateMember:responseObject[@"data"]];
            if (!result) {
                NSLog(@"修改数据库失败!");
                [[TTToolsHelper shared] showAlertMessage:@"修改成员失败!"];
            } else {
                //判断是否为默认成员
                NSDictionary *defaultMember = [DataBaseTool getDefaultMember];
                
                if ([mid isEqualToString:[NSString stringWithFormat:@"%@",defaultMember[@"id"]]]) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateDefaultMemberSuccessNotification" object:nil];
                }
                [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateMemberSuccessNotification" object:nil];
            }
        } else {
            [[TTToolsHelper shared] showAlertMessage:@"修改成员失败!"];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@",error);
//        [[TTToolsHelper shared] showAlertMessage:@"网络不给力哦！"];
        [SVProgressHUD showErrorWithStatus:@"网络不给力哦！"];
    }];

}

+ (void)updateMemberWithMid:(NSString *)mid Name:(NSString *)name Sex:(NSString *)sex Birth:(NSString *)birth City:(NSString *)city IconImage:(UIImage *)iconImage
{
    //发送请求数据
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"mid"] = mid;
    params[@"name"] = name;
    params[@"sex"] = sex;
    params[@"birth"] = birth;
    params[@"city"] = city;
    
    NSString *urlStr = [HOST stringByAppendingString:@"api.php?m=open&c=member&a=setting"];
    [[[self alloc] manager] POST:urlStr parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileData:UIImageJPEGRepresentation(iconImage, 0.5) name:@"img" fileName:@"img.jpg" mimeType:@"image/jpeg"];
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        [SVProgressHUD dismiss];
        if (responseObject[@"status"] == [NSNumber numberWithInteger:1]) {
            BOOL result = [DataBaseTool updateMember:responseObject[@"data"]];
            if (!result) {
                NSLog(@"修改数据库失败!");
                [[TTToolsHelper shared] showAlertMessage:@"修改成员失败!"];
            } else {
                //判断是否为默认成员
                NSDictionary *defaultMember = [DataBaseTool getDefaultMember];
                
                if ([mid isEqualToString:[NSString stringWithFormat:@"%@",defaultMember[@"id"]]]) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateDefaultMemberSuccessNotification" object:nil];
                }
                [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateMemberSuccessNotification" object:nil];
            }
        } else {
            [[TTToolsHelper shared] showAlertMessage:@"修改成员失败!"];
        }

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@",error);
//        [[TTToolsHelper shared] showAlertMessage:@"网络不给力哦！"];
        [SVProgressHUD showErrorWithStatus:@"网络不给力哦！"];
    }];
}

/**
 *  发起添加记录的请求
 */
+ (void)addDiaryWithDate:(NSString *)date Temperature:(NSString *)temperature Symptoms:(NSString *)symptoms Photo_count:(NSString *)photo_count Description:(NSString *)description Member_id:(NSString *)member_id Longitude:(NSString *)longitude Latitude:(NSString *)latitude
{
    //发送请求数据
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"date"] = date;
    params[@"temperature"] = temperature;
    params[@"symptoms"] = symptoms;
    params[@"photo_count"] = photo_count;
    params[@"description"] = description;
    params[@"member_id"] = member_id;
    params[@"longitude"] = longitude;
    params[@"latitude"] = latitude;
    NSString *urlStr = [HOST stringByAppendingString:@"api.php?m=open&c=member&a=addTemperature"];
    [[[self alloc] manager] POST:urlStr parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@",responseObject);
        //[SVProgressHUD dismiss];
        if (responseObject[@"status"]==[NSNumber numberWithInteger:1]) {
            //存储到数据库中
            BOOL result = [DataBaseTool addDiary:responseObject[@"data"]];
            if (!result) {
                NSLog(@"插入数据失败!");
                [[TTToolsHelper shared] showAlertMessage:@"添加数据失败!"];
            } else {
                //[[NSNotificationCenter defaultCenter] postNotificationName:@"AddDiarySuccessNotification" object:nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"AddDiarySuccessNotification" object:nil userInfo:responseObject[@"data"]];
            }
        } else {
            [SVProgressHUD dismiss];
            [SVProgressHUD showErrorWithStatus:responseObject[@"msg"]];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@",error);
//        [[TTToolsHelper shared] showAlertMessage:@"网络不给力哦！"];
        [SVProgressHUD showErrorWithStatus:@"网络不给力哦！"];
    }];

}
/**
 *  删除一条记录
 */
+ (void)removeDiary:(NSString *)diaryId
{
    //发送请求数据
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"diary_id"] = diaryId;
    NSString *urlStr = [HOST stringByAppendingString:@"api.php?m=open&c=member&a=delTemperature"];
    [[[self alloc] manager] POST:urlStr parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (responseObject[@"status"] == [NSNumber numberWithInteger:1]) {
            BOOL result = [DataBaseTool removeDiary:diaryId];
            if (!result) {
                [[TTToolsHelper shared] showAlertMessage:@"删除记录失败!"];
                return;
            } else {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"RemoveDiarySuccessNotification" object:nil];
            }
        } else {
            [SVProgressHUD dismiss];
            [[TTToolsHelper shared] showAlertMessage:@"删除记录失败!"];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@",error);
//        [[TTToolsHelper shared] showAlertMessage:@"网络不给力哦！"];
        [SVProgressHUD showErrorWithStatus:@"网络不给力哦！"];
    }];
}

/**
 *  通过最大得温度记录ID获取最新的温度记录
 */
+ (NSMutableArray *)getAllDefaultMemberDiaryByLastDiaryId:(NSString *)lastDiaryId
{
    //发送请求数据
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"member_id"] = [NSString stringWithFormat:@"%@",[[DataBaseTool getDefaultMember] objectForKey:@"id"]];
    params[@"diary_id"] = lastDiaryId;
    NSString *urlStr = [HOST stringByAppendingString:@"api.php?m=open&c=member&a=compareTemperature"];
    
    NSURL *url = [NSURL URLWithString:urlStr];
    NSMutableURLRequest *urlrequest = [[NSMutableURLRequest alloc]initWithURL:url];
    urlrequest.HTTPMethod = @"POST";
    NSString *bodyStr = [NSString stringWithFormat:@"member_id=%@&diary_id=%@",params[@"member_id"],params[@"diary_id"]];
    NSData *body = [bodyStr dataUsingEncoding:NSUTF8StringEncoding];
    urlrequest.HTTPBody = body;
    AFHTTPRequestOperation *requestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:urlrequest];
    [requestOperation start];
    [requestOperation waitUntilFinished];
    NSDictionary *result = [NSJSONSerialization JSONObjectWithData:requestOperation.responseData options:NSJSONReadingAllowFragments error:nil];
    if (result[@"status"] == [NSNumber numberWithInteger:1]) {
        return result[@"data"];
    } else {
        return nil;
    }
}

/**
 *  判断当前是否能够上网
 */
+ (BOOL)isConnectInternet
{
    BOOL isConnectInternet;
    Reachability *reach = [Reachability reachabilityWithHostName:HOST];
    if (reach.isReachable) {
        isConnectInternet = YES;
    } else {
        isConnectInternet = NO;
    }
    return isConnectInternet;
}

/**
 *  接收验证码
 */
+ (void)getRegistVerifyCode:(NSString *)phone
{
    //发送请求数据
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"phone"] = phone;
    NSString *urlStr = [HOST stringByAppendingString:@"api.php?m=open&c=account&a=regsms"];
    [[[self alloc] manager] POST:urlStr parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (responseObject[@"status"] == [NSNumber numberWithInteger:1]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"GETCODE_SUCCEED" object:nil];
        } else {
            [SVProgressHUD dismiss];
            [[TTToolsHelper shared] showAlertMessage:responseObject[@"msg"]];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@",error);
//        [[TTToolsHelper shared] showAlertMessage:@"网络不给力哦！"];
        [SVProgressHUD showErrorWithStatus:@"网络不给力哦！"];
    }];
}

/**
 *  修改密码接收验证码
 */
+ (void)getResetPwdVerifyCode:(NSString *)phone
{
    //发送请求数据
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"phone"] = phone;
    NSString *urlStr = [HOST stringByAppendingString:@"api.php?m=open&c=account&a=resetsms"];
    [[[self alloc] manager] POST:urlStr parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (responseObject[@"status"] == [NSNumber numberWithInteger:1]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"GETCODE_SUCCEED" object:nil];
        } else {
            [SVProgressHUD dismiss];
            [[TTToolsHelper shared] showAlertMessage:responseObject[@"msg"]];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@",error);
//        [[TTToolsHelper shared] showAlertMessage:@"网络不给力哦！"];
        [SVProgressHUD showErrorWithStatus:@"网络不给力哦！"];
    }];
}

/**
 *  修改用户密码
 */
+ (void)resetAccountPasswordByPhoneNumber:(NSString *)phoneNumber NewPwd:(NSString *)newPwd Code:(NSString *)code
{
    //发送请求数据
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"phone"] = phoneNumber;
    params[@"password"] = newPwd;
    params[@"code"] = code;
    
    NSString *urlStr = [HOST stringByAppendingString:@"api.php?m=open&c=account&a=resetpsw"];
    
    [[[self alloc] manager] POST:urlStr parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (responseObject[@"status"] == [NSNumber numberWithInteger:1]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"UPDATEPWD_SUCCEED" object:nil];
        } else {
            [SVProgressHUD dismiss];
            [[TTToolsHelper shared] showAlertMessage:responseObject[@"msg"]];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@",error);
//        [[TTToolsHelper shared] showAlertMessage:@"网络不给力哦！"];
        [SVProgressHUD showErrorWithStatus:@"网络不给力哦！"];
    }];
}

/**
 *  获取服务器上最新版本
 */
+ (void)getVersion
{
    NSString *urlStr = [HOST stringByAppendingString:@"api.php?m=open&c=version&a=index&device=ios"];
    [[[self alloc] manager] GET:urlStr parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@",responseObject);
        [[NSNotificationCenter defaultCenter] postNotificationName:@"GetVersionSuccessNotification" object:nil userInfo:responseObject];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@",error);
        [SVProgressHUD showErrorWithStatus:@"网络不给力哦!"];
    }];
}

/**
 *  获取广告页图片数据
 */
+ (void)getAdDict
{
    NSString *quality = @"";
    if ([[GlobalTool deviceString] isEqualToString:@"iPhone 4"] || [[GlobalTool deviceString] isEqualToString:@"iPhone 4S"]) {
        quality = @"iphoneL";
    } else if ([[GlobalTool deviceString] isEqualToString:@"iPhone 5"] || [[GlobalTool deviceString] isEqualToString:@"iPhone 5C"] || [[GlobalTool deviceString] isEqualToString:@"iPhone 5S"]) {
        quality = @"iphoneM";
    } else if ([[GlobalTool deviceString] isEqualToString:@"iPhone 6"] || [[GlobalTool deviceString] isEqualToString:@"iPhone 6 Plus"] || [[GlobalTool deviceString] isEqualToString:@"iPhone 6S"] || [[GlobalTool deviceString] isEqualToString:@"iPhone 6S Plus"]) {
        quality = @"iphoneH";
    } else {
        quality = @"iphoneM";
    }
    NSString *urlStr = [[HOST stringByAppendingString:@"api.php?m=open&c=ads&a=spread&identifier="] stringByAppendingString:quality];
    [[[self alloc] manager] GET:urlStr parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        /**
         *  存储广告数据
         */
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:responseObject forKey:@"ad"];
        [defaults synchronize];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@",error);
//        [SVProgressHUD showErrorWithStatus:@"网络不给力哦!"];
    }];
}

/**
 *  上传温度记录图片
 */
+ (void)uploadDiaryImageWithDiaryId:(NSString *)diaryId Image:(UIImage *)image ImageName:(NSString *)imageName
{
    //发送请求数据
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    NSDictionary *dict = [DataBaseTool getDefaultMember];
    NSString *mid = [NSString stringWithFormat:@"%@",dict[@"id"]];
    params[@"mid"] = mid;
    params[@"id"] = diaryId;
    NSString *urlStr = [HOST stringByAppendingString:@"api.php?m=open&c=member&a=album"];
    [[[self alloc] manager] POST:urlStr parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFileData:UIImageJPEGRepresentation(image, 0.5) name:@"img" fileName:[NSString stringWithFormat:@"%@.jpg",imageName] mimeType:@"image/jpeg"];
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@",responseObject);
        if (![responseObject[@"status"] isEqual:[NSNumber numberWithInt:1]]) {
            [[TTToolsHelper shared] showAlertMessage:@"上传图片失败"];
        } else {
            NSMutableDictionary *userInfoDict = [NSMutableDictionary dictionary];
            userInfoDict[@"imageName"] = imageName;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"AddDiaryImageSuccess" object:nil userInfo:userInfoDict];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@",error);
//        [[TTToolsHelper shared] showAlertMessage:@"网络不给力哦！"];
        [SVProgressHUD showErrorWithStatus:@"网络不给力哦！"];
    }];
}

/**
 *  修改温度记录
 */
+ (void)updateDiaryWithTid:(NSString *)tid Date:(NSString *)date Temperature:(NSString *)temperature Symbols:(NSString *)symbols Desc:(NSString *)desc
{
    //发送请求数据
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"id"] = tid;
    params[@"date"] = date;
    params[@"temperature"] = temperature;
    params[@"description"] = desc;
    params[@"symptoms"] = [NSString stringWithFormat:@"%ld",(long)[[self alloc] transferSymbols:symbols]];
    NSString *urlStr = [HOST stringByAppendingString:@"api.php?m=open&c=member&a=editTemperature"];
    [[[self alloc] manager] POST:urlStr parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([responseObject[@"status"] isEqualToNumber:[NSNumber numberWithInt:1]]) {
            NSDictionary *newData = responseObject[@"data"];
            NSString *tid = [NSString stringWithFormat:@"%@",newData[@"id"]];
            NSString *date = [NSString stringWithFormat:@"%@",newData[@"date"]];
            NSString *temperature = [NSString stringWithFormat:@"%@",newData[@"temperature"]];
            NSString *symptoms = [NSString stringWithFormat:@"%@",newData[@"symptoms"]];
            NSString *description = [NSString stringWithFormat:@"%@",newData[@"description"]];
            BOOL result =[DataBaseTool updateDiaryWithTid:tid Date:date Temperature:temperature Symbols:symptoms Desc:description];
            if (result) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateDiarySuccessNotification" object:nil];
            } else {
                [[TTToolsHelper shared] showAlertMessage:@"修改失败"];
            }
        } else {
            [[TTToolsHelper shared] showAlertMessage:@"修改失败"];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@",error);
//        [[TTToolsHelper shared] showAlertMessage:@"网络不给力哦！"];
        [SVProgressHUD showErrorWithStatus:@"网络不给力哦！"];
    }];
}

- (NSInteger)transferSymbols:(NSString *)symbols
{
    NSMutableArray *sympolsArray = [NSMutableArray arrayWithArray:[symbols componentsSeparatedByString:@" "]];
    [sympolsArray removeObject:@" "];
    NSInteger symbolsInt = 0;
    GlobalData *gd = [GlobalData sharedData];
    NSArray *symbolsList = gd.symptonTemplateList;
    for (NSDictionary *symbolDict in symbolsList) {
        if ([sympolsArray containsObject:symbolDict[@"name"]]) {
            NSInteger count = [symbolDict[@"tag"] integerValue];
            symbolsInt += [self count2N:count];
        }
    }
    return symbolsInt;
}

- (NSInteger)count2N:(NSInteger)count
{
    if (count == 1) {
        return 2;
    } else {
        NSInteger result = 2;
        for (int i = 1; i < count; i++) {
            result *= 2;
        }
        return result;
    }
}

/**
 *  进入主页后验证登陆
 */
+ (void)validLogin
{
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *path = [docDir stringByAppendingPathComponent:@"account.archive"];
    Account *account = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    
    NSMutableDictionary *defaultMember = [DataBaseTool getDefaultMember];
    if (defaultMember == nil) { //没有登录过
        return;
    } else {
        if(![[NSFileManager defaultManager] fileExistsAtPath:path]) { //没有这个存储文件
            return;
        } else { //有这个存储文件则验证登陆
            switch (account.platForm) {
                case CurrentLoginStatusPhoneNumber:
                    [self validLoginWithPhoneNumber];
                    break;
                case CurrentLoginStatusSinaWeiBo:
                    [self validLoginWithThirdParty];
                    break;
                case CurrentLoginStatusQQ:
                    [self validLoginWithThirdParty];
                    break;
                case CurrentLoginStatusWeiXin:
                    [self validLoginWithThirdParty];
                    break;
                default:
                    break;
            }
        }
    }
    
//    NSMutableDictionary *defaultMember = [DataBaseTool getDefaultMember];
//    if (defaultMember == nil) { //没有登陆过
//        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
//        return;
//    } else { //有登陆过
//        int currentloginstatus = (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"currentloginstatus"];
//        if (!currentloginstatus) {
//            return;
//        }
//        switch (currentloginstatus) {
//            case CurrentLoginStatusPhoneNumber://电话号码登陆
//                [self validLoginWithPhoneNumber];
//                break;
//            case CurrentLoginStatusSinaWeiBo://新浪微博登陆
//                [self validLoginWithThirdParty];
//                break;
//            case CurrentLoginStatusQQ://QQ登陆
//                [self validLoginWithThirdParty];
//                break;
//            case CurrentLoginStatusWeiXin://微信登陆
//                [self validLoginWithThirdParty];
//                break;
//            default:
//                [[NSUserDefaults standardUserDefaults] setInteger:CurrentLoginStatusNone forKey:@"currentloginstatus"];
//                [[NSUserDefaults standardUserDefaults] synchronize];
//                break;
//        }
//    }
}

+ (void)validLoginWithPhoneNumber
{
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *path = [docDir stringByAppendingPathComponent:@"account.archive"];
    Account *account = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    //发送请求数据
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"phone"] = account.telephone;
    params[@"password"] = account.password;
    params[@"devicetype"] = @"ios";
    params[@"timestamp"] = [NSString stringWithFormat:@"%d",(int)[[NSDate date] timeIntervalSince1970]];
    params[@"version"] = [[self alloc] getCurrentDeviceBuildVersion];
    params[@"uuid"] = [[self alloc] getCurrentDeviceIdentifierNumber];
    params[@"version"] = VERSION;
    params[@"sign"] = [[self alloc] getLoginSignWithPhoneNumber:account.telephone Password:account.password Timestamp:params[@"timestamp"]];
    //取出用户的DeviceToken
    NSData *deviceTokenData = [[NSUserDefaults standardUserDefaults] objectForKey:@"deviceToken"];
    params[@"devicetoken"] = [NSString stringWithFormat:@"%@",deviceTokenData];
    params[@"devicetoken"] = [params[@"devicetoken"] stringByReplacingOccurrencesOfString:@"<" withString:@""];
    params[@"devicetoken"] = [params[@"devicetoken"] stringByReplacingOccurrencesOfString:@">" withString:@""];
    params[@"devicetoken"] = [params[@"devicetoken"] stringByReplacingOccurrencesOfString:@" " withString:@""];
    params[@"device_brand"] = @"apple";
    params[@"device_model"] = [GlobalTool deviceString];
    params[@"device_system"] = @"ios";
    params[@"device_version"] = [NSString stringWithFormat:@"%.1f",[[UIDevice currentDevice].systemVersion floatValue]];
    
    //请求地址
    NSString *urlStr = [HOST stringByAppendingString:@"api.php?m=open&c=account&a=login"];
    
    [[[self alloc] manager] POST:urlStr parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([responseObject[@"status"] isEqual:[NSNumber numberWithInt:0]]) {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            UIViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
            [UIApplication sharedApplication].keyWindow.rootViewController = vc;
            return;
        } else {
            return;
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        return;
    }];

}

+ (void)validLoginWithThirdParty
{
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *path = [docDir stringByAppendingPathComponent:@"account.archive"];
    Account *account = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    
    NSString *platForm = @"";
    NSString *PlatFormMob = @"";
//    NSInteger currentLoginStatus = [[NSUserDefaults standardUserDefaults] integerForKey:@"currentloginstatus"];
//    switch (currentLoginStatus) {
//        case CurrentLoginStatusSinaWeiBo:
//            platForm = @"1";
//            break;
//        case CurrentLoginStatusQQ:
//            platForm = @"2";
//            break;
//        case CurrentLoginStatusWeiXin:
//            platForm = @"3";
//            break;
//        default:
//            break;
//    }
    switch (account.platForm) {
        case CurrentLoginStatusSinaWeiBo:
            platForm = @"1";
            PlatFormMob = @"SinaWeiBo";
            break;
        case CurrentLoginStatusQQ:
            platForm = @"2";
            PlatFormMob = @"QQ";
            break;
        case CurrentLoginStatusWeiXin:
            platForm = @"3";
            PlatFormMob = @"WeiXin";
            break;
        default:
            break;
    }
    
    if ([platForm  isEqualToString:@""]) {
        return;
    }
    
    //发送请求数据
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"openid"] = account.openID;
    params[@"timestamp"] = [NSString stringWithFormat:@"%d",(int)[[NSDate date] timeIntervalSince1970]];
    params[@"platform"] = platForm;
    params[@"devicetype"] = @"ios";
    params[@"version"] = VERSION;
    params[@"uuid"] = [[self alloc] getCurrentDeviceIdentifierNumber];
    params[@"sign"] = [[self alloc] getLoginThirdPartySignWithOpenId:account.openID PlatForm:platForm Timestamp:params[@"timestamp"]];
    
    //取出用户的DeviceToken
    NSData *deviceTokenData = [[NSUserDefaults standardUserDefaults] objectForKey:@"deviceToken"];
    params[@"devicetoken"] = [NSString stringWithFormat:@"%@",deviceTokenData];
    params[@"devicetoken"] = [params[@"devicetoken"] stringByReplacingOccurrencesOfString:@"<" withString:@""];
    params[@"devicetoken"] = [params[@"devicetoken"] stringByReplacingOccurrencesOfString:@">" withString:@""];
    params[@"devicetoken"] = [params[@"devicetoken"] stringByReplacingOccurrencesOfString:@" " withString:@""];
    params[@"device_brand"] = @"apple";
    params[@"device_model"] = [GlobalTool deviceString];
    params[@"device_system"] = @"ios";
    params[@"device_version"] = [NSString stringWithFormat:@"%.1f",[[UIDevice currentDevice].systemVersion floatValue]];
    
    NSString *urlStr = [HOST stringByAppendingString:@"api.php?m=open&c=account&a=oauth"];
    [[[self alloc] manager] POST:urlStr parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if ([responseObject[@"status"] isEqual:[NSNumber numberWithInt:0]]) {
            UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
            UIViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
            [UIApplication sharedApplication].keyWindow.rootViewController = vc;
            
            return;
        } else {
            return;
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        return;
    }];
}

/**
 *  测温统计
 */
+ (void)checkCountWithStartTime:(NSString *)starttime Temperature:(NSString *)temperature TemperatureType:(NSString *)type OperateType:(NSString *)operateType {
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *path = [docDir stringByAppendingPathComponent:@"account.archive"];
    NSString *accountId = @"";
    NSString *accountType = @"";
    NSString *memberId = @"";
    NSString *city = [[GlobalTool shared] city];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSDictionary *memberDict = [DataBaseTool getDefaultMember];
        memberId = [NSString stringWithFormat:@"%@",memberDict[@"id"]];
        Account *account = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
        if ([account.telephone isEqualToString:@""]) {
            switch (account.platForm) {
                case 1:
                    accountType = @"sina";
                    accountId = account.openID;
                    break;
                case 2:
                    accountType = @"qq";
                    accountId = account.openID;
                    break;
                case 3:
                    accountType = @"weixin";
                    accountId = account.openID;
                    break;
                default:
                    break;
            }
        } else {
            accountType = @"local";
            accountId = account.telephone;
        }
    } else {
        accountType = @"guest";
        accountId = @"";
        memberId = @"";
    }
    //发送请求数据
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"starttime"] = starttime;
    params[@"endtime"] = [NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSince1970]];
    params[@"temperature"] = temperature;
    params[@"temperature_type"] = type;
    params[@"operate_type"] = operateType;
    params[@"city"] = city;
    params[@"member_id"] = memberId;
    params[@"account_id"] = accountId;
    params[@"account_type"] = accountType;
    
    /**
     *  2015-12-01 新加入参数
     */
    params[@"version"] = VERSION;
    params[@"device_brand"] = @"apple";
    params[@"device_model"] = [GlobalTool deviceString];
    params[@"device_system"] = @"ios";
    params[@"device_version"] = [UIDevice currentDevice].systemVersion;
    
    NSString *urlStr = [HOST stringByAppendingString:@"api.php?m=open&c=Record&a=temperature"];
    
    [[[self alloc] manager] POST:urlStr parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        return;
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        return;
    }];
}

/**
 *  获取默认用户的所有测温记录
 */
+ (void)getDefaultMemberDiaryInfoByPage:(int)page
{
    //发送请求数据
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    //去除默认用户的id
    NSDictionary *defaultMemberInfo = [DataBaseTool getDefaultMember];
    params[@"mid"] = [NSString stringWithFormat:@"%@",defaultMemberInfo[@"id"]];
    params[@"page"] = [NSString stringWithFormat:@"%d",page];
    NSString *urlStr = [HOST stringByAppendingString:@"api.php?m=open&c=member&a=listTemperature"];
    
    [[[self alloc] manager] POST:urlStr parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (responseObject[@"status"] == [NSNumber numberWithInteger:1]) {
            NSArray *diaryArray = responseObject[@"data"];
            if (diaryArray != nil || diaryArray.count != 0) {
                BOOL result = [DataBaseTool addDiaryWithArray:diaryArray];
                if (!result) {
                    NSLog(@"插入数据库失败!");
                }
                [[NSNotificationCenter defaultCenter] postNotificationName:@"InitDiaryDataSuccessNotification" object:nil];
                
            } else {
                return;
            }
            
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"InitDiaryDataEndSuccessNotification" object:nil];
            return;
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [SVProgressHUD dismiss];
        NSLog(@"%@",error);
        [[NSNotificationCenter defaultCenter] postNotificationName:@"InitDiaryDataEndFailNotification" object:nil];
//        [[TTToolsHelper shared] showAlertMessage:@"网络不给力哦！"];
        [SVProgressHUD showErrorWithStatus:@"网络不给力哦！"];
    }];
}

@end
