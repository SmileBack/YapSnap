//
//  SBPushManager.h
//  NightOut
//
//  Created by Jon Deokule on 2/5/14.
//  Copyright (c) 2014 WhoWentOut. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YSPushManager : NSObject

@property (nonatomic) BOOL pushEnabled;

//@property (nonatomic) BOOL registered;

- (void) receivedPushNotificationWithUserInfo:(NSDictionary *)userInfo forApplication:(UIApplication *)application;

+ (YSPushManager *) sharedPushManager;

- (void) registerForNotifications;
- (void) registeredWithDeviceToken:(NSData *)token;
- (void) registrationFailedWithError:(NSError *) error;

- (void) receivedNotification:(NSDictionary *)notification;
@end
