//
//  OpenInSpotifyAlertView.m
//  YapSnap
//
//  Created by Jon Deokule on 12/28/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import "OpenInSpotifyAlertView.h"

@interface OpenInSpotifyAlertView()
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
        self.track = track;
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
    NSString *url = [NSString stringWithFormat:@"spotify://track/%@", self.track.spotifyID];
    BOOL success = [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
    if (!success) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.track.spotifyURL]];
    }
}

@end
