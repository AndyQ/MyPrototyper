//
//  HotspotView.m
//  Prototyper
//
//  Created by Andy Qua on 10/01/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

#import "HotspotView.h"

@implementation HotspotView
{
    ImageLink *_associatedImageLink;
    
    UIColor *unselBorderColor;
    UIColor *borderColor;
    UIColor *backgroundColor;
    bool selected;
}


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.opaque = NO;
        selected = NO;
    }
    return self;
}

- (void) setColor
{
    if ( _associatedImageLink.linkedToId.length > 0 )
    {
        // Linked
        borderColor = [UIColor greenColor];
    }
    else
    {
        // Unlinked
        borderColor = [UIColor redColor];
    }
    
    CGFloat hue, sat, bright, alpha;
    [borderColor getHue:&hue saturation:&sat brightness:&bright alpha:&alpha];
    unselBorderColor = [UIColor colorWithHue:hue saturation:sat brightness:bright*0.5 alpha:alpha];
    backgroundColor = [borderColor colorWithAlphaComponent:0.2];
}

- (UIColor *) getColor
{
    [self setColor];
    return borderColor;
}

- (ImageLink *) getAssociatedImageLink
{
    return _associatedImageLink;
}

- (void) setAssociatedImageLink:(ImageLink *)link
{
    _associatedImageLink = link;
    [self updateFrame:link.rect];
}

- (void) updateFrame:(CGRect)f
{
    // Round values off (so they aren't on boundaries)
    f.origin.x = (int)f.origin.x;
    f.origin.y = (int)f.origin.y;
    f.size.width = (int)f.size.width;
    f.size.height = (int)f.size.height;
    
    self.frame = f;
    _associatedImageLink.rect = f;
    [self setNeedsDisplay];
}


- (void) setSelected:(bool)sel
{
    selected = sel;
    
    [self setColor];
    [self setNeedsDisplay];
}


- (void)drawRect:(CGRect)rect
{
    [self setColor];
 
    // We don't draw ourselves if selected as the main view handles showing the overlay (allowing user to adjust size)
    if ( selected )
        return;
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextClearRect(context, rect);
    
    CGContextSetFillColorWithColor(context, backgroundColor.CGColor);
    CGContextFillRect(context, rect);
    
    CGContextSetStrokeColorWithColor(context, unselBorderColor.CGColor);
    
    CGContextSetLineWidth(context, 2);
    CGRect r = CGRectInset(rect, 1, 1);
    CGContextStrokeRect(context, r);
}

@end
