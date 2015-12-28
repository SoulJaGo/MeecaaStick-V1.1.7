//
//  TTNetworkHelper.m
//  HomeKinsa
//
//  Created by Zhang guangchun on 15/3/4.
//  Copyright (c) 2015年 Mikai. All rights reserved.
//

#import "TTNetworkHelper.h"
#import <CommonCrypto/CommonDigest.h>
#include <CommonCrypto/CommonHMAC.h>
#include "NSString+MyCategory.h"
//#include "NSData+MyCategory.h"
#import "GlobalData.h"
#import <CRToast/CRToast.h>
#import "TTErrorHelper.h"
#import <SVProgressHUD.h>
#import <SIAlertView/SIAlertView.h>
#import "SSKeychain.h"
#import "TTToolsHelper.h"

@implementation TTNetworkHelper

+ (id)sharedSession {
    static TTNetworkHelper *sharedSession = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedSession = [[self alloc] init];
    });
    return sharedSession;
}

- (id)init {
    if (self = [super init]) {
        
        _requestId = 0;
        _sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        
        NSString *cachePath = @"cache";
        NSArray *myPathList = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *myPath    = [myPathList  objectAtIndex:0];
        NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
        NSString *fullCachePath = [[myPath stringByAppendingPathComponent:bundleIdentifier] stringByAppendingPathComponent:cachePath];
        NSURLCache *myCache = [[NSURLCache alloc] initWithMemoryCapacity: 10 * 1024 * 1024 diskCapacity: 100 * 1024 * 1024 diskPath: fullCachePath];
        
        _sessionConfiguration.URLCache = myCache;
        
    }
    return self;
}

- (void)dealloc {
    // Should never be called, but just here for clarity really.
}

#pragma mark -- URL Query Encode --

- (NSString *)toString:(id) object {
    return [NSString stringWithFormat: @"%@", object];
}

// helper function: get the url encoded string form of any object
- (NSString *)urlEncode:(id) object {
    NSString *string = [self toString:object];
    return [self urlEncodeUsingEncoding:string];
    //return [string stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
}

