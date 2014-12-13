//
//  SpotifyAPI.m
//  YapSnap
//
//  Created by Jon Deokule on 12/13/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import "SpotifyAPI.h"
#import "YSTrack.h"

#define API_KEY @""

@implementation SpotifyAPI

static SpotifyAPI *sharedInstance;

+ (SpotifyAPI *) sharedApi
{
    if (!sharedInstance) {
        sharedInstance = [SpotifyAPI new];
    }

    return sharedInstance;
}

- (void) searchSongs:(NSString *)searchString withCallback:(SpotifySongCallback)callback
{
    NSString *url = @"https://api.spotify.com/v1/search";
    
    NSDictionary *params = @{@"q": searchString,
                             @"type": @"track",
                             @"limit": @50};

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager GET:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
//        NSLog(@"JSON: %@", responseObject);
        NSDictionary *response = responseObject;
        NSArray *items = response[@"tracks"][@"items"];
        
        NSArray *songs = [YSTrack tracksFromDictionaryArray:items];
        NSLog(@"about to make callback with songs: %@", songs);
        callback(songs, nil);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        callback(nil, error);
    }];
}


@end
