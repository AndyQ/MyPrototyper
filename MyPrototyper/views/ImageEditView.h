//
//  ImageEditView.h
//  Prototyper
//
//  Created by Andy Qua on 11/01/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ImageEditViewDelegate <NSObject>

- (void) hotspotAreaUpdate:(CGRect)r;
- (void) touchedViewAtPoint:(CGPoint)p;
@end

@interface ImageEditView : UIView

@property (nonatomic, strong) UIImage *image;

@property (nonatomic, assign) bool showSelectArea;
@property (nonatomic, assign) CGRect selectArea;
@property (nonatomic, weak) IBOutlet id<ImageEditViewDelegate>delegate;

- (void) setColor:(UIColor *)color;
- (void) showSelectArea:(CGRect)r;
- (void) hideSelectArea;

@end
