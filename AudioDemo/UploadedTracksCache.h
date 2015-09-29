//
//  UploadedTracksCache.h
//  YapTap
//
//  Created by Jon Deokule on 3/29/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "API.h"

@interface UploadedTracksCache : NSObject
@property (nonatomic, strong) NSArray *uploadedTracks;

+ (UploadedTracksCache *) sharedCache;

- (void) loadUploadedTracksWithCallback:(UploadedTracksCallback)callback;

@end
