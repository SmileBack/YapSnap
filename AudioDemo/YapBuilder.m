//
//  YapBuilder.m
//  YapSnap
//
//  Created by Jon Deokule on 1/19/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "YapBuilder.h"
#import "YSYap.h"
#import "ContactManager.h"

@implementation YapBuilder

- (id) init
{
    if (self = [super init])
    {
        self.text = @"";
    }
    return self;
}

- (id)initWithYap:(YSYap*)yap sendingAction:(YTYapSendingAction)action
{
    if (self = [self init])
    {
        self.messageType = yap.type;
        self.duration = [yap.duration floatValue];
        self.track = [[YSTrack alloc] init];
        self.track.name = yap.songName;
        self.track.spotifyID = yap.spotifyID;
        self.track.previewURL = yap.playbackURL;
        self.track.artistName = yap.artist;
        if (![yap.imageURL isEqual:[NSNull null]]) {
            self.track.imageURL = yap.imageURL;
        }

        self.track.spotifyURL = yap.listenOnSpotifyURL;
        self.track.secondsToFastForward = yap.secondsToFastForward;
        
        switch (action) {
            case YTYapSendingActionReply:
            {
                PhoneContact* contact = [[ContactManager sharedContactManager] contactForPhoneNumber:yap.senderPhone];
                self.contacts = @[contact];
                
            }
                break;
            case YTYapSendingActionForward:
                self.imageAwsUrl = yap.yapPhotoURL;
                self.text = yap.text;
                if (![yap.yapPhotoURL isEqual:[NSNull null]]) {
                    self.image = [NSURL URLWithString:yap.yapPhotoURL];
                }
                break;
            default:
                break;
        }
    }
    return self;
}

- (BuilderType) builderType
{
    return BuilderTypeYap;
}

@end