- (NSString*)concatenateQuery:(NSDictionary*)parameters {
    if(!parameters||[parameters count]==0) return nil;
    NSMutableString* query = [NSMutableString string];
    for(NSString* parameter in [parameters allKeys])
        [query appendFormat:@"&%@=%@",[parameter stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding],[[parameters valueForKey:parameter] stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
    return [query substringFromIndex:1];
}

- (NSDictionary*)splitQuery:(NSString*)query {
    if(!query||[query length]==0) return nil;
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    for(NSString* parameter in [query componentsSeparatedByString:@"&"]) {
        NSRange range = [parameter rangeOfString:@"="];
        if(range.location!=NSNotFound)
            [parameters setValue:[[parameter substringFromIndex:range.location+range.length] stringByReplacingPercentEscapesUsingEncoding:NSASCIIStringEncoding] forKey:[[parameter substringToIndex:range.location] stringByReplacingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
        else [parameters setValue:[[NSString alloc] init] forKey:[parameter stringByReplacingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
    }
    return parameters;
}

-(NSString *)urlEncodeUsingEncoding:(NSString*) data {
    return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)data, NULL, (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ", CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding)));
}

- (NSString *) URLEncodedString_ch:(NSString*)data {
    NSMutableString * output = [NSMutableString string];
    const unsigned char * source = (const unsigned char *)[data UTF8String];
    int sourceLen = (int)strlen((const char *)source);
    for (int i = 0; i < sourceLen; ++i) {
        const unsigned char thisChar = source[i];
        if (thisChar == ' '){
            [output appendString:@"+"];
        } else if (thisChar == '.' || thisChar == '-' || thisChar == '_' || thisChar == '~' ||
                   (thisChar >= 'a' && thisChar <= 'z') ||
                   (thisChar >= 'A' && thisChar <= 'Z') ||
                   (thisChar >= '0' && thisChar <= '9')) {
            [output appendFormat:@"%c", thisChar];
        } else {
            [output appendFormat:@"%%%02X", thisChar];
        }
    }
    return output;
}

- (NSData*) inflate:(NSData *)data {
    if (data == nil) return nil;
    if ([data length] <= 4) return nil;
    
    UInt8 *s = (UInt8 *)[data bytes];
    // 0xDC 0x7F 0xD8 0x80
    if (*(s+0) == 0xDC &&
        *(s+1) == 0x7F &&
        *(s+2) == 0xD8 &&
        *(s+3) == 0x80) {
//        NSData *d = [[data subdataWithRange:NSMakeRange(4, [data length]-4)]];
//        return d;
    }
    return nil;
}

- (NSString *)buildForm:(NSDictionary*) dict{
    
    NSArray *sortedKeys = [[dict allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1 compare:obj2];
    }];
    
    NSMutableArray *parts = [NSMutableArray array];
    for (NSString *key in sortedKeys){
        NSString *part = [NSString stringWithFormat: @"%@=%@", [self urlEncode:key], [self urlEncode:[dict objectForKey: key]]];
        [parts addObject: part];
    }
    
    return [parts componentsJoinedByString: @"&"];
}

- (NSString *) getJSONStringfromDictionary:(NSDictionary *)body encrypt:(BOOL)encrypt{
    
    NSString *jsonString = nil;
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:body options:kNilOptions error:&error];
    if (! jsonData) {
        NSLog(@"Got an error: %@", error);
    } else {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    
    if (encrypt == true){
        GlobalData *gd = [GlobalData sharedData];
        return [NSString stringWithFormat:@"s=%@", [self urlEncode:[jsonString encryptAES128WithKey:gd.secrectKey]]];
    }else{
        return [self buildForm:body];
    }
}

-(NSURLSession *) getSession:(id <NSURLSessionDelegate>)delegate{
    return [NSURLSession sessionWithConfiguration:_sessionConfiguration delegate:delegate delegateQueue:nil];
}

- (RACSignal *) updateVideo:(NSDictionary *)postParams video:(NSData *)data {
    NSString *url = [NSString stringWithFormat:@"%@", @"http://121.42.46.54/test.php"];
    return [[[TTNetworkHelper sharedSession] updateVideoFromURL:url method:@"POST" body:postParams video:data] map:^(NSDictionary *json) {
        return json;
    }];
}

- (RACSignal *)updateVideoFromURL:(NSString *)url method:(NSString *)method body:(NSDictionary *)postParems video:(NSData *)data{
    return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        // now only post first
        NSString *TWITTERFON_FORM_BOUNDARY = @"0xKhTmLbOuNdArY";
        //根据url初始化request
        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]
                                                               cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                           timeoutInterval:45];
        //分界线 --AaB03x
        NSString *MPboundary=[[NSString alloc]initWithFormat:@"--%@",TWITTERFON_FORM_BOUNDARY];
        //结束符 AaB03x--
        NSString *endMPboundary=[[NSString alloc]initWithFormat:@"%@--",MPboundary];
        
        //http body的字符串
        NSMutableString *body=[[NSMutableString alloc]init];
        //参数的集合的所有key的集合
        NSArray *keys= [postParems allKeys];
        //遍历keys
        for(int i=0;i<[keys count];i++)
        {
            //得到当前key
            NSString *key=[keys objectAtIndex:i];
            
            //添加分界线，换行
            [body appendFormat:@"%@\r\n",MPboundary];
            //添加字段名称，换2行
            [body appendFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n",key];
            //添加字段的值
            [body appendFormat:@"%@\r\n",[postParems objectForKey:key]];
            
            NSLog(@"添加字段的值==%@",[postParems objectForKey:key]);
        }
        [body appendFormat:@"%@\r\n",MPboundary];
        
        //声明pic字段，文件名为boris.png
        [body appendFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n",@"userfile",@"play.raw"];
        //声明上传文件的格式
        //        [body appendFormat:@"Content-Type: image/jpge,image/gif, image/jpeg, image/pjpeg, image/pjpeg\r\n\r\n"];
        [body appendFormat:@"Content-Type: video/mov\r\n\r\n"];
        //声明结束符：--AaB03x--
        NSString *end=[[NSString alloc]initWithFormat:@"\r\n%@",endMPboundary];
        //声明myRequestData，用来放入http body
        NSMutableData *myRequestData=[NSMutableData data];
        [myRequestData appendData:[body dataUsingEncoding:NSUTF8StringEncoding]];
        //将image的data加入
        [myRequestData appendData:data];
        //加入结束符--AaB03x--
        [myRequestData appendData:[end dataUsingEncoding:NSUTF8StringEncoding]];
        //设置HTTPHeader中Content-Type的值
        NSString *content=[[NSString alloc]initWithFormat:@"multipart/form-data; boundary=%@",TWITTERFON_FORM_BOUNDARY];
        //设置HTTPHeader
        [request setValue:content forHTTPHeaderField:@"Content-Type"];
        //设置Content-Length
        [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[myRequestData length]] forHTTPHeaderField:@"Content-Length"];
        //设置http body
        [request setHTTPBody:myRequestData];
        //http method
        [request setHTTPMethod:@"POST"];
        
        NSURLSession *session = [[TTNetworkHelper sharedSession] getSession:nil];
        NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (! error) {
                NSError *jsonError = nil;
                NSData *responseData = data;
                NSHTTPURLResponse *result = (NSHTTPURLResponse*)response;
                
                NSString *responseStr = [[NSString alloc] initWithData:responseData  encoding:NSUTF8StringEncoding];
                NSLog(@"responseStr %@", responseStr);
                
                id json = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&jsonError];
                if ( !result || [result statusCode] != 200){
                    NSString *errorMsg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    [subscriber sendError:[NSError errorWithDomain:errorMsg code:-1 userInfo:nil]];
                }else if (! jsonError) {
                    if ([json[@"ret"] isEqualToString:@"OK"]){
                        [subscriber sendNext:json];
                    }else{
                        NSString *errMsg = json[@"desc"];
                        if (errMsg == nil){
                            errMsg = @"unkown error";
                        }
                        [subscriber sendError:[NSError errorWithDomain:errMsg code:[json[@"code"] intValue] userInfo:nil]];
                    }
                } else {
                    [subscriber sendError:jsonError];
                }
            } else {
                [subscriber sendError:error];
            }
            
            [subscriber sendCompleted];
        }];
        
        [dataTask resume];
        
        return [RACDisposable disposableWithBlock:^{
            [dataTask cancel];
        }];
        
    }] doError:^(NSError *error) {
        NSLog(@"%@",error);
        [self showErrorMessage:@"未能链接服务器!"];
//        [self showErrorMessage:error.description];
    }];
}

//103.6.220.151/fileupload.php?date=xxxxxx
- (RACSignal *) updateImage:(UIImage *)image InDate:(NSNumber *)date WithName:(NSString *)fileName{
    GlobalData *gd = [GlobalData sharedData];
    NSString *url = [NSString stringWithFormat:@"http://%@/fileupload.php?date=%@", [gd connectUrl],date];
//    NSString *url = [NSString stringWithFormat:@"%@%@", @"http://121.42.46.54/test.php?date=",date];
    return [[[TTNetworkHelper sharedSession] updateImageFromURL:url image:image filename:fileName] map:^(NSDictionary *json) {
        return json;
    }];
}

