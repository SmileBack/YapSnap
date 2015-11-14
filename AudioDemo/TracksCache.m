//
//  TracksCache.m
//  YapTap
//
//  Created by Jon Deokule on 3/29/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "TracksCache.h"
#import "YTTrackGroup.h"
#import "NSArray+Shuffle.h"

@interface TracksCache()
@end

@implementation TracksCache

static TracksCache *sharedCache;

+ (TracksCache *) sharedCache
{
    if (!sharedCache) {
        sharedCache = [TracksCache new];
    }
    
    return sharedCache;
}

- (void) loadTracksForGroup:(YTTrackGroup*)trackGroup withCallback:(TracksCallback)callback
{
    __weak TracksCache *weakSelf = self;
    [[API sharedAPI]
     retrieveTracksForCategory:trackGroup
     withCallback:^(NSArray *songs, NSError *error) {
         if (songs) {
             NSLog(@"There are songs");
             if ([trackGroup.apiString  isEqual: @"trending_tracks"]) {
                 weakSelf.trendingSongs = songs;//[songs shuffledArray];
             } else if ([trackGroup.apiString isEqual: @"flirtatious_tracks"]) {
                 weakSelf.flirtatiousSongs = [songs shuffledArray];
             } else if ([trackGroup.apiString isEqual: @"funny_tracks"]) {
                 weakSelf.funnySongs = [songs shuffledArray];
             } else if ([trackGroup.apiString isEqual: @"nostalgic_tracks"]) {
                 weakSelf.nostalgicSongs = [songs shuffledArray];
             } else if ([trackGroup.apiString  isEqual: @"celebrate_tracks"]) {
                 weakSelf.celebrateSongs = [songs shuffledArray];
             } else if ([trackGroup.apiString  isEqual: @"happy_tracks"]) {
                 weakSelf.happySongs = [songs shuffledArray];
             } else if ([trackGroup.apiString  isEqual: @"sad_tracks"]) {
                 weakSelf.sadSongs = [songs shuffledArray];
             } else if ([trackGroup.apiString  isEqual: @"genre_hiphop_tracks"]) {
                 weakSelf.hipHopSongs = songs;//[songs shuffledArray];
             } else if ([trackGroup.apiString  isEqual: @"genre_rock_tracks"]) {
                 weakSelf.rockSongs = songs;//[songs shuffledArray];
             } else if ([trackGroup.apiString  isEqual: @"genre_pop_tracks"]) {
                 weakSelf.popSongs = songs;//[songs shuffledArray];
             } else if ([trackGroup.apiString  isEqual: @"genre_edm_tracks"]) {
                 weakSelf.edmSongs = songs;//[songs shuffledArray];
             } else if ([trackGroup.apiString  isEqual: @"genre_country_tracks"]) {
                 weakSelf.countrySongs = songs;//[songs shuffledArray];
             } else if ([trackGroup.apiString  isEqual: @"genre_latin_tracks"]) {
                 weakSelf.latinSongs = songs;//[songs shuffledArray];
             } else if ([trackGroup.apiString  isEqual: @"genre_film_tracks"]) {
                 weakSelf.filmSongs = songs;//[songs shuffledArray];
             } else if ([trackGroup.apiString  isEqual: @"romantic_tracks"]) {
                 weakSelf.romanticSongs = [songs shuffledArray];
             } else if ([trackGroup.apiString  isEqual: @"inspire_tracks"]) {
                 weakSelf.inspireSongs = [songs shuffledArray];
             }
         } else {
             NSLog(@"Something went wrong");
         }
         
         if (callback) {
             if ([trackGroup.apiString  isEqual: @"trending_tracks"]) {
                 songs = self.trendingSongs;
             } else if ([trackGroup.apiString isEqual: @"flirtatious_tracks"]) {
                 songs = self.flirtatiousSongs;
             } else if ([trackGroup.apiString isEqual: @"funny_tracks"]) {
                 songs = self.funnySongs;
             } else if ([trackGroup.apiString isEqual: @"nostalgic_tracks"]) {
                 songs = self.nostalgicSongs;
             } else if ([trackGroup.apiString  isEqual: @"celebrate_tracks"]) {
                 songs = self.celebrateSongs;
             } else if ([trackGroup.apiString  isEqual: @"happy_tracks"]) {
                 songs = self.happySongs;
             } else if ([trackGroup.apiString  isEqual: @"sad_tracks"]) {
                 songs = self.sadSongs;
             } else if ([trackGroup.apiString  isEqual: @"genre_hiphop_tracks"]) {
                 songs = self.hipHopSongs;
             } else if ([trackGroup.apiString  isEqual: @"genre_rock_tracks"]) {
                 songs = self.rockSongs;
             } else if ([trackGroup.apiString  isEqual: @"genre_pop_tracks"]) {
                 songs = self.popSongs;
             } else if ([trackGroup.apiString  isEqual: @"genre_edm_tracks"]) {
                 songs = self.edmSongs;
             } else if ([trackGroup.apiString  isEqual: @"genre_country_tracks"]) {
                 songs = self.countrySongs;
             } else if ([trackGroup.apiString  isEqual: @"genre_latin_tracks"]) {
                 songs = self.latinSongs;
             } else if ([trackGroup.apiString  isEqual: @"genre_film_tracks"]) {
                 songs = self.filmSongs;
             } else if ([trackGroup.apiString  isEqual: @"romantic_tracks"]) {
                 songs = self.romanticSongs;
             } else if ([trackGroup.apiString  isEqual: @"inspire_tracks"]) {
                 songs = self.inspireSongs;
             }
         
             callback(songs, error);
         }
     }];
}



