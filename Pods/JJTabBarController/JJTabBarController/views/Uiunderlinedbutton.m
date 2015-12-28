//
//  Uiunderlinedbutton.m
//  Pods
//
//  Created by Zhang guangchun on 15/6/3.
//
//

#import "Uiunderlinedbutton.h"

@implementation Uiunderlinedbutton

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void) drawRect:(CGRect)rect {
    if (!self.selected) {
        return;
    }
    CGRect textRect = self.titleLabel.frame;
    
    // need to put the line at top of descenders (negative value)
    CGFloat descender = self.titleLabel.font.descender;
    
    CGContextRef contextRef = UIGraphicsGetCurrentContext();
    
    // set to same colour as text
    CGContextSetStrokeColorWithColor(contextRef, self.titleLabel.textColor.CGColor);
    CGContextSetLineWidth(contextRef, 2);
    CGContextMoveToPoint(contextRef, textRect.origin.x, textRect.origin.y + textRect.size.height + descender + 5);
    
    CGContextAddLineToPoint(contextRef, textRect.origin.x + textRect.size.width, textRect.origin.y + textRect.size.height + descender+5);
    
    CGContextClosePath(contextRef);
    CGContextDrawPath(contextRef, kCGPathStroke); 
}

@end
