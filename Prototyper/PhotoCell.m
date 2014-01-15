//
//  PhotoCell.m
//  Prototyper
//
//  Created by Andy Qua on 09/01/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

#import "PhotoCell.h"

@interface PhotoCell ()
@property(nonatomic, weak) IBOutlet UIImageView *imageView;
@end

@implementation PhotoCell

- (void) setImage:(UIImage *)image
{
    _image = image;
    self.imageView.image = image;
}

- (void) setSelected:(BOOL)selected
{
    [super setSelected:selected];
    
    if ( selected )
        self.backgroundColor = [UIColor greenColor];
    else
        self.backgroundColor = [UIColor clearColor];
}
@end
