//
//  API.h
//  YapSnap
//
//  Created by Daniel Rodriguez on 10/8/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Unirest.h>
#import <AFNetworking/AFNetworking.h>
#import "YSTrack.h"

typedef void (^SuccessOrErrorCallback)(BOOL success, NSError *error);


@interface API : NSObject

+ (API *) sharedAPI;

+ (UNIHTTPJsonResponse *) postToPath:(NSString *)path withParameters:(NSMutableDictionary *)parameters;
+ (UNIHTTPJsonResponse *) postYapToContacts:(NSArray*)contacts;
+ (UNIHTTPJsonResponse *) getYaps;

- (void) sendSong:(YSTrack *) song withCallback:(SuccessOrErrorCallback) callback;

@end
