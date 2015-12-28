//
//  TTRoundButton.m
//  wkw
//
//  Created by Tice Tang on 4/2/15.
//  Copyright (c) 2015 Tice Tang. All rights reserved.
//

#import "TTRoundButton.h"
#import "UIImage+ImageEffects.h"

@interface TTRoundButton()

@property (retain, nonatomic) UIColor *defaultBackgroundColor;

@end


@implementation TTRoundButton

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void) awakeFromNib{
    self.clipsToBounds = YES;
    self.layer.cornerRadius = 8.0f;
    self.defaultBackgroundColor = self.backgroundColor;
}

- (UIColor *)darkerColorForColor:(UIColor *)color
{
    CGFloat r, g, b, a;
    if ([color getRed:&r green:&g blue:&b alpha:&a])
        return [UIColor colorWithRed:MAX(r - 0.2f, 0.0f)
                               green:MAX(g - 0.2f, 0.0f)
                                blue:MAX(b - 0.2f, 0.0f)
                               alpha:a];
    return nil;
}

- (UIColor *)lighterColorForColor:(UIColor *)color
{
    CGFloat r, g, b, a;
    if ([color getRed:&r green:&g blue:&b alpha:&a])
        return [UIColor colorWithRed:MIN(r + 0.2f, 1.0f)
                               green:MIN(g + 0.2f, 1.0f)
                                blue:MIN(b + 0.2f, 1.0f)
                               alpha:a];
    return nil;
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    self.backgroundColor = (highlighted) ? [self darkerColorForColor:self.defaultBackgroundColor] : self.defaultBackgroundColor;
}

- (void) layoutSubviews{
    [super layoutSubviews];
    self.clipsToBounds = NO;
    
//    if (self.imageView != nil){
//        CGRect titleframe = self.titleLabel.frame;
//        CGRect imageFrame = self.imageView.frame;
//        self.titleLabel.frame = CGRectMake((self.frame.size.width-titleframe.size.width)/2, (self.frame.size.height-titleframe.size.height)/2, titleframe.size.width, titleframe.size.height);
//        titleframe = self.titleLabel.frame;
//        self.imageView.frame = CGRectMake(titleframe.origin.x+titleframe.size.width + 5, titleframe.origin.y - imageFrame.size.height / 2 - 5, imageFrame.size.width, imageFrame.size.height);
//    }
}

- (void) setEnabled:(BOOL)enabled{
    [super setEnabled:enabled];
    self.layer.backgroundColor = (!enabled) ? [self lighterColorForColor:self.defaultBackgroundColor].CGColor : self.defaultBackgroundColor.CGColor;
}

@end
