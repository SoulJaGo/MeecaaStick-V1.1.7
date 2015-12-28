//
//  TTDeepCopy.m
//  wkw
//
//  Created by Zhang guangchun on 15/2/6.
//  Copyright (c) 2015年 Tice Tang. All rights reserved.
//

#import "TTDeepCopy.h"

@implementation NSArray (TTDeepCopy)

- (NSArray*)deepCopy {
    NSUInteger count = [self count];
    id cArray[count];
    
    for (NSUInteger i = 0; i < count; ++i) {
        id obj = [self objectAtIndex:i];
        if ([obj respondsToSelector:@selector(deepCopy)]) {
            cArray[i] = [obj deepCopy];
        }
        else if ([obj respondsToSelector:@selector(copyWithZone:)]) {
            cArray[i] = [obj copy];
        }
        else {
//            DLog(@"********Error:NSArray DeepCopy Failed!!! ********");
            return nil;
        }
    }
    
    NSArray *ret = [NSArray arrayWithObjects:cArray count:count];
    
    return ret;
}

- (NSMutableArray*)mutableDeepCopy {
    NSUInteger count = [self count];
    id cArray[count];
    
    for (NSUInteger i = 0; i < count; ++i) {
        id obj = [self objectAtIndex:i];
        
        // Try to do a deep mutable copy, if this object supports it
        if ([obj respondsToSelector:@selector(mutableDeepCopy)]) {
            cArray[i] = [obj mutableDeepCopy];
        }
        // Then try a shallow mutable copy, if the object supports that
        else if ([obj respondsToSelector:@selector(mutableCopyWithZone:)]) {
            cArray[i] = [obj mutableCopy];
        }
        else if ([obj respondsToSelector:@selector(copyWithZone:)]) {
            cArray[i] = [obj copy];
        }
        else {
//            DLog(@"********Error:NSArray MutableDeepCopy Failed!!! ********");
            return nil;
        }
    }
    
    NSMutableArray *ret = [NSMutableArray arrayWithObjects:cArray count:count];
    
    return ret;
}


@end


@implementation NSDictionary (TTDeepCopy)

- (NSDictionary*)deepCopy {
    NSUInteger count = [self count];
    id cObjects[count];
    id cKeys[count];
    
    NSEnumerator *e = [self keyEnumerator];
    NSUInteger i = 0;
    id thisKey;
    while ((thisKey = [e nextObject]) != nil) {
        id obj = [self objectForKey:thisKey];
        
        if ([obj respondsToSelector:@selector(deepCopy)]) {
            cObjects[i] = [obj deepCopy];
        }
        else if([obj respondsToSelector:@selector(copyWithZone:)]) {
            cObjects[i] = [obj copy];
        }
        else {
//            DLog(@"********Error:NSDictionary DeepCopy Failed!!! ********")
            return nil;
        }
        
        if ([thisKey respondsToSelector:@selector(deepCopy)]) {
            cKeys[i] = [thisKey deepCopy];
        }
        else if ([thisKey respondsToSelector:@selector(copyWithZone:)]) {
            cKeys[i] = [thisKey copy];
        }
        else {
//            DLog(@"********Error:NSDictionary Key DeepCopy Failed!!! ********")
            return nil;
        }
        
        ++i;
    }
    
    NSDictionary *ret = [NSDictionary dictionaryWithObjects:cObjects forKeys:cKeys count:count];
    
    return ret;
}

- (NSMutableDictionary*)mutableDeepCopy {
    NSUInteger count = [self count];
    id cObjects[count];
    id cKeys[count];
    
    NSEnumerator *e = [self keyEnumerator];
    unsigned int i = 0;
    id thisKey;
    while ((thisKey = [e nextObject]) != nil) {
        id obj = [self objectForKey:thisKey];
        
        // Try to do a deep mutable copy, if this object supports it
        if ([obj respondsToSelector:@selector(mutableDeepCopy)]) {
            cObjects[i] = [obj mutableDeepCopy];
        }
        // Then try a shallow mutable copy, if the object supports that
        else if ([obj respondsToSelector:@selector(mutableCopyWithZone:)]) {
            cObjects[i] = [obj mutableCopy];
        }
        else if ([obj respondsToSelector:@selector(copyWithZone:)]) {
            cObjects[i] = [obj copy];
        }
        else {
//            DLog(@"********Error:NSDictionary MutableDeepCopy Failed!!! ********")
            return nil;
        }
        
        // I don't think mutable keys make much sense, so just do an ordinary copy
        if ([thisKey respondsToSelector:@selector(deepCopy)]) {
            cKeys[i] = [thisKey deepCopy];
        }
        else if([thisKey respondsToSelector:@selector(copyWithZone:)]) {
            cKeys[i] = [thisKey copy];
        }
        else {
            return nil;
        }
        
        ++i;
    }
    
    NSMutableDictionary *ret = [NSMutableDictionary dictionaryWithObjects:cObjects forKeys:cKeys count:count];
    
    return ret;
}



@end
