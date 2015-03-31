//
//  OpenInSpotifyAlertView.m
//  YapSnap
//
//  Created by Jon Deokule on 12/28/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import "OpenInSpotifyAlertView.h"

@interface OpenInSpotifyAlertView()
@property (nonatomic, strong) NSString *spotifyURL;
@property (nonatomic, strong) NSString *spotifyID;
@property (nonatomic, strong) NSString *songName;
@property (nonatomic, strong) NSString *artistName;

- (void) openInSpotify;
@end

@implementation OpenInSpotifyAlertView

- (id) initWithTrack:(YSTrack *)track
{
    self = [super initWithTitle:@"Listen on Spotify"
                        message:@"Are you sure you want to listen to the full song on Spotify?"
                       delegate:self
              cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
    if (self) {
        self.spotifyID = track.spotifyID;
        self.spotifyURL = track.spotifyURL;
        self.songName = track.name;
        self.artistName = track.artistName;
    }
    return self;
}


- (id) initWithYap:(YSYap *)yap
{
    self = [super initWithTitle:@"Listen on Spotify"
                        message:[NSString stringWithFormat:@"Listen to '%@' by %@ on Spotify?", yap.songName, yap.artist]
                       delegate:self
              cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
    if (self) {
        self.spotifyID = yap.spotifyID;
        self.spotifyURL = yap.listenOnSpotifyURL;
        self.songName = yap.songName;
        self.artistName = yap.artist;
    }
    return self;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        [self openInSpotify];
    }
}

- (void) openInSpotify
{
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Opened Song in Spotify"];
    
    NSString *url = [NSString stringWithFormat:@"spotify://track/%@", self.spotifyID];
    BOOL success = [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
    if (!success) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.spotifyURL]];
    }
}

@end
