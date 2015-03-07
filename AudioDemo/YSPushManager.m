//
//  SBPushManager.m
//  NightOut
//
//  Created by Jon Deokule on 2/5/14.
//  Copyright (c) 2014 WhoWentOut. All rights reserved.
//

#import "YSPushManager.h"
#import "API.h"

#define IS_IOS_8  ([[[UIDevice currentDevice] systemVersion] compare:@"8.0" options:NSNumericSearch] != NSOrderedAscending)


@interface YSPushManager()

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

- (void) refresh
{
    BOOL enabled;
    if (IS_IOS_8) {
        UIUserNotificationSettings *settings = [[UIApplication sharedApplication] currentUserNotificationSettings];
        UIUserNotificationType types = settings.types;
        enabled = types && types != UIUserNotificationTypeNone;
    } else {
        UIRemoteNotificationType types = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
        enabled = types && types != UIRemoteNotificationTypeNone;
    }

    self.pushEnabled = enabled;
}

- (void) registerForNotifications
{
    UIApplication *application = [UIApplication sharedApplication];
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:(UIRemoteNotificationTypeBadge
                                                                                             |UIRemoteNotificationTypeSound
                                                                                             |UIRemoteNotificationTypeAlert) categories:nil];
        [application registerUserNotificationSettings:settings];
    } else {
        UIRemoteNotificationType myTypes = UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound;
        [application registerForRemoteNotificationTypes:myTypes];
    }

//    UIUserNotificationType types = UIUserNotificationTypeBadge |
//    UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
//    
//    UIUserNotificationSettings *mySettings =
//    [UIUserNotificationSettings settingsForTypes:types categories:nil];
//    
//    UIApplication *app = [UIApplication sharedApplication];
//    [app registerUserNotificationSettings:mySettings];
}

- (void) registeredWithDeviceToken:(NSData *)token
{
    NSString *pushToken = [self tokenDataToString:token];
    
    NSLog(@"Registerd with token: %@", pushToken);
    
    [[API sharedAPI] updateUserPushToken:pushToken
                            withCallBack:^(BOOL success, NSError *error) {
                                //TODO handle callback
                            }];
}

- (void) registrationFailedWithError:(NSError *)error
{
    NSLog(@"Registration error: %@", error);
    //TODO handle error
}

- (void) receivedNotification:(NSDictionary *)notification
{
    // TODO do something with notification
    [[YTNotifications sharedNotifications] showNotificationText:@"You've received a new yap"];
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