- (UIImage *)scaleToSize:(UIImage *)img size:(CGSize)size{
    // 创建一个bitmap的context
    // 并把它设置成为当前正在使用的context
    UIGraphicsBeginImageContext(size);
    // 绘制改变大小的图片
    [img drawInRect:CGRectMake(0, 0, size.width, size.height)];
    // 从当前context中创建一个改变大小后的图片
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    // 使当前的context出堆栈
    UIGraphicsEndImageContext();
    // 返回新的改变大小后的图片
    return scaledImage;
}

- (RACSignal *)updateImageFromURL:(NSString *)url  image:(UIImage *)image filename:(NSString *)name{
    return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        // now only post first
        NSString *TWITTERFON_FORM_BOUNDARY = @"0xKhTmLbOuNdArY";
        //根据url初始化request
        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]
                                                               cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                           timeoutInterval:45];
        //分界线 --AaB03x
        NSString *MPboundary=[[NSString alloc]initWithFormat:@"--%@",TWITTERFON_FORM_BOUNDARY];
        //结束符 AaB03x--
        NSString *endMPboundary=[[NSString alloc]initWithFormat:@"%@--",MPboundary];
        //得到图片的data
        
//        UIImage *imageNew = [self scaleToSize:image size:CGSizeMake(image.size.width/3, image.size.height/3)];
        NSData* data = UIImageJPEGRepresentation(image, 0.5);
        //http body的字符串
        NSMutableString *body=[[NSMutableString alloc]init];
        //参数的集合的所有key的集合
        [body appendFormat:@"%@\r\n",MPboundary];
        //声明pic字段，文件名为boris.png
        [body appendFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n",@"file",name];
        //声明上传文件的格式
        //        [body appendFormat:@"Content-Type: image/jpge,image/gif, image/jpeg, image/pjpeg, image/pjpeg\r\n\r\n"];
        [body appendFormat:@"Content-Type: image/jpeg\r\n\r\n"];
        //声明结束符：--AaB03x--
        NSString *end=[[NSString alloc]initWithFormat:@"\r\n%@",endMPboundary];
        //声明myRequestData，用来放入http body
        NSMutableData *myRequestData=[NSMutableData data];
        [myRequestData appendData:[body dataUsingEncoding:NSUTF8StringEncoding]];
        //将image的data加入
        [myRequestData appendData:data];
        //加入结束符--AaB03x--
        [myRequestData appendData:[end dataUsingEncoding:NSUTF8StringEncoding]];
        //设置HTTPHeader中Content-Type的值
        NSString *content=[[NSString alloc]initWithFormat:@"multipart/form-data; boundary=%@",TWITTERFON_FORM_BOUNDARY];
        //设置HTTPHeader
        [request setValue:content forHTTPHeaderField:@"Content-Type"];
        //设置Content-Length
        [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[myRequestData length]] forHTTPHeaderField:@"Content-Length"];
        //设置http body
        [request setHTTPBody:myRequestData];
        //http method
        [request setHTTPMethod:@"POST"];
        
        NSURLSession *session = [[TTNetworkHelper sharedSession] getSession:nil];
        NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (! error) {
//                NSError *jsonError = nil;
                NSData *responseData = data;
//                NSHTTPURLResponse *result = (NSHTTPURLResponse*)response;
                
                NSString *responseStr = [[NSString alloc] initWithData:responseData  encoding:NSUTF8StringEncoding];
                NSLog(@"responseStr %@", responseStr);
                if ([responseStr isEqualToString:@"0"]) {
                    [subscriber sendNext:@0];
                }
                else {
                    [subscriber sendError:nil];
                }
            } else {
                [subscriber sendError:error];
            }
            
            [subscriber sendCompleted];
        }];
        
        [dataTask resume];
        
        return [RACDisposable disposableWithBlock:^{
            [dataTask cancel];
        }];
        
    }] doError:^(NSError *error) {
        NSLog(@"%@",error);
        [self showErrorMessage:error.description];
    }];
}

- (RACSignal *) updateImage:(NSDictionary *)postParams image:(UIImage *)image{
    //    NSString *url = [NSString stringWithFormat:@"%@", @"http://lik.r2digi.com/apps/lik/upload.php"];
    NSString *url = [NSString stringWithFormat:@"%@", @"http://121.42.46.54/lik/upload.php"];
    return [[[TTNetworkHelper sharedSession] updateImageFromURL:url method:@"POST" body:postParams image:image] map:^(NSDictionary *json) {
        return json;
    }];
}


