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

+ (NSString *) getDocsDir;
+ (void) deleteProjectWithName:(NSString *)projectName;
+ (ProjectType) getProjectTypeForProject:(NSString *)projectName;


- (id) initWithProjectName:(NSString *)projectName;
- (NSString *) getProjectFolder;
- (void) addImageToProject:(UIImage *)image;
- (void) removeItem:(ImageDetails *)item;
- (ImageDetails *) getLinkWithId:(NSString *) linkedToId;

- (bool) load;
- (void) save;

- (NSInteger) count;
- (id)objectAtIndexedSubscript:(NSUInteger)idx;

- (NSString *) exportFile;
@end
