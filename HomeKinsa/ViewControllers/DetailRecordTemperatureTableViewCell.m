//
//  DetailRecordTemperatureTableViewCell.m
//  HomeKinsa
//
//  Created by Zhang guangchun on 15/5/15.
//  Copyright (c) 2015年 Mikai. All rights reserved.
//

#import "DetailRecordTemperatureTableViewCell.h"
#import "GlobalData.h"
@interface DetailRecordTemperatureTableViewCell() <UITextFieldDelegate>
@end
@implementation DetailRecordTemperatureTableViewCell

- (void)awakeFromNib {
    // Initialization code
    self.TemperatureTextField.delegate = self;
    GlobalData *gd = [GlobalData sharedData];
    int type = (gd.temperatureType!=nil&&[gd.temperatureType intValue]==2)?2:1;
    if (type == 1) {
        //判断填写的温度
        self.TemperatureTextField.placeholder = @"32.0~44.0";
    } else {
        self.TemperatureTextField.placeholder = @"89.6~111.2";
    }
    self.TemperatureTextField.font = [UIFont systemFontOfSize:32];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if ([self.delegate respondsToSelector:@selector(DetailRecordTemperatureTableViewCellDidEndEditTextField:)]) {
        [self.delegate DetailRecordTemperatureTableViewCellDidEndEditTextField:[textField.text doubleValue]];
    }
}

 - (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.TemperatureTextField.text = @"";
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    NSArray *points = [textField.text componentsSeparatedByString:@"."];
    if (points.count>=2&&[string isEqualToString:@"."]) {
        return NO;
    }
    // Check for total length
    NSUInteger proposedNewLength = textField.text.length - range.length + string.length;
    //限制温度输入长度
    if (proposedNewLength > 5){
        return NO;//限制长度
    }
    return [self validateNumber:string];
}

- (BOOL)validateNumber:(NSString*)number {
    BOOL res = YES;
    NSCharacterSet* tmpSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789."];
    int i = 0;
    while (i< number.length) {
        NSString * string = [number substringWithRange:NSMakeRange(i, 1)];
        NSRange range = [string rangeOfCharacterFromSet:tmpSet];
        if (range.length == 0) {
            res = NO;
            break;
        }
        i++;
    }
    return res;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}
@end
