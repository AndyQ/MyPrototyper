//
//  UIImageView+ContentScale.m
//  Prototyper
//
//  Created by Andy Qua on 31/01/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

#import "UIImageView+ContentScale.h"

@implementation UIImageView (ContentScale)

- (CGFloat) widthScale
{
    CGFloat widthScale = self.bounds.size.width / self.image.size.width;
    return widthScale;
}

- (CGFloat) heightScale
{
    CGFloat heightScale = self.bounds.size.height / self.image.size.height;
    return heightScale;
}

- (CGFloat) contentScaleFactor
{
    CGFloat widthScale = self.bounds.size.width / self.image.size.width;
    CGFloat heightScale = self.bounds.size.height / self.image.size.height;
    
    if (self.contentMode == UIViewContentModeScaleToFill)
    {
        return (widthScale==heightScale) ? widthScale : NAN;
    }
    if (self.contentMode == UIViewContentModeScaleAspectFit)
    {
        return MIN(widthScale, heightScale);
    }
    if (self.contentMode == UIViewContentModeScaleAspectFill)
    {
        return MAX(widthScale, heightScale);
    }
    return 1.0;
    
}

@end
