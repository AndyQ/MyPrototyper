//
//  PSActionSheet.m
//
//  Created by Landon Fuller on 7/3/09.
//  Copyright 2009 Plausible Labs Cooperative, Inc.. All rights reserved.
//

#import "PSActionSheet.h"

@interface PSActionSheet ()
@property (nonatomic, strong, readwrite) UIActionSheet *sheet;
@end

@implementation PSActionSheet
@synthesize sheet = sheet_;
@synthesize dismissAction;

+ (id)sheetWithTitle:(NSString *)title {
    return [[PSActionSheet alloc] initWithTitle:title];
}


- (id)initWithTitle:(NSString *)title {
    if ((self = [super init])) {
        // Create the action sheet
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:title
                                                                 delegate:self
                                                        cancelButtonTitle:nil
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:nil];
        self.sheet = actionSheet;
        
        // Create the blocks storage for handling all button actions
        blocks_ = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void) dealloc {
    self.sheet.delegate = nil;
}

- (void)setDestructiveButtonWithTitle:(NSString *)title block:(void (^)())block {
    assert([title length] > 0 && "sheet destructive button title must not be empty");
    
    [self addButtonWithTitle:title block:block];
    sheet_.destructiveButtonIndex = (sheet_.numberOfButtons - 1);
}

- (void)setCancelButtonWithTitle:(NSString *)title block:(void (^)())block {
    assert([title length] > 0 && "sheet cancel button title must not be empty");
    
    [self addButtonWithTitle:title block:block];
    sheet_.cancelButtonIndex = (sheet_.numberOfButtons - 1);
}

- (void)addButtonWithTitle:(NSString *)title block:(void (^)())block {
    assert([title length] > 0 && "cannot add button with empty title");
    
    if (block) {
        [blocks_ addObject:[block copy]];
    }
    else {
        [blocks_ addObject:[NSNull null]];
    }
    
    [sheet_ addButtonWithTitle:title];
}

- (void)showInView:(UIView *)view {
    [sheet_ showInView:view];
    
    // Ensure that the delegate (that's us) survives until the sheet is dismissed.
    // Release occurs in -actionSheet:clickedButtonAtIndex:
    me = self;
}

- (void)showFromBarButtonItem:(UIBarButtonItem *)item animated:(BOOL)animated {
    [sheet_ showFromBarButtonItem:item animated:animated];
    me = self;
}

- (void)showFromRect:(CGRect)rect inView:(UIView *)view animated:(BOOL)animated {
    [sheet_ showFromRect:rect inView:view animated:animated];
    me = self;
}

- (void) dismissSheet
{
    [sheet_ dismissWithClickedButtonIndex:-1 animated:YES];
    [self actionSheet:sheet_ clickedButtonAtIndex:-1];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    // Run the button's block
    if (buttonIndex >= 0 && buttonIndex < [blocks_ count]) {
        id obj = [blocks_ objectAtIndex:buttonIndex];
        if (![obj isEqual:[NSNull null]]) {
            ((void (^)())obj)();
        }
    }
    
    if ( buttonIndex == -1 )
    {
        if (dismissAction != NULL) {
            dismissAction();
        }
    }
    
    // Sheet to be dismissed, drop our self reference.
    // Retain occurs in -showInView:
    me = nil;
}

- (NSUInteger)buttonCount {
    return [blocks_ count];
}

@end