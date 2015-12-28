//
//  UseHardwareCheckViewController.h
//  HomeKinsa
//
//  Created by Zhang guangchun on 15/5/4.
//  Copyright (c) 2015年 Mikai. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UseHardwareCheckViewController : UIViewController
/**
 *  测温类型
 *  checkType == 1 : 快速测温
 *  checkType == 2 : 常规测温
 */
- (void)setCheckType:(int)_type;
@end
