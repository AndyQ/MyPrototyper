//
//  ImageEditViewController.m
//  Prototyper
//
//  Created by Andy Qua on 09/01/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

#import "ImageEditViewController.h"
#import "LinkImageViewController.h"
#import "DrawViewController.h"
#import "ImageEditView.h"
#import "HotspotView.h"
#import "PopoverView.h"

@interface ImageEditViewController () <DrawViewControllerDelegate, ImageEditViewDelegate, LinkImageViewControllerDelegate, UIActionSheetDelegate, UIGestureRecognizerDelegate, PopoverViewDelegate>
{
    HotspotView* shadeView;
    PopoverView *thePopoverView;
    CGPoint selectedPoint;
}

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageViewTopConstraint;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *toolbarBottomConstraint;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *editImageButton;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet ImageEditView *imageEditView;

@end

@implementation ImageEditViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
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

    [self setupView];
}

- (void) setupView
{
    [self.imageEditView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    shadeView = nil;
    [self showHotspotRect:NO];
    
    self.imageView.image = [self.imageDetails getImage];
    
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
        DrawViewController *vc = segue.destinationViewController;
        vc.delegate = self;
        UIImage *image = [self.imageDetails getImage];
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
    else if(action == @selector(transitionView))
        return YES;
    else if(action == @selector(gotoLink))
        return YES;

    return NO;
}

- (void) showMenuFromRect:(CGRect)r
{
    UIMenuController *sharedController = [UIMenuController sharedMenuController];
    
    UIMenuItem *menuItem1 = [[UIMenuItem alloc] initWithTitle:@"Delete" action:@selector(deleteView)];
    UIMenuItem *menuItem2 = [[UIMenuItem alloc] initWithTitle:@"Link" action:@selector(linkView)];
    UIMenuItem *menuItem3 = [[UIMenuItem alloc] initWithTitle:@"Transition" action:@selector(transitionView)];
    UIMenuItem *menuItem4 = [[UIMenuItem alloc] initWithTitle:@"Follow link" action:@selector(gotoLink)];
    
    NSMutableArray *menuItems = [@[menuItem1, menuItem2, menuItem3] mutableCopy];
    if ( shadeView.associatedImageLink.linkedToId.length > 0 )
        [menuItems addObject:menuItem4];
    
    [sharedController setTargetRect:r inView:self.imageEditView];
    
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

- (void) transitionView
{
    // Display list of transition types
    UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:@"Select transition type" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    
    NSArray *titles = @[@"None", @"Crossfade", @"Slide in from left", @"Slide in from right", @"Slide out from left", @"Slide out from right", @"Push left", @"Push right"];
    for ( int i = 0 ; i < titles.count ; ++i )
    {
        NSString *title = titles[i];
        if ( shadeView.associatedImageLink.transition == i )
            title = [title stringByAppendingString:@" *"];
        [as addButtonWithTitle:title];
    }
    [as showInView:self.view];
}

- (void) gotoLink
{
    self.imageDetails = [self.project getLinkWithId:shadeView.associatedImageLink.linkedToId];
    [self setupView];
}

#pragma mark - UIActionSheetDelegate method
- (void) actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if ( buttonIndex != actionSheet.cancelButtonIndex )
    {
        shadeView.associatedImageLink.transition = buttonIndex;
    }
    [self showMenuFromRect:shadeView.frame];
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


- (void) addHotspotAtPoint:(CGPoint)p
{
    if ( shadeView )
        [shadeView setSelected:NO];
    
    ImageLink *link = [ImageLink new];
    [self.imageDetails.links addObject:link];
    
    shadeView = [[HotspotView alloc] init];
    shadeView.associatedImageLink = link;
    [self.imageEditView addSubview:shadeView];
    
    float w = self.view.frame.size.width / 5;
    CGRect r = CGRectMake( p.x - w/2, p.y - w/2, w, w );
    [self positionHotspotArea:r];
    
    [self showHotspotRect:YES];

}


- (void) showHotspotRect:(bool)show
{
    [self updateLinkColor];

    if ( show )
    {
        [self showMenuFromRect:shadeView.frame];
    }
    else
    {
        [self.imageEditView hideSelectArea];
        [[UIMenuController sharedMenuController] setMenuVisible:NO];
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
    UIView* v = [self.imageEditView hitTest:p withEvent:nil];
    
    // Check if we currently have a hotspot selected, if not, then we may show a popover with options
    bool showPopover = NO;
    if ( shadeView == nil )
        showPopover = YES;
    
    if ( v != nil )
    {
        [shadeView setSelected:NO];
        shadeView = nil;
        if ( [v isKindOfClass:[HotspotView class]] )
        {
            shadeView = (HotspotView *)v;
            [shadeView setSelected:YES];
            [self showHotspotRect:YES];
            [self positionHotspotArea:shadeView.frame];
        }
    }
    
    if ( shadeView == nil )
    {
        [self.imageEditView hideSelectArea];
        [self showHotspotRect:NO];
        
        if ( showPopover )
        {
            selectedPoint = p;
            thePopoverView = [PopoverView showPopoverAtPoint:p inView:self.imageEditView withStringArray:@[@"Add hotspot", @"Edit image"] delegate:self];
        }
        
    }
}

#pragma mark - LinkImageViewController delegate

- (void) LIVC_didSelectImage:(NSString *)imageId
{
    shadeView.associatedImageLink.linkedToId = imageId;
    [shadeView setNeedsDisplay];
    [self updateLinkColor];
    
    double delayInSeconds = 0.5;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self showMenuFromRect:shadeView.frame];
    });
}

#pragma mark - DrawViewControllerDelegateMethods
- (void) drawImageChanged:(UIImage *)image
{
    // Save image
    NSString *path = self.imageDetails.imagePath;
    path = [path stringByReplacingOccurrencesOfString:@".png" withString:@".jpg"];
    bool rc = [UIImageJPEGRepresentation(image, 0.5) writeToFile:path atomically:YES];
    if ( !rc )
        NSLog( @"Failed");

    self.imageView.image = image;
}

#pragma mark - PopoverView delegate

- (void)popoverView:(PopoverView *)popoverView didSelectItemAtIndex:(NSInteger)index itemText:(NSString *)text
{
    [popoverView dismiss];
    
    if ( [text isEqualToString:@"Add hotspot"] )
        [self addHotspotAtPoint:selectedPoint];
    if ( [text isEqualToString:@"Edit image"] )
        [self performSegueWithIdentifier:@"ShowDraw" sender:self];
   
}
@end