//
//  DetailRecordTimeTableViewCell.m
//  HomeKinsa
//
//  Created by Zhang guangchun on 15/5/15.
//  Copyright (c) 2015年 Mikai. All rights reserved.
//

#import "DetailRecordTimeTableViewCell.h"

@implementation DetailRecordTimeTableViewCell

- (void)awakeFromNib {
    // Initialization code
    self.timeLabel.userInteractionEnabled = YES;
    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapTimeLabel)];
    [self.timeLabel addGestureRecognizer:recognizer];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

/**
 *  点击时间Label的方法
 */
- (void)tapTimeLabel {
    if ([self.delegate respondsToSelector:@selector(DetailRecordTimeTableViewCellDidTapTimeLabel:)]) {
        [self.delegate DetailRecordTimeTableViewCellDidTapTimeLabel:self.timeLabel];
    }
}

@end
