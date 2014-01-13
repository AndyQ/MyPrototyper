//
//  PlaybackViewController.m
//  Prototyper
//
//  Created by Andy Qua on 11/01/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

#import "PlaybackViewController.h"
#import "UIColor+Utils.h"

@interface PlaybackViewController () <UIAlertViewDelegate>
{
    ImageDetails *imageDetails;
}
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@end

@implementation PlaybackViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    imageDetails = self.project[0];
    
    self.imageView.image = [UIImage imageWithContentsOfFile:imageDetails.imagePath];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
    [self.view addGestureRecognizer:tap];
    UITapGestureRecognizer *dtap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
    dtap.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:dtap];
    
    // Add views for touchpoints
    [self updateHotspots];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (void) tap:(UITapGestureRecognizer *)gr
{
    if ( gr.state == UIGestureRecognizerStateEnded )
    {
        CGPoint p = [gr locationInView:self.imageView];
        bool hit = NO;
        for ( ImageLink *link in imageDetails.links )
        {
            if ( CGRectContainsPoint( link.rect, p ) )
            {
                hit = YES;
                [self selectLink:link];
                break;
            }
        }
    
        if ( !hit )
        {
            for ( UIView *v in self.imageView.subviews )
                v.alpha = 1;
            
            [UIView animateWithDuration:0.75 animations:^{
                for ( UIView *v in self.imageView.subviews )
                    v.alpha = 0;
                
            }];
        }
    }
}

- (IBAction)hidePressed:(id)sender
{

    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"" message:@"Double tap to unhide the navigation bar" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [av show];
}

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void) doubleTap:(UITapGestureRecognizer *)gr
{
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void) selectLink:(ImageLink *)link
{
    CATransition *transition = [self getTransitionForLink:link];
    if ( transition != nil )
        [self.imageView.layer addAnimation:transition forKey:nil];
    
    imageDetails = [self.project getLinkWithId:link.linkedToId];
    self.imageView.image = [UIImage imageWithContentsOfFile:imageDetails.imagePath];

    if ( transition == nil )
        [self updateHotspots];
}

- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag
{
    [self updateHotspots];
}

- (CATransition *) getTransitionForLink:(ImageLink *)link
{
    if ( link.transition == IT_None )
        return nil;
    
    CATransition *transition = [CATransition animation];
    transition.delegate = self;
    transition.duration = 0.5;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    switch( link.transition )
    {
        case IT_None:
            break;
        case IT_CrossFade:
            transition.type = kCATransitionFade;
            break;
        case IT_SlideInFromLeft:
            transition.type = kCATransitionMoveIn;
            transition.subtype = kCATransitionFromLeft;
            break;
        case IT_SlideInFromRight:
            transition.type = kCATransitionMoveIn;
            transition.subtype = kCATransitionFromRight;
            break;
        case IT_SlideOutFromLeft:
            transition.type = kCATransitionReveal;
            transition.subtype = kCATransitionFromLeft;
            break;
        case IT_SlideOutFromRight:
            transition.type = kCATransitionReveal;
            transition.subtype = kCATransitionFromRight;
            break;
        case IT_PushToLeft:
            transition.type = kCATransitionPush;
            transition.subtype = kCATransitionFromLeft;
            break;
        case IT_PushToRight:
            transition.type = kCATransitionPush;
            transition.subtype = kCATransitionFromRight;
            break;
    }

    return transition;
}

- (void) updateHotspots
{
    [self.imageView.subviews makeObjectsPerformSelector:@selector( removeFromSuperview)];

    int index = 1000;
    for ( ImageLink *link in imageDetails.links )
    {
        UIView *v = [[UIView alloc] initWithFrame:link.rect];
        
        UIColor *bgColor;
        if ( link.linkedToId.length == 0 )
            bgColor = [UIColor redColor];
        else
            bgColor = [UIColor greenColor];
        
        UIColor *darkerColor = [bgColor darkerColorByAmount:0.5];
        
        v.backgroundColor = [[UIColor greenColor] colorWithAlphaComponent:0.2];
        v.layer.borderColor = darkerColor.CGColor;
        v.layer.borderWidth = 2;
        v.alpha = 0;
        [self.imageView addSubview:v];
        index ++;
    }
}

@end
