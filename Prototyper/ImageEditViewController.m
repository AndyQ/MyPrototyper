//
//  ImageEditViewController.m
//  Prototyper
//
//  Created by Andy Qua on 09/01/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

// Uses code based on iOS-Image-Crop-View by Ming Yang (https://github.com/myang-git/iOS-Image-Crop-View)

#import "ImageEditViewController.h"
#import "LinkImageViewController.h"
#import "ImageEditView.h"
#import "ShadeView.h"
#import "ControlPointView.h"

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





@interface ImageEditViewController () <ImageEditViewDelegate, LinkImageViewControllerDelegate, UIGestureRecognizerDelegate>
{
    ShadeView* shadeView;
    CGFloat imageScale;
    
    CGFloat controlPointSize;
    ControlPointView* topLeftPoint;
    ControlPointView* bottomLeftPoint;
    ControlPointView* bottomRightPoint;
    ControlPointView* topRightPoint;

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

    UIImage *image = [UIImage imageWithContentsOfFile:self.imageDetails.imagePath];
    [(ImageEditView *)self.view setImage:image];
    
    // Add existing rects
    for ( ImageLink *link in self.imageDetails.links )
    {
        // Add view
        ShadeView *view = [[ShadeView alloc] init];
        [view setAssociatedImageLink:link];
        
        [self.view addSubview:view];
    }
    
//    UIPanGestureRecognizer* dragRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleDrag:)];
//    [self.view addGestureRecognizer:dragRecognizer];

    UITapGestureRecognizer* tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    tapRecognizer.delegate = self;
    [self.view addGestureRecognizer:tapRecognizer];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ( [segue.identifier isEqualToString:@"showLinkToVC"] )
    {
        LinkImageViewController *vc = segue.destinationViewController;
        vc.delegate = self;
        vc.project = self.project;
        vc.currentImageId = self.imageDetails.imageName;
        vc.linkedId = shadeView.associatedImageLink.linkedToId;
    }
}


