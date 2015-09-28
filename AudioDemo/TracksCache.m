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

- (void) loadTracksWithCallback:(TracksCallback)callback
{
    __weak TracksCache *weakSelf = self;
    [[API sharedAPI]
     retrieveTracksForCategory:[YTTrackGroup defaultTrackGroup]
     withCallback:^(NSArray *songs, NSError *error) {
         if (songs) {
             NSLog(@"There are songs");
             weakSelf.songs = [songs shuffledArray];
         } else {
             NSLog(@"Something went wrong");
         }
     }];
}

- (void) shuffleTracks {
    self.songs = [self.songs shuffledArray];
}

@end
