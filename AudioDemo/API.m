//
//  API.m
//  YapSnap
//
//  Created by Daniel Rodriguez on 10/8/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import "Global.h"
#import "API.h"
#import "PhoneContact.h"

@interface API()

@property (nonatomic, strong) NSString *sessionToken;
@end

@implementation API

static API *sharedAPI;

+ (API *) sharedAPI
{
    if (!sharedAPI) {
        sharedAPI = [API new];
        [AFHTTPRequestOperationManager manager].requestSerializer = [AFJSONRequestSerializer serializer];
    }

    return sharedAPI;
}

- (NSString *)sessionToken
{
    if (!_sessionToken) {
        _sessionToken = [Global retrieveValueForKey:@"session_token"];
    }
    return _sessionToken;
}

- (NSString *) serverUrl
{
    //return @"http://localhost:4000"; // local dev server
    return @"http://yapsnap.herokuapp.com"; // production
    //return @"http://192.168.1.177:3000";
}

#pragma mark - Generic Methods
- (NSString *) urlForEndpoint:(NSString *)endpoint
{
    return [NSString stringWithFormat:@"%@%@", self.serverUrl, endpoint];
}

- (NSDictionary *)paramsWithDict:(NSDictionary *)dict
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:dict];

    if (self.sessionToken) {
        params[@"session_token"] = self.sessionToken;
    }

    return params;
}

#pragma mark - Public APIs

- (void) sendYap:(YapBuilder *)yapBuilder withCallback:(SuccessOrErrorCallback)callback
{
    if ([MESSAGE_TYPE_VOICE isEqualToString:yapBuilder.messageType]) {
        [[API sharedAPI] sendVoiceYap:yapBuilder withCallback:callback];
    } else {
        [[API sharedAPI] sendSongYap:yapBuilder withCallback:callback];
    }
}

- (void) sendVoiceYap:(YapBuilder *)builder withCallback:(SuccessOrErrorCallback)callback
{
    NSArray *pathComponents = @[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject], @"MyAudioMemo.m4a"];
    NSURL *outputFileURL = [NSURL fileURLWithPathComponents:pathComponents];
    
    NSString* recipients = [[builder.contacts valueForKey:@"phoneNumber"] componentsJoinedByString:@", "];
    
    NSDictionary *params = [self paramsWithDict:@{@"session_token": self.sessionToken,
                                                  @"recipients":recipients,
                                                  @"text": builder.text,
                                                  @"duration": [NSNumber numberWithFloat:builder.duration],
                                                  @"color": [NSArray arrayWithObjects:@"0", @"84", @"255", nil], //What is the best way to store these numbers on the back end?
                                                  @"type": MESSAGE_TYPE_VOICE
                                                  }];

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:[self urlForEndpoint:@"/audio_messages"]
       parameters:params
constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
    [formData appendPartWithFileURL:outputFileURL name:@"recording" error:nil];
}
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              NSLog(@"yaps call finished: %@", responseObject);\
              callback(YES, nil);
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              NSLog(@"Error: %@", error);
              callback(NO, error);
          }];
}

- (void) sendSongYap:(YapBuilder *)builder withCallback:(SuccessOrErrorCallback)callback
{
    NSString *url = [self urlForEndpoint:@"/audio_messages"]; //TODO USE REAL ENDPOINT
    
    NSString* recipients = [[builder.contacts valueForKey:@"phoneNumber"] componentsJoinedByString:@", "];
    
    YSTrack *song = builder.track;
    
    //TODO USE REAL SESSION TOKEN
    NSDictionary *params = @{@"session_token": self.sessionToken,
                             @"spotify_song_name": song.name,
                             @"spotify_song_id": song.spotifyID,
                             @"spotify_image_url": song.imageURL,
                             @"spotify_album_name": song.albumName,
                             @"spotify_artist_name": song.artistName,
                             @"spotify_full_song_url": song.spotifyURL,
                             @"spotify_preview_url": song.previewURL,
                             @"recipients": recipients,
                             @"text": builder.text,
                             @"duration": [NSNumber numberWithFloat:builder.duration],
                             @"color": builder.colorComponents, //What is the best way to store these numbers on the back end? See line 59 on AddTextViewController to see how it is currently stored.
                             @"type": MESSAGE_TYPE_SPOTIFY
                             };
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        callback(YES, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        callback(NO, error);
    }];
}

- (void) postSessions:(NSString *)phoneNumber withCallback:(SuccessOrErrorCallback)callback
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:[self urlForEndpoint:@"/sessions"]
       parameters:[self paramsWithDict:@{@"phone": phoneNumber}]
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              NSLog(@"sessions call finished: %@", responseObject);
              NSDictionary *response = responseObject;
              [Global storeValue:phoneNumber forKey:@"phone_number"];
              [Global storeValue:response[@"user_id"] forKey:@"current_user_id"];

              callback(YES, nil);
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              NSLog(@"Error! %@", error);
              callback(NO, error);
          }];
}

- (void) confirmSessionWithCode:(NSString *)code withCallback:(SuccessOrErrorCallback)callback
{
    NSDictionary *params = [self paramsWithDict:@{@"phone":[Global retrieveValueForKey:@"phone_number"],
                                                  @"confirmation_code": code}];
    
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:[self urlForEndpoint:@"/sessions/confirm"]
       parameters:params
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              NSLog(@"confirmed session code. response: %@", responseObject);
              NSDictionary *json = responseObject;
              NSString *token = json[@"session_token"];
              [Global storeValue:token forKey:@"session_token"];
              callback(YES, nil);
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              callback(NO, error);
          }];
}

- (void) getYapsWithCallback:(YapsCallback)callback
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];

    [manager GET:[self urlForEndpoint:@"/audio_messages"]
       parameters:[self paramsWithDict:@{}]
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              NSArray *yapDicts = responseObject; //Assuming it is an array
              NSLog(@"yaps: %@", yapDicts);
              NSArray *yaps = [YSYap yapsWithArray:yapDicts];
              callback(yaps, nil);
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              callback(NO, error);
          }];
}

- (void) yapOpened:(YSYap *)yap withCallback:(SuccessOrErrorCallback)callback
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    [manager GET:[self urlForEndpoint:@"/yap_opened"]
      parameters:[self paramsWithDict:@{@"yap_id": yap.yapID}]
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             callback(YES, nil);
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             callback(NO, error);
         }];
}

- (void) unopenedYapsCountWithCallback:(YapCountCallback)callback
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    [manager GET:[self urlForEndpoint:@"/number_of_unopened_yaps"]
      parameters:[self paramsWithDict:@{}]
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             // Expecting: {"count" : 6}
             NSDictionary *response = responseObject;
             callback(response[@"count"], nil);
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             callback(NO, error);
         }];
}

@end
