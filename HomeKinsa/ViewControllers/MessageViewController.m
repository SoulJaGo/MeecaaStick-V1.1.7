//
//  MessageViewController.m
//  HomeKinsa
//
//  Created by SoulJa on 15/9/22.
//  Copyright © 2015年 Mikai. All rights reserved.
//

#import "MessageViewController.h"
#import "HttpTool.h"
#import "DataBaseTool.h"

@interface MessageViewController ()
/*消息的数据*/
@property (nonatomic,strong) NSMutableArray *msgArray;
@end

@implementation MessageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //设置Nav
    [self setupNav];
    
    //设置tableView
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    
    if (self.msgArray.count ==0 || self.msgArray == nil) {
        UILabel *headerLabel = [[UILabel alloc] init];
        headerLabel.text = @"您还没有收到消息哦!";
        headerLabel.font = [UIFont boldSystemFontOfSize:16];
        headerLabel.frame = CGRectMake(0, 0, self.view.bounds.size.width, 50);
        [headerLabel setTextAlignment:NSTextAlignmentCenter];
        headerLabel.textColor = [UIColor colorWithRed:184/255.0 green:184/255.0 blue:184/255.0 alpha:1.0];
        self.tableView.tableHeaderView = headerLabel;
    } else {
        self.tableView.tableHeaderView = nil;
    }
    
    self.tableView.allowsSelection = NO;
}

/**
 *  2015-9-26 SoulJa
 *  获取消息数据的数组
 */
- (NSMutableArray *)msgArray
{
    return [DataBaseTool getAllMessages];
}

/**
 *  2015-9-22 SoulJa
 *  设置Nav
 */
- (void)setupNav
{
    self.navigationItem.title = @"消息";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"login_back_icon"] style:UIBarButtonItemStyleDone target:self action:@selector(goBack)];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
}

/**
 *  2015-9-22 SoulJa
 *  返回
 */
- (void)goBack
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.msgArray.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *addtime = [NSString stringWithFormat:@"%@",[self.msgArray[section] objectForKey:@"addtime"]];
    if (addtime == nil || addtime == 0) {
        return @"";
    } else {
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:[addtime floatValue]];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        NSString *dateStr = [formatter stringFromDate:date];
        return dateStr;
    }

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *ID = @"cell";
    UITableViewCell *cell = [tableView  dequeueReusableCellWithIdentifier:ID];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:ID];
    }
    cell.textLabel.text = [NSString stringWithFormat:@"%@",[self.msgArray[indexPath.section] objectForKey:@"title"]];
    cell.textLabel.textColor = [UIColor colorWithRed:164/255.0 green:164/255.0 blue:164/255.0 alpha:1.0];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@",[self.msgArray[indexPath.section] objectForKey:@"content"]];
    cell.detailTextLabel.textColor = [UIColor colorWithRed:164/255.0 green:164/255.0 blue:164/255.0 alpha:1.0];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSLog(@"%@",self.msgArray[indexPath.section]);
        NSString *msgid = [NSString stringWithFormat:@"%@",[self.msgArray[indexPath.section] objectForKey:@"msgid"]];
        [self removeMessage:msgid];
    }
}

/**
 *  2015-09-28 SoulJa
 *  删除信息
 */
- (void)removeMessage:(NSString *)msgid
{
    BOOL result = [DataBaseTool removeMessage:msgid];
    if (result) {
        [self.tableView reloadData];
    } else {
        NSLog(@"删除失败!");
    }
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
