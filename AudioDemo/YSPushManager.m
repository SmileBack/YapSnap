//
//  SBPushManager.m
//  NightOut
//
//  Created by Jon Deokule on 2/5/14.
//  Copyright (c) 2014 WhoWentOut. All rights reserved.
//

#import "YSPushManager.h"
#import "API.h"
#import "YapsCache.h"

#define IS_IOS_8  ([[[UIDevice currentDevice] systemVersion] compare:@"8.0" options:NSNumericSearch] != NSOrderedAscending)

@interface YSPushManager()

// A little funky, but we basically want to 'replay' received notifications that we get once the app becomes active
// and view controllers that listen to notifications can respond to them appropriately
@property NSMutableSet *deferredNotifications;
@property BOOL applicationIsActive;

@end

static YSPushManager *_sharedPushManager;

@implementation YSPushManager

+ (YSPushManager *) sharedPushManager
{
    if (!_sharedPushManager) {
        _sharedPushManager = [YSPushManager new];
        
        [_sharedPushManager refresh];
    }

    return _sharedPushManager;
}

- (id)init {
    if (self = [super init]) {
        self.deferredNotifications = [NSMutableSet set];
        self.applicationIsActive = NO;
        __weak YSPushManager *weakSelf = self;
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
                                                          object:nil
                                                           queue:[NSOperationQueue currentQueue]
                                                      usingBlock:^(NSNotification *note) {
                                                          weakSelf.applicationIsActive = YES;
                                                          for (NSDictionary* notification in weakSelf.deferredNotifications) {
                                                              [weakSelf receivedNotification:notification inAppState:UIApplicationStateInactive];
                                                          }
                                                          [weakSelf.deferredNotifications removeAllObjects];
                                                      }];
    }
    return self;
}

- (void) refresh
{
    BOOL enabled;
    // This is only applicable after iOS8
    UIUserNotificationSettings *settings = [[UIApplication sharedApplication] currentUserNotificationSettings];
    UIUserNotificationType types = settings.types;
    enabled = types && types != UIUserNotificationTypeNone;

    self.pushEnabled = enabled;
}

- (void) registerForNotifications
{
    UIApplication *application = [UIApplication sharedApplication];
    
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)])
    {
        UIUserNotificationType userNotificationTypes = (UIUserNotificationTypeAlert |
                                                        UIUserNotificationTypeBadge |
                                                        UIUserNotificationTypeSound);
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:userNotificationTypes
                                                                                 categories:nil];
        [application registerUserNotificationSettings:settings];
        [application registerForRemoteNotifications];
    }
/*    else
    {
        [application registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge |
                                                         UIRemoteNotificationTypeAlert |
                                                         UIRemoteNotificationTypeSound)];
    }
 */
    //Before:
    /*
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:(UIRemoteNotificationTypeBadge
                                                                                             |UIRemoteNotificationTypeSound
                                                                                             |UIRemoteNotificationTypeAlert) categories:nil];
        [application registerUserNotificationSettings:settings];
    } else {
        UIRemoteNotificationType myTypes = UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound;
        [application registerForRemoteNotificationTypes:myTypes];
    }
    */
}

- (void) registeredWithDeviceToken:(NSData *)token
{
    NSString *pushToken = [self tokenDataToString:token];
    
    NSLog(@"Registerd with token: %@", pushToken);
    
    [[API sharedAPI] updateUserPushToken:pushToken
                            withCallBack:^(BOOL success, NSError *error) {
                                if (error) {
                                    Mixpanel *mixpanel = [Mixpanel sharedInstance];
                                    [mixpanel track:@"API Error - updateUserPushToken"];
                                }
                            }];
}

- (void) registrationFailedWithError:(NSError *)error
{
    NSLog(@"Registration error: %@", error);
    //TODO handle error
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Error - registrationFailedWithError"];
}

#pragma mark - Receiving Notifications
- (void) receivedANewYapInBackground:(BOOL)inBackground
{
    [[YapsCache sharedCache] loadYapsWithCallback:nil];
    if (inBackground) {
        [[NSNotificationCenter defaultCenter] postNotificationName:NEW_YAP_NOTIFICATION object:[NSNumber numberWithBool:inBackground]];
    } else {
        double delay = 0.5;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[YTNotifications sharedNotifications] showNotificationText:@"You've Received a New Yap!"];
        });
    }
}

- (void) receivedANewFriendInBackground:(BOOL)inBackground
{
    if (inBackground) {
        [[NSNotificationCenter defaultCenter] postNotificationName:NEW_FRIEND_NOTIFICATION object:[NSNumber numberWithBool:inBackground]];
    } else {
        double delay = 0.5;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[YTNotifications sharedNotifications] showNotificationText:@"You Just Made a New Friend!"];
        });
    }
}

- (void) receivedNotification:(NSDictionary *)notification inAppState:(UIApplicationState)state
{
    if (self.applicationIsActive) {
        BOOL backgroundNotification = state == UIApplicationStateInactive;
        
        if ([notification[@"type"] isEqual: @"new_yap"]) {
            [self receivedANewYapInBackground:backgroundNotification];
        } else if ([notification[@"type"] isEqual: @"new_friend"]) {
            [self receivedANewFriendInBackground:backgroundNotification];
        }
    } else {
        [self.deferredNotifications addObject:notification];
    }
}

#pragma mark - Helpers
- (id) tokenDataToString:(NSData *)data
{
    if (!data || data.class == [NSNull class]) return [NSNull null];
    
    return [[[[data description]
              stringByReplacingOccurrencesOfString: @"<" withString: @""]
             stringByReplacingOccurrencesOfString: @">" withString: @""]
            stringByReplacingOccurrencesOfString: @" " withString: @""];
}

#pragma mark - Push Notifications
- (void) receivedPushNotificationWithUserInfo:(NSDictionary *)userInfo forApplication:(UIApplication *)application
{
//    [Notification processRemoteNotifications:[userInfo objectForKey:@"aps"]];
}


@end
