//
//  YapsCache.m
//  YapTap
//
//  Created by Jon Deokule on 3/29/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "YapsCache.h"

@interface YapsCache()
@end

@implementation YapsCache

static YapsCache *sharedCache;

+ (YapsCache *) sharedCache
{
    if (!sharedCache) {
        sharedCache = [YapsCache new];
    }
    
    return sharedCache;
}

- (void) loadYapsWithCallback:(YapsCallback)callback
{
    __weak YapsCache *weakSelf = self;
    [[API sharedAPI] getYapsWithCallback:^(NSArray *yaps, NSError *error) {
        if (yaps) {
            weakSelf.yaps = yaps;
        }
        if (callback)
            callback(yaps, error);
    }];
}

@end
