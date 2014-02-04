//
//  Shape.h
//  PathHitTesting
//
//  Created by Ole Begemann on 30.01.12.
//  Copyright (c) 2012 Ole Begemann. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    ShapeTypeRect,
    ShapeTypeEllipse,
    ShapeTypeHouse,
    ShapeTypeArc,
    SHAPE_TYPE_COUNT
} ShapeType;


@interface Shape : NSObject

+ (instancetype) randomShapeInBounds:(CGRect)maxBounds;
+ (instancetype) shapeOfType:(ShapeType)type inBounds:(CGRect)bounds lineWidth:(CGFloat)width color:(UIColor *)color;
+ (instancetype) shape;
+ (instancetype) shapeWithText:(NSString *)text atPoint:(CGPoint)p;
+ (instancetype) shapeWithPath:(UIBezierPath *)path lineColor:(UIColor *)lineColor;
- (instancetype) initWithPath:(UIBezierPath *)path lineColor:(UIColor *)lineColor;

- (BOOL) containsPoint:(CGPoint)point;
- (void) moveBy:(CGPoint)delta;
- (void) applyTransform:(CGAffineTransform)transform;

@property (nonatomic, strong) UIBezierPath *path;
@property (nonatomic, strong) UIBezierPath *tapTargetPath;
@property (nonatomic, strong) UIColor *lineColor;
@property (nonatomic, readonly) bool shouldFill;
@property (nonatomic, assign, readonly) CGRect totalBounds;

@end
