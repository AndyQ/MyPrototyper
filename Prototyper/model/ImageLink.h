//
//  ImageLink.h
//  Prototyper
//
//  Created by Andy Qua on 10/01/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImageLink : NSObject <NSCoding>

@property (nonatomic, assign) CGRect rect;
@property (nonatomic, strong) NSString *linkedToId;
@end