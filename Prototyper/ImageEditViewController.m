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
#import "DrawViewController.h"
#import "ImageEditView.h"
#import "HotspotView.h"

@interface ImageEditViewController () <DrawViewControllerDelegate, ImageEditViewDelegate, LinkImageViewControllerDelegate, UIGestureRecognizerDelegate>
{
    HotspotView* shadeView;
}

@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *toolbarBottomConstraint;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *editImageButton;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet ImageEditView *imageEditView;

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
    self.imageView.image = image;
    
    // Add existing rects
    for ( ImageLink *link in self.imageDetails.links )
    {
        // Add view
        HotspotView *view = [[HotspotView alloc] init];
        [view setAssociatedImageLink:link];
        
        [self.imageEditView addSubview:view];
    }
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
    
    if ( [segue.identifier isEqualToString:@"ShowDraw"] )
    {
        UINavigationController *nc = segue.destinationViewController;
        DrawViewController *vc = (DrawViewController *)nc.topViewController;
        vc.delegate = self;
        UIImage *image = [UIImage imageWithContentsOfFile:self.imageDetails.imagePath];
        vc.image = image;
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

#pragma mark - UIMenuController stuff
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
    
    [self.imageEditView hideSelectArea];
}

- (void) linkView
{
    [self performSegueWithIdentifier:@"showLinkToVC" sender:self];
}


#pragma mark - Hotspot area management
- (void) positionHotspotArea:(CGRect)r
{
    [self.imageEditView showSelectArea:r];
    [shadeView updateFrame:r];
    [shadeView setSelected:YES];
}



- (void) updateLinkColor
{
    UIColor *color = [shadeView getColor];
    [self.imageEditView setColor:color];
}


- (IBAction) addCaptureRectPressed
{
    if ( shadeView )
        [shadeView setSelected:NO];
    
    ImageLink *link = [ImageLink new];
    [self.imageDetails.links addObject:link];

    shadeView = [[HotspotView alloc] init];
    shadeView.associatedImageLink = link;
    [self.imageEditView addSubview:shadeView];


    CGRect r = CGRectMake( self.view.bounds.size.width / 2, self.view.bounds.size.height / 2, self.view.frame.size.width / 5, self.view.frame.size.width / 5 );
    [self positionHotspotArea:r];

    [self showCaptureRect:YES];
}



- (void) showCaptureRect:(bool)show
{
    [self updateLinkColor];

    if ( show )
    {
        [self showMenuFromRect:shadeView.frame];
    }
    else
    {
        [self.imageEditView hideSelectArea];
    }
}



#pragma mark - Tapping


- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    
    //ignore any touches from a UIToolbar
    
    if ([touch.view.superview isKindOfClass:[UIToolbar class]])
    {
        return NO;
    }
    
    return YES;
}

#pragma mark - ImageEditViewDelegate methods

// User has modified the current hotspot area
- (void) hotspotAreaUpdate:(CGRect)r
{
    [shadeView updateFrame:r];
    [self showMenuFromRect:shadeView.frame];
    
}

// User has tapped the view outside the current hotspot area
- (void) touchedViewAtPoint:(CGPoint)p
{
    UIView* v = [self.view hitTest:p withEvent:nil];
    
    // Check if we currently have a hotspot selected, if not, then we may be toggling showing/hiding the NavBar 
    bool maybeHideOrShowNavBar = NO;
    if ( shadeView == nil )
    {
        maybeHideOrShowNavBar = YES;
    }
    
    if ( v != nil )
    {
        [shadeView setSelected:NO];
        shadeView = nil;
        if ( [v isKindOfClass:[HotspotView class]] )
        {
            shadeView = (HotspotView *)v;
            [shadeView setSelected:YES];
            [self showCaptureRect:YES];
            [self positionHotspotArea:shadeView.frame];
        }
    }
    
    if ( shadeView == nil )
    {
        [self.imageEditView hideSelectArea];
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

#pragma mark - LinkImageViewController delegate

- (void) LIVC_didSelectImage:(NSString *)imageId
{
    shadeView.associatedImageLink.linkedToId = imageId;
    [shadeView setNeedsDisplay];
    [self updateLinkColor];
}

#pragma mark - DrawViewControllerDelegateMethods
- (void) drawImageChanged:(UIImage *)image
{
    // Save image
    bool rc = [UIImagePNGRepresentation(image) writeToFile:self.imageDetails.imagePath atomically:YES];
    if ( !rc )
        NSLog( @"Failed");

    self.imageView.image = image;
}


@end
