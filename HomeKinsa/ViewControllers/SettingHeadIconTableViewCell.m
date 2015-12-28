//
//  SettingHeadIconTableViewCell.m
//  HomeKinsa
//
//  Created by Zhang guangchun on 15/5/15.
//  Copyright (c) 2015年 Mikai. All rights reserved.
//

#import "SettingHeadIconTableViewCell.h"
#import "GlobalData.h"
#import "TTToolsHelper.h"

@implementation SettingHeadIconTableViewCell

- (void)awakeFromNib {
    // Initialization code
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(profileImageOnClick:)];
    [self.profileImage addGestureRecognizer:tap];
    self.profileImage.layer.backgroundColor = COLOR_VIEW_BACKGROUND.CGColor;
    self.profileImage.layer.cornerRadius = self.profileImage.frame.size.width / 2;
    self.profileImage.clipsToBounds = YES;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) setPreviousController:(UserSettingUIViewController *)previousController{
    _previousController = previousController;
}

- (void)profileImageOnClick:(id)sender {
    DBCameraContainerViewController *container = [[DBCameraContainerViewController alloc] initWithDelegate:self];
    DBCameraViewController *cameraController = [DBCameraViewController initWithDelegate:self];
    [cameraController setUseCameraSegue:NO];
    [cameraController setForceQuadCrop:YES];
    [container setCameraViewController:cameraController];
//    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:container];
//    [nav setNavigationBarHidden:YES];
    [container setFullScreenMode];
    
    [self.previousController presentViewController:container animated:YES completion:nil];
//    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
}

- (void) camera:(id)cameraViewController didFinishWithImage:(UIImage *)image withMetadata:(NSDictionary *)metadata
{
    self.profileImage.image = [[TTToolsHelper shared] thumbnailWithImageWithoutScale:image size:CGSizeMake(43, 43)];
    [cameraViewController restoreFullScreenMode];
    [self.previousController dismissViewControllerAnimated:YES completion:nil];
//    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
    
    UserSettingUIViewController *vc = (UserSettingUIViewController*)self.previousController;
    vc.profileImage = self.profileImage.image;
}

- (void) dismissCamera:(id)cameraViewController{
    [self.previousController dismissViewControllerAnimated:YES completion:nil];
    [cameraViewController restoreFullScreenMode];
//    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
}
@end
