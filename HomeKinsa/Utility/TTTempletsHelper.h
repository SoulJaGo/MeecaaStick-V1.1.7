//
//  TTTempletsHelper.h
//  wkw
//
//  Created by Tice Tang on 15/12/14.
//  Copyright (c) 2014 Tice Tang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TTTempletsHelper : NSObject

+ (id)shared;
- (void) getTemplets:(void (^)(id x))nextBlock error:(void (^)(id x))errorBlock completed:(void (^)(void))completedBlock;
@end
