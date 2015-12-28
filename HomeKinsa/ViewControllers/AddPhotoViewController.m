//
//  AddPhotoViewController.m
//  HomeKinsa
//
//  Created by Zhang guangchun on 15/5/2.
//  Copyright (c) 2015年 Mikai. All rights reserved.
//

#import "AddPhotoViewController.h"
#import "AddPhotoTableViewCell.h"
#import "AddPhotoButton.h"
#import <ZYQAssetPickerController/ZYQAssetPickerController.h>

@interface AddPhotoViewController ()<UITableViewDataSource,UITableViewDelegate,UINavigationControllerDelegate,ZYQAssetPickerControllerDelegate,UITextViewDelegate>{
    int kImageWidth;
    int kImageHeight;
}

@property (strong, nonatomic) IBOutlet UITextView *descLabel;
@property (retain, nonatomic) NSMutableArray *imageList;
@property (weak, nonatomic) IBOutlet UITableView *photoTableView;

@end

@implementation AddPhotoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.photoTableView.dataSource = self;
    self.photoTableView.delegate = self;
    [self.photoTableView reloadData];
    
    /**
     *  2015-11-28 SoulJa
     *  加入textfield代理
     */
    self.descLabel.delegate = self;
    
    kImageWidth = self.view.bounds.size.width/4;
    kImageHeight = kImageWidth;
    
    self.descLabel.text = self.desc!=nil?self.desc:@"";
    if (self.beforeImageList) {
        self.imageList = [NSMutableArray arrayWithArray:self.beforeImageList];
    }
    else {
        self.imageList = [NSMutableArray arrayWithArray:@[[UIImage imageNamed:@"record_add_icon"]]];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onClickBack:(id)sender {
    if (self.addDelegate) {
        [self.addDelegate getChoosePhotos:self.imageList AndDesc:self.descLabel.text];
    }
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark UITable datasource and delegate
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (self.imageList&&self.imageList.count>0) {
        return self.imageList.count/4 + (self.imageList.count%4==0?0:1);
    }
    return 1;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *identifier = @"Cell";    
    //自定义UITableGridViewCell，里面加了个NSArray用于放置里面的3个图片按钮
    AddPhotoTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[AddPhotoTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        cell.selectedBackgroundView = [[UIView alloc] init];
    }
    else {
        for(UIView *view in [cell subviews])
        {
            [view removeFromSuperview];
        }
    }
    NSMutableArray *array = [NSMutableArray array];
    NSInteger row = [indexPath row];
    for (int i=0; i<4; i++) {
        NSInteger value = row*4 + i;
        if (value<self.imageList.count) {
            //自定义继续UIButton的UIImageButton 里面只是加了2个row和column属性
            AddPhotoButton *button = [AddPhotoButton buttonWithType:UIButtonTypeCustom];
            button.bounds = CGRectMake(0, 0, kImageWidth-5, kImageHeight-5);
            button.center = CGPointMake((1 + i) * 5 + (kImageWidth - 5) *( 0.5 + i) , 5 + (kImageHeight - 5) * 0.5);
            [button setValue:[NSNumber numberWithInt:i] forKey:@"column"];
            [button addTarget:self action:@selector(imageItemClick:) forControlEvents:UIControlEventTouchUpInside];
            [button setBackgroundImage:[self.imageList objectAtIndex:value] forState:UIControlStateNormal];
            [button.imageView setContentMode:UIViewContentModeScaleAspectFit];
            
            /**
             *  SoulJa 2015-10-13
             *  添加删除按钮
             */
            if (value != self.imageList.count - 1) {
                UIButton *delBtn = [UIButton buttonWithType:UIButtonTypeCustom];
                delBtn.frame = CGRectMake(0, 0, 20, 20);
                [delBtn setBackgroundImage:[UIImage imageNamed:@"delBtn"] forState:UIControlStateNormal];
                delBtn.center = CGPointMake(button.bounds.size.width - delBtn.bounds.size.width * 0.5-5, button.bounds.size.height - delBtn.bounds.size.height * 0.5-5);
                delBtn.tag = value;
                [delBtn addTarget:self action:@selector(onClickDelBtn:) forControlEvents:UIControlEventTouchUpInside];
                [button addSubview:delBtn];
            }
            [cell addSubview:button];
            [array addObject:button];
        }
    }
    [cell setValue:array forKey:@"buttons"];
    
    //获取到里面的cell里面的4个图片按钮引用
    NSArray *imageButtons =cell.buttons;
    //设置UIImageButton里面的row属性
    [imageButtons setValue:[NSNumber numberWithInt:indexPath.row] forKey:@"row"];
    return cell;
}

/**
 *  SoulJa 2015-10-13
 *  店家删除按钮
 */
- (void)onClickDelBtn:(UIButton *)delBtn
{
    [self.imageList removeObjectAtIndex:delBtn.tag];
    [self.photoTableView reloadData];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return kImageHeight;
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    //不让tableviewcell有选中效果
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(void)imageItemClick:(AddPhotoButton *)button{
    int value = button.row*4 + button.column;
    if (value == self.imageList.count-1) {
        ZYQAssetPickerController *picker = [[ZYQAssetPickerController alloc] init];
        picker.maximumNumberOfSelection = 6-self.imageList.count;
        picker.assetsFilter = [ALAssetsFilter allPhotos];
        picker.showEmptyGroups=NO;
        picker.delegate=self;
        picker.selectionFilter = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
            if ([[(ALAsset*)evaluatedObject valueForProperty:ALAssetPropertyType] isEqual:ALAssetTypeVideo]) {
                NSTimeInterval duration = [[(ALAsset*)evaluatedObject valueForProperty:ALAssetPropertyDuration] doubleValue];
                return duration >= 5;
            } else {
                return YES;
            }
        }];
        
        [self presentViewController:picker animated:YES completion:NULL];
    }
    /*NSString *msg = [NSString stringWithFormat:@"第%i行 第%i列",button.row + 1, button.column + 1];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示"
                                                    message:msg
                                                   delegate:nil
                                          cancelButtonTitle:@"好的，知道了"
                                          otherButtonTitles:nil, nil];
    [alert show];*/
}

