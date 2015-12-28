//
//  DetailRecordTemperatureTableViewCell.h
//  HomeKinsa
//
//  Created by Zhang guangchun on 15/5/15.
//  Copyright (c) 2015年 Mikai. All rights reserved.
//

#import <UIKit/UIKit.h>
@class DetailRecordTemperatureTableViewCell;
@protocol DetailRecordTemperatureTableViewCellDelegte <NSObject>

@optional
- (void)DetailRecordTemperatureTableViewCellDidEndEditTextField:(double)temperature;

@end
@interface DetailRecordTemperatureTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UITextField *TemperatureTextField;
@property (weak, nonatomic) IBOutlet UILabel *TemperatureTypeLable;
@property (nonatomic,weak) id<DetailRecordTemperatureTableViewCellDelegte> delegate;
@end
