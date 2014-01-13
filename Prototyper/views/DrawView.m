//
//  DrawView.m
//  Prototyper
//
//  Created by Andy Qua on 13/01/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

#import "DrawView.h"

static CGPoint midpoint(CGPoint p0, CGPoint p1)
{
    return (CGPoint) {
        (p0.x + p1.x) / 2.0,
        (p0.y + p1.y) / 2.0
    };
}

@implementation DrawView
{
    CGPoint previousPoint;
    
    UIBezierPath *path;
    NSMutableArray *pathArray;
    NSMutableArray *bufferArray;
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    if ( [super initWithCoder:aDecoder] )
    {        
        pathArray=[[NSMutableArray alloc]init];
        bufferArray=[[NSMutableArray alloc]init];

        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
        pan.maximumNumberOfTouches = pan.minimumNumberOfTouches = 1;
        [self addGestureRecognizer:pan];

    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    [[UIColor blackColor] setStroke];
    
    for (UIBezierPath *_path in pathArray)
    {
        [_path strokeWithBlendMode:kCGBlendModeNormal alpha:1.0];
    }
}

-(void) undoButtonPressed
{
    if( [pathArray count] > 0 )
    {
        UIBezierPath *_path = [pathArray lastObject];
        [bufferArray addObject:_path];
        [pathArray removeLastObject];
        [self setNeedsDisplay];
    }
}

-(void) redoButtonPressed
{
    if( [bufferArray count] > 0 )
    {
        UIBezierPath *_path = [bufferArray lastObject];
        [pathArray addObject:_path];
        [bufferArray removeLastObject];
        [self setNeedsDisplay];
    }
}

- (void)pan:(UIPanGestureRecognizer *)pan
{
    CGPoint currentPoint = [pan locationInView:self];
    CGPoint midPoint = midpoint(previousPoint, currentPoint);
    
    if (pan.state == UIGestureRecognizerStateBegan)
    {
        path = [UIBezierPath bezierPath];
        path.lineWidth = 5;
        [pathArray addObject:path];

        [path moveToPoint:currentPoint];
    }
    else if (pan.state == UIGestureRecognizerStateChanged)
    {
        [path addQuadCurveToPoint:midPoint controlPoint:previousPoint];
    }
    
    previousPoint = currentPoint;
    
    [self setNeedsDisplay];
}


@end
