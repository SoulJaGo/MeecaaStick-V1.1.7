//
//  CheckDayDetailTableViewCell.m
//  HomeKinsa
//
//  Created by Zhang guangchun on 15/5/2.
//  Copyright (c) 2015年 Mikai. All rights reserved.
//

#import "CheckDayDetailTableViewCell.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "GlobalData.h"
#import "DataBaseTool.h"

@implementation CheckDayDetailTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)clearImageList{
    if (self.imageList!=nil&&self.imageList.count>0) {
        for (int i=0; i<self.imageList.count; i++) {
            UIImageView *imageView = [self.imageList objectAtIndex:i];
            [imageView removeFromSuperview];
        }
        [self.imageList removeAllObjects];
        self.imageList = nil;
    }
}

- (void)setImageList:(NSString *)mId WithTime:(NSNumber *)time WithCount:(int)count{
    mId = [NSString stringWithFormat:@"%@", [[DataBaseTool getDefaultMember] objectForKey:@"id"]];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    [formatter setDateFormat:@"YYYY-MM-dd"];
    
    NSString *dayStr = [formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:[time doubleValue]]];
    NSDate *date = [formatter dateFromString:dayStr];
    
    [self clearImageList];
    
    self.imageList = [NSMutableArray array];
    
    GlobalData *gd = [GlobalData sharedData];
    
    for (int i=0; i<count; i++) {
        NSString *jpgName = [NSString stringWithFormat:@"%@_%@_%i.jpg",mId,time,i];
        NSString *url = [NSString stringWithFormat:@"http://%@/upload/%i/%@",[gd connectUrl], (int)[date timeIntervalSince1970],jpgName];
        NSLog(@"url:%@",url);
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.symptomLabel.frame.origin.x+i*35, self.symptomLabel.frame.origin.y + self.symptomLabel.frame.size.height + 5, 30, 30)];
        imageView.contentMode = UIViewContentModeScaleToFill;
        [self addSubview:imageView];
        [imageView sd_setImageWithURL:[NSURL URLWithString:url] placeholderImage:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        }];
        
        [self.imageList addObject:imageView];
    }
}

- (void)setImageListWithPics:(NSArray *)pics
{
    [self clearImageList];
    self.imageList = [NSMutableArray array];
    for (int i=0; i<pics.count; i++) {
        NSString *url = pics[i];
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.symptomLabel.frame.origin.x+i*35, self.symptomLabel.frame.origin.y + self.symptomLabel.frame.size.height + 5, 30, 30)];
        imageView.contentMode = UIViewContentModeScaleToFill;
        [self addSubview:imageView];
        [imageView sd_setImageWithURL:[NSURL URLWithString:url] placeholderImage:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        }];
        
        [self.imageList addObject:imageView];
    }

}
@end
