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
#import "YSYap.h"
#import "YapBuilder.h"

typedef void (^SuccessOrErrorCallback)(BOOL success, NSError *error);
typedef void (^YapsCallback)(NSArray *yaps, NSError *error);

@interface API : NSObject

+ (API *) sharedAPI;

- (void) sendYap:(YapBuilder *)yapBuilder withCallback:(SuccessOrErrorCallback)callback;
- (void) postSessions:(NSString *)phoneNumber withCallback:(SuccessOrErrorCallback)callback;
- (void) confirmSessionWithCode:(NSString *)code withCallback:(SuccessOrErrorCallback)callback;
- (void) getYapsWithCallback:(YapsCallback)callback;

@end
