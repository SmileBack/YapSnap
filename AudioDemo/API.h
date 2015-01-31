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
#import "YSUser.h"
#import "YapBuilder.h"

#define NOTIFICATION_INVALID_SESSION @"com.yapsnap.InvalidSessionNotification"

typedef void (^SuccessOrErrorCallback)(BOOL success, NSError *error);
typedef void (^YapsCallback)(NSArray *yaps, NSError *error);
typedef void (^YapCountCallback)(NSNumber *count, NSError *error);
typedef void (^UserCallback)(YSUser *user, NSError *error);

@interface API : NSObject

+ (API *) sharedAPI;

- (void) sendYap:(YapBuilder *)yapBuilder withCallback:(SuccessOrErrorCallback)callback;
- (void) openSession:(NSString *)phoneNumber withCallback:(SuccessOrErrorCallback)callback;
- (void) confirmSessionWithCode:(NSString *)code withCallback:(UserCallback)callback;
- (void) getYapsWithCallback:(YapsCallback)callback;
- (void) yapOpened:(YSYap *)yap withCallback:(SuccessOrErrorCallback)callback;
- (void) unopenedYapsCountWithCallback:(YapCountCallback)callback;

# pragma mark - Updating of User Data
- (void) updateUserData:(NSDictionary *)properties withCallback:(SuccessOrErrorCallback)callback;
- (void) updateUserPushToken:(NSString *)token withCallBack:(SuccessOrErrorCallback)callback;
- (void) updateFirstName:(NSString *)firstName lastName:(NSString *)lastName email:(NSString *)email withCallBack:(SuccessOrErrorCallback)callback;

@end
