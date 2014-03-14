//
//  PhotoCell.m
//  Prototyper
//
//  Created by Andy Qua on 09/01/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

#import "PhotoCell.h"
#import <JSCustomBadge/JSCustomBadge.h>

@interface PhotoCell ()
@end

@implementation PhotoCell


- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self)
    {
        self.layer.borderColor = [UIColor blackColor].CGColor;
        self.layer.borderWidth = 1;
        self.layer.cornerRadius = 5;
        self.badgeNr = -1;
    }
    return self;
}

- (void) setImage:(UIImage *)image withBadgeText:(NSString *)badgeText
{
    _image = image;
    self.imageView.image = image;
    
    [self.imageView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    if ( badgeText.length > 0 )
    {
        JSCustomBadge *badge = [JSCustomBadge customBadgeWithString:badgeText];
        CGRect f = badge.frame;
//        f.origin.x = self.imageView.frame.size.width - 5 - f.size.width;
//        f.origin.x = self.imageView.frame.size.height - 5 - f.size.height;
        badge.frame = f;
        [self.imageView addSubview:badge];
    }
}

- (void) setHighlight:(BOOL)highlight
{
    _highlight = highlight;
    
    if ( _highlight )
        self.backgroundColor = [UIColor greenColor];
    else
        self.backgroundColor = [UIColor clearColor];
}
@end
