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
@property (nonatomic, strong) NSString *playlistURL;
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
              //NSLog(@"Response: %@", responseObject);
              if ([responseObject isKindOfClass:[NSDictionary class]]) {
                  NSDictionary *response = responseObject;
                  weakSelf.tokenType = response[@"token_type"];
                  weakSelf.token = response[@"access_token"];
                  
                  Mixpanel *mixpanel = [Mixpanel sharedInstance];
                  [mixpanel track:@"Spotify Success - token"];
              }
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              NSLog(@"Error: %@", error);
              Mixpanel *mixpanel = [Mixpanel sharedInstance];
              [mixpanel track:@"Spotify Error - token"];
          }];
}

- (NSDictionary *) getAuthorizationHeaders
{
    NSString *token = [self getAuthorizationValue];
    if (token) {
        return @{@"Authorization": token};
    }
    return nil;
}

- (NSString *) getAuthorizationValue
{
    if (!self.tokenType || !self.token) {
        return nil;
    }
    return [NSString stringWithFormat:@"%@ %@", self.tokenType, self.token];
}

- (void) setAuthorizationOnManager:(AFHTTPRequestOperationManager *)manager
{
    if (self.token && self.tokenType) {
        NSString *value = [self getAuthorizationValue];
        [manager.requestSerializer setValue:value forHTTPHeaderField:@"Authorization"];
    } else {
        NSLog(@"NO TOKEN!!");
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel track:@"Spotify - token doesn't exist for user"];
    }
}

- (void) retrieveTracksFromSpotifyForSearchString:(NSString *)searchString withCallback:(SpotifySongCallback)callback
{
    NSString *url = @"https://api.spotify.com/v1/search";

    NSDictionary *params = @{@"q": searchString,
                             @"type": @"track",
                             @"limit": @50};
    
    __weak SpotifyAPI *weakSelf = self;
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [self setAuthorizationOnManager:manager];//!!!
    [manager GET:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *response = responseObject;
        NSLog(@"Response Object: %@", responseObject);
        NSArray *items = response[@"tracks"][@"items"];
        NSArray *songs = [YSTrack tracksFromSpotifyDictionaryArray:items inCategory:NO];
        callback(songs, nil);   
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (operation.response.statusCode == 401) {
            Mixpanel *mixpanel = [Mixpanel sharedInstance];
            [mixpanel track:@"Spotify Error - search (401)"];
            
            //weakSelf.tokenType = nil;
            //weakSelf.token = nil;
            [weakSelf retrieveTracksFromSpotifyForSearchString:searchString withCallback:callback];
            //[weakSelf getAccessToken];
         } else {
             callback(nil, error);
         }
    }];
}



/* JSON FORMAT
 NSError *error;
 NSData *jsonData = [NSJSONSerialization dataWithJSONObject:response
 options:(NSJSONWritingOptions)    (YES ? NSJSONWritingPrettyPrinted : 0)
 error:&error];
 
 if (! jsonData) {
 NSLog(@"bv_jsonStringWithPrettyPrint: error: %@", error.localizedDescription);
 NSString *json = @"{}";
 NSLog(@"json: %@", json);
 } else {
 NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
 NSLog(@"json: %@", json);
 }
 */


@end
