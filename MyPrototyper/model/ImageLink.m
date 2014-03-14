//
//  ImageLink.m
//  Prototyper
//
//  Created by Andy Qua on 10/01/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

#import "ImageLink.h"
#import "UIColor-Expanded.h"

@implementation ImageLink

+ (ImageLink *) fromDictionary:(NSDictionary *)dict;
{
    ImageLink *link = [ImageLink new];
    
    link.rect = CGRectFromString(dict[@"rect"] );
    link.linkedToId = dict[@"linkedToId"];
    link.transition = [dict[@"transition"] intValue];
    link.linkType = [dict[@"linkType"] intValue];
    link.infoText = dict[@"infoText"];

    if ( dict[@"infoLinkColor"] != nil )
        link.infoLinkColor = [UIColor colorWithHexString:dict[@"infoLinkColor"]];
    else
        link.infoLinkColor = [UIColor whiteColor];
    
    if ( dict[@"speakInfoText"] != nil )
        link.speakInfoText = [dict[@"speakInfoText"] boolValue];
    else
        link.speakInfoText = NO;

    return link;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.transition = IT_None;
        self.linkType = ILT_Normal;
        self.infoText = @"";
        self.infoLinkColor = [UIColor whiteColor];
        self.speakInfoText = NO;
    }
    return self;
}

- (NSDictionary *) toDictionary
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];

    dict[@"rect"] = NSStringFromCGRect(self.rect);
    dict[@"linkedToId"] = self.linkedToId != nil ? self.linkedToId : @"";
    dict[@"transition"] = @(self.transition);
    dict[@"linkType"] = @(self.linkType);
    dict[@"infoText"] = self.infoText != nil ? self.infoText : @"";
    dict[@"infoLinkColor"] = [self.infoLinkColor hexStringFromColor];
    dict[@"speakInfoText"] = @(self.speakInfoText);

    return dict;
}

@end
