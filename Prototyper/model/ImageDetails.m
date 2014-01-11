//
//  ImageDetails.m
//  Prototyper
//
//  Created by Andy Qua on 09/01/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

#import "ImageDetails.h"

@implementation ImageLink
// Decode an object from an archive
- (id)initWithCoder:(NSCoder *)aDecoder
{
    if(self = [super init])
    {
        self.rect = [aDecoder decodeCGRectForKey:@"rect"];
        self.linkedToId = [aDecoder decodeObjectForKey:@"linkedToId"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeCGRect:self.rect forKey:@"rect"];
    [coder encodeObject:self.linkedToId forKey:@"linkedToId"];
}
@end

@implementation ImageDetails

- (id)init
{
    self = [super init];
    if (self) {
        self.links = [NSMutableArray array];
    }
    return self;
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
