//
//  AddPhotoViewController.h
//  HomeKinsa
//
//  Created by Zhang guangchun on 15/5/2.
//  Copyright (c) 2015年 Mikai. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol AddPhotoViewControllerDelegate <NSObject>
- (void)getChoosePhotos:(NSArray *)photos AndDesc:(NSString *)desc;
@optional
@end

@interface AddPhotoViewController : UIViewController

@property (nonatomic, weak) id<AddPhotoViewControllerDelegate> addDelegate;
@property (nonatomic, retain) NSArray *beforeImageList;
@property (nonatomic, retain) NSString *desc;
@end
