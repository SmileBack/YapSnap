//
//  SpotifyAPI.h
//  YapSnap
//
//  Created by Jon Deokule on 12/13/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>
#import "YTSpotifyCategory.h"

typedef void (^SpotifySongCallback)(NSArray* songs, NSError *error);

@interface SpotifyAPI : NSObject

+ (SpotifyAPI *) sharedApi;

- (void) searchSongs:(NSString *)searchString withCallback:(SpotifySongCallback)callback;

- (void) searchCategory:(YTSpotifyCategory *)searchString withCallback:(SpotifySongCallback)callback;

- (NSDictionary *) getAuthorizationHeaders;

@end
