//
//  GetServerUrlViewController.m
//  HomeKinsa
//
//  Created by SoulJa on 15/9/2.
//  Copyright (c) 2015年 Mikai. All rights reserved.
//

#import "GetServerUrlViewController.h"
#import "AFNetworking.h"

@interface GetServerUrlViewController ()

@end

@implementation GetServerUrlViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

+ (NSString *)getServerUrl
{
    NSString *urlStr = @"http://121.199.40.188/api.php?m=open&c=server&a=setting";
    NSURL *url = [NSURL URLWithString:urlStr];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    NSDictionary *dict=[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
    if (dict[@"host"]) {
        return dict[@"host"];
    } else {
        return @"121.199.40.188";
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
