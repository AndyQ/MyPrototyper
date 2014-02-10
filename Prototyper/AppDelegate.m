//
//  AppDelegate.m
//  Prototyper
//
//  Created by Andy Qua on 10/01/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

#import "AppDelegate.h"
#import "Project.h"
#import "SSZipArchive.h"

#import "Constants.h"
@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSDictionary *userDefaultsDefaults = @{ PREF_IMAGE_FORMAT : @"jpg",
                                            PREF_IMAGE_QUALITY : @"0.5"};
    [[NSUserDefaults standardUserDefaults] registerDefaults:userDefaultsDefaults];

    // Add in tutorial if first launch
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    if ( [defaults objectForKey:@"FirstUse"] == nil )
    {
        [defaults setObject:@"YES" forKey:@"FirstUse"];
        
        // Copy over demo file into place
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"demo" withExtension:@"zip"];
        [Project importProjectArchiveFromURL:url];
    }

    return YES;
}

#pragma mark - Open File from external app

-(BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication
        annotation:(id)annotation
{
    if (url != nil && [url isFileURL])
    {
        [Project importProjectArchiveFromURL:url];
        
        // Remove all stored files in Inbox folder
        NSFileManager *fm = [NSFileManager defaultManager];
        NSURL *docsUrl = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                                 inDomains:NSUserDomainMask] lastObject];
        NSString *path = [docsUrl.path stringByAppendingPathComponent:@"Inbox"];
        NSArray *files = [fm contentsOfDirectoryAtPath:path error:nil];
        for ( NSString *file in files )
        {
            [fm removeItemAtPath:[path stringByAppendingPathComponent:file] error:nil];
        }

        // Post notification to update files
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIF_IMPORTED object:self];
    }
    return YES;
}
				
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
