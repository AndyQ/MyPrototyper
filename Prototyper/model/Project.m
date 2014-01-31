//
//  ProjectManager.m
//  Prototyper
//
//  Created by Andy Qua on 09/01/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

#import "Project.h"
#import "Constants.h"

#import "SSZipArchive.h"

@interface Project () 

@end


@implementation Project
{
    NSMutableArray *_images;
}

+ (NSString *) getDocsDir
{
    NSURL *docsUrl = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                   inDomains:NSUserDomainMask] lastObject];
    
    NSString *path = [docsUrl.path stringByAppendingPathComponent:@"Projects"];
    return path;
}

+ (void) deleteProjectWithName:(NSString *)projectName;
{
    NSFileManager *mgr = [NSFileManager defaultManager];
    
    NSError *err = nil;
    NSString *path = [[self getDocsDir] stringByAppendingPathComponent:projectName];
    [mgr removeItemAtPath:path error:&err];
    if ( err != nil )
    {
        NSLog( @"Failed to remove project - %@ because %@", projectName, err.localizedDescription );
    }
}


+ (ProjectType) getProjectTypeForProject:(NSString *)projectName
{
    NSString *dataFile = [[[Project getDocsDir] stringByAppendingPathComponent:projectName] stringByAppendingPathComponent:@"project.dat"];
    NSURL *archiveURL = [NSURL fileURLWithPath:dataFile];
    NSData *data = [NSData dataWithContentsOfURL:archiveURL];
    
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    
    // Customize the unarchiver.
    ProjectType projectType = [unarchiver decodeIntegerForKey:@"projectType"];
    
    [unarchiver finishDecoding];

    return projectType;
}

- (id) initWithProjectName:(NSString *)projectName
{
    self = [super init];
    if (self) {
        _projectName = projectName;
        
        NSFileManager *mgr = [NSFileManager defaultManager];
        
        NSString *projectFolder = [self getProjectFolder];
        NSString *dataFile = [projectFolder stringByAppendingPathComponent:@"project.dat"];
        if ( ![mgr fileExistsAtPath:dataFile isDirectory:nil] )
        {
            NSError *err = nil;
            [mgr createDirectoryAtPath:projectFolder withIntermediateDirectories:YES attributes:nil error:&err];
            if ( err )
            {
                NSLog( @"Error creating project directory - %@", err.localizedDescription );
            }
            
            if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
                _projectType = PT_IPAD;
            else
                _projectType = PT_IPHONE;
            _images = [NSMutableArray array];
        }
        else
        {
            [self load];
            [self setupProjectPaths];
            
            // Little hack temporarily to assign unknown project types to the device we are running on
            if ( _projectType == 0 )
                _projectType = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? PT_IPAD : PT_IPHONE;
        }
        

        
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

    NSString *imageName = [NSString stringWithFormat:@"%@.jpg", guid];

    // Save image to string
    NSString *imagePath = [[self getProjectFolder] stringByAppendingPathComponent:imageName];
    if ( image != nil )
    {
        bool rc = [UIImageJPEGRepresentation(image, 0.8) writeToFile:imagePath atomically:YES];
        if ( rc != YES )
        {
            NSLog( @"Failed to save image - %@", imagePath );
        }
    }
    else
        NSLog( @"Failed to save image as its nil!" );
    
    // Add image to list
    ImageDetails *item = [ImageDetails new];
    item.imageName = [imageName stringByDeletingPathExtension];
    item.imagePath = imagePath;
    [_images addObject:item];
    
    // Save Project
    [self save];
}

- (void) removeItem:(ImageDetails *)item;
{
    [_images removeObject:item];
    
    NSString *path = item.imagePath;

    NSError *err;
    NSFileManager *mgr = [NSFileManager defaultManager];
    [mgr removeItemAtPath:path error:&err];
    
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

- (ImageDetails *) getLinkWithId:(NSString *) linkedToId;
{
    ImageDetails *ret = nil;
    for ( ImageDetails *item in _images )
    {
        if ( [item.imageName isEqualToString:linkedToId] )
        {
            ret = item;
            break;
        }
    }
    
    return ret;
}



- (NSInteger) count
{
    return _images.count;
}

- (id)objectAtIndexedSubscript:(NSUInteger)idx;
{
    return _images[idx];
}

- (NSString *) exportFile
{
    NSString *path = [Project getDocsDir];
    NSString *zipPath = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.zip", self.projectName]];

    NSMutableArray *filesList = [NSMutableArray array];
    
    for ( int i = 0 ; i < self.count ; ++i )
    {
        ImageDetails *imageDetails = self[i];
        NSString *path = imageDetails.imagePath;
        [filesList addObject:path];
    }
    [filesList addObject:[[self getProjectFolder] stringByAppendingPathComponent:@"project.dat"]];
    
    NSLog( @"Creating zip file - %@", zipPath );
    [SSZipArchive createZipFileAtPath:zipPath withFilesAtPaths:filesList];
    NSLog( @"Zip file created." );

    return zipPath;
}


- (void) setupProjectPaths
{
    // Set image paths
    NSArray *extensions = @[@"jpg", @"png"];
    NSFileManager *fm = [NSFileManager defaultManager];
    for ( int i = 0 ; i < self.count ; ++i )
    {
        ImageDetails *imageDetails = self[i];
        imageDetails.imageName = [imageDetails.imageName stringByDeletingPathExtension];
        NSString *base = [[self getProjectFolder] stringByAppendingPathComponent:imageDetails.imageName];
        for ( NSString *ext in extensions )
        {
            NSString *file = [base stringByAppendingPathExtension:ext];
            if ( [fm fileExistsAtPath:file] )
            {
                imageDetails.imagePath = file;
                break;
            }
        }
        
        // Remove extensions from links
        for ( ImageLink *il in imageDetails.links )
        {
            il.linkedToId = [il.linkedToId stringByDeletingPathExtension];
        }
    }
    
    [self save];
}


#pragma mark - serialization
- (bool) load
{
    NSString *dataFile = [[self getProjectFolder] stringByAppendingPathComponent:@"project.dat"];
    NSURL *archiveURL = [NSURL fileURLWithPath:dataFile];
    NSData *data = [NSData dataWithContentsOfURL:archiveURL];
    
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    
    bool valid = NO;
    if ( [unarchiver containsValueForKey:@"projectType"] && [unarchiver containsValueForKey:@"images"] )
    {
        _projectType = [unarchiver decodeIntegerForKey:@"projectType"];
        _images = [unarchiver decodeObjectForKey:@"images"];
        valid = YES;
    }
    [unarchiver finishDecoding];

    return valid;
}



- (void) save
{
    NSMutableData *data = [NSMutableData data];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    
    [archiver encodeInteger:_projectType forKey:@"projectType"];
    [archiver encodeObject:_images forKey:@"images"];
    [archiver finishEncoding];
    
    NSString *dataFile = [[self getProjectFolder] stringByAppendingPathComponent:@"project.dat"];
    NSURL *archiveURL = [NSURL fileURLWithPath:dataFile];
    BOOL rc = [data writeToURL:archiveURL atomically:YES];
    NSLog( @"Rc - %d", rc );
}


@end