#pragma mark - ZYQAssetPickerController Delegate
-(void)assetPickerController:(ZYQAssetPickerController *)picker didFinishPickingAssets:(NSArray *)assets{
//    [self.imageList removeAllObjects];
    for (int i=0; i<assets.count; i++) {
        ALAsset *asset=assets[i];
        UIImage *tempImg=[UIImage imageWithCGImage:asset.defaultRepresentation.fullScreenImage];
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self.imageList addObject:tempImg];
        [self.imageList insertObject:tempImg atIndex:0];
//        });
    }
//    [self.imageList addObject:[UIImage imageNamed:@"record_add_icon"]];
    [self.photoTableView reloadData];
}

-(void)assetPickerControllerDidMaximum:(ZYQAssetPickerController *)picker{
    NSLog(@"到达上限");
}

#pragma mark 根据size截取图片中间矩形区域的图片 这里的size是正方形
-(UIImage *)cutCenterImage:(UIImage *)image size:(CGSize)size{
    CGSize imageSize = image.size;
    CGRect rect;
    //根据图片的大小计算出图片中间矩形区域的位置与大小
    if (imageSize.width > imageSize.height) {
        float leftMargin = (imageSize.width - imageSize.height) * 0.5;
        rect = CGRectMake(leftMargin, 0, imageSize.height, imageSize.height);
    }else{
        float topMargin = (imageSize.height - imageSize.width) * 0.5;
        rect = CGRectMake(0, topMargin, imageSize.width, imageSize.width);
    }
    
    CGImageRef imageRef = image.CGImage;
    //截取中间区域矩形图片
    CGImageRef imageRefRect = CGImageCreateWithImageInRect(imageRef, rect);
    
    UIImage *tmp = [[UIImage alloc] initWithCGImage:imageRefRect];
    CGImageRelease(imageRefRect);
    
    UIGraphicsBeginImageContext(size);
    CGRect rectDraw = CGRectMake(0, 0, size.width, size.height);
    [tmp drawInRect:rectDraw];
    // 从当前context中创建一个改变大小后的图片
    tmp = UIGraphicsGetImageFromCurrentImageContext();
    
    // 使当前的context出堆栈
    UIGraphicsEndImageContext();
    
    return tmp;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.view endEditing:YES];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    return YES;
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
