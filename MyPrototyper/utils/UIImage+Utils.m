//
//  UIImage+Utils.m
//  BALearningEditor
//
//  Created by Andy Qua on 05/03/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

#import "UIImage+Utils.h"

@implementation UIImage (Utils)

- (UIImage *) createThumbnail
{
    CGSize destinationSize = CGSizeMake( 94, 136 );
    UIGraphicsBeginImageContext(destinationSize);
    [self drawInRect:CGRectMake(0,0,destinationSize.width,destinationSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return newImage;
}
@end
