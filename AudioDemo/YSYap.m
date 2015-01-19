//
//  YSYap.m
//  YapSnap
//
//  Created by Jon Deokule on 12/24/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import "YSYap.h"
#import "ContactManager.h"

@implementation YSYap

+ (YSYap *) yapWithDictionary:(NSDictionary *)dict
{
    YSYap *yap = [YSYap new];
    
    yap.yapID = dict[@"id"];
    yap.createdAt = dict[@"created_at"];

    yap.artist = dict[@"spotify_artist_name"];
    
    yap.playbackURL = dict[@"spotify_preview_url"];
    
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
