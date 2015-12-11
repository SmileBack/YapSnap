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
#import <SDWebImage/SDWebImagePrefetcher.h>
#import "Flurry.h"


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
    
    NSString* recipients = yapBuilder.contactsList;
    params[@"recipients"] = recipients;
    
    params[@"duration"] = [NSNumber numberWithFloat:yapBuilder.duration];
    
    if (yapBuilder.originYapID) {
        params[@"origin_yap_id"] = yapBuilder.originYapID;
    }
    params[@"public"] = yapBuilder.isPublic ? @"true" : @"false";
    
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
    if (yapBuilder.yapImageAwsUrl)
        params[@"aws_photo_url"] = yapBuilder.yapImageAwsUrl;
    
    if (yapBuilder.yapImageAwsEtag)
        params[@"aws_photo_etag"] = yapBuilder.yapImageAwsEtag;
    
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
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              callback(NO, error);
              NSLog(@"Error logging out: %@", error);
          }];
    // Eventually stick this in the success response
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_LOGOUT object:nil];
    [YSUser wipeCurrentUserData];
}

- (void) clearYaps:(SuccessOrErrorCallback)callback
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager PATCH:[self urlForEndpoint:@"users/self/clear_yaps"]
        parameters:[self paramsWithDict:@{}]
           success:^(AFHTTPRequestOperation *operation, id responseObject) {
               callback(YES, nil);
               NSLog(@"Cleared Yaps Successfully");
           }
           failure:^(AFHTTPRequestOperation *operation, NSError *error) {
               callback(NO, error);
               NSLog(@"Error clearing yaps: %@", error);
               
               [self processFailedOperation:operation];
           }];
}

- (void) sendFriendRequests:(AddFriendsBuilder *)addFriendsBuilder withCallback:(SuccessOrErrorCallback)callback
{
    NSDictionary *params = @{@"recipients": addFriendsBuilder.contactsList};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:[self urlForEndpoint:@"friends/add"]
       parameters:[self paramsWithDict:params]
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              callback(YES, nil);
              NSLog(@"Added friends successfully");
              NSLog(@"responseObject: %@", responseObject);
              
              if ([responseObject isKindOfClass:[NSArray class]]) {
                  NSArray *yapDicts = responseObject;
                  NSArray *yaps = [YSYap yapsWithArray:yapDicts];
                  [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_FRIEND_REQUEST_SENT object:nil userInfo:@{@"yaps": yaps}];
              }
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              callback(NO, error);
              NSLog(@"Error adding friends: %@", error);
              
              [self processFailedOperation:operation];
          }];
}

- (void) confirmFriendFromYap:(YSYap *)yap withCallback:(SuccessOrErrorCallback)callback
{
    NSDictionary *params = @{@"sender_id": yap.senderID};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:[self urlForEndpoint:@"friends/confirm"]
       parameters:[self paramsWithDict:params]
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              callback(YES, nil);
              NSLog(@"Friend confirmed successfully");
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              callback(NO, error);
              NSLog(@"Error confirming friend: %@", error);
              
              [self processFailedOperation:operation];
          }];
}

#pragma mark - Yaps

