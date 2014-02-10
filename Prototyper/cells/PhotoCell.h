//
//  PhotoCell.h
//  Prototyper
//
//  Created by Andy Qua on 09/01/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>

@interface PhotoCell : UICollectionViewCell

@property(nonatomic, weak) IBOutlet UIImageView *imageView;

@property(nonatomic, strong) UIImage *image;
@property(nonatomic, assign) BOOL highlight;

@end

