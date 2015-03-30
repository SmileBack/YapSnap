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
#import "YSPushManager.h"
#import "Environment.h"

@interface API()

@property (nonatomic, strong) NSString *sessionToken;
@property (nonatomic, strong) NSString *apiUrl;
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

- (NSString *) apiUrl
{
    if (!_apiUrl) {
        _apiUrl = [Environment sharedInstance].apiURL;
    }
    return _apiUrl;
}

#pragma mark - Generic Methods
- (NSString *) urlForEndpoint:(NSString *)endpoint
{
    return [NSString stringWithFormat:@"%@%@", self.apiUrl, endpoint];
}

- (NSMutableDictionary *)paramsWithDict:(NSDictionary *)dict
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:dict];

    if (self.sessionToken) {
        NSLog(@"Session token: %@", self.sessionToken);
        params[@"session_token"] = self.sessionToken;
    }

    return params;
}

- (NSDictionary *) paramsWithDict:(NSDictionary *)dict andYapBuilder:(YapBuilder *)yapBuilder
{
    NSMutableDictionary *params = [self paramsWithDict:dict];
    
    params[@"text"] = yapBuilder.text;
    
    NSString* recipients = [[yapBuilder.contacts valueForKey:@"phoneNumber"] componentsJoinedByString:@", "];
    params[@"recipients"] = recipients;
    
    params[@"duration"] = [NSNumber numberWithFloat:yapBuilder.duration];
    
    // Send Color
    CGFloat red;
    CGFloat green;
    CGFloat blue;
    CGFloat alpha;
    [yapBuilder.color getRed:&red green:&green blue:&blue alpha:&alpha];
    NSMutableArray* rgbColorComponents = [NSMutableArray arrayWithCapacity:3];
    for (NSNumber* number in @[[NSNumber numberWithFloat:red * 255.0], [NSNumber numberWithFloat:green * 255.0], [NSNumber numberWithFloat:blue * 255.0]])
    {
        [rgbColorComponents addObject:number.stringValue];
    }
    params[@"color_rgb"] = rgbColorComponents; //[NSArray arrayWithObjects:@"0", @"84", @"255", nil],
    
    // Photo stuff
    if (yapBuilder.imageAwsUrl)
        params[@"aws_photo_url"] = yapBuilder.imageAwsUrl;
    
    if (yapBuilder.imageAwsEtag)
        params[@"aws_photo_etag"] = yapBuilder.imageAwsEtag;
    
    return params;
}


- (void) processFailedOperation:(AFHTTPRequestOperation *)operation
{
    if (operation.response.statusCode == 401) {
        [self logout:^(BOOL success, NSError *error) {
        }];
        NSLog(@"Invalid Session Notification triggered");
    }
}

#pragma mark - Sessions

- (void) openSession:(NSString *)phoneNumber withCallback:(SuccessOrErrorCallback)callback
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:[self urlForEndpoint:@"sessions"]
       parameters:[self paramsWithDict:@{@"phone": phoneNumber}]
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              NSLog(@"sessions call finished: %@", responseObject);
              
              YSUser *user = [YSUser new];
              user.phone = phoneNumber;
              [YSUser setCurrentUser:user];
              
              callback(YES, nil);
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              Mixpanel *mixpanel = [Mixpanel sharedInstance];
              [mixpanel track:@"API Error - openSession"];
              
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
    [manager POST:[self urlForEndpoint:@"sessions/confirm"]
       parameters:params
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              NSDictionary *json = responseObject;
              
              YSUser *user = [YSUser userFromDictionary:json];
              [YSUser setCurrentUser:user];
              self.sessionToken = user.sessionToken;
              
              NSLog(@"responseObject: %@", responseObject);
              NSLog(@"user: %@", user);
              
              callback(user, nil);
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              Mixpanel *mixpanel = [Mixpanel sharedInstance];
              [mixpanel track:@"API Error - confirmSessionWithCode"];
              
              [self processFailedOperation:operation];
              callback(nil, error);
          }];
}

- (void) logout:(SuccessOrErrorCallback)callback
{
    NSLog(@"Logging out");
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:[self urlForEndpoint:@"sessions/logout"]
       parameters:[self paramsWithDict:@{}]
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              callback(YES, nil);
              [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_LOGOUT object:nil];
              [YSUser wipeCurrentUserData];
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              callback(NO, error);
              NSLog(@"Error logging out: %@", error);
              [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_LOGOUT object:nil];
              [YSUser wipeCurrentUserData];
          }];
}

#pragma mark - Yaps

