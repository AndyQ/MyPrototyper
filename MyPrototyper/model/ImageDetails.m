//
//  ImageDetails.m
//  Prototyper
//
//  Created by Andy Qua on 09/01/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

#import "ImageDetails.h"
#import "ImageLink.h"
#import "Project.h"
#import "UIImage+Utils.h"


@implementation ImageDetails

+ (ImageDetails *) fromDictionary:(NSDictionary *)dict;
{
    ImageDetails *imageDetails = [ImageDetails new];
    imageDetails.imageName = dict[@"imageName"];
    
    for ( NSDictionary *d in dict[@"links"] )
    {
        [imageDetails.links addObject:[ImageLink fromDictionary:d]];
    }
    
    return imageDetails;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.links = [NSMutableArray array];
    }
    return self;
}

- (UIImage *) getImage
{
    UIImage *i = [UIImage imageWithContentsOfFile:self.imagePath];
    return i;
}

- (UIImage *) getThumbImage
{
    UIImage *i = [UIImage imageWithContentsOfFile:self.thumbImagePath];
    if ( i == nil )
    {
        i = [[self getImage] createThumbnail];
        CGFloat imageQuality = [[[NSUserDefaults standardUserDefaults] objectForKey:PREF_IMAGE_QUALITY] floatValue];
        [UIImageJPEGRepresentation(i, imageQuality) writeToFile:self.thumbImagePath atomically:YES];
    }
    
    return i;
}


- (NSDictionary *) toDictionary
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
   
    dict[@"imageName"] = self.imageName;

    NSMutableArray *links = [NSMutableArray array];
    dict[@"links"] = links;

    for ( ImageLink *link in self.links )
    {
        NSDictionary *d = [link toDictionary];
        [links addObject:d];
    }
    
    return dict;
}


@end
