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

- (void) retrieveTracksFromSpotifyForPlaylist:(NSString *)playlistName withCallback:(SpotifySongCallback)callback
{
    if ([playlistName isEqualToString:@"Trending"]) {
        self.playlistURL = @"https://api.spotify.com/v1/users/spotify/playlists/4hOKQuZbraPDIfaGbM3lKI/tracks";
        
    } else if ([playlistName isEqualToString:@"Funny"]) {
        self.playlistURL = @"https://api.spotify.com/v1/users/spotify/playlists/5FJXhjdILmRA2z5bvz4nzf/tracks";
        
    } else if ([playlistName isEqualToString:@"Nostalgic"]) {
        self.playlistURL = @"https://api.spotify.com/v1/users/spotify/playlists/4ldNPWkhPThHdq0FSxB0EZ/tracks";
        
    } else if ([playlistName isEqualToString:@"Happy"]) {
        self.playlistURL = @"https://api.spotify.com/v1/users/filtr/playlists/0rZJqZmX61rQ4xMkmEWQar/tracks";
        
    } else if ([playlistName isEqualToString:@"Flirty"]) {
        self.playlistURL = @"https://api.spotify.com/v1/users/spotify/playlists/4NDUPAZZ1LBw9wvTOq1Mm2/tracks";
        
    } else if ([playlistName isEqualToString:@"Party"]) {
        self.playlistURL = @"https://api.spotify.com/v1/users/spotify/playlists/63zow2qCS9wMsRJAMffMwP/tracks";
        
    } else if ([playlistName isEqualToString:@"?????"]) {
        self.playlistURL = @"https://api.spotify.com/v1/users/spotify/playlists/63zow2qCS9wMsRJAMffMwP/tracks";
    
    } else if ([playlistName isEqualToString:@"?????"]) {
        self.playlistURL = @"https://api.spotify.com/v1/users/spotify/playlists/63zow2qCS9wMsRJAMffMwP/tracks";
        
    } else if ([playlistName isEqualToString:@"?????"]) {
        self.playlistURL = @"https://api.spotify.com/v1/users/spotify/playlists/63zow2qCS9wMsRJAMffMwP/tracks";
    
    } else {
        self.playlistURL = @"Error";
        NSLog(@"Error");
    }
    
    __weak SpotifyAPI *weakSelf = self;
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [self setAuthorizationOnManager:manager];
    [manager GET:self.playlistURL parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSDictionary *response = responseObject;
        NSLog(@"Response Object: %@", responseObject);
        NSArray *items = response[@"items"];
        
        NSArray *songs = [YSTrack tracksFromDictionaryArray:items inCategory:YES];
        callback(songs, nil);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (operation.response.statusCode == 401) {
            Mixpanel *mixpanel = [Mixpanel sharedInstance];
            [mixpanel track:@"Spotify Error - search (401)"];
            
            //weakSelf.tokenType = nil;
            //weakSelf.token = nil;
            [weakSelf retrieveTracksFromSpotifyForPlaylist:playlistName withCallback:callback];
            //[weakSelf getAccessToken];
        } else {
            callback(nil, error);
        }
    }];
   
    /*
    if ([playlistName isEqualToString:@"Comedy New Releases"]) {
        self.playlistURL = @"https://api.spotify.com/v1/users/spotify/playlists/2dspQtcF977JB0kbsVfjZd/tracks";
        
    } else if ([playlistName isEqualToString:@"Comedy Top Tracks"]) {
        self.playlistURL = @"https://api.spotify.com/v1/users/spotify/playlists/1Hj7y9lWU96vYLPEom2qEw/tracks";
        
    } else if ([playlistName isEqualToString:@"The Laugh List"]) {
        self.playlistURL = @"https://api.spotify.com/v1/users/spotify/playlists/1gxinVbwRfBTm8u9Ilg2Qo/tracks";
        
    } else if ([playlistName isEqualToString:@"British Humor"]) {
        self.playlistURL = @"https://api.spotify.com/v1/users/spotify/playlists/3u4FZFuZc99oVibVNpWzrl/tracks";
        
    } else if ([playlistName isEqualToString:@"Quirck It"]) {
        self.playlistURL = @"https://api.spotify.com/v1/users/spotify/playlists/5uSVaNDK1MqYaE5rTi0RVn/tracks";
        
    } else if ([playlistName isEqualToString:@"Funny Things About Football"]) {
        self.playlistURL = @"https://api.spotify.com/v1/users/spotify/playlists/4YSzEZkXyQD8Gx2z2OomVl/tracks";
        
    } else if ([playlistName isEqualToString:@"Monty Python Emporium"]) {
        self.playlistURL = @"https://api.spotify.com/v1/users/spotify/playlists/2Twy4JGPNrfXj4tCfUyADN/tracks";
    
    } else if ([playlistName isEqualToString:@"Ladies Night"]) {
        self.playlistURL = @"https://api.spotify.com/v1/users/spotify/playlists/5cAjiZhOKpmiopQjEQwg3V/tracks";
        
    } else if ([playlistName isEqualToString:@"20 Questions"]) {
        self.playlistURL = @"https://api.spotify.com/v1/users/spotify/playlists/52VctsYfnswlvPrC09f9Eb/tracks";
        
    } else if ([playlistName isEqualToString:@"Animal Humor"]) {
        self.playlistURL = @"https://api.spotify.com/v1/users/spotify/playlists/4u4nF4ogvWJLCABAhBnz1I/tracks";
        
    } else if ([playlistName isEqualToString:@"Music Jokes"]) {
        self.playlistURL = @"https://api.spotify.com/v1/users/spotify/playlists/2A35dmgrzELFaoCdhljKdF/tracks";
        
    } else if ([playlistName isEqualToString:@"Dating Issues"]) {
        self.playlistURL = @"https://api.spotify.com/v1/users/spotify/playlists/23aBoyL0oNVuFc9B0SHBAW/tracks";
        
    } else if ([playlistName isEqualToString:@"Comedy Goes Country"]) {
        self.playlistURL = @"https://api.spotify.com/v1/users/spotify/playlists/0GhKoiJHUKgggBXUxiKyow/tracks";
    
    } else if ([playlistName isEqualToString:@"Unsolicited Advice"]) {
        self.playlistURL = @"https://api.spotify.com/v1/users/spotify/playlists/5ubDpyt7Bsxn7Yxxi2khwC/tracks";
        
    } else if ([playlistName isEqualToString:@"Office Offensive"]) {
        self.playlistURL = @"https://api.spotify.com/v1/users/spotify/playlists/7MWljdfpMPdchK0llbMz88/tracks";
        
    } else if ([playlistName isEqualToString:@"Love & Marriage"]) {
        self.playlistURL = @"https://api.spotify.com/v1/users/spotify/playlists/51kEQ0ZG3REksX08cf3lzu/tracks";
        
    } else if ([playlistName isEqualToString:@"The Interwebs"]) {
        self.playlistURL = @"https://api.spotify.com/v1/users/spotify/playlists/1aR0iR9yZKCoToAlXo8Y8b/tracks";
        
    } else if ([playlistName isEqualToString:@"Lights, Camera, Comedy!"]) {
        self.playlistURL = @"https://api.spotify.com/v1/users/spotify/playlists/3y6VsDt3U2gMrzalY1U5Qf/tracks";
        
    } else if ([playlistName isEqualToString:@"Louis CK | Collected"]) {
        self.playlistURL = @"https://api.spotify.com/v1/users/spotify/playlists/2g1xDZGflQHIDyxQGQoUI7/tracks";
        
    } else if ([playlistName isEqualToString:@"[Family]"]) {
        self.playlistURL = @"https://api.spotify.com/v1/users/spotify/playlists/1JGLzVvhngik1Tbn9tNKRL/tracks";
        
    } else if ([playlistName isEqualToString:@"Comedy Top Trackss"]) {
        self.playlistURL = @"https://api.spotify.com/v1/users/soundrop/playlists/4wnH0AlKv96zOHGBnUOL94/tracks";
    }
     
     COMEDY PLAYLISTS
     self.playlistOne = @"Comedy New Releases";
     self.playlistTwo = @"Comedy Top Tracks";
     self.playlistThree = @"The Laugh List";
     self.playlistFour = @"British Humour";
     self.playlistFive = @"Quirck It";
     self.playlistSix = @"Funny Things About Football";
     self.playlistSeven = @"Monty Python Emporium";
     self.playlistEight = @"Ladies Night";
     self.playlistNine = @"20 Questions";
     self.playlistTen = @"Animal Humor";
     self.playlistEleven = @"Music Jokes";
     self.playlistTwelve = @"Dating Issues";
     self.playlistThirteen = @"Comedy Goes Country";
     self.playlistFourteen = @"Unsolicited Advice";
     self.playlistFifteen = @"Office Offensive";
     self.playlistSixteen = @"Love & Marriage";
     self.playlistSeventeen = @"The Interwebs";
     self.playlistEighteen = @"Lights, Camera, Comedy!";
     self.playlistNineteen = @"Louis CK | Collected";
     self.playlistTwenty = @"[Family]";
     self.playlistTwentyOne = @"Comedy Top Trackss";
     */
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
        NSArray *songs = [YSTrack tracksFromDictionaryArray:items inCategory:NO];
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
