//
//  UITableView+SafeReloadData.m
//  wkw
//
//  Created by Tice Tang on 6/2/15.
//  Copyright (c) 2015 Tice Tang. All rights reserved.
//

#import "UITableView+SafeReloadData.h"

@implementation UITableView (UITableView_SafeReloadData)

- (void) safeReloadData{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self reloadData];
    });
}

@end