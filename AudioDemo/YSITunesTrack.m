//
//  YSITunesTrack.m
//  YapTap
//
//  Created by Jon Deokule on 8/26/15.
//

#import "YSITunesTrack.h"

@implementation YSITunesTrack

+ (NSArray *) tracksFromArrayOfDictionaries:(NSArray *)array
{
    NSMutableArray *tracks = [NSMutableArray arrayWithCapacity:array.count];
    
    for (NSDictionary *trackDict in array) {
        YSITunesTrack *track = [YSITunesTrack trackFromDictionary:trackDict];
        [tracks addObject:track];
    }
    
    return tracks;
}

+ (YSITunesTrack *) trackFromDictionary:(NSDictionary *)trackDict
{
    YSITunesTrack *track = [YSITunesTrack new];
    
    track.iTunesTrackID = trackDict[@"itunes_track_id"] != nil && trackDict[@"itunes_track_id"] != [NSNull null] ? trackDict[@"itunes_track_id"] : nil;
    track.label = trackDict[@"label"] != nil && trackDict[@"label"] != [NSNull null] ? trackDict[@"label"] : nil;
    track.artistName = trackDict[@"artist_name"] != nil && trackDict[@"artist_name"] != [NSNull null] ? trackDict[@"artist_name"] : nil;
    track.songName = trackDict[@"song_name"] != nil && trackDict[@"song_name"] != [NSNull null] ? trackDict[@"song_name"] : nil;
    track.persistentID = trackDict[@"persistent_id"] != nil && trackDict[@"persistent_id"] != [NSNull null] ? trackDict[@"persistent_id"] : nil;
    track.awsSongUrl = trackDict[@"aws_song_url"] != nil && trackDict[@"aws_song_url"] != [NSNull null] ? trackDict[@"aws_song_url"] : nil;
    track.awsSongEtag = trackDict[@"aws_song_etag"] != nil && trackDict[@"aws_song_etag"] != [NSNull null] ? trackDict[@"aws_song_etag"] : nil;
    track.awsArtworkUrl = trackDict[@"aws_image_url"] != nil && trackDict[@"aws_image_url"] != [NSNull null] ? trackDict[@"aws_image_url"] : nil;
    track.awsArtworkEtag = trackDict[@"aws_image_etag"] != nil && trackDict[@"aws_image_etag"] != [NSNull null] ? trackDict[@"aws_image_etag"] : nil;

    return track;
}

@end
