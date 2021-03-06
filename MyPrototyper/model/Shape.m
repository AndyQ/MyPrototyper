//
//  Shape.m
//  PathHitTesting
//
//  Created by Ole Begemann on 30.01.12.
//  Copyright (c) 2012 Ole Begemann. All rights reserved.
//

#import "UIBezierPath+TextPaths.h"
#import "Shape.h"

@interface Shape ()
{
}
- (UIBezierPath *)tapTargetForPath:(UIBezierPath *)path;

+ (ShapeType)randomShapeType;
+ (CGRect)randomRectInBounds:(CGRect)maxBounds;
+ (UIColor *)randomColor;
+ (CGFloat)randomLineWidth;
+ (UIBezierPath *)houseInRect:(CGRect)bounds;
+ (UIBezierPath *)arcInRect:(CGRect)bounds;

@end


@implementation Shape

@dynamic totalBounds;


+ (instancetype) randomShapeInBounds:(CGRect)maxBounds
{
    CGRect bounds = [self randomRectInBounds:maxBounds];
    ShapeType type = [self randomShapeType];
    int width = 5;
    UIColor *lineColor = [self randomColor];

    return [Shape shapeOfType:type inBounds:bounds lineWidth:width color:lineColor];
}

+ (instancetype) shapeOfType:(ShapeType)type inBounds:(CGRect)bounds lineWidth:(CGFloat)width color:(UIColor *)color
{
    UIBezierPath *path = nil;
    switch (type) {
        case ShapeTypeRect:
            path = [UIBezierPath bezierPathWithRect:bounds];
            break;
        case ShapeTypeEllipse:
            path = [UIBezierPath bezierPathWithOvalInRect:bounds];
            break;
        case ShapeTypeHouse:
            path = [self houseInRect:bounds];
            break;
        case ShapeTypeArc:
            path = [self arcInRect:bounds];
            break;
        default:
            path = [UIBezierPath bezierPathWithRect:bounds];
            break;
    }

    path.lineWidth = width;
    
    return [[self alloc] initWithPath:path lineColor:color];
}

+ (instancetype) shapeWithText:(NSString *)text atPoint:(CGPoint)p;
{
    UIBezierPath *path = nil;
    path = [self text:text atPoint:p];
    path.lineWidth = 1;
    
    Shape *s = [[self alloc] initWithPath:path lineColor:[UIColor blackColor]];
    s->_shouldFill = YES;
    return s;
}

+ (instancetype) shape
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    return [[self alloc] initWithPath:path lineColor:[UIColor blackColor]];
}

+ (instancetype)shapeWithPath:(UIBezierPath *)path lineColor:(UIColor *)lineColor
{
    return [[self alloc] initWithPath:path lineColor:lineColor];
}


- (instancetype) initWithPath:(UIBezierPath *)path lineColor:(UIColor *)lineColor
{
    self = [super init];
    if (self != nil)
    {
        _path = path;
        _lineColor = lineColor;
        _tapTargetPath = [self tapTargetForPath:_path];
    }
    return self;
}

- (instancetype) init
{
    UIBezierPath *defaultPath = [UIBezierPath bezierPathWithRect:CGRectMake(0.0f, 0.0f, 100.0f, 100.0f)];
    UIColor *defaultLineColor = [UIColor blackColor];
    return [self initWithPath:defaultPath lineColor:defaultLineColor];
}


#pragma mark - Description

- (NSString *) description
{
    return [NSString stringWithFormat:@"<Shape: %p - Bounds: %@ - Color: %@>", self, NSStringFromCGRect(self.path.bounds), self.lineColor];
}


#pragma mark - Hit Testing

- (UIBezierPath *) tapTargetForPath:(UIBezierPath *)path
{
    if (path == nil) {
        return nil;
    }
    
    CGPathRef tapTargetPath = CGPathCreateCopyByStrokingPath(path.CGPath, NULL, fmaxf(35.0f, path.lineWidth), path.lineCapStyle, path.lineJoinStyle, path.miterLimit);
    
    if (tapTargetPath == NULL) {
        return nil;
    }
    
    UIBezierPath *tapTarget = [UIBezierPath bezierPathWithCGPath:tapTargetPath];
    CGPathRelease(tapTargetPath);
    return tapTarget;
}

- (BOOL)containsPoint:(CGPoint)point
{
    return [self.tapTargetPath containsPoint:point];
}


#pragma mark - Bounds

- (CGRect) totalBounds
{
    if (self.path == nil) {
        return CGRectZero;
    }
    
    return CGRectInset(self.path.bounds, -(self.path.lineWidth + 1.0f), -(self.path.lineWidth + 1.0f));
}


#pragma mark - Modifying Shapes

- (void) moveBy:(CGPoint)delta
{
    CGAffineTransform transform = CGAffineTransformMakeTranslation(delta.x, delta.y);
    [self.path applyTransform:transform];
    [self.tapTargetPath applyTransform:transform];
}

- (void) applyTransform:(CGAffineTransform)transform;
{
    [self.path applyTransform:transform];
    [self.tapTargetPath applyTransform:transform];
}

#pragma mark - Random Shape Generator Methods

+ (ShapeType) randomShapeType
{
    return arc4random_uniform(SHAPE_TYPE_COUNT);
}

