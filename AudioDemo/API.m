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

@implementation API

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


+ (UNIHTTPJsonResponse *) postYap {
    
    NSArray *pathComponents = [NSArray arrayWithObjects:
                               [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject],
                               @"MyAudioMemo.m4a",
                               nil];
    NSURL *outputFileURL = [NSURL fileURLWithPathComponents:pathComponents];
    NSMutableDictionary *parameters = [@{@"recording":outputFileURL} mutableCopy];
    
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

@end
