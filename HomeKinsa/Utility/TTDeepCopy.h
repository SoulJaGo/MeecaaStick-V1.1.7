//
//  TTDeepCopy.h
//  wkw
//
//  Created by Zhang guangchun on 15/2/6.
//  Copyright (c) 2015年 Tice Tang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (TTDeepCopy)

- (NSArray*)deepCopy;
- (NSMutableArray*) mutableDeepCopy;

@end


@interface NSDictionary (TTDeepCopy)

- (NSDictionary*)deepCopy;
- (NSMutableDictionary*)mutableDeepCopy;

@end
