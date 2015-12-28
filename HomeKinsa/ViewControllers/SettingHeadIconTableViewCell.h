//
//  SettingHeadIconTableViewCell.h
//  HomeKinsa
//
//  Created by Zhang guangchun on 15/5/15.
//  Copyright (c) 2015年 Mikai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UserSettingUIViewController.h"
#import "DBCameraViewController.h"
#import "DBCameraContainerViewController.h"

@interface SettingHeadIconTableViewCell : UITableViewCell<DBCameraViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *profileImage;
@property (nonatomic, weak) UserSettingUIViewController *previousController;
@end
