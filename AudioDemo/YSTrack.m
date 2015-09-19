//
//  YSTrack.m
//  YapSnap
//
//  Created by Jon Deokule on 12/13/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import "YSTrack.h"

@implementation YSTrack


// FROM SPOTIFY BACKEND
+ (NSArray *) tracksFromSpotifyDictionaryArray:(NSArray *)itemDictionaries inCategory:(BOOL)inCategory
{
    NSMutableArray *tracks = [NSMutableArray arrayWithCapacity:itemDictionaries.count];

    for (NSDictionary *trackDictionary in itemDictionaries) {
//        if (inCategory) {
//            if (![trackDictionary[@"track"][@"preview_url"] isEqual: [NSNull null]]
//                && ![trackDictionary[@"track"][@"id"] isEqual: [NSNull null]]
//                && ![trackDictionary[@"track"][@"id"] isEqual: @"1DXNI5YQ9zCDLuBNi0sfJW"]
//                ) {
//                [tracks addObject:[YSTrack trackFromSpotifyDictionary:trackDictionary[@"track"]]];
//            }
//        } else {
            if (![trackDictionary[@"preview_url"] isEqual: [NSNull null]]) {
                [tracks addObject:[YSTrack trackFromSpotifyDictionary:trackDictionary]];
            }
//        }
    }
    
    return tracks;
}

+ (YSTrack *) trackFromSpotifyDictionary:(NSDictionary *)trackDictionary
{
    YSTrack *track = [YSTrack new];
    
    track.name = trackDictionary[@"name"];
    track.spotifyID = trackDictionary[@"id"];
    track.previewURL = trackDictionary[@"preview_url"];

    NSArray *artists = trackDictionary[@"artists"];
    NSDictionary *artist = artists[0];
    track.artistName = artist[@"name"];

    track.spotifyURL = trackDictionary[@"external_urls"][@"spotify"];
    
    NSDictionary *album = trackDictionary[@"album"];
    track.albumName = album[@"name"];
    
    NSArray *images = album[@"images"];
    if (images && images.count > 0) {
        track.albumImageURL = ((NSDictionary *)images[0])[@"url"];
    } else {
        track.albumImageURL = nil;
    }
    
    track.secondsToFastForward = trackDictionary[@"seconds_to_fast_forward"];
    
    return track;
}



// FROM YAPTAP BACKEND
+ (NSArray *) tracksFromYapTapDictionaryArray:(NSArray *)itemDictionaries inCategory:(BOOL)inCategory
{
    NSMutableArray *tracks = [NSMutableArray arrayWithCapacity:itemDictionaries.count];
    
    for (NSDictionary *trackDictionary in itemDictionaries) {
        if (![trackDictionary[@"preview_url"] isEqual: [NSNull null]]) {
            [tracks addObject:[YSTrack trackFromYapTapDictionary:trackDictionary]];
        }
    }
    
    return tracks;
}

+ (YSTrack *) trackFromYapTapDictionary:(NSDictionary *)trackDictionary
{
    YSTrack *track = [YSTrack new];
    
    track.name = trackDictionary[@"spotify_song_name"];
    track.spotifyID = trackDictionary[@"spotify_song_id"];
    track.previewURL = trackDictionary[@"spotify_preview_url"];
    track.artistName = trackDictionary[@"spotify_artist_name"];
    track.spotifyURL = trackDictionary[@"spotify_full_song_url"];
    track.albumName = trackDictionary[@"spotify_album_name"];
    track.albumImageURL = trackDictionary[@"spotify_image_url"];
    
    track.secondsToFastForward = trackDictionary[@"seconds_to_fast_forward"];
    
    return track;
}

+ (YSTrack *)trackFromiTunesTrack:(YSITunesTrack *)itunesTrack {
    YSTrack *track = YSTrack.new;
    track.name = itunesTrack.songName;
    track.artistName = itunesTrack.artistName;
    track.albumName = itunesTrack.albumName;
    track.genreName = itunesTrack.genreName;
    track.albumImageURL = itunesTrack.albumName;
    return track;
}

@end
