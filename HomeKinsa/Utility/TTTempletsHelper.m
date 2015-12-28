//
//  TTTempletsHelper.m
//  wkw
//
//  Created by Tice Tang on 15/12/14.
//  Copyright (c) 2014 Tice Tang. All rights reserved.
//

#import "TTTempletsHelper.h"
#import "TTNetworkHelper.h"
#import "NSString+MyCategory.h"
//#import "NSData+MyCategory.h"
#import "GlobalData.h"

@implementation TTTempletsHelper

+ (id)shared {
    static TTTempletsHelper *shared = nil;
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

- (NSString *) getTemplateFileName{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
    NSString *path = [paths objectAtIndex:0];
    return [path stringByAppendingPathComponent:@"templates.plist"];
}

- (NSDictionary *) getTemplateFileContent{
    
    NSString *filename = [self getTemplateFileName];
    NSFileManager* fm = [NSFileManager defaultManager];
    if ([fm isReadableFileAtPath:filename] == false){
        filename = [[NSBundle mainBundle] pathForResource:@"templates" ofType:@"plist"];
    }
    
    return [NSDictionary dictionaryWithContentsOfFile:filename];
}

- (void) saveTemplate:(NSString *)name object:(NSDictionary *) saveObject{
    
    //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSString *filename = [self getTemplateFileName];
        NSMutableDictionary *data;
        NSFileManager* fm = [NSFileManager defaultManager];
        if ([fm isReadableFileAtPath:filename] == false){
            data = [NSMutableDictionary dictionaryWithCapacity:1];
        }else{
            data = [NSMutableDictionary dictionaryWithContentsOfFile:filename];
        }
        
        [data setValue:saveObject forKey:name];
        [data writeToFile:filename atomically:YES];
        
        dispatch_async(dispatch_get_main_queue(), ^{

        });
    //});
}

@end
