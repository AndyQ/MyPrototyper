//
//  PhotoCell.m
//  Prototyper
//
//  Created by Andy Qua on 09/01/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

#import "ItemCell.h"

@interface ItemCell ()
@end

@implementation ItemCell


- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self)
    {
        self.layer.borderColor = [UIColor whiteColor].CGColor;
        self.layer.borderWidth = 3;
        self.layer.cornerRadius = 5;
    }
    return self;
}


- (void) setHighlight:(BOOL)highlight
{
 //   [super setSelected:highlighted];
    _highlight = highlight;
    
    if ( _highlight )
        self.backgroundColor = [UIColor greenColor];
    else
        self.backgroundColor = [UIColor clearColor];
}
@end