- (NSArray *) sendYapBuilder:(YapBuilder *)yapBuilder withCallback:(SuccessOrErrorCallback)callback
{
    // First, if there is a photo upload it to AWS.  The URL and Etag will be returned.
    if (yapBuilder.yapImage) {
        __weak API *weakSelf = self;
        [[AmazonAPI sharedAPI] uploadPhoto:yapBuilder.yapImage withCallback:^(NSString *url, NSString *etag, NSError *error) {
            if (error) {
                Mixpanel *mixpanel = [Mixpanel sharedInstance];
                [mixpanel track:@"AWS Error - uploadPhoto"];
                
                NSLog(@"Error uploading photo to amazon! %@", error);
                [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_YAP_SENDING_FAILED object:nil];
                callback(NO, error);
                
            } else {
                yapBuilder.yapImageAwsUrl = url;
                yapBuilder.yapImageAwsEtag = etag;
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
    
    if (!builder.awsVoiceURL || [builder.awsVoiceURL length] == 0) {
        [[AmazonAPI sharedAPI] uploadYap:outputFileURL withCallback:^(NSString *url, NSString *etag, NSError *error) {
            if (error) {
                Mixpanel *mixpanel = [Mixpanel sharedInstance];
                [mixpanel track:@"AWS Error - uploadYap"];
                
                NSLog(@"Error uploading voice file to amazon! %@", error);
                [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_YAP_SENDING_FAILED object:nil];
                callback(NO, error);
            } else {
                NSLog(@"Successfully uploaded voice file to AWS");
            }
            
            NSDictionary *params = [weakSelf paramsWithDict:@{@"type": MESSAGE_TYPE_VOICE,
                                                              @"aws_recording_url": url,
                                                              @"aws_recording_etag": etag,
                                                              @"pitch_value": builder.pitchValueInCentUnits
                                                              }
                                              andYapBuilder:builder];
            
            AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
            [manager POST:[weakSelf urlForEndpoint:@"audio_messages"]
               parameters:params
                  success:^(AFHTTPRequestOperation *operation, id responseObject) {
                      Mixpanel *mixpanel = [Mixpanel sharedInstance];
                      [mixpanel track:@"Sent Yap - Voice"];
                      [mixpanel.people increment:@"Sent Yap - Voice #" by:[NSNumber numberWithInt:1]];
                      
                      if ([responseObject isKindOfClass:[NSArray class]]) {
                          NSArray *yapDicts = responseObject;
                          NSArray *yaps = [YSYap yapsWithArray:yapDicts];
                          [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_YAP_SENT object:nil userInfo:@{@"yaps": yaps}];
                      }
                      callback(YES, nil);
                  }
                  failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                      Mixpanel *mixpanel = [Mixpanel sharedInstance];
                      [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_YAP_SENDING_FAILED object:nil];
                      [mixpanel track:@"API Error - sendVoiceYap"];
                      
                      [self processFailedOperation:operation];
                      
                      NSLog(@"Error: %@", error);
                      callback(NO, error);
                  }];
            
        }];
    } else {
        // THIS GETS TRIGGERED WHEN FORWARDING OF A VOICE YAP OCCURS
        NSDictionary *params = [weakSelf paramsWithDict:@{@"type": MESSAGE_TYPE_VOICE,
                                                          @"aws_recording_url": builder.awsVoiceURL,
                                                          @"aws_recording_etag": @"forwarded_yap",
                                                          @"pitch_value": builder.pitchValueInCentUnits
                                                          }
                                          andYapBuilder:builder];
        
        // TODO: THIS CAN BE CLEANED UP. IT IS IDENTICAL TO CODE ABOVE!!!
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        [manager POST:[weakSelf urlForEndpoint:@"audio_messages"]
           parameters:params
              success:^(AFHTTPRequestOperation *operation, id responseObject) {
                  Mixpanel *mixpanel = [Mixpanel sharedInstance];
                  [mixpanel track:@"Sent Yap - Voice"];
                  [mixpanel.people increment:@"Sent Yap - Voice #" by:[NSNumber numberWithInt:1]];
                  
                  if ([responseObject isKindOfClass:[NSArray class]]) {
                      NSArray *yapDicts = responseObject;
                      NSArray *yaps = [YSYap yapsWithArray:yapDicts];
                      [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_YAP_SENT object:nil userInfo:@{@"yaps": yaps}];
                  }
                  callback(YES, nil);
              }
              failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                  Mixpanel *mixpanel = [Mixpanel sharedInstance];
                  [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_YAP_SENDING_FAILED object:nil];
                  [mixpanel track:@"API Error - sendVoiceYap"];
                  
                  [self processFailedOperation:operation];
                  
                  NSLog(@"Error: %@", error);
                  callback(NO, error);
              }];
    }
}

- (void) sendSongYap:(YapBuilder *)builder withCallback:(SuccessOrErrorCallback)callback
{
    NSString *url = [self urlForEndpoint:@"audio_messages"];
    
    YSTrack *song = builder.track;
    NSMutableDictionary *dictionary;
    if ([builder.messageType isEqualToString:MESSAGE_TYPE_SPOTIFY]) {
        dictionary = [NSMutableDictionary dictionaryWithDictionary:@{@"spotify_song_name": song.name,
                                                                     @"spotify_song_id": song.spotifyID,
                                                                     @"spotify_image_url": song.albumImageURL,
                                                                     @"spotify_artist_name": song.artistName,
                                                                     @"spotify_full_song_url": song.spotifyURL,
                                                                     @"spotify_preview_url": song.previewURL,
                                                                     @"type": builder.messageType,
                                                                     @"seconds_to_fast_forward": song.secondsToFastForward,
                                                                     }];
        if (song.albumName) {
            dictionary[@"spotify_album_name"] = song.albumName;
        } else { // TODO: Hack, back-end fails when album name isn't specified, so just specify a fake one.
            dictionary[@"spotify_album_name"] = @"no album name";
        }
    } else {
        // iTunes track
        dictionary = [NSMutableDictionary dictionaryWithDictionary:@{@"spotify_preview_url": builder.awsVoiceURL,
                                                                     @"type": builder.messageType
                                                                     }];
        if (builder.track.albumName) {
            dictionary[@"spotify_album_name"] = builder.track.albumName;
        } else {
            dictionary[@"spotify_album_name"] = @"Album";
        }
        
        if (builder.track.artistName) {
            dictionary[@"spotify_artist_name"] = builder.track.artistName;
        } else {
            dictionary[@"spotify_artist_name"] = @"Artist";
        }
        
        if (builder.track.name) {
            dictionary[@"spotify_song_name"] = builder.track.name;
        } else {
            dictionary[@"spotify_song_name"] = @"Song Name";
        }

        if (builder.track.albumImageURL) {
            dictionary[@"spotify_image_url"] = builder.track.albumImageURL;
        }
    }
    
    NSDictionary *params = [self paramsWithDict:dictionary
                                  andYapBuilder:builder];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Send Song Yap call finished: %@", responseObject);
        
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel track:@"Sent Yap - Song"];
        [mixpanel.people increment:@"Sent Yap - Song #" by:[NSNumber numberWithInt:1]];
        
        [Flurry logEvent:@"Sent Yap - Song"];
        
        if ([responseObject isKindOfClass:[NSArray class]]) {
            NSArray *yapDicts = responseObject;
            NSArray *yaps = [YSYap yapsWithArray:yapDicts];
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_YAP_SENT object:nil userInfo:@{@"yaps": yaps}];
        }
        
        callback(YES, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_YAP_SENDING_FAILED object:nil];
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel track:@"API Error - sendSongYap"];
        
        [self processFailedOperation:operation];
        
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
             NSArray *yapDicts = responseObject; //Assuming it is an array
             NSArray *yaps = [YSYap yapsWithArray:yapDicts];
             //NSLog(@"Yaps: %@", responseObject);
             
             NSMutableArray *imagesToPrefetch = [NSMutableArray new];
             for (YSYap *yap in yaps) {
                 if (!yap.wasOpened && yap.receivedByCurrentUser && yap.yapPhotoURL && ![yap.yapPhotoURL isEqual:[NSNull null]]) {
                     NSLog(@"Prefetching: %@", yap.yapPhotoURL);
                     [imagesToPrefetch addObject:yap.yapPhotoURL];
                 }
             }
             if (imagesToPrefetch.count > 0) {
                 [[SDWebImagePrefetcher sharedImagePrefetcher] prefetchURLs:imagesToPrefetch];
             }
             
             callback(yaps, nil);
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             Mixpanel *mixpanel = [Mixpanel sharedInstance];
             [mixpanel track:@"API Error - getYaps"];
             
             [self processFailedOperation:operation];
             callback(NO, error);
         }];
}

