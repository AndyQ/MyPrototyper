//
//  Utils.m
//  Prototyper
//
//  Created by Andy Qua on 13/01/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

#import "UIColor+Utils.h"

@implementation UIColor (Utils)

- (UIColor *) darkerColorByAmount:(CGFloat) amount
{
    CGFloat hue, sat, bright, alpha;
    [self getHue:&hue saturation:&sat brightness:&bright alpha:&alpha];
    UIColor *darkerColor = [UIColor colorWithHue:hue saturation:sat brightness:bright*amount alpha:alpha];

    return darkerColor;
}

@end