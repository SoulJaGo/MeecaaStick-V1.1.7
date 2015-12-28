//
//  TTBoardButton.m
//  wkw
//
//  Created by Tice Tang on 11/2/15.
//  Copyright (c) 2015 Tice Tang. All rights reserved.
//

#import "TTBoardButton.h"
#import "UIImage+ImageEffects.h"


@interface TTBoardButton()


@end

@implementation TTBoardButton

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void) awakeFromNib{
    self.clipsToBounds = YES;
    self.defaultBackgroundColor = self.backgroundColor;
    self.layer.cornerRadius = 8.0f;
    self.layer.borderColor = self.defaultBackgroundColor.CGColor;
    self.layer.borderWidth = 1.0f;
    [self setTitleColor:self.backgroundColor forState:UIControlStateNormal];
    [self setTitleColor:self.defaultBackgroundColor forState:UIControlStateHighlighted];
    [self setTitleColor:[UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1.0f] forState:UIControlStateDisabled];
    [self setBackgroundImage:[UIImage imageWithColor:[UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:0.5f]] forState:UIControlStateHighlighted];

    self.backgroundColor = [UIColor clearColor];
}

- (UIColor *)darkerColorForColor:(UIColor *)color{
    CGFloat r, g, b, a;
    if ([color getRed:&r green:&g blue:&b alpha:&a])
        return [UIColor colorWithRed:MAX(r - 0.2f, 0.0f)
                               green:MAX(g - 0.2f, 0.0f)
                                blue:MAX(b - 0.2f, 0.0f)
                               alpha:a];
    return nil;
}

- (UIColor *)lighterColorForColor:(UIColor *)color{
    CGFloat r, g, b, a;
    if ([color getRed:&r green:&g blue:&b alpha:&a])
        return [UIColor colorWithRed:MIN(r + 0.2f, 1.0f)
                               green:MIN(g + 0.2f, 1.0f)
                                blue:MIN(b + 0.2f, 1.0f)
                               alpha:a];
    return nil;
}

- (void) setEnabled:(BOOL)enabled{
    [super setEnabled:enabled];
    self.layer.borderColor = (!enabled) ? [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1.0f].CGColor : self.defaultBackgroundColor.CGColor;
}

@end