- (void) updateYapStatus:(YSYap *)yap toStatus:(NSString *)status withCallback:(IsFriendCallback)callback
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    [manager PUT:[self urlForEndpoint:[NSString stringWithFormat:@"audio_messages/%@", yap.yapID]]
      parameters:[self paramsWithDict:@{@"id": yap.yapID,
                                        @"status" : status}]
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             if (![responseObject isKindOfClass:[NSDictionary class]]) {
                 callback(NO, nil, NO);
                 return;
             }
             NSDictionary *yapDict = responseObject;
             YSYap *yap = [YSYap yapWithDictionary:yapDict];
             
             NSNumber *isFriend = yapDict[@"is_friend"];
             if (!isFriend || isFriend.class == [NSNull class]) {
                 isFriend = nil;
             }
             
             [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_YAP_OPENED object:yap];
             callback(YES, nil, isFriend);
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             Mixpanel *mixpanel = [Mixpanel sharedInstance];
             [mixpanel track:@"API Error - updateYapStatus"];
             
             [self processFailedOperation:operation];
             callback(NO, error, NO);
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
             
             [self processFailedOperation:operation];
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
             
             [self processFailedOperation:operation];
             
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
    NSLog(@"push enabled: %@", props[@"push_enabled"]);
    
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

#pragma mark - Metric events

- (void) sendSearchTerm:(NSString*)searchTerm withCallback:(SuccessOrErrorCallback)callback
{
    NSDictionary *params = [self paramsWithDict:@{@"search_term": searchTerm}];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:[self urlForEndpoint:@"search_terms"]
       parameters:params
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              callback(YES, nil);
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              Mixpanel *mixpanel = [Mixpanel sharedInstance];
              [mixpanel track:@"API Error - sendSearchTerm"];
              [self processFailedOperation:operation];
              callback(NO, error);
          }];
}

