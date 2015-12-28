//
//  AddSymptonViewController.h
//  HomeKinsa
//
//  Created by Zhang guangchun on 15/5/2.
//  Copyright (c) 2015年 Mikai. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol AddSymptonViewControllerDelegate <NSObject>
- (void)getChooseSymptons:(NSArray *)symptons;
@optional

@end

@interface AddSymptonViewController : UIViewController

@property (nonatomic, weak) id<AddSymptonViewControllerDelegate> delegate;
@property (nonatomic, retain) NSArray *beforeSymptons;
@end
