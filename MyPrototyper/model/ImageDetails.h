//
//  ImageDetails.h
//  Prototyper
//
//  Created by Andy Qua on 09/01/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ImageDetails : NSObject

@property (nonatomic, strong) NSString *imageName;
@property (nonatomic, strong) NSMutableArray *links;

// This is set dynamically when the project is loaded
@property (nonatomic, strong) NSString *imagePath;
@property (nonatomic, strong) NSString *thumbImagePath;

+ (ImageDetails *) fromDictionary:(NSDictionary *)dict;

- (UIImage *) getImage;
- (UIImage *) getThumbImage;
- (NSDictionary *) toDictionary;
@end
