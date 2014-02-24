//
//  UIBezierPath+TextPaths.h
//  PathHitTesting
//
//  Copyright (c) 2014 Ole Begemann. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIBezierPath (TextPaths)

// NSString

+ (UIBezierPath *)pathFromString:(NSString *)string WithFont:(UIFont *)font;

// centered as default
+ (UIBezierPath *)pathFromMultilineString:(NSString *)string WithFont:(UIFont *)font maxWidth:(CGFloat)maxWidth;

+ (UIBezierPath *)pathFromMultilineString:(NSString *)string WithFont:(UIFont *)font maxWidth:(CGFloat)maxWidth textAlignment:(NSTextAlignment)alignment;


// NSAttributedString

+ (UIBezierPath *)pathFromAttributedString:(NSAttributedString *)string;

+ (UIBezierPath *)pathFromMultilineAttributedString:(NSAttributedString *)string maxWidth:(CGFloat)maxWidth;

@end

