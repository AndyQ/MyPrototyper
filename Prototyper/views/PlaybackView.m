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
}
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void) setImageDetails:(ImageDetails *)imageDetails
{
    _imageDetails = imageDetails;
    
    image = [UIImage imageWithContentsOfFile:_imageDetails.imagePath];
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    // Drawing code
    
    [image drawInRect:self.frame];
    
    for ( ImageLink *link in self.imageDetails.links )
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
