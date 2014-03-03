//
//  PhotoCell.h
//  Prototyper
//PhotoCell
//  Created by Andy Qua on 09/01/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>

@interface ItemCell : UICollectionViewCell

@property(nonatomic, weak) IBOutlet UILabel *label;

@property(nonatomic, assign) BOOL highlight;

@end