- (NSArray *) sendYapBuilder:(YapBuilder *)yapBuilder withCallback:(SuccessOrErrorCallback)callback
{
    // First, if there is a photo upload it to AWS.  The URL and Etag will be returned.
    if (yapBuilder.image) {
        __weak API *weakSelf = self;
        [[AmazonAPI sharedAPI] uploadPhoto:yapBuilder.image withCallback:^(NSString *url, NSString *etag, NSError *error) {
            if (error) {
                Mixpanel *mixpanel = [Mixpanel sharedInstance];
                [mixpanel track:@"AWS Error - uploadPhoto"];
                
                NSLog(@"Error uploading photo to amazon! %@", error);
                [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_YAP_SENDING_FAILED object:nil];
                callback(NO, error);
            } else {
                yapBuilder.imageAwsUrl = url;
                yapBuilder.imageAwsEtag = etag;
                [weakSelf sendYap:yapBuilder withCallback:callback];
            }
        }];
    } else {
        [self sendYap:yapBuilder withCallback:callback];
    }

    return [YSYap pendingYapsWithYapBuilder:yapBuilder];
}

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
            Mixpanel *mixpanel = [Mixpanel sharedInstance];
            [mixpanel track:@"AWS Error - uploadYap"];
            
            NSLog(@"Error uploading voice file to amazon! %@", error);
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_YAP_SENDING_FAILED object:nil];
            callback(NO, error);
        }
        
        NSDictionary *params = [weakSelf paramsWithDict:@{@"type": MESSAGE_TYPE_VOICE,
                                                          @"aws_recording_url": url,
                                                          @"aws_recording_etag": etag}
                                          andYapBuilder:builder];
        
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        [manager POST:[weakSelf urlForEndpoint:@"audio_messages"]
           parameters:params
              success:^(AFHTTPRequestOperation *operation, id responseObject) {
                  NSLog(@"yaps call finished: %@", responseObject);
                  if ([responseObject isKindOfClass:[NSArray class]]) {
                      NSArray *yapDicts = responseObject;
                      NSArray *yaps = [YSYap yapsWithArray:yapDicts];
                      [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_YAP_SENT object:yaps];
                  }
                  callback(YES, nil);
              }
              failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                  Mixpanel *mixpanel = [Mixpanel sharedInstance];
                  [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_YAP_SENDING_FAILED object:nil];
                  [mixpanel track:@"API Error - sendVoiceYap"];
                  
                  NSLog(@"Error: %@", error);
                  callback(NO, error);
              }];
        
    }];
}

- (void) sendSongYap:(YapBuilder *)builder withCallback:(SuccessOrErrorCallback)callback
{
    NSString *url = [self urlForEndpoint:@"audio_messages"]; //TODO USE REAL ENDPOINT
    
    YSTrack *song = builder.track;
    
    NSDictionary *params = [self paramsWithDict:@{@"spotify_song_name": song.name,
                                                  @"spotify_song_id": song.spotifyID,
                                                  @"spotify_image_url": song.imageURL,
                                                  @"spotify_album_name": song.albumName,
                                                  @"spotify_artist_name": song.artistName,
                                                  @"spotify_full_song_url": song.spotifyURL,
                                                  @"spotify_preview_url": song.previewURL,
                                                  @"type": MESSAGE_TYPE_SPOTIFY}
                                  andYapBuilder:builder];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSArray *yapDicts = responseObject;
        NSArray *yaps = [YSYap yapsWithArray:yapDicts];
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_YAP_SENT object:yaps];
        callback(YES, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_YAP_SENDING_FAILED object:nil];
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel track:@"API Error - sendSongYap"];
        
        callback(NO, error);
        NSLog(@"Error: %@", error);
    }];
}

- (void) getYapsWithCallback:(YapsCallback)callback
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];

    [manager GET:[self urlForEndpoint:@"audio_messages"]
       parameters:[self paramsWithDict:@{}]
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
//              NSLog(@"YAPS: In callback from API %@", responseObject);
              NSArray *yapDicts = responseObject; //Assuming it is an array
              NSArray *yaps = [YSYap yapsWithArray:yapDicts];
              callback(yaps, nil);
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              Mixpanel *mixpanel = [Mixpanel sharedInstance];
              [mixpanel track:@"API Error - getYaps"];
              
             [self processFailedOperation:operation];
              callback(NO, error);
          }];
}

- (void) updateYapStatus:(YSYap *)yap toStatus:(NSString *)status withCallback:(SuccessOrErrorCallback)callback
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    [manager PUT:[self urlForEndpoint:[NSString stringWithFormat:@"audio_messages/%@", yap.yapID]]
      parameters:[self paramsWithDict:@{@"id": yap.yapID,
                                        @"status" : status}]
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             if (![responseObject isKindOfClass:[NSDictionary class]]) {
                 callback(NO, nil);
                 return;
             }
             NSDictionary *responseDict = responseObject;
             YSYap *yap = [YSYap yapWithDictionary:responseDict];
             [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_YAP_OPENED object:yap];
             callback(YES, nil);
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             Mixpanel *mixpanel = [Mixpanel sharedInstance];
             [mixpanel track:@"API Error - updateYapStatus"];
             
             [self processFailedOperation:operation];
             callback(NO, error);
         }];
}

