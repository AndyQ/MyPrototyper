//
//  PSAlertView.m
//
//  Created by Peter Steinberger on 17.03.10.
//  Loosely based on Landon Fullers "Using Blocks", Plausible Labs Cooperative.
//  http://landonf.bikemonkey.org/code/iphone/Using_Blocks_1.20090704.html
//

#import "PSAlertView.h"

@implementation PSAlertView

@synthesize alertView = view_;

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Static

+ (PSAlertView *)alertWithTitle:(NSString *)title; {
    return [[PSAlertView alloc] initWithTitle:title message:nil];
}

+ (PSAlertView *)alertWithTitle:(NSString *)title message:(NSString *)message {
    return [[PSAlertView alloc] initWithTitle:title message:message];
}

+ (PSAlertView *)alertWithTitle:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelButton otherButtonTitles:(NSString *)otherButtonTitles,...{
    return [[PSAlertView alloc] initWithTitle:title message:message cancelButtonTitle:cancelButton otherButtonTitles:otherButtonTitles,nil ];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark NSObject

- (id)initWithTitle:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelTitle otherButtonTitles:(NSString *)otherButtonTitles,...
{
    if ((self = [super init])) {
        view_ = [[UIAlertView alloc] initWithTitle:title
                                           message:message
                                          delegate:self
                                 cancelButtonTitle:cancelTitle
                                 otherButtonTitles:otherButtonTitles, nil];
        blocks_ = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (id)initWithTitle:(NSString *)title message:(NSString *)message 
{
    if ((self = [super init])) {
        view_ = [[UIAlertView alloc] initWithTitle:title
                                           message:message
                                          delegate:self
                                 cancelButtonTitle:nil
                                 otherButtonTitles:nil];
        blocks_ = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)dealloc {
    view_.delegate = nil;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Public

- (void)setCancelButtonWithTitle:(NSString *)title block:(void (^)())block {
    assert([title length] > 0 && "cannot set empty button title");
    
    [self addButtonWithTitle:title block:block];
    view_.cancelButtonIndex = (view_.numberOfButtons - 1);
}

- (void)addButtonWithTitle:(NSString *)title block:(void (^)())block {
    assert([title length] > 0 && "cannot add button with empty title");
    
    if (block) {
        [blocks_ addObject:[block copy]];
    }
    else {
        [blocks_ addObject:[NSNull null]];
    }
    
    [view_ addButtonWithTitle:title];
}

- (void)addBlock:(void (^)())block {
    if (block) {
        [blocks_ addObject:[block copy]];
    }
    else {
        [blocks_ addObject:[NSNull null]];
    }
}



- (void)show {
    [view_ show];
    
    /* Ensure that the delegate (that's us) survives until the sheet is dismissed */
    me = self;
}


- (void)dismissWithClickedButtonIndex:(NSInteger)buttonIndex animated:(BOOL)animated {
    [view_ dismissWithClickedButtonIndex:buttonIndex animated:animated];
    [self alertView:view_ clickedButtonAtIndex:buttonIndex];
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    /* Run the button's block */
    if (buttonIndex >= 0 && buttonIndex < [blocks_ count]) {
        id obj = [blocks_ objectAtIndex: buttonIndex];
        if (![obj isEqual:[NSNull null]]) {
            ((void (^)())obj)();
        }
    }
    
    /* AlertView to be dismissed, drop our self reference */
    me = nil;
}

- (void)addShouldShowFirstOtherButtonBlockHandlerBlock:(BOOL (^)(UIAlertView *))block
{
    if (block)
        shouldEnableFirstOtherButtonBlock = [block copy];

}

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView
{
    if (![shouldEnableFirstOtherButtonBlock isEqual:[NSNull null]])
        return ((BOOL (^)(UIAlertView *))shouldEnableFirstOtherButtonBlock)(alertView);
    else
        return YES;
}


@end