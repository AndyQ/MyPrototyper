//
//  ProjectManager.m
//  Prototyper
//
//  Created by Andy Qua on 09/01/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

#import "Project.h"

@implementation Project
{
    NSString *_projectName;
    NSMutableArray *_images;
}

+ (NSString *) getDocsDir
{
    NSURL *docsUrl = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                   inDomains:NSUserDomainMask] lastObject];
    
    return docsUrl.path;
}

+ (Project *) setupProject:(NSString *)projectName
{
    Project *project;
    NSFileManager *mgr = [NSFileManager defaultManager];
    
    NSString *path = [[self getDocsDir] stringByAppendingPathComponent:projectName];
    NSString *dataFile = [path stringByAppendingPathComponent:@"project.dat"];
    if ( ![mgr fileExistsAtPath:dataFile isDirectory:nil] )
    {
        NSError *err = nil;
        [mgr createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&err];
        if ( err )
        {
            NSLog( @"Error creating project directory - %@", err.localizedDescription );
        }
        
        project = [[Project alloc] initWithProjectName:projectName];
    }
    else
    {
        // Load images
        project = [NSKeyedUnarchiver unarchiveObjectWithFile:dataFile];
        
    }
    
    return project;
}

- (id) initWithProjectName:(NSString *)projectName
{
    self = [super init];
    if (self) {
        _projectName = projectName;
        _images = [NSMutableArray array];
    }
    return self;
}

- (NSString *) getProjectFolder
{
    NSString *path = [[Project getDocsDir] stringByAppendingPathComponent:_projectName];
    return path;
}


- (void) addImageToProject:(UIImage *)image
{
    // Generate file name for image
    NSString *guid = [[NSUUID new] UUIDString];

    NSString *imageName = [NSString stringWithFormat:@"%@.png", guid];

    // Save image to string
    NSString *path = [self getProjectFolder];
    NSString *imageFile = [path stringByAppendingPathComponent:imageName];
    if ( image != nil )
        [UIImagePNGRepresentation(image) writeToFile:imageFile atomically:YES];
    
    // Add image to list
    ImageDetails *item = [ImageDetails new];
    item.imageName = imageName;
    item.imagePath = imageFile;
    [_images addObject:item];
    
    // Save Project
    [self save];
}

- (void) removeItem:(ImageDetails *)item;
{
    [_images removeObject:item];
    
    NSError *err;
    NSFileManager *mgr = [NSFileManager defaultManager];
    [mgr removeItemAtPath:item.imagePath error:&err];
    
    // Now go through all the existing items and links and set any links that use this image to nil;
    for ( ImageDetails *image in _images )
    {
        for ( ImageLink *link in image.links )
        {
            if ( [link.linkedToId isEqualToString:item.imageName] )
                link.linkedToId = nil;
        }
    }
    
    [self save];
}

- (void) save
{
    NSString *path = [self getProjectFolder];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self];
    NSString *dataFile = [path stringByAppendingPathComponent:@"project.dat"];
    [data writeToFile:dataFile atomically:YES];

}

- (NSInteger) count
{
    return _images.count;
}

- (id)objectAtIndexedSubscript:(NSUInteger)idx;
{
    return _images[idx];
}


// Decode an object from an archive
- (id)initWithCoder:(NSCoder *)aDecoder
{
    if(self = [super init])
    {
        _projectName = [aDecoder decodeObjectForKey:@"projectName"];
        _images = [aDecoder decodeObjectForKey:@"images"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:_projectName forKey:@"projectName"];
    [coder encodeObject:_images forKey:@"images"];
}


@end
