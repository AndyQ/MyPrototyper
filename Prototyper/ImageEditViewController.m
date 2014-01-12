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

@interface ImageEditViewController () <ImageEditViewDelegate, LinkImageViewControllerDelegate, UIGestureRecognizerDelegate>
{
    ShadeView* shadeView;
    CGFloat imageScale;
    
    CGFloat controlPointSize;
    ControlPointView* topLeftPoint;
    ControlPointView* bottomLeftPoint;
    ControlPointView* bottomRightPoint;
    ControlPointView* topRightPoint;

    UIView *dragControl;
}

@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *toolbarBottomConstraint;

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

    UITapGestureRecognizer* tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    tapRecognizer.delegate = self;
//    [self.view addGestureRecognizer:tapRecognizer];
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
    
    [(ImageEditView *)self.view hideSelectArea];
}

- (void) linkView
{
    [self performSegueWithIdentifier:@"showLinkToVC" sender:self];
}


- (void) positionCaptureRect:(CGRect)r
{
    [(ImageEditView *)self.view showSelectArea:r];
    [shadeView updateFrame:r];
    [shadeView setSelected:YES];
}



- (void) setControlPointsColor
{
    UIColor *color = [shadeView getColor];
    
    [(ImageEditView *)self.view setColor:color];
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

    if ( show )
    {
        [self showMenuFromRect:shadeView.frame];
    }
    else
    {
        [(ImageEditView *)self.view hideSelectArea];
    }
}


- (void) selectAreaUpdate:(CGRect)r
{
    [shadeView updateFrame:r];
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

- (void) touchedViewAtPoint:(CGPoint)p
{
    UIView* v = [self.view hitTest:p withEvent:nil];
    
    bool maybeHideOrShowNavBar = NO;
    if ( shadeView == nil )
    {
        maybeHideOrShowNavBar = YES;
    }
    
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
        [(ImageEditView *)self.view hideSelectArea];
        [self showCaptureRect:NO];
        
        if ( maybeHideOrShowNavBar )
        {
            // Toggle navigation bar hidden
            BOOL hide = ![self.navigationController isNavigationBarHidden];
            [self.navigationController setNavigationBarHidden:hide animated:YES];
            [UIView animateWithDuration:0.15 animations:^{
                
                if ( hide )
                    self.toolbarBottomConstraint.constant = -self.toolbar.frame.size.height;
                else
                    self.toolbarBottomConstraint.constant = 0;
                
                [self.view layoutIfNeeded];
            }];
        }
        
    }
}

- (void) handleTap:(UITapGestureRecognizer*)recognizer
{
    if (recognizer.state==UIGestureRecognizerStateEnded)
    {
        CGPoint p = [recognizer locationInView:self.view];
        UIView* v = [self.view hitTest:p withEvent:nil];

        bool maybeHideOrShowNavBar = NO;
        if ( shadeView == nil )
        {
            maybeHideOrShowNavBar = YES;
        }
        
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
            [(ImageEditView *)self.view hideSelectArea];
            [self showCaptureRect:NO];
            
            if ( maybeHideOrShowNavBar )
            {
                // Toggle navigation bar hidden
                BOOL hide = ![self.navigationController isNavigationBarHidden];
                [self.navigationController setNavigationBarHidden:hide animated:YES];
                [UIView animateWithDuration:0.15 animations:^{
                    
                    if ( hide )
                        self.toolbarBottomConstraint.constant = -self.toolbar.frame.size.height;
                    else
                        self.toolbarBottomConstraint.constant = 0;
                    
                    [self.view layoutIfNeeded];
                }];
            }
            
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

@end
