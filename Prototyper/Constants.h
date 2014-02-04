//
//  Constants.h
//  Prototyper
//
//  Created by Andy Qua on 13/01/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

// Various app wide constants

typedef enum ProjectType
{
    PT_IPAD = 1,
    PT_IPHONE
} ProjectType;

// Preferences
#define PREF_IMAGE_FORMAT @"pref_imageFormat"
#define PREF_IMAGE_QUALITY @"pref_imageQuality"

#define JPEG @"jpg"
#define PNG @"png"

// Notifications
#define NOTIF_IMPORTED @"NOTIF_IMPORTED"

// Errors
#define PROTOTYPER_ERROR_DOMAIN @"Prototyper"

#define FAILED_TO_SAVE kCFURLErrorCannotWriteToFile
#define PROJECT_NOT_FOUND  10001