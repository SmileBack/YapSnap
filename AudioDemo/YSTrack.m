//
//  YSTrack.m
//  YapSnap
//
//  Created by Jon Deokule on 12/13/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import "YSTrack.h"

@implementation YSTrack

+ (NSArray *) tracksFromDictionaryArray:(NSArray *)itemDictionaries inCategory:(BOOL)inCategory
{
    NSMutableArray *tracks = [NSMutableArray arrayWithCapacity:itemDictionaries.count];

    for (NSDictionary *trackDictionary in itemDictionaries) {
        if (inCategory) {
            if (![trackDictionary[@"track"][@"preview_url"] isEqual: [NSNull null]]
                && ![trackDictionary[@"track"][@"id"] isEqual: [NSNull null]]
                && ![trackDictionary[@"track"][@"id"] isEqual: @"1DXNI5YQ9zCDLuBNi0sfJW"]
                ) {
                [tracks addObject:[YSTrack trackFromDictionary:trackDictionary[@"track"]]];
            }
        } else {
            if (![trackDictionary[@"preview_url"] isEqual: [NSNull null]]) {
                [tracks addObject:[YSTrack trackFromDictionary:trackDictionary]];
            }
        }
    }
    
    return tracks;
}

+ (YSTrack *) trackFromDictionary:(NSDictionary *)trackDictionary
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
        track.imageURL = ((NSDictionary *)images[0])[@"url"];
    } else {
        track.imageURL = nil;
    }
    
    track.secondsToFastForward = trackDictionary[@"seconds_to_fast_forward"];
    
    return track;
}

@end
