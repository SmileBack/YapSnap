//
//  YapBuilder.h
//  YapSnap
//
//  Created by Jon Deokule on 1/19/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YTBuilder.h"
#import "YSTrack.h"

#define MESSAGE_TYPE_VOICE @"VoiceMessage"
#define MESSAGE_TYPE_SPOTIFY @"SpotifyMessage"

typedef NS_ENUM(NSUInteger, YTYapSendingAction) {
    YTYapSendingActionReply,
    YTYapSendingActionForward
};

@class YSYap;

@interface YapBuilder : YTBuilder

@property (nonatomic, strong) NSString *messageType;
@property (nonatomic, strong) YSTrack *track; // Only used for Spotify
@property (nonatomic) CGFloat duration;
@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) UIColor *color;
@property (nonatomic, strong) NSNumber *pitchValueInCentUnits;
@property (strong, nonatomic) NSNumber *originYapID;

#pragma mark - Photo Stuff
@property (nonatomic, strong) NSURL *image;
@property (nonatomic, strong) NSString *imageAwsUrl;
@property (nonatomic, strong) NSString *imageAwsEtag;

- (id)initWithYap:(YSYap*)yap sendingAction:(YTYapSendingAction)action;

@end
