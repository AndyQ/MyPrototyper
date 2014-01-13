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

@interface DrawViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet DrawView *drawView;

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

    self.imageView.image = self.image;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)undoPressed:(id)sender
{
    [self.drawView undoButtonPressed];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ( [segue.identifier isEqualToString:@"unwind"] )
    {
        // Take screenshot
        UIImage *image = [self snapshotView];
        
        [self.delegate drawImageChanged:image];
    }
}

- (UIImage *) snapshotView
{
    UIImage* image = nil;
    
    UIGraphicsBeginImageContext(self.drawView.frame.size);
    {
        [[UIColor whiteColor] setFill];
        CGContextFillRect( UIGraphicsGetCurrentContext(), self.drawView.frame );
        [self.imageView.layer renderInContext: UIGraphicsGetCurrentContext()];
        [self.drawView.layer renderInContext: UIGraphicsGetCurrentContext()];
        image = UIGraphicsGetImageFromCurrentImageContext();
    }
    UIGraphicsEndImageContext();
    
    return image;
}

@end
