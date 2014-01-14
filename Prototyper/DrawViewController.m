//
//  DrawViewController.m
//  Prototyper
//
//  Created by Andy Qua on 13/01/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

#import "DrawViewController.h"
#import "DrawView.h"
#import "Project.h"
#import "Shape.h"


static CGPoint midpoint(CGPoint p0, CGPoint p1)
{
    return (CGPoint) {
        (p0.x + p1.x) / 2.0,
        (p0.y + p1.y) / 2.0
    };
}


@interface DrawViewController () <UIAlertViewDelegate>
{
    CGPoint previousPoint;
    DrawStates state;
    
    UIBezierPath *path;
    bool addingText;
    CGPoint textPoint;
}

@property (nonatomic, strong) NSMutableArray *shapes;
@property (nonatomic, assign) NSUInteger selectedShapeIndex;
@property (nonatomic, readonly) Shape *selectedShape;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet DrawView *drawView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segDraw;

- (void)addShape:(Shape *)newShape;
- (NSUInteger)hitTest:(CGPoint)point;

@end

@implementation DrawViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    state = DRAW;

    self.imageView.image = self.image;
    
    _selectedShapeIndex = NSNotFound;
    self.shapes = [NSMutableArray array];
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapDetected:)];
    [self.drawView addGestureRecognizer:tapRecognizer];

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    pan.maximumNumberOfTouches = pan.minimumNumberOfTouches = 1;
    [self.drawView addGestureRecognizer:pan];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)undoPressed:(id)sender
{
//    [self.drawView undoButtonPressed];
}

- (IBAction)segDrawChanged:(id)sender
{
    if ( self.segDraw.selectedSegmentIndex == 0 )
        state = DRAW;
    if ( self.segDraw.selectedSegmentIndex == 1 )
        state = ERASE;
    if ( self.segDraw.selectedSegmentIndex == 2 )
        state = MOVE;
}

- (IBAction) addTextPressed:(id)sender
{
    // Wait for tap
    addingText = YES;
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ( [segue.identifier isEqualToString:@"unwind"] )
    {
        [self setSelectedShapeIndex:NSNotFound];
        
        // Take screenshot
        UIImage *image = [self snapshotView];
        
        [self.delegate drawImageChanged:image];
    }
}

- (UIImage *) snapshotView
{
    UIImage* image = nil;
    
    UIGraphicsBeginImageContext(self.drawView.frame.size);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    {
        [[UIColor whiteColor] setFill];
        CGContextFillRect( UIGraphicsGetCurrentContext(), self.drawView.frame );
        [self.imageView.layer renderInContext: ctx];
        [self.drawView.layer renderInContext: ctx];
        image = UIGraphicsGetImageFromCurrentImageContext();
    }
    UIGraphicsEndImageContext();
    
    return image;
}


- (void)tapDetected:(UITapGestureRecognizer *)tapRecognizer
{
    CGPoint tapLocation = [tapRecognizer locationInView:self.drawView];
    
    if ( !addingText )
    {
        self.selectedShapeIndex = [self hitTest:tapLocation];
    }
    else
    {
        addingText = NO;
        
        textPoint = tapLocation;
        // Ask what text to add
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Enter text to draw" message:@"" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
        alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
        [alertView show];
    }
}

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ( buttonIndex == 1 )
    {
        // Add Text
        NSString *text = [[alertView textFieldAtIndex:0] text];
        Shape *shape = [Shape shapeWithText:text atPoint:textPoint];
        [self addShape:shape];
    }
}

