//
//  API.m
//  YapSnap
//
//  Created by Daniel Rodriguez on 10/8/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import "API.h"
#import "PhoneContact.h"
#import "AmazonAPI.h"

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
        _sessionToken = [YSUser currentUser].sessionToken;
    }
    return _sessionToken;
}

- (NSString *) serverUrl
{
    return @"http://yapsnap.herokuapp.com"; // production
    //return @"http://192.168.1.177:4000"; // local dev server
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

- (void) processFailedOperation:(AFHTTPRequestOperation *)operation
{
    if (operation.response.statusCode == 401) {
        [self logout:nil];
        NSLog(@"Invalid Session Notification triggered");
    }
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
    
    __weak API *weakSelf = self;
    
    [[AmazonAPI sharedAPI] uploadYap:outputFileURL withCallback:^(NSString *url, NSString *etag, NSError *error) {
        if (error) {
            NSLog(@"Error uploading to amazon! %@", error);
            return;
        }
        NSString* recipients = [[builder.contacts valueForKey:@"phoneNumber"] componentsJoinedByString:@", "];
        
        // Send Color
        CGFloat red;
        CGFloat green;
        CGFloat blue;
        CGFloat alpha;
        [builder.color getRed:&red green:&green blue:&blue alpha:&alpha];
        NSMutableArray* rgbColorComponents = [NSMutableArray arrayWithCapacity:3];
        for (NSNumber* number in @[[NSNumber numberWithFloat:red * 255.0], [NSNumber numberWithFloat:green * 255.0], [NSNumber numberWithFloat:blue * 255.0]])
        {
            [rgbColorComponents addObject:number.stringValue];
        }
        
        NSDictionary *params = [weakSelf paramsWithDict:@{@"recipients":recipients,
                                                          @"text": builder.text,
                                                          @"duration": [NSNumber numberWithFloat:builder.duration],
                                                          @"color_rgb": rgbColorComponents, //[NSArray arrayWithObjects:@"0", @"84", @"255", nil],
                                                          @"type": MESSAGE_TYPE_VOICE,
                                                          @"aws_recording_url": url,
                                                          @"aws_etag": etag
                                                          }];
        
        
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        [manager POST:[weakSelf urlForEndpoint:@"/api/v1/audio_messages"]
           parameters:params
              success:^(AFHTTPRequestOperation *operation, id responseObject) {
                  NSLog(@"yaps call finished: %@", responseObject);
                  callback(YES, nil);
              }
              failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                  NSLog(@"Error: %@", error);
                  callback(NO, error);
              }];
        
    }];
}

- (void) sendSongYap:(YapBuilder *)builder withCallback:(SuccessOrErrorCallback)callback
{
    NSString *url = [self urlForEndpoint:@"/api/v1/audio_messages"]; //TODO USE REAL ENDPOINT
    
    NSString* recipients = [[builder.contacts valueForKey:@"phoneNumber"] componentsJoinedByString:@", "];
    
    YSTrack *song = builder.track;
    
    // Send Color
    CGFloat red;
    CGFloat green;
    CGFloat blue;
    CGFloat alpha;
    [builder.color getRed:&red green:&green blue:&blue alpha:&alpha];
    NSMutableArray* rgbColorComponents = [NSMutableArray arrayWithCapacity:3];
    for (NSNumber* number in @[[NSNumber numberWithFloat:red * 255.0], [NSNumber numberWithFloat:green * 255.0], [NSNumber numberWithFloat:blue * 255.0]])
    {
        [rgbColorComponents addObject:number.stringValue];
    }
    
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
                             @"color_rgb": rgbColorComponents, //[NSArray arrayWithObjects:@"0", @"84", @"255", nil],
                             @"type": MESSAGE_TYPE_SPOTIFY
                             };
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        callback(YES, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        callback(NO, error);
        NSLog(@"Error: %@", error);
    }];
}

- (void) openSession:(NSString *)phoneNumber withCallback:(SuccessOrErrorCallback)callback
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:[self urlForEndpoint:@"/api/v1/sessions"]
       parameters:[self paramsWithDict:@{@"phone": phoneNumber}]
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              NSLog(@"sessions call finished: %@", responseObject);
              
              YSUser *user = [YSUser new];
              user.phone = phoneNumber;
              [YSUser setCurrentUser:user];

              callback(YES, nil);
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             [self processFailedOperation:operation];
              NSLog(@"Error! %@", error);
              callback(NO, error);
          }];
}

