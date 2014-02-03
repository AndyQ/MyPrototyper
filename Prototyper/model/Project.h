//
//  ProjectManager.h
//  Prototyper
//
//  Created by Andy Qua on 09/01/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ImageDetails.h"
#import "ImageLink.h"
#import "Constants.h"


@interface Project : NSObject

@property (nonatomic, strong) NSString *projectName;
@property (nonatomic, assign) NSInteger projectType;
@property (nonatomic, strong) NSString *startImage;

+ (NSString *) getDocsDir;
+ (void) deleteProjectWithName:(NSString *)projectName;
+ (bool) isProjectValidWithName:(NSString *)projectName;

//+ (ProjectType) getProjectTypeForProject:(NSString *)projectName;


- (id) initWithProjectName:(NSString *)projectName;
- (NSString *) getProjectFolder;
- (void) addImageToProject:(UIImage *)image;
- (void) removeItem:(ImageDetails *)item;
- (ImageDetails *) getLinkWithId:(NSString *) linkedToId;
- (ImageDetails *) getStartImageDetails;
- (bool) renameProject:(NSString *)newName error:(NSError **)error;
- (bool) load:(NSError **)error;
- (bool) save:(NSError **)error;

- (NSInteger) count;
- (id)objectAtIndexedSubscript:(NSUInteger)idx;

- (NSString *) exportFile;
@end
