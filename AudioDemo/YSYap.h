//
//  YSYap.h
//  YapSnap
//
//  Created by Jon Deokule on 12/24/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YSYap : NSObject

@property (strong, nonatomic) NSNumber *yapID;
@property (strong, nonatomic) NSDate *createdAt;
@property (strong, nonatomic) NSString *status;
@property (strong, nonatomic) NSString *type;
@property (strong, nonatomic) NSNumber *duration;

// Spotify stuff
@property (strong, nonatomic) NSString *artist;
@property (strong, nonatomic) NSString *playbackURL;
@property (strong, nonatomic) NSString *listenOnSpotifyURL;

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

@property (nonatomic, readonly) NSString *displayReceiverName;
@property (nonatomic, readonly) NSString *displaySenderName;

@end
