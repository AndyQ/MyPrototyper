//
//  PlaybackViewController.m
//  Prototyper
//
//  Created by Andy Qua on 11/01/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

@import AVFoundation;

#import "PlaybackViewController.h"
#import "UIColor+Utils.h"
#import "UIImageView+ContentScale.h"
#import <PopoverView/PopoverView.h>

@interface PlaybackViewController () <UIAlertViewDelegate>
{
    bool hasShownDoubleTapInfo;
    ImageDetails *imageDetails;
    
    CGSize imageScale;
    
    NSMutableArray *breadcrumbTrail;
}
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomConstraint;
@property (weak, nonatomic) IBOutlet UILabel *doubleTapText;

@end

@implementation PlaybackViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    breadcrumbTrail = [NSMutableArray array];
    
    hasShownDoubleTapInfo = NO;
    imageDetails = [self.project getStartImageDetails];
    
    self.imageView.image = [imageDetails getImage];

    UISwipeGestureRecognizer *backSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(backSwipe:)];
    backSwipe.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:backSwipe];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
    [self.view addGestureRecognizer:tap];
    UITapGestureRecognizer *dtap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
    dtap.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:dtap];
    
    // Add outline around double tap text
    self.doubleTapText.layer.shadowColor = [UIColor blackColor].CGColor;
    self.doubleTapText.layer.shadowRadius = 5;
    self.doubleTapText.layer.shadowOpacity = 1;
    self.doubleTapText.layer.shadowOffset = CGSizeMake( 0, 0 );
}

- (void) viewDidAppear:(BOOL)animated
{
    // Have to do this here as this is when the autolayout stuff has finished
    
    // Add views for touchpoints
    [self updateHotspots];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) backSwipe:(UITapGestureRecognizer *)gr
{
    if ( gr.state == UIGestureRecognizerStateEnded )
    {
        if ( breadcrumbTrail.count > 0 )
        {
            // Pop off the last page of the breakcrumb stack
            NSString *imageId = [breadcrumbTrail lastObject];
            [breadcrumbTrail removeLastObject];
            
            imageDetails = [self.project getLinkWithId:imageId];
            self.imageView.image = [imageDetails getImage];
            [self updateHotspots];
            
            CATransition *transition = [CATransition animation];
            transition.delegate = self;
            transition.duration = 0.5;
            transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            transition.type = kCATransitionMoveIn;
            transition.subtype = kCATransitionFromLeft;
            [self.imageView.layer addAnimation:transition forKey:nil];
        }
    }
}

- (void) tap:(UITapGestureRecognizer *)gr
{
    if ( gr.state == UIGestureRecognizerStateEnded )
    {
        CGPoint p = [gr locationInView:self.imageView];
        p.x /= imageScale.width;
        p.y /= imageScale.height;
        bool hit = NO;
        for ( ImageLink *link in imageDetails.links )
        {
            if ( CGRectContainsPoint( link.rect, p ) )
            {
                hit = YES;
                if ( link.linkType == ILT_Info || link.linkedToId.length > 0 )
                    [self selectLink:link];
                break;
            }
        }
    
        if ( !hit )
        {
            for ( UIView *v in self.imageView.subviews )
                v.alpha = 1;

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:.5 animations:^{
                    for ( UIView *v in self.imageView.subviews )
                        v.alpha = 0;
                }];
            });
        }
    }
}

- (IBAction)hidePressed:(id)sender
{
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    self.topConstraint.constant = 22;
    self.bottomConstraint.constant = 22;

    if ( hasShownDoubleTapInfo )
        return;
    hasShownDoubleTapInfo = YES;

    self.doubleTapText.alpha = 1;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:.25 animations:^{
            self.doubleTapText.alpha = 0;
        }];
    });
}

- (void) doubleTap:(UITapGestureRecognizer *)gr
{
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    self.topConstraint.constant = 0;
    self.bottomConstraint.constant = 0;
}

- (void) selectLink:(ImageLink *)link
{
    if ( link.linkType == ILT_Normal )
    {
        // Save current page in breadcrumb trail so we can swip back
        [breadcrumbTrail addObject:imageDetails.imageName];

        CATransition *transition = [self getTransitionForLink:link];
        if ( transition != nil )
            [self.imageView.layer addAnimation:transition forKey:nil];
        
        imageDetails = [self.project getLinkWithId:link.linkedToId];
        self.imageView.image = [imageDetails getImage];

        if ( transition == nil )
            [self updateHotspots];
    }
    else
    {
        // Show popover with text
        CGRect r = link.rect;
        CGPoint center = CGPointMake(r.origin.x + (r.size.width / 2), r.origin.y + (r.size.height / 2));
        center.x *= imageScale.width;
        center.y *= imageScale.height;
        [PopoverView showPopoverAtPoint:center inView:self.view withText:link.infoText delegate:nil];

// TODO : May add speech for popups
/*
        // Speak text
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *voice = [defaults stringForKey:@"speechvoice_preference"];
        if ( voice == nil )
            voice = @"en-GB";
        
        AVSpeechUtterance *utterance = [[AVSpeechUtterance alloc] initWithString:link.infoText];
        utterance.rate = 0.25;
        utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:voice];
        
        AVSpeechSynthesizer *synthesizer = [[AVSpeechSynthesizer alloc] init];
        [synthesizer speakUtterance:utterance];
*/
    }
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

    imageScale.width = self.imageView.widthScale;
    imageScale.height = self.imageView.heightScale;

    int index = 1000;
    for ( ImageLink *link in imageDetails.links )
    {
        if ( link.linkType == ILT_Normal && link.linkedToId.length == 0 )
            continue;
        
        CGRect f = link.rect;
        f.origin.x *= imageScale.width;
        f.origin.y *= imageScale.height;
        f.size.width *= imageScale.width;
        f.size.height *= imageScale.height;
        UIView *v = [[UIView alloc] initWithFrame:f];
        
        UIColor *bgColor;
        if ( link.linkType == ILT_Normal )
        {
            if ( link.linkedToId.length == 0 )
                bgColor = [UIColor redColor];
            else
                bgColor = [UIColor greenColor];
            
            UIColor *darkerColor = [bgColor darkerColorByAmount:0.5];
            
            v.backgroundColor = [bgColor colorWithAlphaComponent:0.2];
            v.layer.borderColor = darkerColor.CGColor;
            v.layer.borderWidth = 2;
            v.alpha = 0;
        }
        else
        {
            UIButton *infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
            infoButton.frame = f;
            v = infoButton;
        }
        [self.imageView addSubview:v];
        index ++;
    }
}

@end
