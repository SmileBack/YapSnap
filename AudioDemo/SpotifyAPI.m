//
//  SpotifyAPI.m
//  YapSnap
//
//  Created by Jon Deokule on 12/13/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import "SpotifyAPI.h"
#import "YSTrack.h"
#import "Environment.h"

#define API_KEY @""

@interface SpotifyAPI()
@property (nonatomic, strong) NSString *tokenType;
@property (nonatomic, strong) NSString *token;
@end

@implementation SpotifyAPI

static SpotifyAPI *sharedInstance;

+ (SpotifyAPI *) sharedApi
{
    if (!sharedInstance) {
        sharedInstance = [SpotifyAPI new];
        [sharedInstance getAccessToken];
    }

    return sharedInstance;
}

- (void) getAccessToken
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];

    NSString *value = [NSString stringWithFormat:@"Basic %@", [Environment sharedInstance].spotifyToken];
    [manager.requestSerializer setValue:value forHTTPHeaderField:@"Authorization"];

    __weak SpotifyAPI *weakSelf = self;
    [manager POST:@"https://accounts.spotify.com/api/token"
       parameters:@{@"grant_type": @"client_credentials"}
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              NSLog(@"Response: %@", responseObject);
              if ([responseObject isKindOfClass:[NSDictionary class]]) {
                  NSDictionary *response = responseObject;
                  weakSelf.tokenType = response[@"token_type"];
                  weakSelf.token = response[@"access_token"];
              }
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              NSLog(@"Error: %@", error);
          }];
}

- (void) setAuthorizationOnManager:(AFHTTPRequestOperationManager *)manager
{
    if (self.token && self.tokenType) {
        NSString *value = [NSString stringWithFormat:@"%@ %@", self.tokenType, self.token];
        [manager.requestSerializer setValue:value forHTTPHeaderField:@"Authorization"];
    } else {
        NSLog(@"NO TOKEN!!");
    }
}

- (void) searchSongs:(NSString *)searchString withCallback:(SpotifySongCallback)callback
{
    NSString *url = @"https://api.spotify.com/v1/search";

    NSDictionary *params = @{@"q": searchString,
                             @"type": @"track",
                             @"limit": @50};

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [self setAuthorizationOnManager:manager];
    [manager GET:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *response = responseObject;
        NSArray *items = response[@"tracks"][@"items"];

        NSArray *songs = [YSTrack tracksFromDictionaryArray:items];
        callback(songs, nil);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        callback(nil, error);
    }];
}


@end