- (RACSignal *)updateImageFromURL:(NSString *)url method:(NSString *)method body:(NSDictionary *)postParems image:(UIImage *)image{
    return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        // now only post first
        NSString *TWITTERFON_FORM_BOUNDARY = @"0xKhTmLbOuNdArY";
        //根据url初始化request
        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]
                                                               cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                           timeoutInterval:45];
        //分界线 --AaB03x
        NSString *MPboundary=[[NSString alloc]initWithFormat:@"--%@",TWITTERFON_FORM_BOUNDARY];
        //结束符 AaB03x--
        NSString *endMPboundary=[[NSString alloc]initWithFormat:@"%@--",MPboundary];
        //得到图片的data
        NSData* data = UIImageJPEGRepresentation(image, 0.6);
        /*if (UIImagePNGRepresentation(image)) {
         if (UIImagePNGRepresentation(image)) {
         //返回为png图像。
         data = UIImagePNGRepresentation(image);
         }else {
         //返回为JPEG图像。
         data = UIImageJPEGRepresentation(image, 1.0);
         }
         }*/
        //http body的字符串
        NSMutableString *body=[[NSMutableString alloc]init];
        //参数的集合的所有key的集合
        NSArray *keys= [postParems allKeys];
        //遍历keys
        for(int i=0;i<[keys count];i++)
        {
            //得到当前key
            NSString *key=[keys objectAtIndex:i];
            
            //添加分界线，换行
            [body appendFormat:@"%@\r\n",MPboundary];
            //添加字段名称，换2行
            [body appendFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n",key];
            //添加字段的值
            [body appendFormat:@"%@\r\n",[postParems objectForKey:key]];
            
            NSLog(@"添加字段的值==%@",[postParems objectForKey:key]);
        }
        [body appendFormat:@"%@\r\n",MPboundary];
        
        //声明pic字段，文件名为boris.png
        [body appendFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n",@"file",@"ipodfile.jpg"];
        //声明上传文件的格式
        //        [body appendFormat:@"Content-Type: image/jpge,image/gif, image/jpeg, image/pjpeg, image/pjpeg\r\n\r\n"];
        [body appendFormat:@"Content-Type: image/jpeg\r\n\r\n"];
        //声明结束符：--AaB03x--
        NSString *end=[[NSString alloc]initWithFormat:@"\r\n%@",endMPboundary];
        //声明myRequestData，用来放入http body
        NSMutableData *myRequestData=[NSMutableData data];
        [myRequestData appendData:[body dataUsingEncoding:NSUTF8StringEncoding]];
        //将image的data加入
        [myRequestData appendData:data];
        //加入结束符--AaB03x--
        [myRequestData appendData:[end dataUsingEncoding:NSUTF8StringEncoding]];
        //设置HTTPHeader中Content-Type的值
        NSString *content=[[NSString alloc]initWithFormat:@"multipart/form-data; boundary=%@",TWITTERFON_FORM_BOUNDARY];
        //设置HTTPHeader
        [request setValue:content forHTTPHeaderField:@"Content-Type"];
        //设置Content-Length
        [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[myRequestData length]] forHTTPHeaderField:@"Content-Length"];
        //设置http body
        [request setHTTPBody:myRequestData];
        //http method
        [request setHTTPMethod:@"POST"];
        
        NSURLSession *session = [[TTNetworkHelper sharedSession] getSession:nil];
        NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (! error) {
                NSError *jsonError = nil;
                NSData *responseData = data;
                NSHTTPURLResponse *result = (NSHTTPURLResponse*)response;
                
                NSString *responseStr = [[NSString alloc] initWithData:responseData  encoding:NSUTF8StringEncoding];
                NSLog(@"response str:%@", responseStr);
                id json = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&jsonError];
                if ( !result || [result statusCode] != 200){
                    NSString *errorMsg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    [subscriber sendError:[NSError errorWithDomain:errorMsg code:-1 userInfo:nil]];
                }else if (! jsonError) {
                    if ([json objectForKey:@"error"]) {
                        NSString *errMsg = [json objectForKey:@"error"];
                        [subscriber sendError:[NSError errorWithDomain:errMsg code:-1 userInfo:nil]];
                    }
                    else {
                        [subscriber sendNext:[json objectForKey:@"ret"]];
                    }
                } else {
                    [subscriber sendError:jsonError];
                }
            } else {
                [subscriber sendError:error];
            }
            
            [subscriber sendCompleted];
        }];
        
        [dataTask resume];
        
        return [RACDisposable disposableWithBlock:^{
            [dataTask cancel];
        }];
        
    }] doError:^(NSError *error) {
        NSLog(@"%@",error);
        [self showErrorMessage:error.description];
    }];
}

- (RACSignal *) downloadDataFromURL:(NSString *)url {
    return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
        NSURLSession *session = [[TTNetworkHelper sharedSession] getSession:nil];
        NSURLSessionDownloadTask *dataTask = [session downloadTaskWithRequest:request completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
            
        }];
        [dataTask resume];
        return [RACDisposable disposableWithBlock:^{
            [dataTask cancel];
        }];
    }]
            doError:^(NSError *error) {
                NSLog(@"%@",error);
                [self showErrorMessage:error.description];
            }];
}

