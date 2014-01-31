//
//  HotspotView.h
//  Prototyper
//
//  Created by Andy Qua on 10/01/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ImageLink.h"

@interface HotspotView : UIView
{
}

@property (nonatomic, strong) ImageLink *associatedImageLink;

- (id)initWithScale:(CGSize)imageScale;
- (void) updateFrame:(CGRect)f;
- (UIColor *) getColor;
- (void) setSelected:(bool)sel;
@end
