//
//  TracksCache.h
//  YapTap
//
//  Created by Jon Deokule on 3/29/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "API.h"

@interface TracksCache : NSObject
@property (nonatomic, strong) NSArray *trendingSongs;
@property (nonatomic, strong) NSArray *flirtatiousSongs;
@property (nonatomic, strong) NSArray *nostalgicSongs;
@property (nonatomic, strong) NSArray *funnySongs;
@property (nonatomic, strong) NSArray *celebrateSongs;
@property (nonatomic, strong) NSArray *happySongs;
@property (nonatomic, strong) NSArray *sadSongs;
@property (nonatomic, strong) NSArray *hipHopSongs;
@property (nonatomic, strong) NSArray *rockSongs;
@property (nonatomic, strong) NSArray *popSongs;
@property (nonatomic, strong) NSArray *edmSongs;
@property (nonatomic, strong) NSArray *countrySongs;
@property (nonatomic, strong) NSArray *latinSongs;

+ (TracksCache *) sharedCache;

- (void) loadTracksForGroup:(YTTrackGroup*)trackGroup withCallback:(TracksCallback)callback;

- (BOOL) haveSongsForTrackGroup:(YTTrackGroup*)trackGroup;

- (NSArray*) cachedSongsForTrackGroup:(YTTrackGroup*)trackGroup;

- (void) shuffleCachedTracks;

//- (void) shuffleTracksForTrackGroup:(YTTrackGroup*)trackGroup;

@end
