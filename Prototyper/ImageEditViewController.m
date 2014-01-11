//
//  ImageEditViewController.m
//  Prototyper
//
//  Created by Andy Qua on 09/01/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

#import "ImageEditViewController.h"

typedef struct {
    CGPoint dragStart;
    CGPoint topLeftCenter;
    CGPoint bottomLeftCenter;
    CGPoint bottomRightCenter;
    CGPoint topRightCenter;
    CGPoint clearAreaCenter;
} DragPoint;


CGRect SquareCGRectAtCenter(CGFloat centerX, CGFloat centerY, CGFloat size) {
    CGFloat x = centerX - size / 2.0;
    CGFloat y = centerY - size / 2.0;
    return CGRectMake(x, y, size, size);
}


#pragma mark ControlPointView implementation

@implementation ControlPointView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.color = [UIColor colorWithRed:18.0/255.0 green:173.0/255.0 blue:251.0/255.0 alpha:1];
        self.opaque = NO;
    }
    return self;
}

- (void)setColor:(UIColor *)_color {
    [_color getRed:&red green:&green blue:&blue alpha:&alpha];
    [self setNeedsDisplay];
}

- (UIColor*)color {
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextClearRect(context, rect);
    CGContextSetRGBFillColor(context, red, green, blue, alpha);
    CGContextFillEllipseInRect(context, rect);
}

@end

#pragma mark - MaskView implementation

@implementation ShadeView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.opaque = NO;
    }
    return self;
}

- (void)setCropBorderColor:(UIColor *)_color {
    [_color getRed:&cropBorderRed green:&cropBorderGreen blue:&cropBorderBlue alpha:&cropBorderAlpha];
    [self setNeedsDisplay];
}

- (UIColor*)cropBorderColor {
    return [UIColor colorWithRed:cropBorderRed green:cropBorderGreen blue:cropBorderBlue alpha:cropBorderAlpha];
}

- (void)setCropArea:(CGRect)_clearArea {
    cropArea = _clearArea;
    [self setNeedsDisplay];
}

- (CGRect)cropArea {
    return cropArea;
}

- (void)setShadeAlpha:(CGFloat)_alpha {
    shadeAlpha = cropBorderAlpha;
    [self setNeedsDisplay];
}

- (CGFloat)shadeAlpha {
    return shadeAlpha;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextClearRect(context, rect);
    
    CGContextSetRGBFillColor(context, cropBorderRed, cropBorderGreen, cropBorderBlue, 0.2);
    CGContextFillRect(context, rect);
    
    CGContextSetRGBStrokeColor(context, cropBorderRed, cropBorderGreen, cropBorderBlue, cropBorderAlpha);
    CGContextSetLineWidth(context, 2);
    CGRect r = CGRectInset(rect, 1, 1);
    CGContextStrokeRect(context, r);
    
}

@end


@interface ImageEditViewController ()
{
    ShadeView* shadeView;
    CGFloat imageScale;
    
    CGFloat controlPointSize;
    ControlPointView* topLeftPoint;
    ControlPointView* bottomLeftPoint;
    ControlPointView* bottomRightPoint;
    ControlPointView* topRightPoint;

    UIColor *_controlColor;
    DragPoint dragPoint;
    UIView *dragControl;


}
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation ImageEditViewController

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

    self.imageView.image = [UIImage imageWithContentsOfFile:self.imageDetails.imagePath];

    // Add existing rects
    for ( ImageLinks *link in self.imageDetails.links )
    {
        // Add view
        ShadeView *view = [[ShadeView alloc] initWithFrame:link.rect];
        view.cropBorderColor = [UIColor greenColor];
        [self.view addSubview:view];
    }
    
    [self setupCaptureRect];
    
    self.controlColor = [UIColor redColor];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) setupCaptureRect
{
    //control points
    controlPointSize = 15;
    int initialClearAreaSize = self.view.frame.size.width / 5;
    CGPoint centerInView = CGPointMake(self.view.bounds.size.width / 2, self.view.bounds.size.height / 2);
    
    CGRect r = SquareCGRectAtCenter(centerInView.x - initialClearAreaSize,
                                    centerInView.y - initialClearAreaSize,
                                    controlPointSize);
    topLeftPoint = [[ControlPointView alloc] initWithFrame:r];
    
    r = SquareCGRectAtCenter(centerInView.x + initialClearAreaSize,
                             centerInView.y - initialClearAreaSize,
                             controlPointSize);
    topRightPoint = [[ControlPointView alloc] initWithFrame:r];

    r = SquareCGRectAtCenter(centerInView.x - initialClearAreaSize,
                             centerInView.y + initialClearAreaSize,
                             controlPointSize);
    bottomLeftPoint = [[ControlPointView alloc] initWithFrame:r];

    r = SquareCGRectAtCenter(centerInView.x + initialClearAreaSize,
                             centerInView.y + initialClearAreaSize,
                             controlPointSize);
    bottomRightPoint = [[ControlPointView alloc] initWithFrame:r];

    CGRect cropArea = [self clearAreaFromControlPoints];
    
    //the shade
    shadeView = [[ShadeView alloc] initWithFrame:cropArea];
    
    UIPanGestureRecognizer* dragRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleDrag:)];
    [self.view addGestureRecognizer:dragRecognizer];
    
    [self.view addSubview:shadeView];
    [self.view addSubview:topRightPoint];
    [self.view addSubview:bottomRightPoint];
    [self.view addSubview:topLeftPoint];
    [self.view addSubview:bottomLeftPoint];
    
}