- (void)pan:(UIPanGestureRecognizer *)pan
{
    CGPoint currentPoint = [pan locationInView:self.drawView];
    CGPoint midPoint = midpoint(previousPoint, currentPoint);
    
    if (pan.state == UIGestureRecognizerStateBegan)
    {
        if ( state == DRAW || state == ERASE )
        {
            path = [UIBezierPath bezierPath];
            path.lineWidth = 5;
            
            [path moveToPoint:currentPoint];
            self.drawView.tmpPath = path;
            self.drawView.tmpPathColor = state == DRAW ? [UIColor blackColor] : [UIColor whiteColor];
        }
        else
        {
            CGPoint tapLocation = [pan locationInView:self.drawView];
            self.selectedShapeIndex = [self hitTest:tapLocation];
        }
    }
    else if (pan.state == UIGestureRecognizerStateChanged)
    {
        if ( state == DRAW || state == ERASE )
            [path addQuadCurveToPoint:midPoint controlPoint:previousPoint];
        else
        {
            CGPoint translation = [pan translationInView:self.drawView];
            CGRect originalBounds = self.selectedShape.totalBounds;
            CGRect newBounds = CGRectApplyAffineTransform(originalBounds, CGAffineTransformMakeTranslation(translation.x, translation.y));
            CGRect rectToRedraw = CGRectUnion(originalBounds, newBounds);
            
            [self.selectedShape moveBy:translation];
            [self.drawView reloadDataInRect:rectToRedraw];
            [pan setTranslation:CGPointZero inView:self.drawView];
        }
    }
    else if (pan.state == UIGestureRecognizerStateEnded)
    {
        if ( state == DRAW || state == ERASE )
        {
            Shape *pathShape = [Shape shapeWithPath:path lineColor:state == DRAW ? [UIColor blackColor] : [UIColor whiteColor]];
            [self addShape:pathShape];
            
            self.drawView.tmpPath = nil;

        }
    }
    previousPoint = currentPoint;
    
    [self.drawView setNeedsDisplay];
}

- (void)addShape:(Shape *)newShape
{
    [self.shapes addObject:newShape];
    [self.drawView reloadDataInRect:newShape.totalBounds];
}

- (void) deleteShape:(id)sender
{
    if (self.selectedShapeIndex == NSNotFound) {
        return;
    }
    
    CGRect rectToRedraw = self.selectedShape.totalBounds;
    [self.shapes removeObjectAtIndex:self.selectedShapeIndex];
    self.selectedShapeIndex = NSNotFound;
    [self.drawView reloadDataInRect:rectToRedraw];
}

- (void)setSelectedShapeIndex:(NSUInteger)selectedShapeIndex
{
    CGRect oldSelectionBounds = CGRectZero;
    if (_selectedShapeIndex < [self.shapes count]) {
        oldSelectionBounds = self.selectedShape.totalBounds;
    }
    _selectedShapeIndex = selectedShapeIndex;
    CGRect newSelectionBounds = self.selectedShape.totalBounds;
    CGRect rectToRedraw = CGRectUnion(oldSelectionBounds, newSelectionBounds);
    [self.drawView setNeedsDisplayInRect:rectToRedraw];
    
    if ( _selectedShapeIndex != NSNotFound )
    {
        UIBarButtonItem *btnErase = [[UIBarButtonItem alloc] initWithTitle:@"Remove" style:UIBarButtonItemStyleBordered target:self action:@selector(deleteShape:)];
        self.navigationItem.rightBarButtonItem = btnErase;
    }
    else
        self.navigationItem.rightBarButtonItem = nil;
}

- (Shape *)selectedShape
{
    if (_selectedShapeIndex == NSNotFound) {
        return nil;
    }
    return [self.shapes objectAtIndex:_selectedShapeIndex];
}

#pragma mark - Hit Testing

- (NSUInteger)hitTest:(CGPoint)point
{
    __block NSUInteger hitShapeIndex = NSNotFound;
    [self.shapes enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id shape, NSUInteger idx, BOOL *stop) {
        if ([shape containsPoint:point]) {
            hitShapeIndex = idx;
            *stop = YES;
        }
    }];
    return hitShapeIndex;
}

#pragma mark - DrawingViewDataSource

- (NSUInteger)numberOfShapesInDrawingView:(DrawView *)drawingView
{
    return [self.shapes count];
}

- (UIBezierPath *)drawingView:(DrawView *)drawingView pathForShapeAtIndex:(NSUInteger)shapeIndex
{
    Shape *shape = [self.shapes objectAtIndex:shapeIndex];
    return shape.path;
}

- (UIColor *)drawingView:(DrawView *)drawingView lineColorForShapeAtIndex:(NSUInteger)shapeIndex
{
    Shape *shape = [self.shapes objectAtIndex:shapeIndex];
    return shape.lineColor;
}

- (BOOL) drawingView:(DrawView *)drawingView shouldFillShapeAtIndex:(NSUInteger)shapeIndex;
{
    Shape *shape = [self.shapes objectAtIndex:shapeIndex];
    return shape.shouldFill;
}

- (NSUInteger)indexOfSelectedShapeInDrawingView:(DrawView *)drawingView
{
    return self.selectedShapeIndex;
}

@end