- (BOOL) haveSongsForTrackGroup:(YTTrackGroup*)trackGroup {
    if ([trackGroup.apiString  isEqual: @"trending_tracks"]) {
        return self.trendingSongs.count > 0;
    } else if ([trackGroup.apiString  isEqual: @"flirtatious_tracks"]) {
        return self.flirtatiousSongs.count > 0;
    } else if ([trackGroup.apiString  isEqual: @"nostalgic_tracks"]) {
        return self.nostalgicSongs.count > 0;
    } else if ([trackGroup.apiString  isEqual: @"funny_tracks"]) {
        return self.funnySongs.count > 0;
    } else if ([trackGroup.apiString  isEqual: @"celebrate_tracks"]) {
        return self.celebrateSongs.count > 0;
    } else if ([trackGroup.apiString  isEqual: @"happy_tracks"]) {
        return self.happySongs.count > 0;
    } else if ([trackGroup.apiString  isEqual: @"sad_tracks"]) {
        return self.sadSongs.count > 0;
    } else if ([trackGroup.apiString  isEqual: @"genre_hiphop_tracks"]) {
        return self.hipHopSongs.count > 0;
    } else if ([trackGroup.apiString  isEqual: @"genre_rock_tracks"]) {
        return self.rockSongs.count > 0;
    } else if ([trackGroup.apiString  isEqual: @"genre_pop_tracks"]) {
        return self.popSongs.count > 0;
    } else if ([trackGroup.apiString  isEqual: @"genre_edm_tracks"]) {
        return self.edmSongs.count > 0;
    } else if ([trackGroup.apiString  isEqual: @"genre_country_tracks"]) {
        return self.countrySongs.count > 0;
    } else if ([trackGroup.apiString  isEqual: @"genre_latin_tracks"]) {
        return self.latinSongs.count > 0;
    } else if ([trackGroup.apiString  isEqual: @"genre_film_tracks"]) {
        return self.filmSongs.count > 0;
    } else if ([trackGroup.apiString  isEqual: @"romantic_tracks"]) {
        return self.romanticSongs.count > 0;
    } else if ([trackGroup.apiString  isEqual: @"inspire_tracks"]) {
        return self.inspireSongs.count > 0;
    } else {
        return NO;
    }
}

