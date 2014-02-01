//
//  ImageLink.h
//  Prototyper
//
//  Created by Andy Qua on 10/01/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum ImageTransition
{
    IT_None = 0,
    IT_CrossFade,
    IT_SlideInFromLeft,
    IT_SlideInFromRight,
    IT_SlideOutFromLeft,
    IT_SlideOutFromRight,
    IT_PushToLeft,
    IT_PushToRight
} ImageTransition;

@interface ImageLink : NSObject <NSCoding>

@property (nonatomic, assign) CGRect rect;
@property (nonatomic, strong) NSString *linkedToId;
@property (nonatomic, assign) ImageTransition transition;

+ (ImageLink *) fromDictionary:(NSDictionary *)dict;
- (NSDictionary *) toDictionary;

@end
