//
//  PlaybackView.h
//  Prototyper
//
//  Created by Andy Qua on 12/01/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Project.h"

@interface PlaybackView : UIView

//@property (nonatomic, strong) ImageDetails *imageDetails;

- (void) transitionTo:(ImageDetails *)newDetails;
@end
