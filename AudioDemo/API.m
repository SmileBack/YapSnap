//
//  API.m
//  YapSnap
//
//  Created by Daniel Rodriguez on 10/8/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import "Global.h"
#import "API.h"
#import <Unirest.h>
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

+ (UNIHTTPJsonResponse *) postToPath:(NSString *)path withParameters:(NSMutableDictionary *)parameters {
    
    NSString *fullUrl = [NSString stringWithFormat:@"%@%@", [self serverUrl], path];
    NSDictionary* headers = @{@"accept": @"application/json"};
    
    NSString *session_token = [Global retrieveValueForKey:@"session_token"];
    if (session_token) {
        [parameters setValue:session_token forKey:@"session_token"];
    }
    
    // NOTE: this is a synchronous request
    UNIHTTPJsonResponse *response = [[UNIRest post:^(UNISimpleRequest *request) {
        [request setUrl:fullUrl];
        [request setHeaders:headers];
        [request setParameters:parameters];
    }] asJson];
    
    return response;
}


+ (UNIHTTPJsonResponse *) postYapToContacts:(NSArray *)contacts {
    
    NSArray *pathComponents = [NSArray arrayWithObjects:
                               [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject],
                               @"MyAudioMemo.m4a",
                               nil];
    NSURL *outputFileURL = [NSURL fileURLWithPathComponents:pathComponents];
    NSString* recipients = [[contacts valueForKey:@"phoneNumber"] componentsJoinedByString:@", "];
    NSMutableDictionary *parameters = [@{@"recording":outputFileURL, @"recipients":recipients} mutableCopy];
    
    NSString *fullUrlString = [NSString stringWithFormat:@"%@%@", [self serverUrl], @"/yaps"];
    //NSURL *fullUrl = [NSURL URLWithString:fullUrlString];
    NSDictionary* headers = @{@"accept": @"application/json"};
    
    NSString *session_token = [Global retrieveValueForKey:@"session_token"];
    if (session_token) {
        [parameters setValue:session_token forKey:@"session_token"];
    }
    
    // NOTE: this is a synchronous request
    UNIHTTPJsonResponse *response = [[UNIRest post:^(UNISimpleRequest *request) {
        [request setUrl:fullUrlString];
        [request setHeaders:headers];
        [request setParameters:parameters];
    }] asJson];
    
    return response;
}

+ (NSString *) serverUrl {
    //return @"http://localhost:4000"; // local dev server
    return @"http://yapsnap.herokuapp.com"; // production
}

- (void) sendSong:(YSTrack *)song withCallback:(SuccessOrErrorCallback)callback
{
    NSString *url = [API serverUrl]; //TODO USE REAL ENDPOINT

    //TODO USE REAL SESSION TOKEN
    NSDictionary *params = @{@"session_token": @"dummy_token",//self.sessionToken,
                             @"name": song.name,
                             @"spotify_id": song.spotifyID,
                             @"image": song.imageURL};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager POST:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //        NSLog(@"JSON: %@", responseObject);
        NSDictionary *response = responseObject;
        callback(YES, nil);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        callback(NO, error);
    }];
}

@end
