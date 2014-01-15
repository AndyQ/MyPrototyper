//
//  PSAlertView.h
//
//  Created by Peter Steinberger on 17.03.10.
//  Loosely based on Landon Fullers "Using Blocks", Plausible Labs Cooperative.
//  http://landonf.bikemonkey.org/code/iphone/Using_Blocks_1.20090704.html
//

#import <UIKit/UIKit.h>

@interface PSAlertView : NSObject <UIAlertViewDelegate> {
@private
    UIAlertView *view_;
    NSMutableArray *blocks_;
    id shouldEnableFirstOtherButtonBlock;
    // Used to keep us alive UNTIL the view has finished (fix for ARC)
    PSAlertView *me;
}

+ (PSAlertView *)alertWithTitle:(NSString *)title;
+ (PSAlertView *)alertWithTitle:(NSString *)title message:(NSString *)message;

// If you use this method, DO NOT use the addButtonWithTitle method, use the addBlock method
+ (PSAlertView *)alertWithTitle:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelButton otherButtonTitles:(NSString *)otherButtonTitles,... NS_REQUIRES_NIL_TERMINATION;

- (id)initWithTitle:(NSString *)title message:(NSString *)message;

// If you use this method, DO NOT use the addButtonWithTitle method, use the addBlock method
- (id)initWithTitle:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelTitle otherButtonTitles:(NSString *)otherButtonTitles,... NS_REQUIRES_NIL_TERMINATION;

- (void)setCancelButtonWithTitle:(NSString *)title block:(void (^)())block;
- (void)addButtonWithTitle:(NSString *)title block:(void (^)())block;
- (void)addBlock:(void (^)())block;
- (void)addShouldShowFirstOtherButtonBlockHandlerBlock:(BOOL (^)(UIAlertView *))block;

- (void)show;
- (void)dismissWithClickedButtonIndex:(NSInteger)buttonIndex animated:(BOOL)animated;

@property (nonatomic, strong) UIAlertView *alertView;

@end