//
//  CheckDayDetailTableViewCell.h
//  HomeKinsa
//
//  Created by Zhang guangchun on 15/5/2.
//  Copyright (c) 2015年 Mikai. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CheckDayDetailTableViewCell : UITableViewCell

@property (retain, nonatomic) NSMutableArray *imageList;

@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *symptomLabel;
@property (weak, nonatomic) IBOutlet UILabel *temperatureLabel;
@property (weak, nonatomic) IBOutlet UILabel *nickNameLabel;

- (void)setImageList:(NSString *)mId WithTime:(NSNumber *)time WithCount:(int)count;
- (void)setImageListWithPics:(NSArray *)pics;
- (void)clearImageList;
@end
