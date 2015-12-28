//
//  AddSymptonViewController.m
//  HomeKinsa
//
//  Created by Zhang guangchun on 15/5/2.
//  Copyright (c) 2015年 Mikai. All rights reserved.
//

#import "AddSymptonViewController.h"
#import "GlobalData.h"

@interface AddSymptonViewController ()

@property (retain, nonatomic)NSMutableArray *symptonViews;
@end

@implementation AddSymptonViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    GlobalData *gd = [GlobalData sharedData];
    NSArray *infoList = gd.symptonTemplateList;
    
    self.symptonViews = [NSMutableArray array];
    for (int i=0; i<infoList.count; i++) {
        int dx = i%4;
        int dy = i/4;
        
        int dh = 60;
        NSDictionary *info = [infoList objectAtIndex:i];
        float cx = (self.view.bounds.size.width/4-70)/2;
        CGPoint pos = CGPointMake(dx*self.view.bounds.size.width/4+cx, dy*dh+50);
        [self.symptonViews addObject:[self addSymptonBtn:[info objectForKey:@"name"] withTag:[[info objectForKey:@"tag"] intValue] withColor:[UIColor grayColor] onPos:pos]];
    }
}

- (UIView *)addSymptonBtn:(NSString *)title withTag:(int)tag withColor:(UIColor *)color onPos:(CGPoint)pos {
    UIView *symptonView = [[UIView alloc] initWithFrame:CGRectMake(pos.x, pos.y, 70, 40)];
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btn.backgroundColor = [UIColor clearColor];
    btn.layer.cornerRadius = 15.0f;
    btn.layer.borderColor = color.CGColor;
    btn.layer.borderWidth = 1.0f;
    btn.frame = CGRectMake(0, 0, 70, 40);
    btn.titleLabel.textColor = [UIColor blackColor];
    btn.tintColor = [UIColor blackColor];
    btn.tag = tag;
    [btn addTarget:self action:@selector(onAddClick:) forControlEvents: UIControlEventTouchUpInside];
    [btn setTitle:title forState:UIControlStateNormal];
    [symptonView addSubview:btn];
    
    UIImage *chooseImg = [UIImage imageNamed:@"check_choose_icon"];
    UIImageView *chooseImgView = [[UIImageView alloc] initWithImage:chooseImg];
    chooseImgView.tag = 111;
    chooseImgView.hidden = ![self isHaveChoose:tag];
    [chooseImgView setFrame:CGRectMake(symptonView.frame.size.width-chooseImg.size.width, symptonView.frame.size.height - chooseImg.size.height, chooseImg.size.width, chooseImg.size.height)];
    [symptonView addSubview:chooseImgView];
    
    [self.view addSubview:symptonView];
    return symptonView;
}

- (BOOL)isHaveChoose:(int)tag{
    if (self.beforeSymptons) {
        for (int i=0; i<self.beforeSymptons.count; i++) {
            if (tag==[[self.beforeSymptons objectAtIndex:i] intValue]) {
                return true;
            }
        }
    }
    return false;
}

- (void) onAddClick: (UIButton *) button {
    UIView *symptonView = button.superview;
    for (UIView *subview in symptonView.subviews){
        if ([subview isKindOfClass:[UIImageView class]]) {
            subview.hidden = !subview.hidden;
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onClickBack:(id)sender {
    NSMutableArray *symptons = [NSMutableArray array];
    for (int i = 0; i<self.symptonViews.count; i++) {
        UIView *symptonView = [self.symptonViews objectAtIndex:i];
        NSArray *subViews = [symptonView subviews];
        UIButton *btn = [subViews objectAtIndex:0];
        UIImageView *chooseImg = [subViews objectAtIndex:1];
        if (!chooseImg.hidden) {
            [symptons addObject:[NSNumber numberWithInteger:btn.tag]];
        }
    }
    if (self.delegate) {
        [self.delegate getChooseSymptons:symptons];
    }
    [self.navigationController popViewControllerAnimated:YES];
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
