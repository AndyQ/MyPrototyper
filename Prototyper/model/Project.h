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


@interface Project : NSObject <NSCoding>

+ (Project *) setupProject:(NSString *)projectName;
+ (NSString *) getDocsDir;

- (NSString *) getProjectFolder;
- (void) addImageToProject:(UIImage *)image;
- (void) removeItem:(ImageDetails *)item;

- (void) save;

- (NSInteger) count;
- (id)objectAtIndexedSubscript:(NSUInteger)idx;

@end
