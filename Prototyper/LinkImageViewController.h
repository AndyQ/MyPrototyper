//
//  LinkImageViewController.h
//  Prototyper
//
//  Created by Andy Qua on 10/01/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Project.h"

@protocol LinkImageViewControllerDelegate <NSObject>

- (void) LIVC_didSelectImage:(NSString *)imageId;


@end
@interface LinkImageViewController : UIViewController

@property (nonatomic, assign) id<LinkImageViewControllerDelegate> delegate;
@property (nonatomic, strong) Project *project;
@property (nonatomic, strong) NSString *currentImageId;
@property (nonatomic, strong) NSString *linkedId;
@end