- (RACSignal *)fetchJSONFromURL:(NSString *)url method:(NSString*) method body:(NSDictionary *)bodyDictionary encrypt:(BOOL)encrypt{
    
    return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        NSMutableURLRequest *request;
        request.HTTPMethod = method;
        
        if ([method isEqualToString:@"GET"]) {
            NSString *cmdStr = @"";
            NSString *paramStr = @"";
            for (NSString *key in bodyDictionary) {
                id value = bodyDictionary[key];
                if ([key isEqualToString:@"cmd"]) {
                    if ([value intValue]==-1) {
                        cmdStr = [NSString stringWithFormat:@"ver.php?cmd=%@", value];
                    }
                    else{
                        cmdStr = [NSString stringWithFormat:@"?cmd=%@", value];
                    }
                }
                else {
                    paramStr = [paramStr stringByAppendingFormat:@"&%@=%@",key, [self urlEncode:value]];
                }
            }
            NSLog(@"%@",[NSString stringWithFormat:@"%@%@%@",url,cmdStr,paramStr]);
            request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@",url,cmdStr,paramStr]]];
        }
        else {
            request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
            
            NSMutableDictionary *mutableBodydict = [NSMutableDictionary dictionaryWithDictionary:bodyDictionary];
            [mutableBodydict setValue:[NSNumber numberWithInteger:++_requestId] forKey:@"_no"];
            NSString *postString = [self getJSONStringfromDictionary:mutableBodydict encrypt:encrypt];
            request.HTTPBody = [postString dataUsingEncoding:NSUTF8StringEncoding];
        }
        
        NSURLSession *session = [[TTNetworkHelper sharedSession] getSession:nil];
        NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (! error) {
                NSError *jsonError = nil;
                NSData *responseData = data;
                NSHTTPURLResponse *result = (NSHTTPURLResponse*)response;
                
                NSString *responseStr = [[NSString alloc] initWithData:responseData  encoding:NSUTF8StringEncoding];
                NSLog(@"responseStr %@", responseStr);
                if ([responseStr isEqualToString:@"0"]
                    ||[responseStr isEqualToString:@"1"]) {
                    if ( !result || [result statusCode] != 200){
                        NSString *errorMsg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                        [subscriber sendError:[NSError errorWithDomain:errorMsg code:-1 userInfo:nil]];
                    }else if (! jsonError) {
                        [subscriber sendNext:[NSArray arrayWithObjects:responseStr, nil]];
                    } else {
                        [subscriber sendError:jsonError];
                    }
                }
                else{
                    id json = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&jsonError];
                    if ( !result || [result statusCode] != 200){
                        NSString *errorMsg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                        [subscriber sendError:[NSError errorWithDomain:errorMsg code:-1 userInfo:nil]];
                    }else if (! jsonError) {
                        NSLog(@"%@", json);
                        
                        if ([json objectForKey:@"error"]) {
                            NSString *errMsg = [json objectForKey:@"error"];
                            [subscriber sendError:[NSError errorWithDomain:errMsg code:-1 userInfo:nil]];
                        }
                        else {
                            [subscriber sendNext:[json objectForKey:@"ret"]];
                        }
                    } else {
                        [subscriber sendError:jsonError];
                    }
                }
            } else {
                [subscriber sendError:error];
            }
            [subscriber sendCompleted];
        }];
        [dataTask resume];
        
        return [RACDisposable disposableWithBlock:^{
            [dataTask cancel];
        }];
        
    }] doError:^(NSError *error) {
        NSLog(@"%@",error);
//        [self showErrorMessage:error.description];
        [self showErrorMessage:@"未能链接服务器!"];
    }];
}

- (RACSignal *) fetchDictionaryFromJSON:(NSString*) method url:(NSString *)url bodyDict:(NSDictionary*)bodyDict rootName:(NSString *)rootName encrypt:(BOOL)encrypt class:(Class) typeClass{
    return [[[TTNetworkHelper sharedSession] fetchJSONFromURL:url method:method body:bodyDict encrypt:encrypt] map:^(NSDictionary *json) {
        NSDictionary *object = rootName == nil ? json : json[rootName];
        return object;
    }];
}

- (RACSignal *) fetchDictionaryFromJSON:(NSDictionary*)bodyDict encrypt:(BOOL)encrypt{
    
//    NSString *url = [NSString stringWithFormat:@"%@", @"http://198.11.174.249/"];
//    NSString *url = [NSString stringWithFormat:@"%@", @"http://103.6.220.151/"];
    GlobalData *gd = [GlobalData sharedData];
    NSString *url = [NSString stringWithFormat:@"http://%@/", [gd connectUrl]];
//    NSString *rootName = @"re";
    
    return [[[TTNetworkHelper sharedSession] fetchJSONFromURL:url method:@"GET" body:bodyDict encrypt:encrypt] map:^(NSArray *json) {
//        NSDictionary *object = rootName == nil ? json : json[rootName];
        return json;
    }];
}

- (void) dismissProgressHUD{
    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD dismiss];
    });
}

- (void) showErrorMessage:(NSString *)errMsg{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        
        NSDictionary *options = @{
                                  kCRToastTextKey : errMsg,
                                  kCRToastTimeIntervalKey : @3,
                                  kCRToastNotificationPresentationTypeKey : @(CRToastPresentationTypeCover),
                                  kCRToastTextAlignmentKey : @(NSTextAlignmentCenter),
                                  kCRToastBackgroundColorKey : [UIColor clearColor],
                                  kCRToastAnimationInTypeKey : @(CRToastAnimationTypeSpring),
                                  kCRToastAnimationOutTypeKey : @(CRToastAnimationTypeSpring),
                                  kCRToastAnimationInDirectionKey : @(CRToastAnimationDirectionTop),
                                  kCRToastAnimationOutDirectionKey : @(CRToastAnimationDirectionTop),
                                  kCRToastNotificationTypeKey : @(CRToastTypeNavigationBar),
                                  };
        
        [CRToastManager showNotificationWithOptions:options completionBlock:nil];
    });
}

- (void) getServerTime:(NSDictionary *)json{
    NSDictionary *retDict = json[@"re"];
    if (retDict == nil || [[retDict class] isSubclassOfClass:[NSNull class]] || retDict.count == 0 ) return;
    NSString *time = retDict[@"now"];
    if (time == nil) return;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss zzz"];
    NSDate *serverTime = [dateFormatter dateFromString:time];
    NSDate *nowDate = [NSDate date];
    NSTimeInterval timedifference = [serverTime timeIntervalSinceDate:nowDate];
    GlobalData *gd = [GlobalData sharedData];
    gd.serverTimeDifference = timedifference;
}

#pragma mark -- NetWork Messages --