- (CGRect)clearAreaFromControlPoints {
    CGFloat width = topRightPoint.center.x - topLeftPoint.center.x;
    CGFloat height = bottomRightPoint.center.y - topRightPoint.center.y;
    CGRect hole = CGRectMake(topLeftPoint.center.x, topLeftPoint.center.y, width, height);
    return hole;
}


- (UIColor *) controlColor
{
    return _controlColor;
}

- (void) setControlColor:(UIColor *)_color
{
    _controlColor = _color;
    shadeView.cropBorderColor = _color;
    topLeftPoint.color = _color;
    bottomLeftPoint.color = _color;
    bottomRightPoint.color = _color;
    topRightPoint.color = _color;
}

- (IBAction)backPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^{}];
}

- (IBAction) saveRectPressed
{
    // Create Rect
    CGRect rect = [self clearAreaFromControlPoints];
    ImageLinks *link = [ImageLinks new];
    link.rect = rect;
    
    [self.imageDetails.links addObject:link];
    
    // Add view
    ShadeView *view = [[ShadeView alloc] initWithFrame:rect];
    view.cropBorderColor = [UIColor greenColor];
    [self.view addSubview:view];
}


#pragma mark - Dragging

- (CGRect)boundingBoxForTopLeft:(CGPoint)topLeft bottomLeft:(CGPoint)bottomLeft bottomRight:(CGPoint)bottomRight topRight:(CGPoint)topRight {
    CGFloat width = topRight.x - topLeft.x + controlPointSize;
    CGFloat height = bottomRight.y - topRight.y + controlPointSize;
    CGRect box = CGRectMake(topLeft.x - controlPointSize / 2, topLeft.y - controlPointSize / 2, width, height);
    return box;
}

- (void)handleDrag:(UIPanGestureRecognizer*)recognizer {
    if (recognizer.state==UIGestureRecognizerStateBegan) {
        dragPoint.dragStart = [recognizer locationInView:self.view];
        dragPoint.topLeftCenter = topLeftPoint.center;
        dragPoint.bottomLeftCenter = bottomLeftPoint.center;
        dragPoint.bottomRightCenter = bottomRightPoint.center;
        dragPoint.topRightCenter = topRightPoint.center;
        dragPoint.clearAreaCenter = shadeView.center;
        
        CGRect dragPointRect;
        dragPointRect.origin = CGPointMake( dragPoint.dragStart.x-10, dragPoint.dragStart.y-10 );

        dragPointRect.size = CGSizeMake( 20, 20 );
        if ( CGRectIntersectsRect( topLeftPoint.frame, dragPointRect ) )
            dragControl = topLeftPoint;
        else if ( CGRectIntersectsRect(topRightPoint.frame, dragPointRect ) )
            dragControl = topRightPoint;
        else if ( CGRectIntersectsRect(bottomLeftPoint.frame, dragPointRect ) )
            dragControl = bottomLeftPoint;
        else if ( CGRectIntersectsRect(bottomRightPoint.frame, dragPointRect ) )
            dragControl = bottomRightPoint;
        else if ( CGRectIntersectsRect(shadeView.frame, dragPointRect ) )
            dragControl = shadeView;
        return;
    }
    
    if (recognizer.state==UIGestureRecognizerStateEnded)
    {
        dragControl = nil;
    }
    
    CGPoint location = [recognizer locationInView:self.view];
    if (dragControl==topLeftPoint) {
        [self handleDragTopLeft:location];
    }
    else if (dragControl==bottomLeftPoint) {
        [self handleDragBottomLeft:location];
    }
    else if (dragControl==bottomRightPoint) {
        [self handleDragBottomRight:location];
    }
    else if (dragControl==topRightPoint) {
        [self handleDragTopRight:location];
    }
    else if (dragControl==shadeView) {
        [self handleDragClearArea:location];
    }
    
    CGRect clearArea = [self clearAreaFromControlPoints];
    shadeView.frame = clearArea;
    
    [shadeView setNeedsDisplay];
}

