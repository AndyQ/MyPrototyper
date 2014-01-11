//
//  PhotoCell.m
//  Prototyper
//
//  Created by Andy Qua on 09/01/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

#import "PhotoCell.h"

@interface PhotoCell ()
@property(nonatomic, weak) IBOutlet UIImageView *photoImageView;
@end

@implementation PhotoCell

- (void) setImage:(UIImage *)image
{
    _image = image;
    self.photoImageView.image = image;
}

@end
