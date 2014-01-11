//
//  ControlPointView.m
//  Prototyper
//
//  Created by Andy Qua on 10/01/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

#import "ControlPointView.h"

@implementation ControlPointView
{
    UIColor *pointColor;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.color = [UIColor colorWithRed:18.0/255.0 green:173.0/255.0 blue:251.0/255.0 alpha:1];
        self.opaque = NO;
    }
    return self;
}

- (void)setColor:(UIColor *)_color
{
    pointColor = _color;
    [self setNeedsDisplay];
}

- (UIColor*)color {
    return pointColor;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextClearRect(context, rect);
    CGContextSetFillColorWithColor(context, pointColor.CGColor);
    CGContextFillEllipseInRect(context, rect);
}

@end