- (void) sendRequestByCommand:(NSString*)command paramDict:(NSDictionary *)paramDict sucess:(void (^)(NSArray *result))successBlock error:(void (^)(id x))errorBlock dismissProgressView:(BOOL)dismissProgressView encrypt:(BOOL)encrypt{
    
    @weakify(self);
    self.retryBlock = ^{
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:paramDict];
        GlobalData *gd = [GlobalData sharedData];
        if (gd.sid!=nil&&![gd.sid isEqualToString:@""]) {
            [dict setObject:gd.sid forKey:@"sid"];
        }
        [dict setObject:command forKey:@"cmd"];
        RACSignal *signal = [[TTNetworkHelper sharedSession] fetchDictionaryFromJSON:dict encrypt:encrypt];
        [[signal deliverOn:RACScheduler.mainThreadScheduler]
         subscribeNext:^(NSArray *object){
             @strongify(self);
             self.retryBlock = nil;
             if (successBlock != nil) successBlock(object);
             if (dismissProgressView == YES) [self dismissProgressHUD];
         }
         error:^(NSError *error){
             @strongify(self);
             [self dismissProgressHUD];
//             [[NSNotificationCenter defaultCenter] postNotificationName:@"NETWORK_ERROR" object:nil];
             
//             [[TTToolsHelper shared] showNoticetMessage:@"网络不是很给力哦!" handler:^{
                 
//             }];
/*             TTSimpleDailogView *dialog = [[TTSimpleDailogView alloc] init];
             [[dialog setMessage:@"哎呀呀" message:@"网络不是很给力哦，是否再来一次?" confirmMessage:@"再来一次" cancelMessage:@"算了" confirmBlock:^{
                 @strongify(self);
                 [SVProgressHUD show];
                 self.retryBlock();
             } cancelBlock:^{
                 if (errorBlock != nil) errorBlock(error);
             }] show];*/
         }
         completed:^{
         }];
    };
    
    self.retryBlock();
}

-(NSString *) getUUID{
    NSString *retrieveuuid = [SSKeychain passwordForService:@"com.Mikai.HomeKinsa" account:@"kinsa-uuid"];
    
    if ( retrieveuuid == nil || [retrieveuuid isEqualToString:@""]){
        CFUUIDRef uuid = CFUUIDCreate(NULL);
        assert(uuid != NULL);
        CFStringRef uuidStr = CFUUIDCreateString(NULL, uuid);
        retrieveuuid = [NSString stringWithFormat:@"%@", uuidStr];
        [SSKeychain setPassword:retrieveuuid forService:@"com.Mikai.HomeKinsa" account:@"kinsa-uuid"];
    }
    
    return retrieveuuid;
}

- (void) getAccountCodeByPhoneNumber:(NSString *)phoneNumber dismissProgressView:(BOOL)dismissProgressView{
    [SVProgressHUD show];
    NSDictionary *dict = @{@"phone":phoneNumber};
    [self sendRequestByCommand:@"1" paramDict:dict sucess:^(NSArray* result) {
        NSLog(@"%@",result);
        if([[GlobalData sharedData] handleMsgs:result]){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"GETCODE_SUCCEED" object:nil];
        }
        
    } error:^(id x) {
        
    } dismissProgressView:dismissProgressView encrypt:YES];
}

- (void)accountRegisterByPhoneNumber:(NSString *)phoneNumber Password:(NSString *)pwd Code:(NSString *)code Name:(NSString *)name Sex:(int)sex City:(NSString *)city Birth:(NSString *)birth Addr:(NSString *)addr dismissProgressView:(BOOL)dismissProgressView{
    [SVProgressHUD show];
    NSDictionary *dict = @{@"phone":phoneNumber,
                           @"device":pwd,//[self getUUID],
                           @"code":code,
                           @"name":name,
                           @"sex":[NSNumber numberWithInt:sex],
                           @"city":city,
                           @"birth":birth,
                           @"addr":addr
                           };
    [self sendRequestByCommand:@"2" paramDict:dict sucess:^(NSArray* result) {
        NSString *msg = [NSString stringWithFormat:@"%@",[result[0] objectForKey:@"_msg"]];
        if ([[GlobalData sharedData] handleMsgs:result]) {
            if (![msg isEqualToString:@"-1"]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"REGISTER_SUCCEED" object:nil];
            }
            
        }
    } error:^(id x) {
        
    } dismissProgressView:dismissProgressView encrypt:YES];
}

- (void)accountLoginByPhoneNumber:(NSString *)phoneNumber  Password:(NSString *)pwd Mid:(NSString *)mid dismissProgressView:(BOOL)dismissProgressView{
    [SVProgressHUD show];
    NSDictionary *dict = @{@"phone":phoneNumber,
                           @"device":pwd,//[self getUUID],
                           @"mid":mid
                           };
    [self sendRequestByCommand:@"3" paramDict:dict sucess:^(NSArray* result) {
        if ([[GlobalData sharedData] handleMsgs:result]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"LOGIN_SUCCEED" object:nil];
        }
    } error:^(id x) {
        
    } dismissProgressView:dismissProgressView encrypt:YES];
}

/**
 *  获取验证码
 */
- (void)accountRestPwdSMSByPhoneNumber:(NSString *)PhoneNumber dismissProgressView:(BOOL)dismissProgressView
{
    [SVProgressHUD show];
    NSDictionary *dict = @{@"phone":PhoneNumber};
    [self sendRequestByCommand:@"11" paramDict:dict sucess:^(NSArray* result) {
        if ([[GlobalData sharedData] handleMsgs:result]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"GETCODE_SUCCEED" object:nil];
        }
    } error:^(id x) {
        
    } dismissProgressView:dismissProgressView encrypt:YES];
}

/**
 *  更改密码
 */
- (void)accountRestPwdByPhoneNumber:(NSString *)PhoneNumber newPwd:(NSString *)newPwd code:(NSString *)code dismissProgressView:(BOOL)dismissProgressView
{
    [SVProgressHUD show];
    NSDictionary *dict = @{@"phone":PhoneNumber,
                           @"device":newPwd,
                           @"code":code
                           };
    [self sendRequestByCommand:@"12" paramDict:dict sucess:^(NSArray *result) {
        if ([[GlobalData sharedData] handleMsgs:result]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"UPDATEPWD_SUCCEED" object:nil];
        }

    } error:^(id x) {
        
    } dismissProgressView:dismissProgressView encrypt:YES];
}

