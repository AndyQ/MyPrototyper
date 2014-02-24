//
//  DrawView.m
//  Prototyper
//
//  Created by Andy Qua on 13/01/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

#import "DrawView.h"

@implementation DrawView

- (void)reloadData
{
    [self setNeedsDisplay];
}

- (void)reloadDataInRect:(CGRect)rect
{
    [self setNeedsDisplayInRect:rect];
}

- (void)drawRect:(CGRect)rect
{
    NSUInteger numberOfShapes = [self.dataSource numberOfShapesInDrawingView:self];
    NSUInteger indexOfSelectedShape = NSNotFound;
    if ([self.dataSource respondsToSelector:@selector(indexOfSelectedShapeInDrawingView:)]) {
        indexOfSelectedShape = [self.dataSource indexOfSelectedShapeInDrawingView:self];
    }
    
    for (NSUInteger shapeIndex = 0; shapeIndex < numberOfShapes; shapeIndex++)
    {
        UIBezierPath *path = [self.dataSource drawingView:self pathForShapeAtIndex:shapeIndex];
        if (CGRectIntersectsRect(rect, CGRectInset(path.bounds, -(path.lineWidth + 1.0f), -(path.lineWidth + 1.0f))))
        {
            UIColor *lineColor = [self.dataSource drawingView:self lineColorForShapeAtIndex:shapeIndex];
            if ( [self.dataSource drawingView:self shouldFillShapeAtIndex:shapeIndex] )
            {
                [lineColor setFill];
                [path fill];
            }
            else
            {
                [lineColor setStroke];
                [path stroke];
            }
            
            if (shapeIndex == indexOfSelectedShape) {
                UIBezierPath *pathCopy = [path copy];
                CGPathRef cgPathSelectionRect = CGPathCreateCopyByStrokingPath(pathCopy.CGPath, NULL, pathCopy.lineWidth, pathCopy.lineCapStyle, pathCopy.lineJoinStyle, pathCopy.miterLimit);
                UIBezierPath *selectionRect = [UIBezierPath bezierPathWithCGPath:cgPathSelectionRect];
                CGPathRelease(cgPathSelectionRect);
                
                CGFloat dashStyle[] = { 5.0f, 5.0f };
                [selectionRect setLineDash:dashStyle count:2 phase:0];
                [[UIColor blackColor] setStroke];
                [selectionRect stroke];
            }
        }
    }
    
    if ( self.tmpPath != nil )
    {
        [self.tmpPathColor setStroke];
        [self.tmpPath stroke];

    }
}

@end