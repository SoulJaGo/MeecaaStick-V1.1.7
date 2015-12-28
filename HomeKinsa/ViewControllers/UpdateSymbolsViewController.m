//
//  UpdateSymbolsViewController.m
//  HomeKinsa
//
//  Created by SoulJa on 15/10/19.
//  Copyright © 2015年 Mikai. All rights reserved.
//

#import "UpdateSymbolsViewController.h"
#import "GlobalData.h"
#import "HealthDetailViewController.h"

@interface UpdateSymbolsViewController ()
@property (retain, nonatomic)NSMutableArray *symptonViews;
@property (nonatomic,strong) NSMutableArray *symbolsArray;
@end

@implementation UpdateSymbolsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    /**
     *  SoulJa 2015-10-19
     *  设置Nav
     */
    [self setupNav];
    
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    GlobalData *gd = [GlobalData sharedData];
    NSArray *infoList = gd.symptonTemplateList;
    
    NSString *symbolsStr = [self.detailRecordInfo objectForKey:@"symbton"];
    NSArray *symbolsArray = [symbolsStr componentsSeparatedByString:@" "];
    self.symbolsArray = [NSMutableArray arrayWithArray:symbolsArray];
    
    /**
     *  SoulJa 2015-10-19
     *  设置选择按钮
     */
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

/**
 *  设置Nav
 */
- (void)setupNav
{
    self.navigationItem.title = @"添加记录";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"login_back_icon"] style:UIBarButtonItemStylePlain target:self action:@selector(goBack)];
    
}

- (void)goBack
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    HealthDetailViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"HealthDetailViewController"];
    NSString *symbolsStr = [self.symbolsArray componentsJoinedByString:@" "];
    NSMutableDictionary *tempDict = [NSMutableDictionary dictionaryWithDictionary:self.detailRecordInfo];
    tempDict[@"symbton"] = symbolsStr;
    vc.detailRecordInfo = tempDict;
    vc.dayInfo = self.dayInfo;
    [self.navigationController pushViewController:vc animated:YES];
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
    [chooseImgView setFrame:CGRectMake(symptonView.frame.size.width-chooseImg.size.width, symptonView.frame.size.height - chooseImg.size.height, chooseImg.size.width, chooseImg.size.height)];
    NSString *symbolsStr = [self.detailRecordInfo objectForKey:@"symbton"];
    NSArray *symbolsArray = [symbolsStr componentsSeparatedByString:@" "];
    if ([symbolsArray containsObject:btn.titleLabel.text]) {
        chooseImgView.hidden = NO;
    } else {
        chooseImgView.hidden = YES;
    }
    [symptonView addSubview:chooseImgView];
    
    [self.view addSubview:symptonView];
    return symptonView;
}

- (void) onAddClick: (UIButton *) button {
    UIView *symptonView = button.superview;
    for (UIView *subview in symptonView.subviews){
        if ([subview isKindOfClass:[UIImageView class]]) {
            if (subview.hidden == YES) {
                subview.hidden = NO;
                [self.symbolsArray addObject:button.titleLabel.text];
                [self.symbolsArray removeObject:@""];
                NSLog(@"symbolsArray=%@",self.symbolsArray);
            } else {
                subview.hidden = YES;
                [self.symbolsArray removeObject:button.titleLabel.text];
                [self.symbolsArray removeObject:@""];
                NSLog(@"symbolsArray=%@",self.symbolsArray);
            }
        }
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
