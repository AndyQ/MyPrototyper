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

@property (nonatomic, strong) NSMutableArray *images;

@end


@implementation Project
{
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

+ (bool) isProjectValidWithName:(NSString *)projectName;
{
    NSString *dataFile = [[[Project getDocsDir] stringByAppendingPathComponent:projectName] stringByAppendingPathComponent:@"project.json"];
    
    NSData *data = [NSData dataWithContentsOfFile:dataFile];
    NSError *err = nil;
    id jsonObj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
    if ( err != nil || ![jsonObj isKindOfClass:[NSDictionary class]] )
    {
        // Invalid object
        return NO;
    }

    // Check that this JSON object contains a valid project name (may also want to add version number check
    // when version numbers get implemented)
    NSDictionary *dict = jsonObj;
    if ( dict[@"projectName"] == nil )
        return NO;
    
    return YES;
}

- (id) initWithProjectName:(NSString *)projectName
{
    self = [super init];
    if (self) {
        self.projectName = projectName;
        self.images = [NSMutableArray array];

        NSFileManager *mgr = [NSFileManager defaultManager];
        
        NSString *projectFolder = [self getProjectFolder];
        NSString *dataFile = [projectFolder stringByAppendingPathComponent:@"project.json"];
        NSString *oldDataFile = [projectFolder stringByAppendingPathComponent:@"project.dat"];
        if ( ![mgr fileExistsAtPath:dataFile isDirectory:nil] && ![mgr fileExistsAtPath:oldDataFile isDirectory:nil]  )
        {
            NSError *err = nil;
            [mgr createDirectoryAtPath:projectFolder withIntermediateDirectories:YES attributes:nil error:&err];
            if ( err )
            {
                NSLog( @"Error creating project directory - %@", err.localizedDescription );
            }
            
            if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
                self.projectType = PT_IPAD;
            else
                self.projectType = PT_IPHONE;
        }
        else
        {
            NSError *err = nil;
            [self load:&err];
            if ( err )
                NSLog( @"Error loading project - %@", err.localizedDescription );
            
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
    NSString *path = [[Project getDocsDir] stringByAppendingPathComponent:self.projectName];
    return path;
}

- (bool) renameProject:(NSString *)newName error:(NSError **)error;
{
    NSFileManager *mgr = [NSFileManager defaultManager];
    
    NSString *oldProjectFolder = [self getProjectFolder];
    NSString *newProjectFolder = [oldProjectFolder stringByReplacingOccurrencesOfString:self.projectName withString:newName];

    NSError *err = nil;
    [mgr moveItemAtPath:oldProjectFolder toPath:newProjectFolder error:&err];
    if ( err != nil )
    {
        NSLog( @"Error! - %@", err.localizedDescription);
        *error = err;
        return NO;
    }
    
    self.projectName = newName;
    return YES;
}

- (void) addImageToProject:(UIImage *)image
{
    // Generate file name for image
    NSString *guid = [[NSUUID new] UUIDString];
    
    // If we haven't got a start image then mark this image as the start image
    if ( self.startImage.length == 0 )
        self.startImage = guid;

    
    NSString *imageType = [[NSUserDefaults standardUserDefaults] objectForKey:PREF_IMAGE_FORMAT];
    NSString *imageName = [NSString stringWithFormat:@"%@.%@", guid, imageType];
    NSString *imagePath = [[self getProjectFolder] stringByAppendingPathComponent:imageName];

    bool rc;
    if ( image != nil )
    {
        if ( [imageType isEqualToString:JPEG] )
        {
            CGFloat imageQuality = [[[NSUserDefaults standardUserDefaults] objectForKey:PREF_IMAGE_QUALITY] floatValue];
            rc = [UIImageJPEGRepresentation(image, imageQuality) writeToFile:imagePath atomically:YES];
        }
        else
        {
            rc = [UIImagePNGRepresentation(image) writeToFile:imagePath atomically:YES];
        }

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
    NSError *err = nil;
    [self save:&err];
    if ( err != nil )
        NSLog( @"Error saving project - %@", err.localizedDescription );
}

- (void) removeItem:(ImageDetails *)item;
{
    [_images removeObject:item];
    
    NSString *path = item.imagePath;

    NSError *err = nil;
    NSFileManager *mgr = [NSFileManager defaultManager];
    [mgr removeItemAtPath:path error:&err];
    
    // Now go through all the existing items and links and set any links that use this image to nil;
    for ( ImageDetails *image in self.images )
    {
        for ( ImageLink *link in image.links )
        {
            if ( [link.linkedToId isEqualToString:item.imageName] )
                link.linkedToId = nil;
        }
    }
    
    err = nil;
    [self save:&err];
    if ( err != nil )
        NSLog( @"Error saving project - %@", err.localizedDescription );
}

- (ImageDetails *) getLinkWithId:(NSString *) linkedToId;
{
    ImageDetails *ret = nil;
    for ( ImageDetails *item in self.images )
    {
        if ( [item.imageName isEqualToString:linkedToId] )
        {
            ret = item;
            break;
        }
    }
    
    return ret;
}


- (ImageDetails *) getStartImageDetails;
{
    ImageDetails *ret = nil;
    for ( ImageDetails *item in self.images )
    {
        if ( [item.imageName isEqualToString:self.startImage] )
        {
            ret = item;
            break;
        }
    }
    
    return ret;
}

- (NSInteger) count
{
    return self.images.count;
}

- (id)objectAtIndexedSubscript:(NSUInteger)idx;
{
    return self.images[idx];
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
    [filesList addObject:[[self getProjectFolder] stringByAppendingPathComponent:@"project.json"]];
    
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
        ImageDetails *imageDetails = self.images[i];
        
        // Set start image if necessary
        if ( self.startImage.length == 0 )
            self.startImage = imageDetails.imageName;
        
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
    
    NSError *err = nil;
    [self save:&err];
    if ( err != nil )
        NSLog( @"Error saving project - %@", err.localizedDescription );
}


#pragma mark - serialization
- (bool) load:(NSError **)error;
{
    NSString *dataFile = [[self getProjectFolder] stringByAppendingPathComponent:@"project.json"];
    NSFileManager *fm = [NSFileManager defaultManager];
    if ( ![fm fileExistsAtPath:dataFile] )
        return [self loadOldProject];
    
    NSData *data = [NSData dataWithContentsOfFile:dataFile];
    
    NSError *err = nil;
    id jsonObj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
    if ( err != nil || ![jsonObj isKindOfClass:[NSDictionary class]] )
    {
        // Invalid object
        *error = err;
        return NO;
    }

    NSDictionary *dict = jsonObj;
    self.projectName = dict[@"projectName"];
    self.startImage = dict[@"startImage"];
    for ( NSDictionary *d in dict[@"images"] )
    {
        ImageDetails *imageDetails = [ImageDetails fromDictionary:d];
        [self.images addObject:imageDetails];
    }

    return YES;
}

- (bool) loadOldProject
{
    NSString *dataFile = [[self getProjectFolder] stringByAppendingPathComponent:@"project.dat"];
    NSURL *archiveURL = [NSURL fileURLWithPath:dataFile];
    NSData *data = [NSData dataWithContentsOfURL:archiveURL];
    
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    
    bool valid = NO;
    if ( [unarchiver containsValueForKey:@"projectType"] && [unarchiver containsValueForKey:@"images"] )
    {
        self.projectType = [unarchiver decodeIntegerForKey:@"projectType"];
        self.startImage = [unarchiver decodeObjectForKey:@"startImage"];
        self.images = [unarchiver decodeObjectForKey:@"images"];
        valid = YES;
    }
    [unarchiver finishDecoding];

    return valid;
}

- (bool) save:(NSError **)error
{
    NSMutableDictionary *proj = [NSMutableDictionary dictionary];
    proj[@"projectName"] = self.projectName;
    proj[@"startImage"] = self.startImage;
    NSMutableArray *images = [NSMutableArray array];
    proj[@"images"] = images;
    
    for ( ImageDetails *imageDetails in self.images )
    {
        NSDictionary *d = [imageDetails toDictionary];
        [images addObject:d];
    }
    
    NSError *err = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:proj
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&err];
    if ( err )
    {
        NSLog( @"Error serialising JSON - %@", err.localizedDescription );
        *error = err;
        return NO;
    }
    
    NSString *dataFile = [[self getProjectFolder] stringByAppendingPathComponent:@"project.json"];
    NSURL *archiveURL = [NSURL fileURLWithPath:dataFile];
    BOOL rc = [jsonData writeToURL:archiveURL atomically:YES];
    if ( !rc )
    {
        NSLog( @"Rc - %d", rc );
        *error = [NSError errorWithDomain:PROTOTYPER_ERROR_DOMAIN
                                     code:FAILED_TO_SAVE
                                 userInfo:nil];
        return NO;
    }
    
    return YES;
}


@end
