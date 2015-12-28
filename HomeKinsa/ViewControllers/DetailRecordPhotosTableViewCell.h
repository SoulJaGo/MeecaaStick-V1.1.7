//
//  DetailRecordPhotosTableViewCell.h
//  HomeKinsa
//
//  Created by Zhang guangchun on 15/5/15.
//  Copyright (c) 2015年 Mikai. All rights reserved.
//

#import <UIKit/UIKit.h>
@class DetailRecordPhotosTableViewCell;
@protocol DetailRecordPhotosTableViewCellDelegate <NSObject>
@optional
- (void)DetailRecordPhotosTableViewCellWithImageList:(NSMutableArray *)imageList TapImageView:(UIImageView *)imageView;
- (void)DetailRecordPhotosTableViewCellDidEndEditingTextView:(NSString *)text;
@end
@interface DetailRecordPhotosTableViewCell : UITableViewCell <UITextViewDelegate>

@property (retain, nonatomic) NSMutableArray *imageList;
@property (weak, nonatomic) IBOutlet UITextView *descLabel;
@property (retain, nonatomic) UIView *parentView;

- (void)setImageList:(NSString *)mId WithTime:(NSNumber *)time WithCount:(int)count;
@property (nonatomic,weak) id<DetailRecordPhotosTableViewCellDelegate> delegate;
/**
 *  2015-10-19 SoulJa
 *  修改图片
 */
- (void)setImageListWithArray:(NSMutableArray *)imageList;
@end
