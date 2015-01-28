//
//  YSYap.m
//  YapSnap
//
//  Created by Jon Deokule on 12/24/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import "YSYap.h"
#import "ContactManager.h"
#import "NSDate+InternetDateTime.h"

@implementation YSYap

+ (YSYap *) yapWithDictionary:(NSDictionary *)dict
{
    YSYap *yap = [YSYap new];
    
    yap.yapID = dict[@"id"];
    yap.createdAt = [NSDate dateFromInternetDateTimeString:dict[@"created_at"] formatHint:DateFormatHintRFC3339];
    yap.status = dict[@"status"];
    yap.type = dict[@"type"];
    yap.duration = dict[@"duration"];
    yap.text = dict[@"text"];
    yap.rgbColorComponents = dict[@"color_rgb"];

    yap.artist = dict[@"spotify_artist_name"];
    
    if ([dict[@"type"]  isEqual: @"SpotifyMessage"]) {
        yap.playbackURL = dict[@"spotify_preview_url"];
    } else {
        yap.playbackURL = dict[@"recording"][@"url"];
    };
    yap.listenOnSpotifyURL = dict[@"spotify_full_song_url"];
    yap.songName = dict[@"spotify_song_name"];
    yap.spotifyID = dict[@"spotify_song_id"];
    yap.imageURL = dict[@"spotify_image_url"];
    
    yap.senderID = dict[@"sender_id"];
    yap.senderName = @"Sender Name"; //dict[@"sender_name"];
    yap.senderPhone = dict[@"sender_phone"];

    yap.receiverID = dict[@"receiver_id"];
    yap.receiverName = @"Receiver Name"; //dict[@"receiver_name"];
    yap.receiverPhone = dict[@"receiver_phone"];

    return yap;
}

+ (NSArray *) yapsWithArray:(NSArray *)array
{
    NSMutableArray *yaps = [NSMutableArray arrayWithCapacity:array.count];
    for (NSDictionary *dict in array) {
        [yaps addObject:[YSYap yapWithDictionary:dict]];
    }
    return yaps;
}

- (NSString *) displayReceiverName
{
    if ([ContactManager sharedContactManager].isAuthorizedForContacts) {
        NSString *displayName = [[ContactManager sharedContactManager] nameForPhoneNumber:self.receiverPhone];
        if (displayName) {
            return displayName;
        }
    }
    
    return self.receiverName;
}

- (NSString *) displaySenderName
{
    if ([ContactManager sharedContactManager].isAuthorizedForContacts) {
        NSString *displayName = [[ContactManager sharedContactManager] nameForPhoneNumber:self.senderPhone];
        if (displayName) {
            return displayName;
        }
    }
    
    return self.senderName;
}

@end
