//
//  ImageDetails.h
//  Prototyper
//
//  Created by Andy Qua on 09/01/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ImageDetails : NSObject <NSCoding>

@property (nonatomic, strong) NSString *imageName;
@property (nonatomic, strong) NSString *imagePath;
@property (nonatomic, strong) NSMutableArray *links;

- (UIImage *) getImage;

@end