/**
 *  第三方登陆
 platformID: 新浪微博--1 QQ--2
 */
- (void)accountRegisterPByOpenId:(NSString *)OpenId token:(NSString *)token platformID:(NSString *)platformID Name:(NSString *)name Sex:(int)sex City:(NSString *)city Birth:(NSString *)birth Addr:(NSString *)addr  dismissProgressView:(BOOL)dismissProgressView
{
    [SVProgressHUD show];
    NSString *versionStr = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    NSDictionary *dict;
    if ([versionStr isEqualToString:@"1.4.5"]) {
        dict = @{@"openID":OpenId,
                 @"token":token,
                 @"platformID":platformID,
                 @"name":name,
                 @"sex":[NSNumber numberWithInt:sex],
                 @"city":city,
                 @"birth":birth,
                 @"addr":addr
                 };
    } else {
        dict = @{@"openID":OpenId,
                 @"token":token,
                 @"platformID":platformID,
                 @"name":name,
                 @"sex":[NSNumber numberWithInt:sex],
                 @"city":city,
                 @"birth":birth,
                 @"addr":addr,
                 @"v":versionStr
                 };
    }
    
    [self sendRequestByCommand:@"18" paramDict:dict sucess:^(NSArray *result) {
        NSDictionary *dict = result[0];
        NSArray *members = dict[@"members"];
        NSLog(@"%@",members);
        NSDictionary *memberDict = members[0];
        if ([[GlobalData sharedData] handleMsgs:result]) {
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"CREATETHIRD_SUCCEED" object:nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"LOGINTHIRD_SUCCEED" object:nil];
//            [[TTNetworkHelper sharedSession] accountLoginPByOpenId:OpenId token:@"1" platformID:platformID mid:memberDict[@"id"] dismissProgressView:YES];
        }
        
    } error:^(id x) {
        
    } dismissProgressView:dismissProgressView encrypt:YES];
    
}

- (void)accountLoginPByOpenId:(NSString *)OpenId token:(NSString *)token platformID:(NSString *)platformID mid:(NSString *)mid dismissProgressView:(BOOL)dismissProgressView
{
    [SVProgressHUD show];
    NSString *versionStr = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    NSDictionary *dict;
    if ([versionStr isEqualToString:@"1.4.5"]) {
        dict = @{@"openID":OpenId,
                               @"token":token,
                               @"platformID":platformID,
                               @"mid":mid
                               };
    } else {
        dict = @{@"openID":OpenId,
                 @"token":token,
                 @"platformID":platformID,
                 @"mid":mid,
                 @"v":versionStr
                 };
    }
    [self sendRequestByCommand:@"19" paramDict:dict sucess:^(NSArray *result) {
        if ([[GlobalData sharedData] handleMsgs:result]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"LOGINTHIRD_SUCCEED" object:nil];
        }
        
    } error:^(id x) {
        
    } dismissProgressView:dismissProgressView encrypt:YES];
}


- (void)createMemberByName:(NSString *)name Sex:(int)sex City:(NSString *)city Birth:(NSString *)birth Addr:(NSString *)addr  dismissProgressView:(BOOL)dismissProgressView{
    [SVProgressHUD show];
    NSDictionary *dict = @{@"name":name,
                           @"sex":[NSNumber numberWithInt:sex],
                           @"city":city,
                           @"birth":birth,
                           @"addr":addr
                           };
    [self sendRequestByCommand:@"4" paramDict:dict sucess:^(NSArray *result) {
        NSDictionary *dict = result[0];
        NSArray *members = dict[@"members"];
        NSDictionary *memberDict = members[0];
        GlobalData *gd = [GlobalData sharedData];
        [gd.members addObject:memberDict];
    } error:^(id x) {
        
    } dismissProgressView:dismissProgressView encrypt:YES];
}

- (void)changeMemberInfo:(NSString *)mId Name:(NSString *)name Sex:(int)sex City:(NSString *)city Birth:(NSString *)birth  dismissProgressView:(BOOL)dismissProgressView{
    [SVProgressHUD show];
    NSDictionary *dict = @{@"name":name,
                           @"sex":[NSNumber numberWithInt:sex],
                           @"city":city,
                           @"birth":birth,
                           @"id":mId,
                           @"addr":@"aa"
                           };
    [self sendRequestByCommand:@"13" paramDict:dict sucess:^(NSArray* result) {
        if ([[GlobalData sharedData] handleMsgs:result]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"CHANGE_USEINFO_SUCCEED" object:nil];
        }
    } error:^(id x) {
        
    } dismissProgressView:dismissProgressView encrypt:YES];
}

- (void)deleteDiary:(NSString *)mid Id:(NSString *)tid dismissProgressView:(BOOL)dismissProgressView{
    [SVProgressHUD show];
    NSDictionary *dict = @{@"mid":mid,
                           @"id":tid
                           };
    [self sendRequestByCommand:@"15" paramDict:dict sucess:^(NSArray* result) {
        if ([[GlobalData sharedData] handleMsgs:result]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"DELETE_DIARY_SUCCEED" object:nil];
        }
    } error:^(id x) {
        
    } dismissProgressView:dismissProgressView encrypt:YES];
}

