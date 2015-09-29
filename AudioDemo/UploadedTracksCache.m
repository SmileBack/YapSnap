//
//  UploadedTracksCache
//  YapTap
//
//  Created by Jon Deokule on 3/29/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "UploadedTracksCache.h"

@interface UploadedTracksCache()
@end

@implementation UploadedTracksCache

static UploadedTracksCache *sharedCache;

+ (UploadedTracksCache *) sharedCache
{
    if (!sharedCache) {
        sharedCache = [UploadedTracksCache new];
    }
    
    return sharedCache;
}

- (void) loadUploadedTracksWithCallback:(UploadedTracksCallback)callback
{
    __weak UploadedTracksCache *weakSelf = self;
    [[API sharedAPI] getItunesTracks:^(NSArray *songs, NSError *error) {
        if (error) {
            // TODO: Display error callback
        } else {
            NSArray* tracksInReverseOrder = [[songs reverseObjectEnumerator] allObjects];
            weakSelf.uploadedTracks = tracksInReverseOrder;
        }
        
        if (callback) {
            NSArray* tracksInReverseOrder = [[songs reverseObjectEnumerator] allObjects];
            callback(tracksInReverseOrder, error);
        }
    }];
}

@end