- (NSArray*) cachedSongsForTrackGroup:(YTTrackGroup*)trackGroup {
    if ([trackGroup.apiString  isEqual: @"trending_tracks"]) {
        return self.trendingSongs;
    } else if ([trackGroup.apiString isEqual: @"flirtatious_tracks"]) {
        return self.flirtatiousSongs;
    } else if ([trackGroup.apiString isEqual: @"nostalgic_tracks"]) {
        return self.nostalgicSongs;
    } else if ([trackGroup.apiString isEqual: @"funny_tracks"]) {
        return self.funnySongs;
    } else if ([trackGroup.apiString  isEqual: @"celebrate_tracks"]) {
        return self.celebrateSongs;
    } else if ([trackGroup.apiString  isEqual: @"happy_tracks"]) {
        return self.happySongs;
    } else if ([trackGroup.apiString  isEqual: @"sad_tracks"]) {
        return self.sadSongs;
    } else if ([trackGroup.apiString  isEqual: @"genre_hiphop_tracks"]) {
        return self.hipHopSongs;
    } else if ([trackGroup.apiString  isEqual: @"genre_rock_tracks"]) {
        return self.rockSongs;
    } else if ([trackGroup.apiString  isEqual: @"genre_pop_tracks"]) {
        return self.popSongs;
    } else if ([trackGroup.apiString  isEqual: @"genre_edm_tracks"]) {
        return self.edmSongs;
    } else if ([trackGroup.apiString  isEqual: @"genre_country_tracks"]) {
        return self.countrySongs;
    } else if ([trackGroup.apiString  isEqual: @"genre_latin_tracks"]) {
        return self.latinSongs;
    } else if ([trackGroup.apiString  isEqual: @"genre_film_tracks"]) {
        return self.filmSongs;
    } else if ([trackGroup.apiString  isEqual: @"inspire_tracks"]) {
        return self.inspireSongs;
    } else if ([trackGroup.apiString  isEqual: @"romantic_tracks"]) {
        return self.romanticSongs;
    } else {
        return self.trendingSongs;
    }
}

- (void) shuffleCachedTracks {
//    self.trendingSongs = [self.trendingSongs shuffledArray];
    self.flirtatiousSongs = [self.flirtatiousSongs shuffledArray];
    self.nostalgicSongs = [self.nostalgicSongs shuffledArray];
    self.funnySongs = [self.funnySongs shuffledArray];
    self.celebrateSongs = [self.celebrateSongs shuffledArray];
    self.happySongs = [self.happySongs shuffledArray];
    self.sadSongs = [self.sadSongs shuffledArray];
//    self.hipHopSongs = [self.hipHopSongs shuffledArray];
//    self.rockSongs = [self.rockSongs shuffledArray];
//    self.popSongs = [self.popSongs shuffledArray];
//    self.edmSongs = [self.edmSongs shuffledArray];
//    self.countrySongs = [self.countrySongs shuffledArray];
//    self.latinSongs = [self.latinSongs shuffledArray];
//    self.filmSongs = [self.filmSongs shuffledArray];
    self.romanticSongs = [self.romanticSongs shuffledArray];
    self.inspireSongs = [self.inspireSongs shuffledArray];
}













/*
- (void) shuffleTracksForTrackGroup:(YTTrackGroup*)trackGroup {
    if ([trackGroup.apiString  isEqual: @"trending_tracks"]) {
        self.trendingSongs = [self.trendingSongs shuffledArray];
    } else if ([trackGroup.apiString  isEqual: @"flirtatious_tracks"]) {
        self.flirtatiousSongs = [self.flirtatiousSongs shuffledArray];
    } else if ([trackGroup.apiString  isEqual: @"nostalgic_tracks"]) {
        self.nostalgicSongs = [self.nostalgicSongs shuffledArray];
    } else if ([trackGroup.apiString  isEqual: @"funny_tracks"]) {
        self.funnySongs = [self.funnySongs shuffledArray];
    } else if ([trackGroup.apiString  isEqual: @"celebrate_tracks"]) {
        self.celebrateSongs = [self.celebrateSongs shuffledArray];
    } else if ([trackGroup.apiString  isEqual: @"happy_tracks"]) {
        self.happySongs = [self.happySongs shuffledArray];
    } else if ([trackGroup.apiString  isEqual: @"sad_tracks"]) {
        self.sadSongs = [self.sadSongs shuffledArray];
    } else if ([trackGroup.apiString  isEqual: @"genre_hiphop_tracks"]) {
        self.hipHopSongs = [self.hipHopSongs shuffledArray];
    } else if ([trackGroup.apiString  isEqual: @"genre_rock_tracks"]) {
        self.rockSongs = [self.rockSongs shuffledArray];
    } else if ([trackGroup.apiString  isEqual: @"genre_pop_tracks"]) {
        self.popSongs = [self.popSongs shuffledArray];
    } else if ([trackGroup.apiString  isEqual: @"genre_edm_tracks"]) {
        self.edmSongs = [self.edmSongs shuffledArray];
    } else if ([trackGroup.apiString  isEqual: @"genre_country_tracks"]) {
        self.countrySongs = [self.countrySongs shuffledArray];
    } else if ([trackGroup.apiString  isEqual: @"genre_latin_tracks"]) {
        self.latinSongs = [self.latinSongs shuffledArray];
    }
}
*/

@end
