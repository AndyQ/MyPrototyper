//
//  PlaybackView.m
//  Prototyper
//
//  Created by Andy Qua on 12/01/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

#import "PlaybackView.h"

@implementation PlaybackView
{
    UIImage *image;
    ImageDetails *imageDetails;
    ImageDetails *tmpDetails;
    
    UIImageView *transitionImageView;
}
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

/*
- (void) setImageDetails:(ImageDetails *)imageDetails
{
    _imageDetails = imageDetails;
    
    image = [UIImage imageWithContentsOfFile:_imageDetails.imagePath];
}
*/
- (void) transitionTo:(ImageDetails *)newDetails;
{
    if ( image == nil )
    {
        imageDetails = newDetails;
        image = [UIImage imageWithContentsOfFile:imageDetails.imagePath];
    }
    else
    {

        tmpDetails = newDetails;
        UIImage *tmpImage = [UIImage imageWithContentsOfFile:newDetails.imagePath];

        transitionImageView = [[UIImageView alloc] initWithImage:image];
        transitionImageView.contentMode = UIViewContentModeScaleToFill;
        transitionImageView.frame = self.frame;
        [self addSubview:transitionImageView];
        
        image = nil;
        [self setNeedsDisplay];

        
        double delayInSeconds = 0.1;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){

            
            CATransition *transition = [CATransition animation];
            transition.delegate = self;
            transition.duration = 0.5;
            transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            transition.type = kCATransitionMoveIn;
//            transition.subtype = kCATransitionFromRight;
//            transition.type = kCATransitionMoveIn;
            transition.subtype = kCATransitionFade;
            
            [transitionImageView.layer addAnimation:transition forKey:nil];
            transitionImageView.image = tmpImage;
        });
    }
}

- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag
{
    [transitionImageView removeFromSuperview];
    imageDetails = tmpDetails;
    image = [UIImage imageWithContentsOfFile:imageDetails.imagePath];

    tmpDetails = nil;
    [self setNeedsDisplay];
}


- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if ( image == nil )
        return;
    
    [image drawInRect:self.frame];
    
    for ( ImageLink *link in imageDetails.links )
    {
        UIColor *backgroundColor = [[UIColor greenColor] colorWithAlphaComponent:0.2];
        CGContextSetFillColorWithColor(context, backgroundColor.CGColor);
        CGContextFillRect(context, link.rect);
        
        CGContextSetStrokeColorWithColor(context, [UIColor greenColor].CGColor);
        
        CGContextSetLineWidth(context, 2);
        CGRect r = CGRectInset(link.rect, 1, 1);
        CGContextStrokeRect(context, r);
    }
}

@end
