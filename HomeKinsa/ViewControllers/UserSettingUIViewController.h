//
//  UserSettingUIViewController.h
//  HomeKinsa
//
//  Created by Zhang guangchun on 15/5/8.
//  Copyright (c) 2015年 Mikai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <HSDatePickerViewController/HSDatePickerViewController.h>

#define COLOR_NAV_BACKGROUND [UIColor colorWithRed:80/255.0 green:205/255.0 blue:216/255.0 alpha:1.0]
#define COLOR_VIEW_BACKGROUND [UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1.0]
@interface UserSettingUIViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UITextViewDelegate, HSDatePickerViewControllerDelegate>

@property (nonatomic, retain) UIImage *profileImage;
@property (retain, nonatomic) UITextField *setLocation;
@property (retain, nonatomic) UILabel *birth;
@property (retain, nonatomic) UIImageView *chooseManIcon;
@property (retain, nonatomic) UIImageView *chooseWoManIcon;
@property (nonatomic, assign) NSInteger keyboardHeight;
@property (nonatomic, assign) BOOL keyboardIsShowing;
@property (nonatomic, assign) CGFloat orgViewY;
@property (retain, nonatomic) NSDictionary *memberObj;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@end
