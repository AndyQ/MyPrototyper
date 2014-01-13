//
//  PlaybackViewController.m
//  Prototyper
//
//  Created by Andy Qua on 11/01/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

#import "PlaybackViewController.h"
#import "PlaybackView.h"

@interface PlaybackViewController () <UIAlertViewDelegate>
{
    ImageDetails *imageDetails;
}
@end

@implementation PlaybackViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    imageDetails = self.project[0];
    
//    ((PlaybackView *)self.view).imageDetails = imageDetails;
    [(PlaybackView *)self.view transitionTo:imageDetails];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
    [self.view addGestureRecognizer:tap];
    UITapGestureRecognizer *dtap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
    dtap.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:dtap];
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
        CGPoint p = [gr locationInView:self.view];
     
        for ( ImageLink *link in imageDetails.links )
        {
            if ( CGRectContainsPoint( link.rect, p ) )
            {
                [self selectLink:link.linkedToId];
                break;
            }
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

- (void) selectLink:(NSString *)linkId
{
    for ( int i = 0 ; i < self.project.count ; ++i )
    {
        ImageDetails *item = self.project[i];
        if ( [item.imageName isEqualToString:linkId] )
        {
            imageDetails = item;
            [(PlaybackView *)self.view transitionTo:imageDetails];

            [self.view setNeedsDisplay];
        }
    }
}
@end
