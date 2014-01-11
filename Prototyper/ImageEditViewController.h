//
//  ImageEditViewController.h
//  Prototyper
//
//  Created by Andy Qua on 09/01/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Project.h"
#import "ImageDetails.h"

@interface ImageEditViewController : UIViewController

@property (nonatomic, strong) Project *project;
@property (nonatomic, strong) ImageDetails *imageDetails;

@end
