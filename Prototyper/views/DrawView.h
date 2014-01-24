//
//  DrawView.h
//  Prototyper
//
//  Created by Andy Qua on 13/01/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum DrawStates
{
    DRAW_FREEHAND = 0,
    DRAW_TEXT,
    DRAW_RECT,
    DRAW_OVAL
    
} DrawStates;


@protocol DrawViewDataSource;

@interface DrawView : UIView

@property (nonatomic, weak) IBOutlet id <DrawViewDataSource> dataSource;
@property (nonatomic, strong) UIColor *tmpPathColor;
@property (nonatomic, strong) UIBezierPath *tmpPath;

- (void)reloadData;
- (void)reloadDataInRect:(CGRect)rect;

@end


@protocol DrawViewDataSource <NSObject>

@required
- (NSUInteger) numberOfShapesInDrawingView:(DrawView *)drawingView;
- (UIBezierPath *) drawingView:(DrawView *)drawingView pathForShapeAtIndex:(NSUInteger)shapeIndex;
- (UIColor *) drawingView:(DrawView *)drawingView lineColorForShapeAtIndex:(NSUInteger)shapeIndex;
- (BOOL) drawingView:(DrawView *)drawingView shouldFillShapeAtIndex:(NSUInteger)shapeIndex;

@optional
- (NSUInteger)indexOfSelectedShapeInDrawingView:(DrawView *)drawingView;

@end
