//
//  mianzeViewController.m
//  HomeKinsa
//
//  Created by SoulJa on 15/7/28.
//  Copyright (c) 2015年 Mikai. All rights reserved.
//

#import "mianzeViewController.h"

@interface mianzeViewController () <UIWebViewDelegate>
@property (nonatomic,strong) UIWebView *webView;
@end

@implementation mianzeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"免责声明";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"login_back_icon"] style:UIBarButtonItemStyleDone target:self action:@selector(goBack)];
    [self setupWebView];
}

/**
 *  返回
 */
- (void)goBack
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)setupWebView
{
    UIWebView *webView = [[UIWebView alloc] init];
    webView.frame = [UIScreen mainScreen].bounds;
    webView.scrollView.bounces = NO;
    NSString *path = [[NSBundle mainBundle] pathForResource:@"免责声明" ofType:@"html"];
    
    NSURL *url = [NSURL fileURLWithPath:path];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [webView loadRequest:request];
    [self.view addSubview:webView];
    self.webView = webView;
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
