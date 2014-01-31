//
//  HotspotView.m
//  Prototyper
//
//  Created by Andy Qua on 10/01/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

#import "HotspotView.h"
#import "UIColor+Utils.h"



/**
 *
 * A Hotspot view is used to display a touchable hotspot
 * However, when we are editing it, we don't display this view but a draggable area in the ImageEditView instead
 * This is so that we can simply expand/contract/move the area within the view and the just update the bounds of this
 * view rather than trying to figure out touchpositions in this view relative to the parent view which TBH got too messy and complex
 * and wasn't worth the bother so this was simpler at a cost of slight obscurity
 */
@implementation HotspotView
{
    ImageLink *_associatedImageLink;
    CGSize scale;
    
    UIColor *unselBorderColor;
    UIColor *borderColor;
    UIColor *backgroundColor;
    bool selected;
}


- (id)initWithScale:(CGSize)imageScale
{
    self = [super init];
    if (self)
    {
        self.opaque = NO;
        selected = NO;
        scale = imageScale;
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
    
    unselBorderColor = [borderColor darkerColorByAmount:0.5];
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
    
    CGRect f = link.rect;
    f.origin.x *= scale.width;
    f.origin.y *= scale.height;
    f.size.width *= scale.width;
    f.size.height *= scale.height;

    self.frame = f;
    [self setNeedsDisplay];
//    [self updateFrame:link.rect];
}

- (void) updateFrame:(CGRect)f
{
    // Round values off (so they aren't on boundaries)
    f.origin.x = (int)f.origin.x;
    f.origin.y = (int)f.origin.y;
    f.size.width = (int)f.size.width;
    f.size.height = (int)f.size.height;
    
    self.frame = f;
    
    f.origin.x /= scale.width;
    f.origin.y /= scale.height;
    f.size.width /= scale.width;
    f.size.height /= scale.height;
    
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
