 //
//  PSActionSheet.h
//
//  Created by Landon Fuller on 7/3/09.
//  Copyright 2009 Plausible Labs Cooperative, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * A simple block-enabled API wrapper on top of UIActionSheet.
 */
@interface PSActionSheet : NSObject <UIActionSheetDelegate> {
@private
    UIActionSheet *sheet_;
    NSMutableArray *blocks_;
    
    // Used to keep us alive UNTIL the view has finished (fix for ARC)
    PSActionSheet *me;
}

@property(copy) dispatch_block_t dismissAction;
@property (nonatomic, strong, readonly) UIActionSheet *sheet;

+ (id)sheetWithTitle:(NSString *)title;

- (id)initWithTitle:(NSString *)title;

- (void)setCancelButtonWithTitle:(NSString *) title block:(void (^)()) block;
- (void)setDestructiveButtonWithTitle:(NSString *) title block:(void (^)()) block;
- (void)addButtonWithTitle:(NSString *) title block:(void (^)()) block;

- (void) dismissSheet;
- (void)showInView:(UIView *)view;
- (void)showFromBarButtonItem:(UIBarButtonItem *)item animated:(BOOL)animated;
- (void)showFromRect:(CGRect)rect inView:(UIView *)view animated:(BOOL)animated;

- (NSUInteger)buttonCount;

@end