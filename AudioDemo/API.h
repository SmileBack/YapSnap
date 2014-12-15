//
//  API.h
//  YapSnap
//
//  Created by Daniel Rodriguez on 10/8/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>
#import "YSTrack.h"

typedef void (^SuccessOrErrorCallback)(BOOL success, NSError *error);


@interface API : NSObject

+ (API *) sharedAPI;

- (void) postYapToContacts:(NSArray *)contacts withCallback:(SuccessOrErrorCallback)callback;
- (void) postSessions:(NSString *)phoneNumber withCallback:(SuccessOrErrorCallback)callback;
- (void) confirmSessionWithCode:(NSString *)code withCallback:(SuccessOrErrorCallback)callback;

+ (UNIHTTPJsonResponse *) getYaps;

#pragma mark - Music
- (void) sendSong:(YSTrack *) song withCallback:(SuccessOrErrorCallback) callback;

@end