- (void) unopenedYapsCountWithCallback:(YapCountCallback)callback
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    [manager GET:[self urlForEndpoint:@"audio_messages/number_of_unopened_yaps"]
      parameters:[self paramsWithDict:@{}]
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             NSDictionary *response = responseObject;
             callback(response[@"count"], nil);
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             Mixpanel *mixpanel = [Mixpanel sharedInstance];
             [mixpanel track:@"API Error - unopenedYapsCount"];
             
             [self processFailedOperation:operation];
             callback(NO, error);
             NSLog(@"Error Getting Yaps Unopened Count %@", error);
         }];
}

- (void) getMeWithCallback:(UserCallback)callback
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    [manager GET:[self urlForEndpoint:@"users/self"]
      parameters:[self paramsWithDict:@{}]
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             if (![responseObject isKindOfClass:[NSDictionary class]]) {
                 callback(nil, [NSError errorWithDomain:@"REsponse error" code:1 userInfo:nil]);
                 return;
             }
             NSDictionary *response = responseObject;
             YSUser *me = [YSUser userFromDictionary:response];
             [YSUser setCurrentUser:me];
             callback(me, nil);
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             Mixpanel *mixpanel = [Mixpanel sharedInstance];
             [mixpanel track:@"API Error - getMe"];
             
             [self processFailedOperation:operation];
             callback(nil, error);
             NSLog(@"Error Getting Me %@", error);
         }];
}

# pragma mark - Block User

- (void) blockUserId:(NSNumber *)userId withCallback:(SuccessOrErrorCallback)callback
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *endpoint = [NSString stringWithFormat:@"users/self/block_user/%d", userId.intValue];
    [manager PATCH:[self urlForEndpoint:endpoint]
       parameters:[self paramsWithDict:@{}]
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              NSLog(@"responseObject: %@", responseObject);
              callback(YES, nil);
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              Mixpanel *mixpanel = [Mixpanel sharedInstance];
              [mixpanel track:@"API Error - blockUser"];
              
              [self processFailedOperation:operation];
              callback(NO, error);
          }];
}

# pragma mark - Friends & Top Friends

- (void) friends:(FriendsCallback)callback
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];

    [manager GET:[self urlForEndpoint:@"users/self/friends"]
      parameters:[self paramsWithDict:@{}]
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             if (![responseObject isKindOfClass:[NSArray class]]) {
                 callback(nil, NO);
                 return;
             }
             NSArray *friends = [YSUser usersFromArray:responseObject];
             callback(friends, nil);
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             Mixpanel *mixpanel = [Mixpanel sharedInstance];
             [mixpanel track:@"API Error - friends"];
             
             NSLog(@"Friends Error: %@", error);
             callback(nil, error);
         }];
}

- (void) topFriendsForUser:(YSUser *)user withCallback:(FriendsCallback)callback
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    NSString *endpoint = [NSString stringWithFormat:@"users/top_friends/%d", user.userID.intValue];

    [manager GET:[self urlForEndpoint:endpoint]
      parameters:[self paramsWithDict:@{}]
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             if (![responseObject isKindOfClass:[NSArray class]]) {
                 callback(nil, NO);
                 return;
             }
             NSArray *friends = [YSUser usersFromArray:responseObject];
             NSLog(@"Top Friends: %@", friends);
             
             callback(friends, nil);
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             Mixpanel *mixpanel = [Mixpanel sharedInstance];
             [mixpanel track:@"API Error - topFriends"];
             
             NSLog(@"Top Friends Error: %@", error);
             callback(nil, error);
         }];
}

# pragma mark - Updating of User Data
- (void) updateUserData:(NSDictionary *)properties withCallback:(SuccessOrErrorCallback)callback
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];

    NSMutableDictionary *props = [NSMutableDictionary dictionaryWithDictionary:properties];
    props[@"app_version"] = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    props[@"os_version"] = [[UIDevice currentDevice] systemVersion];
    props[@"os"] = @"iOS";
    props[@"push_enabled"] = [NSNumber numberWithBool:[YSPushManager sharedPushManager].pushEnabled];
    
    NSDictionary *params = [self paramsWithDict:props];

    NSString *endpoint = @"users/self";
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
              Mixpanel *mixpanel = [Mixpanel sharedInstance];
              [mixpanel track:@"API Error - updateUserData"];
              
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
