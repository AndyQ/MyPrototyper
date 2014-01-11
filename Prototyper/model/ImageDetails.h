//
//  ImageDetails.h
//  Prototyper
//
//  Created by Andy Qua on 09/01/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ImageDetails;
@interface ImageLink : NSObject <NSCoding>

@property (nonatomic, assign) CGRect rect;
@property (nonatomic, strong) NSString *linkedToId;
@end

@interface ImageDetails : NSObject <NSCoding>

@property (nonatomic, strong) NSString *imageName;
@property (nonatomic, strong) NSString *imagePath;
@property (nonatomic, strong) NSMutableArray *links;

@end