- (IBAction)unwindFromViewController:(UIStoryboardSegue *)segue
{
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(BOOL)canBecomeFirstResponder
{
    return YES;
}

-(BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    if(action == @selector(deleteView))
        return YES;
    else if(action == @selector(linkView))
        return YES;

    return NO;
}

- (void) showMenuFromRect:(CGRect)r
{
    UIMenuController *sharedController = [UIMenuController sharedMenuController];
    
    UIMenuItem *menuItem1 = [[UIMenuItem alloc] initWithTitle:@"Delete" action:@selector(deleteView)];
    UIMenuItem *menuItem2 = [[UIMenuItem alloc] initWithTitle:@"Link" action:@selector(linkView)];
    
    NSArray *menuItems = @[menuItem1, menuItem2];
    
    [sharedController setTargetRect:r inView:self.view];
    
    [sharedController setMenuItems:menuItems];
    [sharedController setMenuVisible:YES animated:YES];
    
    [sharedController setMenuItems:nil];

}

- (void) deleteView
{
    // Remove item from list
    [self.imageDetails.links removeObject:shadeView.associatedImageLink];
    
    // Delete shadeView
    [shadeView removeFromSuperview];
    shadeView = nil;
    
    [self showCaptureRect:NO];
}

- (void) linkView
{
    [self performSegueWithIdentifier:@"showLinkToVC" sender:self];
}


- (void) setupCaptureRect
{
    // Create points if necessary
    topLeftPoint = [[ControlPointView alloc] init];
    topRightPoint = [[ControlPointView alloc] init];
    bottomLeftPoint = [[ControlPointView alloc] init];
    bottomRightPoint = [[ControlPointView alloc] init];

    [self.view addSubview:topRightPoint];
    [self.view addSubview:bottomRightPoint];
    [self.view addSubview:topLeftPoint];
    [self.view addSubview:bottomLeftPoint];
    
    [self setControlPointsColor];
}

- (void) positionCaptureRect:(CGRect)r
{
    if ( topLeftPoint == nil )
        [self setupCaptureRect];
    
    controlPointSize = 15;

    r.origin.x -= controlPointSize/2;
    r.origin.y -= controlPointSize/2;
    CGPoint topLeft = CGPointMake( r.origin.x, r.origin.y );
    CGPoint topRight = CGPointMake( r.origin.x + r.size.width, r.origin.y );
    CGPoint bottomLeft = CGPointMake( r.origin.x, r.origin.y + r.size.height );
    CGPoint bottomRight = CGPointMake( r.origin.x + r.size.width, r.origin.y + r.size.height );
    CGSize size = CGSizeMake( controlPointSize, controlPointSize );

    

    topLeftPoint.frame = (CGRect){ .origin = topLeft, .size = size};
    topRightPoint.frame = (CGRect){ .origin = topRight, .size = size};
    bottomLeftPoint.frame = (CGRect){ .origin = bottomLeft, .size = size};
    bottomRightPoint.frame = (CGRect){ .origin = bottomRight, .size = size};
    
    [shadeView updateFrame:[self clearAreaFromControlPoints]];
    [shadeView setSelected:YES];
}


- (CGRect)clearAreaFromControlPoints {
    CGFloat width = topRightPoint.center.x - topLeftPoint.center.x;
    CGFloat height = bottomRightPoint.center.y - topRightPoint.center.y;
    CGRect hole = CGRectMake(topLeftPoint.center.x, topLeftPoint.center.y, width, height);
    return hole;
}


- (void) setControlPointsColor
{
    UIColor *color = [shadeView getColor];
    
//    [(ImageEditView *)self.view setColor:color];
    topLeftPoint.color = color;
    bottomLeftPoint.color = color;
    bottomRightPoint.color = color;
    topRightPoint.color = color;
}


- (IBAction) addCaptureRectPressed
{
    if ( shadeView )
        [shadeView setSelected:NO];
    
    ImageLink *link = [ImageLink new];
    [self.imageDetails.links addObject:link];

    shadeView = [[ShadeView alloc] init];
    shadeView.associatedImageLink = link;
    [self.view addSubview:shadeView];


    CGRect r = CGRectMake( self.view.bounds.size.width / 2, self.view.bounds.size.height / 2, self.view.frame.size.width / 5, self.view.frame.size.width / 5 );
    [self positionCaptureRect:r];

    [self showCaptureRect:YES];
}



- (void) showCaptureRect:(bool)show
{
    [self setControlPointsColor];

    shadeView.hidden = !show;
    topLeftPoint.hidden = !show;
    bottomLeftPoint.hidden = !show;
    bottomRightPoint.hidden = !show;
    topRightPoint.hidden = !show;
    
    if ( show )
    {
        [self showMenuFromRect:shadeView.frame];
    }
}


- (void) selectAreaUpdate:(CGRect)r
{
    shadeView.frame = r;
    [self showMenuFromRect:shadeView.frame];

}
#pragma mark - Tapping


- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    
    //ignore any touches from a UIToolbar
    
    if ([touch.view.superview isKindOfClass:[UIToolbar class]]) {
        return NO;
    }
    
    return YES;
}
- (void) handleTap:(UITapGestureRecognizer*)recognizer
{
    if (recognizer.state==UIGestureRecognizerStateEnded)
    {
        CGPoint p = [recognizer locationInView:self.view];
        UIView* v = [self.view hitTest:p withEvent:nil];

        if ( v != nil )
        {
            [shadeView setSelected:NO];
            shadeView = nil;
            if ( [v isKindOfClass:[ShadeView class]] )
            {
                shadeView = (ShadeView *)v;
                [shadeView setSelected:YES];
                [self showCaptureRect:YES];
                [self positionCaptureRect:shadeView.frame];
            }
        }
        
        if ( shadeView == nil )
        {
            [self showCaptureRect:NO];
        }
    }
}

#pragma mark - LinkImageViewController delegate

- (void) LIVC_didSelectImage:(NSString *)imageId
{
    shadeView.associatedImageLink.linkedToId = imageId;
    [shadeView setNeedsDisplay];
    [self setControlPointsColor];
}

#pragma mark - Dragging

- (CGRect)boundingBoxForTopLeft:(CGPoint)topLeft bottomLeft:(CGPoint)bottomLeft bottomRight:(CGPoint)bottomRight topRight:(CGPoint)topRight {
    CGFloat width = topRight.x - topLeft.x + controlPointSize;
    CGFloat height = bottomRight.y - topRight.y + controlPointSize;
    CGRect box = CGRectMake(topLeft.x - controlPointSize / 2, topLeft.y - controlPointSize / 2, width, height);
    return box;
}

- (void)handleDrag:(UIPanGestureRecognizer*)recognizer
{
    if (recognizer.state==UIGestureRecognizerStateBegan)
    {
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
        if ( shadeView != nil )
            [self showMenuFromRect:shadeView.frame];
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
    [shadeView updateFrame:clearArea];
    
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
        if ( sizeW > -20 )
            sizeW = -20;
        newX = oppositePoint.x - fabs(sizeW);
    }
    else {
        //on the left
        if ( sizeW < 20 )
            sizeW = 20;
        newX = oppositePoint.x + fabs(sizeW);
    }
    if (yDir>=0) {
        //on the top
        if ( sizeH > -20 )
            sizeH = -20;
        newY = oppositePoint.y - fabs(sizeH);
    }
    else {
        //on the bottom
        if ( sizeH < 20 )
            sizeH = 20;
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
    if (CGRectContainsRect(imageFrameInView, boundingBox))
    {
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
