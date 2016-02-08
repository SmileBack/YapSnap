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
        self.isPublic = NO;
        self.text = @"";
    }
    return self;
}

- (id)initWithYap:(YSYap*)yap sendingAction:(YTYapSendingAction)action
{
    if (self = [self init])
    {
        self.isPublic = NO;
        self.messageType = yap.type;
        self.duration = [yap.duration floatValue];
        self.track = [[YSTrack alloc] init];
        self.track.name = yap.songName;
        self.track.spotifyID = yap.spotifyID;
        self.track.previewURL = yap.playbackURL;
        self.track.artistName = yap.artist;
        if (![yap.albumImageURL isEqual:[NSNull null]]) {
            self.track.albumImageURL = yap.albumImageURL;
        }

        self.track.spotifyURL = yap.listenOnSpotifyURL;
        self.track.secondsToFastForward = yap.secondsToFastForward;
        
        self.originYapID = yap.yapID;
        if ([yap.type isEqualToString:@"VoiceMessage"] || [yap.type isEqualToString:@"UploadedMessage"]) {
            self.awsVoiceURL = yap.playbackURL;
        }
        
        switch (action) {
            case YTYapSendingActionReply:
            {
                if (yap.sentByCurrentUser && !yap.isPublic) {
                    YSContact *contact = [YSContact contactWithName:yap.displayReceiverName andPhoneNumber:yap.receiverPhone];
                    self.contacts = @[contact];
                } else {
                    YSContact *contact = [YSContact contactWithName:yap.displaySenderName andPhoneNumber:yap.senderPhone];
                    self.contacts = @[contact];
                }
            }
                break;
            case YTYapSendingActionForward:
                self.giphyImageId = yap.yapGiphyID;
                self.yapImageAwsUrl = yap.yapPhotoURL;
                self.text = yap.text;
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
