//
//  ShadeView.h
//  Prototyper
//
//  Created by Andy Qua on 10/01/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ImageLink.h"

@interface ShadeView : UIView
{
}

@property (nonatomic, strong) ImageLink *associatedImageLink;

- (void) updateFrame:(CGRect)f;
- (UIColor *) getColor;
- (void) setSelected:(bool)sel;
@end
