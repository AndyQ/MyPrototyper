//
//  DrawView.h
//  Prototyper
//
//  Created by Andy Qua on 13/01/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DrawView : UIView

@property (nonatomic, strong) UIImage *image;

-(void)undoButtonPressed;
-(void)redoButtonPressed;

@end