#pragma mark - Retrieve Tracks
/*
 - (void) retrieveTracksForCategory:(YTTrackGroup*)category withCallback:(OnboardingTracksCallback)callback
 {
 AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
 
 NSString *url = [NSString stringWithFormat:@"/spotify/%@", category.apiString];
 [manager GET:[self urlForEndpoint:url]
 parameters:[self paramsWithDict:@{}]
 success:^(AFHTTPRequestOperation *operation, id responseObject) {
 NSDictionary *response = responseObject;
 //NSLog(@"Response Object: %@", responseObject);
 NSArray *items = response[@"tracks"][@"items"];
 NSLog(@"Items: %@", items);
 
 NSArray *songs = [YSTrack tracksFromSpotifyDictionaryArray:items inCategory:NO];
 callback(songs, nil);
 }
 failure:^(AFHTTPRequestOperation *operation, NSError *error) {
 
 [self processFailedOperation:operation];
 callback(NO, error);
 }];
 NSLog(@"category in API.m: %@", category);
 }
 */


- (void) retrieveTracksForCategory:(YTTrackGroup*)category withCallback:(OnboardingTracksCallback)callback
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    NSString *url = @"/spotify_songs";
    [manager GET:[self urlForEndpoint:url]
      parameters:[self paramsWithDict:@{@"category": category.apiString}]
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             NSArray *songs = nil;
             if ([responseObject isKindOfClass:[NSArray class]]) {
                 NSArray *response = responseObject;
                 //NSLog(@"Items: %@", response);
                 songs = [YSTrack tracksFromYapTapDictionaryArray:response inCategory:NO];
             }
             
             callback(songs, nil);
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             
             [self processFailedOperation:operation];
             callback(NO, error);
         }];
    NSLog(@"category in API.m: %@", category);
}

# pragma mark - iTunes
- (void) getItunesTracks:(ITunesTracksCallback)callback
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    NSString *url = @"users/self/uploaded_tracks";
    [manager GET:[self urlForEndpoint:url]
      parameters:[self paramsWithDict:@{}]
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             NSArray *tracks = nil;
             if ([responseObject isKindOfClass:[NSArray class]]) {
                 NSArray *response = responseObject;
                 //NSLog(@"Tracks: %@", response);
                 tracks = [YSITunesTrack tracksFromArrayOfDictionaries:response];
             }
             callback(tracks, nil);
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             [self processFailedOperation:operation];
             callback(NO, error);
         }];
}

- (void) uploadItunesTrack:(YSiTunesUpload *)track withCallback:(ITunesUploadCallback)callback
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    NSString *url = @"/uploaded_tracks";
    NSMutableDictionary *params = [self paramsWithDict:@{@"aws_song_url": track.awsSongUrl,
                                                         @"aws_song_etag": track.awsSongEtag,
                                                         @"persistent_id": track.persistentID}];
    
    if (track.label)
        params[@"label"] = track.label;
    if (track.artistName)
        params[@"artist_name"] = track.artistName;
    if (track.songName)
        params[@"song_name"] = track.songName;
    if (track.awsAlbumImageUrl && track.awsAlbumImageEtag) {
        params[@"aws_image_url"] = track.awsAlbumImageUrl;
        params[@"aws_image_etag"] = track.awsAlbumImageEtag;
    }
    if (track.genreName) {
        params[@"genre"] = track.genreName;
    }
    if (track.albumName) {
        params[@"album_name"] = track.albumName;
    }
    
    [manager POST:[self urlForEndpoint:url]
       parameters:params
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              YSITunesTrack *returnedTrack = nil;
              if ([responseObject isKindOfClass:[NSDictionary class]]) {
                  NSDictionary *response = responseObject;
                  NSLog(@"Track response: %@", response);
                  returnedTrack = [YSITunesTrack trackFromDictionary:response];
              }
              callback(returnedTrack, nil);
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              [self processFailedOperation:operation];
              callback(NO, error);
          }];
}

@end

