//
//  SpotifyTrackFactory.m
//  YapTap
//
//  Created by Jon Deokule on 5/2/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "SpotifyTrackFactory.h"

@implementation SpotifyTrackFactory

+ (NSMutableArray *) tracks {
    YSTrack *track = [YSTrack new];
    track.name = @"1";
    track.spotifyID = @"Home";
    track.previewURL = @"Home";
    track.artistName = @"Home";
    track.albumName = @"Home";
    track.spotifyURL = @"Home";
    track.imageURL = @"Home";
    
    YSTrack *track2 = [YSTrack new];
    track2.name = @"2";
    track2.spotifyID = @"Home";
    track2.previewURL = @"Home";
    track2.artistName = @"Home";
    track2.albumName = @"Home";
    track2.spotifyURL = @"Home";
    track2.imageURL = @"Home";
    
    YSTrack *track3 = [YSTrack new];
    track3.name = @"3";
    track3.spotifyID = @"Home";
    track3.previewURL = @"Home";
    track3.artistName = @"Home";
    track3.albumName = @"Home";
    track3.spotifyURL = @"Home";
    track3.imageURL = @"Home";
    
    YSTrack *track4 = [YSTrack new];
    track4.name = @"4";
    track4.spotifyID = @"Home";
    track4.previewURL = @"Home";
    track4.artistName = @"Home";
    track4.albumName = @"Home";
    track4.spotifyURL = @"Home";
    track4.imageURL = @"Home";
    
    YSTrack *track5 = [YSTrack new];
    track5.name = @"5";
    track5.spotifyID = @"Home";
    track5.previewURL = @"Home";
    track5.artistName = @"Home";
    track5.albumName = @"Home";
    track5.spotifyURL = @"Home";
    track5.imageURL = @"Home";
    
    YSTrack *track6 = [YSTrack new];
    track6.name = @"6";
    track6.spotifyID = @"Home";
    track6.previewURL = @"Home";
    track6.artistName = @"Home";
    track6.albumName = @"Home";
    track6.spotifyURL = @"Home";
    track6.imageURL = @"Home";

    return [NSMutableArray arrayWithObjects:track, track2, track3, track4, track5, track6, nil];
}


@end
