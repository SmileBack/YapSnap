//
//  YSTrack.m
//  YapSnap
//
//  Created by Jon Deokule on 12/13/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import "YSTrack.h"

@implementation YSTrack

+ (NSArray *) tracksFromDictionaryArray:(NSArray *)itemDictionaries
{
    NSMutableArray *tracks = [NSMutableArray arrayWithCapacity:itemDictionaries.count];

    for (NSDictionary *trackDictionary in itemDictionaries) {
        [tracks addObject:[YSTrack trackFromDictionary:trackDictionary]];
    }
    
    return tracks;
}

+ (YSTrack *) trackFromDictionary:(NSDictionary *)trackDictionary
{
    NSLog(@"Creating track with diatioanry: %@", trackDictionary);
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
    track.imageURL = ((NSDictionary *)images[0])[@"url"];

    return track;
}

@end
