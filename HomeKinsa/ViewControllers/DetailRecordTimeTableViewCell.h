//
//  DetailRecordTimeTableViewCell.h
//  HomeKinsa
//
//  Created by Zhang guangchun on 15/5/15.
//  Copyright (c) 2015年 Mikai. All rights reserved.
//

#import <UIKit/UIKit.h>
@class DetailRecordTimeTableViewCell;
@protocol DetailRecordTimeTableViewCellDelegate <NSObject>

@optional
- (void)DetailRecordTimeTableViewCellDidTapTimeLabel:(UILabel *)label;

@end
@interface DetailRecordTimeTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (nonatomic,weak) id<DetailRecordTimeTableViewCellDelegate> delegate;
@end
