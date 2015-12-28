//
//  DetailRecordPhotosTableViewCell.m
//  HomeKinsa
//
//  Created by Zhang guangchun on 15/5/15.
//  Copyright (c) 2015年 Mikai. All rights reserved.
//

#import "DetailRecordPhotosTableViewCell.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "GlobalData.h"
#import <UIImageView+WebCache.h>
@interface DetailRecordPhotosTableViewCell()<UIImagePickerControllerDelegate,UITextViewDelegate>
@property (nonatomic,strong) NSMutableArray *imageViewList;
@end
@implementation DetailRecordPhotosTableViewCell

- (void)awakeFromNib {
    // Initialization code
    self.descLabel.delegate = self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.descLabel.delegate = self;
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setImageList:(NSString *)mId WithTime:(NSNumber *)time WithCount:(int)count{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    [formatter setDateFormat:@"YYYY-MM-dd"];
    
    NSString *dayStr = [formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:[time doubleValue]]];
    NSDate *date = [formatter dateFromString:dayStr];
    
    if (self.imageList!=nil&&self.imageList.count>0) {
        for (int i=0; i<self.imageList.count; i++) {
            UIImageView *imageView = [self.imageList objectAtIndex:i];
            [imageView removeFromSuperview];
        }
        [self.imageList removeAllObjects];
        self.imageList = nil;
    }
    
    self.imageList = [NSMutableArray array];
    
    GlobalData *gd = [GlobalData sharedData];
    
    for (int i=0; i<count; i++) {
        NSString *jpgName = [NSString stringWithFormat:@"%@_%@_%i.jpg",mId,time,i];
        NSString *url = [NSString stringWithFormat:@"http://%@/upload/%i/%@",[gd connectUrl], (int)[date timeIntervalSince1970],jpgName];
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.descLabel.frame.origin.x+i*35, self.descLabel.frame.origin.y + self.descLabel.frame.size.height , 30, 30)];
        imageView.contentMode = UIViewContentModeScaleToFill;
        [self addSubview:imageView];
        [imageView sd_setImageWithURL:[NSURL URLWithString:url] placeholderImage:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        }];
        imageView.userInteractionEnabled = true;
        [self.imageList addObject:imageView];
    }
}


- (void)handleTap:(id)sender{
    if (self.parentView) {
        UITapGestureRecognizer *tap = (UITapGestureRecognizer *)sender;
        UIView *maskView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.parentView.bounds.size.width, self.parentView.bounds.size.height)];
        maskView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.6];
        
        UIImageView *imageView = (UIImageView *)(tap.view);
        float height = self.parentView.bounds.size.width*imageView.frame.size.height/imageView.frame.size.width;
        
        UIImageView *bigImageView = [[UIImageView alloc] initWithImage:imageView.image];
        [bigImageView setFrame:CGRectMake(0, (self.parentView.bounds.size.height - height)/2, self.parentView.bounds.size.width, height)];
        [maskView addSubview:bigImageView];
        [self.parentView addSubview:maskView];
        
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleMaskTap:)];
        maskView.userInteractionEnabled = true;
        [maskView addGestureRecognizer:tapRecognizer];
    }
}

- (void)handleMaskTap:(id)sender{
    UITapGestureRecognizer *tap = (UITapGestureRecognizer *)sender;
    UIView *tapView = tap.view;
    [tapView removeFromSuperview];
    [tapView removeGestureRecognizer:tap];
}


/**
 *  2015-10-19 SoulJa
 *  修改图片
 */
- (void)setImageListWithArray:(NSMutableArray *)imageList
{
    int count = (int)imageList.count;
    for (int i=0; i<count; i++) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.descLabel.frame.origin.x+i*55, self.descLabel.frame.origin.y + self.descLabel.frame.size.height , 50, 50)];
        imageView.contentMode = UIViewContentModeScaleToFill;
        [self addSubview:imageView];
        NSString *urlStr = imageList[i];
        [imageView sd_setImageWithURL:[NSURL URLWithString:urlStr] placeholderImage:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        }];
        /*
        UIButton *delBtn = [UIButton buttonWithType:UIButtonTypeContactAdd];
        delBtn.tag = i;
        [delBtn addTarget:self action:@selector(onClickDelImageViewBtn:) forControlEvents:UIControlEventTouchUpInside];
        [imageView addSubview:delBtn];
        imageView.tag = i;
        imageView.userInteractionEnabled = true;
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapImageView:)];
        [imageView addGestureRecognizer:tapGestureRecognizer];
        [self.imageViewList addObject:imageView.image];
        NSLog(@"%@",self.imageViewList);
         */
    }
}

- (void)onClickDelImageViewBtn:(UIButton *)btn
{
    [btn.superview removeFromSuperview];
}

- (void)tapImageView:(UITapGestureRecognizer *)recognizer
{
    if ([self.delegate respondsToSelector:@selector(DetailRecordPhotosTableViewCellWithImageList:TapImageView:)]) {
        [self.delegate DetailRecordPhotosTableViewCellWithImageList:self.imageList TapImageView:(UIImageView *)recognizer.view];
    }
}

#pragma mark - UITextViewDelegate
- (void)textViewDidEndEditing:(UITextView *)textView
{
    if ([self.delegate respondsToSelector:@selector(DetailRecordPhotosTableViewCellDidEndEditingTextView:)]) {
        [self.delegate DetailRecordPhotosTableViewCellDidEndEditingTextView:textView.text];
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    return YES;
}
@end
