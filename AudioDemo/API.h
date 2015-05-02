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
#import "AddFriendsBuilder.h"

#define NOTIFICATION_INVALID_SESSION @"com.yapsnap.InvalidSessionNotification"
#define NOTIFICATION_LOGOUT @"com.yapsnap.LogoutNotification"
#define NOTIFICATION_YAP_OPENED @"com.yapsnap.YapOpened"
#define NOTIFICATION_YAP_SENT @"com.yaptap.YapSent"
#define NOTIFICATION_YAP_SENDING_FAILED @"com.yaptap.YapSendingFailed"

typedef void (^SuccessOrErrorCallback)(BOOL success, NSError *error);
typedef void (^YapsCallback)(NSArray *yaps, NSError *error);
typedef void (^YapCountCallback)(NSNumber *count, NSError *error);
typedef void (^UserCallback)(YSUser *user, NSError *error);
typedef void (^FriendsCallback)(NSArray *friends, NSError *error);
typedef void (^IsFriendCallback)(BOOL success, NSError *error, NSNumber *isFriend);

@interface API : NSObject

+ (API *) sharedAPI;

- (NSArray *) sendYapBuilder:(YapBuilder *)yapBuilder withCallback:(SuccessOrErrorCallback)callback;
- (void) openSession:(NSString *)phoneNumber withCallback:(SuccessOrErrorCallback)callback;
- (void) confirmSessionWithCode:(NSString *)code withCallback:(UserCallback)callback;
- (void) getYapsWithCallback:(YapsCallback)callback;
- (void) updateYapStatus:(YSYap *)yap toStatus:(NSString *)status withCallback:(IsFriendCallback)callback;
- (void) unopenedYapsCountWithCallback:(YapCountCallback)callback;
- (void) logout:(SuccessOrErrorCallback)callback;
- (void) friends:(FriendsCallback)callback;
- (void) topFriendsForUser:(YSUser *)user withCallback:(FriendsCallback)callback;
- (void) getMeWithCallback:(UserCallback)callback;
- (void) blockUserId:(NSNumber *)userId withCallback:(SuccessOrErrorCallback)callback;
- (void) clearYaps:(SuccessOrErrorCallback)callback;
- (void) addFriends:(AddFriendsBuilder *)addFriendsBuilder withCallback:(SuccessOrErrorCallback)callback;
- (void) confirmFriendFromYap:(YSYap *)yap withCallback:(SuccessOrErrorCallback)callback;

# pragma mark - Updating of User Data
- (void) updateUserData:(NSDictionary *)properties withCallback:(SuccessOrErrorCallback)callback;
- (void) updateUserPushToken:(NSString *)token withCallBack:(SuccessOrErrorCallback)callback;
- (void) updateFirstName:(NSString *)firstName lastName:(NSString *)lastName email:(NSString *)email withCallBack:(SuccessOrErrorCallback)callback;
- (void) updateFirstName:(NSString *)firstName withCallBack:(SuccessOrErrorCallback)callback;
- (void) updateLastName:(NSString *)lastName withCallBack:(SuccessOrErrorCallback)callback;
- (void) updateEmail:(NSString *)email withCallBack:(SuccessOrErrorCallback)callback;

@end