- (void) confirmSessionWithCode:(NSString *)code withCallback:(UserCallback)callback
{
    YSUser *currentUser = [YSUser currentUser];
    NSDictionary *params = [self paramsWithDict:@{@"phone": currentUser.phone,
                                                  @"confirmation_code": code}];
    
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:[self urlForEndpoint:@"/api/v1/sessions/confirm"]
       parameters:params
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              NSDictionary *json = responseObject;

              YSUser *user = [YSUser userFromDictionary:json];
              [YSUser setCurrentUser:user];
              
              callback(user, nil);
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             [self processFailedOperation:operation];
              callback(nil, error);
          }];
}

- (void) getYapsWithCallback:(YapsCallback)callback
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];

    [manager GET:[self urlForEndpoint:@"/api/v1/audio_messages"]
       parameters:[self paramsWithDict:@{}]
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              NSArray *yapDicts = responseObject; //Assuming it is an array
              NSArray *yaps = [YSYap yapsWithArray:yapDicts];
              callback(yaps, nil);
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             [self processFailedOperation:operation];
              callback(NO, error);
          }];
}

- (void) yapOpened:(YSYap *)yap withCallback:(SuccessOrErrorCallback)callback
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    [manager PUT:[self urlForEndpoint:[NSString stringWithFormat:@"/api/v1/audio_messages/%@", yap.yapID]]
      parameters:[self paramsWithDict:@{@"id": yap.yapID,
                                        @"status" : @"opened"}]
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             callback(YES, nil);
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             [self processFailedOperation:operation];
             callback(NO, error);
         }];
}

- (void) unopenedYapsCountWithCallback:(YapCountCallback)callback
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    [manager GET:[self urlForEndpoint:@"/api/v1/number_of_unopened_yaps"]
      parameters:[self paramsWithDict:@{}]
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             // Expecting: {"count" : 6}
             NSDictionary *response = responseObject;
             callback(response[@"count"], nil);
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             [self processFailedOperation:operation];
             callback(NO, error);
         }];
}

- (void) logout:(SuccessOrErrorCallback)callback
{
    // TODO POST a call to the backend
    NSLog(@"Logging out");
    [YSUser wipeCurrentUserData];
    callback(YES, nil);
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_LOGOUT object:nil];
}

# pragma mark - Updating of User Data
- (void) updateUserData:(NSDictionary *)properties withCallback:(SuccessOrErrorCallback)callback
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];

    NSDictionary *params = [self paramsWithDict:properties];

    YSUser *currentUser = [YSUser currentUser];
    NSString *endpoint = [NSString stringWithFormat:@"/api/v1/users/%d", currentUser.userID.intValue];
    [manager PUT:[self urlForEndpoint:endpoint]
       parameters:params
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              if ([responseObject isKindOfClass:[NSDictionary class]]) {
                  NSDictionary *dict = responseObject;
                  YSUser *user = [YSUser userFromDictionary:dict];
                  [YSUser setCurrentUser:user];
                  callback(YES, nil);
              } else {
                  callback(NO, nil);
              }
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             [self processFailedOperation:operation];
              callback(NO, error);
          }];
}

- (void) updateUserPushToken:(NSString *)token withCallBack:(SuccessOrErrorCallback)callback
{
    [self updateUserData:@{@"push_token" : token}
            withCallback:callback];
}

- (void) updateFirstName:(NSString *)firstName lastName:(NSString *)lastName email:(NSString *)email withCallBack:(SuccessOrErrorCallback)callback
{
    [self updateUserData:@{@"first_name": firstName,
                           @"last_name": lastName,
                           @"email": email}
            withCallback:callback];
}

- (void) updateFirstName:(NSString *)firstName withCallBack:(SuccessOrErrorCallback)callback
{
    [self updateUserData:@{@"first_name": firstName} withCallback:callback];
}

- (void) updateLastName:(NSString *)lastName withCallBack:(SuccessOrErrorCallback)callback
{
    [self updateUserData:@{@"last_name": lastName} withCallback:callback];
}

- (void) updateEmail:(NSString *)email withCallBack:(SuccessOrErrorCallback)callback
{
    [self updateUserData:@{@"email": email} withCallback:callback];
}

@end
