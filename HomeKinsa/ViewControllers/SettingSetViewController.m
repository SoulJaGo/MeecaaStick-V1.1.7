//
//  SettingSetViewController.m
//  HomeKinsa
//
//  Created by Zhang guangchun on 15/5/3.
//  Copyright (c) 2015年 Mikai. All rights reserved.
//

#import "SettingSetViewController.h"
#import "SetType0TableViewCell.h"
#import "SetType1TableViewCell.h"
#import "GlobalData.h"

@interface SettingSetViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@end

@implementation SettingSetViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section{
    return @"";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 43;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSUInteger section = [indexPath section];
    GlobalData *gd = [GlobalData sharedData];
    int type = (gd.temperatureType!=nil&&[gd.temperatureType intValue]==2)?2:1;
    
    if (section==0) {
        SetType0TableViewCell *cell = (SetType0TableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"SetType0TableViewCell"];
        cell.chooseIcon.hidden = (type==2);
        return cell;
    }
    SetType1TableViewCell *cell = (SetType1TableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"SetType1TableViewCell"];
    cell.chooseIcon.hidden = (type==1);
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    NSInteger section = [indexPath section];
    GlobalData *gd = [GlobalData sharedData];
    if (section==0) {
        gd.temperatureType = [NSNumber numberWithInt:1];
    }
    else{
        gd.temperatureType = [NSNumber numberWithInt:2];
    }
    [tableView reloadData];
}

- (IBAction)onClickBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - 2015-10-12 新加代码
/**
 *  SoulJa 2015-10-12
 *  显示状态栏
 */
- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
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
