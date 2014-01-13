//
//  ImageLink.m
//  Prototyper
//
//  Created by Andy Qua on 10/01/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

#import "ImageLink.h"

@implementation ImageLink

- (id)init
{
    self = [super init];
    if (self) {
        self.transition = IT_None;
    }
    return self;
}

// Decode an object from an archive
- (id)initWithCoder:(NSCoder *)aDecoder
{
    if(self = [super init])
    {
        self.rect = [aDecoder decodeCGRectForKey:@"rect"];
        self.linkedToId = [aDecoder decodeObjectForKey:@"linkedToId"];
        
        if ( [aDecoder containsValueForKey:@"transition"] )
            self.transition = [aDecoder decodeInt32ForKey:@"transition"];
        else
            self.transition = IT_None;
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeCGRect:self.rect forKey:@"rect"];
    [coder encodeObject:self.linkedToId forKey:@"linkedToId"];
    [coder encodeInt32:self.transition forKey:@"transition"];
}
@end
