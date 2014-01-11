//
//  ProjectManager.h
//  Prototyper
//
//  Created by Andy Qua on 09/01/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Project : NSObject <NSCoding>

+ (Project *) setupProject:(NSString *)projectName;

- (NSString *) getProjectFolder;
- (void) addImageToProject:(UIImage *)image;

- (void) save;

- (NSInteger) count;
- (id)objectAtIndexedSubscript:(NSUInteger)idx;

@end