- (CGSize)deriveDisplacementFromDragLocation:(CGPoint)dragLocation draggedPoint:(CGPoint)draggedPoint oppositePoint:(CGPoint)oppositePoint {
    CGFloat dX = dragLocation.x - dragPoint.dragStart.x;
    CGFloat dY = dragLocation.y - dragPoint.dragStart.y;
    CGPoint tempDraggedPoint = CGPointMake(draggedPoint.x + dX, draggedPoint.y + dY);
    CGFloat width = (tempDraggedPoint.x - oppositePoint.x);
    CGFloat height = (tempDraggedPoint.y - oppositePoint.y);
    CGFloat sizeW = width;
    CGFloat sizeH = height;
    CGFloat xDir = draggedPoint.x<=oppositePoint.x ? 1 : -1;
    CGFloat yDir = draggedPoint.y<=oppositePoint.y ? 1 : -1;
    CGFloat newX = 0, newY = 0;
    if (xDir>=0) {
        //on the right
        newX = oppositePoint.x - fabs(sizeW);
    }
    else {
        //on the left
        newX = oppositePoint.x + fabs(sizeW);
    }
    
    if (yDir>=0) {
        //on the top
        newY = oppositePoint.y - fabs(sizeH);
    }
    else {
        //on the bottom
        newY = oppositePoint.y + fabs(sizeH);
    }
    
    CGSize displacement = CGSizeMake(newX - draggedPoint.x, newY - draggedPoint.y);
    return displacement;
}

- (void)handleDragTopLeft:(CGPoint)dragLocation {
    CGSize disp = [self deriveDisplacementFromDragLocation:dragLocation draggedPoint:dragPoint.topLeftCenter oppositePoint:dragPoint.bottomRightCenter];
    CGPoint topLeft = CGPointMake(dragPoint.topLeftCenter.x + disp.width, dragPoint.topLeftCenter.y + disp.height);
    CGPoint topRight = CGPointMake(dragPoint.topRightCenter.x, dragPoint.topLeftCenter.y + disp.height);
    CGPoint bottomLeft = CGPointMake(dragPoint.bottomLeftCenter.x + disp.width, dragPoint.bottomLeftCenter.y);
    
    CGRect boundingBox = [self boundingBoxForTopLeft:topLeft bottomLeft:bottomLeft bottomRight:dragPoint.bottomRightCenter topRight:topRight];
    
    CGRect imageFrameInView = self.imageView.frame;
    if (CGRectContainsRect(imageFrameInView, boundingBox)) {
        topLeftPoint.center = topLeft;
        topRightPoint.center = topRight;
        bottomLeftPoint.center = bottomLeft;
    }
    
}
- (void)handleDragBottomLeft:(CGPoint)dragLocation {
    CGSize disp = [self deriveDisplacementFromDragLocation:dragLocation draggedPoint:dragPoint.bottomLeftCenter oppositePoint:dragPoint.topRightCenter];
    CGPoint bottomLeft = CGPointMake(dragPoint.bottomLeftCenter.x + disp.width, dragPoint.bottomLeftCenter.y + disp.height);
    CGPoint topLeft = CGPointMake(dragPoint.topLeftCenter.x + disp.width, dragPoint.topLeftCenter.y);
    CGPoint bottomRight = CGPointMake(dragPoint.bottomRightCenter.x, dragPoint.bottomRightCenter.y + disp.height);
    
    CGRect boundingBox = [self boundingBoxForTopLeft:topLeft bottomLeft:bottomLeft bottomRight:bottomRight topRight:dragPoint.topRightCenter];
    
    CGRect imageFrameInView = self.imageView.frame;
    if (CGRectContainsRect(imageFrameInView, boundingBox)) {
        bottomLeftPoint.center = bottomLeft;
        topLeftPoint.center = topLeft;
        bottomRightPoint.center = bottomRight;
    }
    
}

