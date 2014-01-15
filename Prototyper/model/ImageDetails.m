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
    NSString *path = [Project getDocsDir];
    NSString *imagePath = [path stringByAppendingPathComponent:self.imagePath];
    
    UIImage *i = [UIImage imageWithContentsOfFile:imagePath];
    return i;
}

// Decode an object from an archive
- (id)initWithCoder:(NSCoder *)aDecoder
{
    if(self = [super init])
    {
        self.imageName = [aDecoder decodeObjectForKey:@"imageName"];
        self.imagePath = [aDecoder decodeObjectForKey:@"imagePath"];
        self.links = [aDecoder decodeObjectForKey:@"links"];
        
        if ( self.links == nil )
            self.links = [NSMutableArray array];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.imageName forKey:@"imageName"];
    [coder encodeObject:self.imagePath forKey:@"imagePath"];
    [coder encodeObject:self.links forKey:@"links"];
}

@end
