//
//  DrawViewController.h
//  Prototyper
//
//  Created by Andy Qua on 13/01/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol DrawViewControllerDelegate <NSObject>

- (void) drawImageChanged:(UIImage *)image;

@end

@interface DrawViewController : UIViewController

@property (nonatomic, weak) id<DrawViewControllerDelegate> delegate;

@property (nonatomic, strong) NSString *imageFile;
@property (nonatomic, strong) UIImage *image;
@end
