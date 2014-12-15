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

- (void) postYapToContacts:(NSArray *)contacts withCallback:(SuccessOrErrorCallback)callback
{
    NSDictionary *params = [self yapParamsForContacts:contacts];

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:[self urlForEndpoint:@"/yaps"]
       parameters:params
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              NSLog(@"yaps call finished: %@", responseObject);\
              callback(YES, nil);
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
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

// returns all your yaps
+ (UNIHTTPJsonResponse *) getYaps {    // NOTE: this is a synchronous request
    NSDictionary* headers = @{@"accept": @"application/json"};
    NSString *fullUrlString = [NSString stringWithFormat:@"%@%@", [self serverUrl], @"/yaps"];
    NSMutableDictionary *parameters = [@{} mutableCopy];
    NSString *session_token = [Global retrieveValueForKey:@"session_token"];
    if (session_token) {
        [parameters setValue:session_token forKey:@"session_token"];
    }
    UNIHTTPJsonResponse *response = [[UNIRest get:^(UNISimpleRequest *request) {
        [request setUrl:fullUrlString];
        [request setHeaders:headers];
        [request setParameters:parameters];
    }] asJson];
    
    return response;
}

- (void) sendSong:(YSTrack *)song withCallback:(SuccessOrErrorCallback)callback
{
    NSString *url = [self urlForEndpoint:@"send_song"]; //TODO USE REAL ENDPOINT

    //TODO USE REAL SESSION TOKEN
    NSDictionary *params = @{@"session_token": @"dummy_token",//self.sessionToken,
                             @"name": song.name,
                             @"spotify_id": song.spotifyID,
                             @"image": song.imageURL};

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //        NSLog(@"JSON: %@", responseObject);
//        NSDictionary *response = responseObject;
        
        callback(YES, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        callback(NO, error);
    }];
}

#pragma mark - API Helpers
- (NSDictionary *) yapParamsForContacts:(NSArray *)contacts
{
    NSArray *pathComponents = @[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject], @"MyAudioMemo.m4a"];
    NSURL *outputFileURL = [NSURL fileURLWithPathComponents:pathComponents];

    NSString* recipients = [[contacts valueForKey:@"phoneNumber"] componentsJoinedByString:@", "];
    return [self paramsWithDict:@{@"recording":outputFileURL,
                                  @"recipients":recipients}];
}

@end
