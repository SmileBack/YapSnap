//
//  YapBuilder.h
//  YapSnap
//
//  Created by Jon Deokule on 1/19/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YSTrack.h"

#define MESSAGE_TYPE_VOICE @"VoiceMessage"
#define MESSAGE_TYPE_SPOTIFY @"SpotifyMessage"

@interface YapBuilder : NSObject

@property (nonatomic, strong) NSString *messageType;
@property (nonatomic, strong) YSTrack *track; // Only used for Spotify
@property (nonatomic) CGFloat duration;
@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) NSArray *contacts;

@end
