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
@property (nonatomic, strong) NSArray *songs;

+ (TracksCache *) sharedCache;

- (void) loadTracksWithCallback:(TracksCallback)callback;

- (void) shuffleTracks;

@end
