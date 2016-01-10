//
//  YSYap.h
//  YapSnap
//
//  Created by Jon Deokule on 12/24/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YapBuilder.h"

#define YAP_STATUS_SENDING @"sending"

@interface YSYap : NSObject

@property (strong, nonatomic) NSNumber *yapID;
@property (strong, nonatomic) NSDate *createdAt;
@property (strong, nonatomic) NSString *status;
@property (strong, nonatomic) NSString *type;
@property (strong, nonatomic) NSNumber *duration;
@property (strong, nonatomic) NSString *text;
@property (strong, nonatomic) NSArray *rgbColorComponents;
@property (nonatomic, strong) NSNumber *pitchValueInCentUnits;
@property (nonatomic, strong) NSString *notificationType;
@property (nonatomic, strong) NSString *playbackURL;
@property (nonatomic, strong) NSString *senderFacebookId;
@property (nonatomic, strong) NSNumber *playCount;
@property (nonatomic, strong) NSNumber *secondsToFastForward;
@property (nonatomic) BOOL isPublic;

// Spotify stuff
@property (strong, nonatomic) YSTrack *track;

// These just defer to the above track
@property (readonly) NSString *artist;
@property (readonly) NSString *listenOnSpotifyURL;
@property (readonly) NSString *songName;
@property (readonly) NSString *spotifyID;
@property (readonly) NSString *albumImageURL;


// Photo
@property (strong, nonatomic) NSString *yapPhotoURL;

// Sender
@property (strong, nonatomic) NSNumber *senderID;
@property (strong, nonatomic) NSString *senderName;
@property (strong, nonatomic) NSString *senderPhone;

// Receiver
@property (strong, nonatomic) NSNumber *receiverID;
@property (strong, nonatomic) NSString *receiverName;
@property (strong, nonatomic) NSString *receiverPhone;

+ (YSYap *) yapWithDictionary:(NSDictionary *)dict;
+ (NSArray *) yapsWithArray:(NSArray *)array;
+ (NSArray *) pendingYapsWithYapBuilder:(YapBuilder *)yapBuilder;

@property (nonatomic, strong) NSString *displayReceiverName;
@property (nonatomic, strong) NSString *displaySenderName;

- (BOOL) wasOpened;
- (BOOL) wasOpenedOnce;
- (BOOL) wasOpenedTwice;
- (BOOL) isPending;
- (BOOL) isSending;
- (BOOL) sentByCurrentUser;
- (BOOL) receivedByCurrentUser;
- (BOOL) isFriendRequest;

@end