- (void)createDiaryByMid:(NSString *)mid Date:(NSNumber *)date Temperature:(NSNumber *)tvalue Symptoms:(NSNumber *)svalue Photo:(int)pvalue Desc:(NSString *)desc Longitude:(NSString *)longitude Latitude:(NSString *)latitude dismissProgressView:(BOOL)dismissProgressView{
    [SVProgressHUD show];
    NSDictionary *dict = @{@"mid":mid,
                           @"date":date,
                           @"temperature":[NSString stringWithFormat:@"%.1f",[tvalue floatValue]],
                           @"symptoms":svalue,
                           @"photo":[NSNumber numberWithInt:pvalue],
                           @"desc":[desc isEqualToString:@""]?@"未描述":desc,
                           @"longitude":longitude,
                           @"latitude":latitude
                           };
    [self sendRequestByCommand:@"5" paramDict:dict sucess:^(NSArray* result) {
        NSLog(@"%@",result);
        if ([[GlobalData sharedData] handleMsgs:result]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"CREATE_DIARY_SUCCEED" object:nil];
        }
    } error:^(id x) {
        
    } dismissProgressView:dismissProgressView encrypt:YES];
}

- (void)getDiaryByMid:(NSString *)mid Ids:(NSString *)did Count:(int)value dismissProgressView:(BOOL)dismissProgressView{
    [SVProgressHUD show];
    NSDictionary *dict = @{@"mid":mid,
                           @"Ids":did,
                           @"count":[NSNumber numberWithInt:value]
                           };
    [self sendRequestByCommand:@"6" paramDict:dict sucess:^(NSArray* result) {
        if ([[GlobalData sharedData] handleMsgs:result]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"GET_DIARY_SUCCEED" object:nil];
        }
    } error:^(id x) {
        
    } dismissProgressView:dismissProgressView encrypt:YES];
}

- (void)getDiaryLastRecords:(NSNumber *)pos Range:(NSNumber *)range MId:(NSString *)mid dismissProgressView:(BOOL)dismissProgressView{
    [SVProgressHUD show];
    
    NSDictionary *dict = @{@"pos":pos,@"range":range,@"mid":mid};
    [self sendRequestByCommand:@"14" paramDict:dict sucess:^(NSArray* result) {
        if ([[GlobalData sharedData] handleMsgs:result]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"GET_DIARY_LAST_SUCCEED" object:nil];
        }
    } error:^(id x) {
    } dismissProgressView:dismissProgressView encrypt:YES];
}

- (void)createGroup:(NSString *)groupName dismissProgressView:(BOOL)dismissProgressView{
    [SVProgressHUD show];
    NSDictionary *dict = @{@"name":groupName
                           };
    [self sendRequestByCommand:@"7" paramDict:dict sucess:^(NSArray* result) {
        NSLog(@"%@", result);
    } error:^(id x) {
        
    } dismissProgressView:dismissProgressView encrypt:YES];
}

- (void)enterGroup:(int)gid dismissProgressView:(BOOL)dismissProgressView{
    [SVProgressHUD show];
    NSDictionary *dict = @{@"gid":[NSNumber numberWithInt:gid]
                           };
    [self sendRequestByCommand:@"8" paramDict:dict sucess:^(NSArray* result) {
        NSLog(@"%@", result);
    } error:^(id x) {
        
    } dismissProgressView:dismissProgressView encrypt:YES];
}

- (void)addGroup:(int)gid dismissProgressView:(BOOL)dismissProgressView{
    [SVProgressHUD show];
    NSDictionary *dict = @{@"gid":[NSNumber numberWithInt:gid]
                           };
    [self sendRequestByCommand:@"9" paramDict:dict sucess:^(NSArray* result) {
        NSLog(@"%@", result);
    } error:^(id x) {
        
    } dismissProgressView:dismissProgressView encrypt:YES];
}

- (void)chatGroup:(int)gid Msg:(NSString *)content dismissProgressView:(BOOL)dismissProgressView{
    [SVProgressHUD show];
    NSDictionary *dict = @{@"gid":[NSNumber numberWithInt:gid],
                           @"msg":content
                           };
    [self sendRequestByCommand:@"10" paramDict:dict sucess:^(NSArray* result) {
        NSLog(@"%@", result);
    } error:^(id x) {
        
    } dismissProgressView:dismissProgressView encrypt:YES];
}

- (void)accountSetIcon:(int)iconId image:(UIImage *)image dismissProgressView:(BOOL)dismissProgressView{
    [SVProgressHUD show];
    
    GlobalData *gd = [GlobalData sharedData];
    NSString *url = [NSString stringWithFormat:@"http://%@/",[gd connectUrl]];
    RACSignal *signal = [[TTNetworkHelper sharedSession] updateImageFromURL:url method:@"POST" body:@{@"id":[NSNumber numberWithInt:iconId],@"cmd":@16,@"sid":gd.sid} image:image];
    [[signal deliverOn:RACScheduler.mainThreadScheduler]
     subscribeNext:^(NSArray *result){
         NSLog(@"result:%@", result);
         if ([[GlobalData sharedData] handleMsgs:result]) {
//             [[NSNotificationCenter defaultCenter] postNotificationName:@"GET_DIARY_SUCCEED" object:nil];
         }
     }
     error:^(NSError *error){
     }
     completed:^{
     }];
}

- (void)checkVer:(NSString *)ver dismissProgressView:(BOOL)dismissProgressView{
    [SVProgressHUD show];
    NSDictionary *dict = @{@"ver":ver};
    [self sendRequestByCommand:@"-1" paramDict:dict sucess:^(NSArray* result) {
        NSLog(@"%@", result);
        NSNumber *value = [result objectAtIndex:0];
        if ([value intValue]==0) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"CHECK_VER" object:nil];
        }
        else{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"REALLY_VER" object:nil];
        }
    } error:^(id x) {
        
    } dismissProgressView:dismissProgressView encrypt:YES];
}
@end
