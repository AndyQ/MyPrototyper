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
/*
    // Fix image path it it has more that two path components - only get the last two (the project and filename
    // This is to support older style projects that embedded the full path! Should no longer be needed but 
    // kept here whilst I check.
    NSArray *items = [self.imagePath pathComponents];
    if ( items.count >= 2 )
    {
        NSString *project = items[items.count-2];
        NSString *file = [items lastObject];
        self.imagePath = [project stringByAppendingPathComponent:file];
    }
*/
    UIImage *i = [UIImage imageWithContentsOfFile:self.imagePath];
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

// Decode an object from an archive
- (id)initWithCoder:(NSCoder *)aDecoder
{
    if(self = [super init])
    {
        self.imageName = [aDecoder decodeObjectForKey:@"imageName"];
        self.links = [aDecoder decodeObjectForKey:@"links"];
        
        if ( self.links == nil )
            self.links = [NSMutableArray array];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.imageName forKey:@"imageName"];
    [coder encodeObject:self.links forKey:@"links"];
}

@end