+ (CGRect) randomRectInBounds:(CGRect)maxBounds
{
    CGRect normalizedBounds = CGRectStandardize(maxBounds);
    uint32_t minOriginX = normalizedBounds.origin.x;
    uint32_t minOriginY = normalizedBounds.origin.y;
    uint32_t minWidth = 44;
    uint32_t minHeight = 44;

    uint32_t maxOriginX = normalizedBounds.size.width - minWidth;
    uint32_t maxOriginY = normalizedBounds.size.height - minHeight;

    uint32_t originX = arc4random_uniform(maxOriginX - minOriginX) + minOriginX;
    uint32_t originY = arc4random_uniform(maxOriginY - minOriginY) + minOriginY;
    
    uint32_t maxWidth = normalizedBounds.size.width - originX;
    uint32_t maxHeight = normalizedBounds.size.height - originY;

    uint32_t width = arc4random_uniform(maxWidth - minWidth) + minWidth;
    uint32_t height = arc4random_uniform(maxHeight - minHeight) + minHeight;
    
    CGRect randomRect = CGRectMake(originX, originY, width, height);
    return randomRect;
}

+ (UIColor *) randomColor
{
    NSArray *colors = [NSArray arrayWithObjects:
                       [UIColor blueColor], 
                       [UIColor redColor], 
                       [UIColor greenColor], 
                       [UIColor yellowColor], 
                       [UIColor magentaColor], 
                       [UIColor brownColor], 
                       [UIColor purpleColor], 
                       [UIColor orangeColor], 
                       nil];
    NSUInteger colorIndex = arc4random_uniform([colors count]);
    return [colors objectAtIndex:colorIndex];
}

+ (CGFloat) randomLineWidth
{
    uint32_t maxLineWidth = 15;
    CGFloat lineWidth = arc4random_uniform(maxLineWidth) + 1.0f; // avoid lineWidth == 0.0f
    return lineWidth;
}

+ (UIBezierPath *) houseInRect:(CGRect)bounds
{
    CGPoint bottomLeft 	= CGPointMake(CGRectGetMinX(bounds), CGRectGetMinY(bounds));
    CGPoint topLeft		= CGPointMake(CGRectGetMinX(bounds), CGRectGetMinY(bounds) + CGRectGetHeight(bounds) * 2.0f/3.0f);
    CGPoint bottomRight = CGPointMake(CGRectGetMaxX(bounds), CGRectGetMinY(bounds));
    CGPoint topRight	= CGPointMake(CGRectGetMaxX(bounds), CGRectGetMinY(bounds) + CGRectGetHeight(bounds) * 2.0f/3.0f);
    CGPoint roofTip		= CGPointMake(CGRectGetMidX(bounds), CGRectGetMaxY(bounds));
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:bottomLeft];
    [path addLineToPoint:topLeft];
    [path addLineToPoint:roofTip];
    [path addLineToPoint:topRight];
    [path addLineToPoint:topLeft];
    [path addLineToPoint:bottomRight];
    [path addLineToPoint:topRight];
    [path addLineToPoint:bottomLeft];
    [path addLineToPoint:bottomRight];
    
    path.lineJoinStyle = kCGLineJoinRound;

    CGAffineTransform transform = CGAffineTransformIdentity;
    transform = CGAffineTransformTranslate(transform, bounds.origin.x, bounds.origin.y);
    transform = CGAffineTransformTranslate(transform, 0.0, bounds.size.height);
    transform = CGAffineTransformScale(transform, 1.0f, -1.0f);
    transform = CGAffineTransformTranslate(transform, -bounds.origin.x, -bounds.origin.y);
    [path applyTransform:transform];
    
    return path;
}

+ (UIBezierPath *) arcInRect:(CGRect)bounds
{
    CGPoint center      = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
    CGPoint centerRight = CGPointMake(CGRectGetMaxX(bounds), CGRectGetMidY(bounds));
    CGFloat radius      = CGRectGetWidth(bounds) / 2.0f;
    CGPoint center2     = CGPointMake(center.x, center.y - radius / 2.0f);
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:centerRight];
    [path addArcWithCenter:center radius:radius startAngle:0.0f endAngle:M_PI * 1.5f clockwise:YES];
    [path addArcWithCenter:center2 radius:radius / 2.0f startAngle:M_PI * 1.5f endAngle:M_PI clockwise:YES];
    
    path.lineJoinStyle = kCGLineJoinRound;
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    transform = CGAffineTransformTranslate(transform, bounds.origin.x, bounds.origin.y);
    transform = CGAffineTransformTranslate(transform, 0.0, bounds.size.height);
    transform = CGAffineTransformScale(transform, 1.0f, -1.0f);
    transform = CGAffineTransformTranslate(transform, -bounds.origin.x, -bounds.origin.y);
    [path applyTransform:transform];
    
    return path;
}


+ (UIBezierPath *) text:(NSString *)text atPoint:(CGPoint)p
{
    UIFont *font = [UIFont fontWithName:@"Helvetica-Bold" size:60];

    UIBezierPath *textPath = [UIBezierPath pathFromString:text WithFont:font];
    CGAffineTransform transform = CGAffineTransformIdentity;
    transform = CGAffineTransformTranslate(transform, p.x, p.y);
    transform = CGAffineTransformScale(transform, 1.0f, -1.0f);
    [textPath applyTransform:transform];

    return textPath;
}
@end