- (void)handleDragBottomRight:(CGPoint)dragLocation {
    CGSize disp = [self deriveDisplacementFromDragLocation:dragLocation draggedPoint:dragPoint.bottomRightCenter oppositePoint:dragPoint.topLeftCenter];
    CGPoint bottomRight = CGPointMake(dragPoint.bottomRightCenter.x + disp.width, dragPoint.bottomRightCenter.y + disp.height);
    CGPoint topRight = CGPointMake(dragPoint.topRightCenter.x + disp.width, dragPoint.topRightCenter.y);
    CGPoint bottomLeft = CGPointMake(dragPoint.bottomLeftCenter.x, dragPoint.bottomLeftCenter.y + disp.height);
    
    CGRect boundingBox = [self boundingBoxForTopLeft:dragPoint.topLeftCenter bottomLeft:bottomLeft bottomRight:bottomRight topRight:topRight];
    
    CGRect imageFrameInView = self.imageView.frame;
    if (CGRectContainsRect(imageFrameInView, boundingBox)) {
        bottomRightPoint.center = bottomRight;
        topRightPoint.center = topRight;
        bottomLeftPoint.center = bottomLeft;
    }
    
}

- (void)handleDragTopRight:(CGPoint)dragLocation {
    CGSize disp = [self deriveDisplacementFromDragLocation:dragLocation draggedPoint:dragPoint.topRightCenter oppositePoint:dragPoint.bottomLeftCenter];
    CGPoint topRight = CGPointMake(dragPoint.topRightCenter.x + disp.width, dragPoint.topRightCenter.y + disp.height);
    CGPoint topLeft = CGPointMake(dragPoint.topLeftCenter.x, dragPoint.topLeftCenter.y + disp.height);
    CGPoint bottomRight = CGPointMake(dragPoint.bottomRightCenter.x + disp.width, dragPoint.bottomRightCenter.y);
    
    CGRect boundingBox = [self boundingBoxForTopLeft:topLeft bottomLeft:dragPoint.bottomLeftCenter bottomRight:bottomRight topRight:topRight];
    
    CGRect imageFrameInView = self.imageView.frame;
    if (CGRectContainsRect(imageFrameInView, boundingBox)) {
        topRightPoint.center = topRight;
        topLeftPoint.center = topLeft;
        bottomRightPoint.center = bottomRight;
    }
    
    
}

- (void)handleDragClearArea:(CGPoint)dragLocation {
    CGFloat dX = dragLocation.x - dragPoint.dragStart.x;
    CGFloat dY = dragLocation.y - dragPoint.dragStart.y;
    
    CGPoint newTopLeft = CGPointMake(dragPoint.topLeftCenter.x + dX, dragPoint.topLeftCenter.y + dY);
    CGPoint newBottomLeft = CGPointMake(dragPoint.bottomLeftCenter.x + dX, dragPoint.bottomLeftCenter.y + dY);
    CGPoint newBottomRight = CGPointMake(dragPoint.bottomRightCenter.x + dX, dragPoint.bottomRightCenter.y + dY);
    CGPoint newTopRight = CGPointMake(dragPoint.topRightCenter.x + dX, dragPoint.topRightCenter.y + dY);
    
    CGFloat clearAreaWidth = dragPoint.topRightCenter.x - dragPoint.topLeftCenter.x;
    CGFloat clearAreaHeight = dragPoint.bottomLeftCenter.y - dragPoint.topLeftCenter.y;
    
    CGRect imageFrameInView = self.imageView.frame;

    CGFloat halfControlPointSize = controlPointSize / 2 + 1;
    CGFloat minX = imageFrameInView.origin.x + halfControlPointSize;
    CGFloat maxX = imageFrameInView.origin.x + imageFrameInView.size.width - halfControlPointSize;
    CGFloat minY = imageFrameInView.origin.y + halfControlPointSize;
    CGFloat maxY = imageFrameInView.origin.y + imageFrameInView.size.height - halfControlPointSize;
    
    if (newTopLeft.x<minX) {
        newTopLeft.x = minX;
        newBottomLeft.x = minX;
        newTopRight.x = newTopLeft.x + clearAreaWidth;
        newBottomRight.x = newTopRight.x;
    }
    
    if(newTopLeft.y<minY) {
        newTopLeft.y = minY;
        newTopRight.y = minY;
        newBottomLeft.y = newTopLeft.y + clearAreaHeight;
        newBottomRight.y = newBottomLeft.y;
    }
    
    if (newBottomRight.x>maxX) {
        newBottomRight.x = maxX;
        newTopRight.x = maxX;
        newTopLeft.x = newBottomRight.x - clearAreaWidth;
        newBottomLeft.x = newTopLeft.x;
    }
    
    if (newBottomRight.y>maxY) {
        newBottomRight.y = maxY;
        newBottomLeft.y = maxY;
        newTopRight.y = newBottomRight.y - clearAreaHeight;
        newTopLeft.y = newTopRight.y;
    }
    topLeftPoint.center = newTopLeft;
    bottomLeftPoint.center = newBottomLeft;
    bottomRightPoint.center = newBottomRight;
    topRightPoint.center = newTopRight;
    
}


@end
