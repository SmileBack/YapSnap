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
#import "YSUser.h"

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
    yap.pitchValueInCentUnits = dict[@"pitch_value"];
    yap.secondsToFastForward = dict[@"seconds_to_fast_forward"];

    yap.artist = dict[@"spotify_artist_name"];
    
    if ([dict[@"type"]  isEqual: @"SpotifyMessage"]) {
        yap.playbackURL = dict[@"spotify_preview_url"];
    } else {
        yap.playbackURL = dict[@"aws_recording_url"];
    };
    yap.listenOnSpotifyURL = dict[@"spotify_full_song_url"];
    yap.songName = dict[@"spotify_song_name"];
    yap.spotifyID = dict[@"spotify_song_id"];
    yap.imageURL = dict[@"spotify_image_url"];
    
    yap.yapPhotoURL = dict[@"aws_photo_url"];
    
    yap.senderID = dict[@"sender_id"];
    yap.senderName = dict[@"sender_name"];
    yap.senderPhone = dict[@"sender_phone"];

    yap.receiverID = dict[@"receiver_id"];
    yap.receiverName = dict[@"receiver_name"];
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
    if (!_displayReceiverName) {
        if ([ContactManager sharedContactManager].isAuthorizedForContacts) {
            NSString *displayName = [[ContactManager sharedContactManager] nameForPhoneNumber:self.receiverPhone];
            if (displayName) {
                _displayReceiverName = displayName;
            }
        }
        if (!_displayReceiverName) {
            _displayReceiverName = self.receiverName;
        }
    }
     
    return _displayReceiverName;
}

- (NSString *) displaySenderName
{
    
    if (!_displaySenderName) {
        if ([ContactManager sharedContactManager].isAuthorizedForContacts) {
            NSString *displayName = [[ContactManager sharedContactManager] nameForPhoneNumber:self.senderPhone];
            if (displayName) {
                _displaySenderName = displayName;
            }
        }
        
        if (!_displaySenderName) {
            _displaySenderName = self.senderName;
        }
    }
    
    return _displaySenderName;
}

+ (NSArray *) pendingYapsWithYapBuilder:(YapBuilder *)yapBuilder
{
    NSMutableArray *yaps = [NSMutableArray arrayWithCapacity:yapBuilder.contacts.count];
    
    for (YSContact *contact in yapBuilder.contacts) {
        YSYap *yap = [YSYap new];
        
        YSUser *me = [YSUser currentUser];
        yap.senderID = me.userID;
        yap.senderName = me.displayName;
        yap.senderPhone = me.phone;
        
        yap.receiverID = nil; //TODO the cell may depend on this
        yap.receiverName = contact.name;
        yap.receiverPhone = contact.phoneNumber;
        
        yap.createdAt = [NSDate date];
        
        yap.status = YAP_STATUS_SENDING;
        
        [yaps addObject:yap];
    }
    
    return yaps;
}

- (BOOL) wasOpened
{
    return ([@"opened" isEqualToString:self.status] || [@"opened2" isEqualToString:self.status]);
}

- (BOOL) wasOpenedOnce
{
    return [@"opened" isEqualToString:self.status];
}

- (BOOL) wasOpenedTwice
{
    return [@"opened2" isEqualToString:self.status];
}

- (BOOL) isPending
{
    return [@"pending" isEqualToString:self.status];
}

- (BOOL) isSending
{
    return [YAP_STATUS_SENDING isEqualToString:self.status];
}

- (BOOL) sentByCurrentUser
{
    return [self.senderID isEqualToNumber:[YSUser currentUser].userID];
}

- (BOOL) receivedByCurrentUser
{
    return [self.receiverID isEqualToNumber:[YSUser currentUser].userID];
}

@end
