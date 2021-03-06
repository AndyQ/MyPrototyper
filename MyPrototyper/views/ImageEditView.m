//
//  ImageEditView.m
//  Prototyper
//
//  Created by Andy Qua on 11/01/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

#import "ImageEditView.h"

#define TOP_LEFT 1
#define TOP_RIGHT 2
#define BOTTOM_LEFT 3
#define BOTTOM_RIGHT 4
#define FRAME 5

CGPoint CGRectCenter( CGRect r )
{
    CGPoint p = CGPointMake(r.origin.x + (r.size.width / 2), r.origin.y + (r.size.height / 2) );
    return p;
}

/**
 * This view is used to dispay an editable hotspot area that can be moved/expanded/contracted and will update its delegate
 * (parent VC in this case) when it gets moved
 * It also shows the starting image - allowing the user to 'draw' (create paths) on top of the base image.
 */
@implementation ImageEditView
{
    UIColor *borderColor;
    UIColor *backgroundColor;
    
    CGRect topLeftPoint;
    CGRect topRightPoint;
    CGRect bottomLeftPoint;
    CGRect bottomRightPoint;

    int pointMove;
    CGPoint startPoint;
    
    UIBezierPath *path;
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    if ( (self = [super initWithCoder:aDecoder]) )
    {
        [self setColor:[UIColor redColor]];
    }
    return self;
}

- (void) showSelectArea:(CGRect)r
{
    self.selectArea = r;
    [self updatePointsFromRect];
    self.showSelectArea = YES;
    [self setNeedsDisplay];
}

- (void) hideSelectArea
{
    self.showSelectArea = NO;
    [self setNeedsDisplay];
}

- (void) setColor:(UIColor *)color
{
    borderColor = color;

    backgroundColor = [borderColor colorWithAlphaComponent:0.2];
    [self setNeedsDisplay];
}

- (void) updatePointsFromRect
{
    CGFloat controlPointSize = 30;
    CGRect r = self.selectArea;
    r.origin.x -= controlPointSize/2;
    r.origin.y -= controlPointSize/2;
    
    CGPoint topLeft = CGPointMake( r.origin.x, r.origin.y );
    CGPoint topRight = CGPointMake( r.origin.x + r.size.width, r.origin.y );
    CGPoint bottomLeft = CGPointMake( r.origin.x, r.origin.y + r.size.height );
    CGPoint bottomRight = CGPointMake( r.origin.x + r.size.width, r.origin.y + r.size.height );
    CGSize size = CGSizeMake( controlPointSize, controlPointSize );
    
    
    topLeftPoint = (CGRect){ .origin = topLeft, .size = size};
    topRightPoint = (CGRect){ .origin = topRight, .size = size};
    bottomLeftPoint = (CGRect){ .origin = bottomLeft, .size = size};
    bottomRightPoint = (CGRect){ .origin = bottomRight, .size = size};
    
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];

    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [self.image drawInRect:self.frame];

    if ( self.showSelectArea )
    {
        CGContextSetFillColorWithColor(context, backgroundColor.CGColor);
        CGContextFillRect(context, self.selectArea);
        
        CGContextSetStrokeColorWithColor(context, borderColor.CGColor);
        
        CGContextSetLineWidth(context, 2);
        CGRect r = CGRectInset(self.selectArea, 1, 1);
        CGContextStrokeRect(context, r);
        
        // Draw control points
        if ( self.allowResize )
        {
            CGContextSetFillColorWithColor(context, borderColor.CGColor);
            CGContextFillEllipseInRect (context, CGRectInset( topLeftPoint, 7, 7 ));
            CGContextFillEllipseInRect (context, CGRectInset( topRightPoint, 7, 7 ));
            CGContextFillEllipseInRect (context, CGRectInset( bottomLeftPoint, 7, 7 ));
            CGContextFillEllipseInRect (context, CGRectInset( bottomRightPoint, 7, 7 ));
        }
    }
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint p = [touch locationInView:self];
    
    startPoint = p;
    
    // Which point to move
    if ( self.showSelectArea  )
    {
        if ( CGRectContainsPoint(topLeftPoint, p) && self.allowResize)
            pointMove = TOP_LEFT;
        else if ( CGRectContainsPoint(topRightPoint, p) && self.allowResize)
            pointMove = TOP_RIGHT;
        else if ( CGRectContainsPoint(bottomLeftPoint, p) && self.allowResize)
            pointMove = BOTTOM_LEFT;
        else if ( CGRectContainsPoint(bottomRightPoint, p) && self.allowResize)
            pointMove = BOTTOM_RIGHT;
        else if ( CGRectContainsPoint(self.selectArea, p) )
            pointMove = FRAME;
        else
        {
            // User didn't tap on hotspot area so we may need to do/select something else
            // so tell the delegate we aren't interested in this
            [self.delegate touchedViewAtPoint:p];
        }
    }
    else
        [self.delegate touchedViewAtPoint:p];
}

- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint p = [touch locationInView:self];
    
    CGFloat dx = p.x - startPoint.x;
    CGFloat dy = p.y - startPoint.y;
    
    if ( pointMove == TOP_LEFT  )
    {
        topLeftPoint = CGRectOffset(topLeftPoint, dx, dy );
        topRightPoint = CGRectOffset(topRightPoint, 0, dy );
        bottomLeftPoint = CGRectOffset(bottomLeftPoint, dx, 0 );
    }
    if ( pointMove == TOP_RIGHT )
    {
        topRightPoint = CGRectOffset(topRightPoint, dx, dy );
        topLeftPoint = CGRectOffset(topLeftPoint, 0, dy );
        bottomRightPoint = CGRectOffset(bottomRightPoint, dx, 0 );
    }
    if ( pointMove == BOTTOM_LEFT )
    {
        bottomLeftPoint = CGRectOffset(bottomLeftPoint, dx, dy );
        topLeftPoint = CGRectOffset(topLeftPoint, dx, 0 );
        bottomRightPoint = CGRectOffset(bottomRightPoint, 0, dy );
    }
    if ( pointMove == BOTTOM_RIGHT  )
    {
        bottomRightPoint = CGRectOffset(bottomRightPoint, dx, dy );
        topRightPoint = CGRectOffset(topRightPoint, dx, 0 );
        bottomLeftPoint = CGRectOffset(bottomLeftPoint, 0, dy );
    }
    if ( pointMove == FRAME )
    {
        topLeftPoint = CGRectOffset(topLeftPoint, dx, dy );
        topRightPoint = CGRectOffset(topRightPoint, dx, dy );
        bottomLeftPoint = CGRectOffset(bottomLeftPoint, dx, dy );
        bottomRightPoint = CGRectOffset(bottomRightPoint, dx, dy );
    }
    
    // Update selectArea based on control points
    CGFloat width = CGRectCenter( topRightPoint ).x - CGRectCenter( topLeftPoint ).x;
    CGFloat height = CGRectCenter( bottomRightPoint ).y - CGRectCenter( topRightPoint ).y;
    self.selectArea = CGRectMake( CGRectCenter( topLeftPoint ).x, CGRectCenter( topLeftPoint ).y, width, height);
    
    startPoint = p;
    [self setNeedsDisplay];
}



- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    pointMove = 0;
    
    // Notify delegate that the frame has changed
    if ( self.showSelectArea )
        [self.delegate hotspotAreaUpdate:self.selectArea];
}
@end
