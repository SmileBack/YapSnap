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
    
    track.iTunesTrackID = trackDict[@"itunes_track_id"];

    track.label = trackDict[@"label"];
    track.artistName = trackDict[@"artist_name"];
    track.songName = trackDict[@"song_name"];
    track.persistentID = trackDict[@"persistent_id"];

    track.awsSongUrl = trackDict[@"aws_song_url"];
    track.awsSongEtag = trackDict[@"aws_song_etag"];
    track.awsArtworkUrl = trackDict[@"aws_artwork_url"];
    track.awsArtworkEtag = trackDict[@"aws_artwork_etag"];

    return track;
}

@end
