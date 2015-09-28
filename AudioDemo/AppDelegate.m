//
//  AppDelegate.m
//  AudioDemo
//
//  Created by Simon on 24/2/13.
//  Copyright (c) 2013 Appcoda. All rights reserved.
//

#import "AppDelegate.h"
#import <AFNetworking/AFNetworkActivityIndicatorManager.h>
#import <AFNetworking/AFNetworkReachabilityManager.h>
#import <Crashlytics/Crashlytics.h>
#import "ContactManager.h"
#import "YSPushManager.h"
#import "API.h"
#import "Mixpanel.h"
#import "Environment.h"
#import "YapsCache.h"
#import "TracksCache.h"
#import "FeedbackMonitor.h"
#import "SpotifyAPI.h"

#define APP_OPENED_COUNTER @"yaptap.AppOpenedCounter"

@interface AppDelegate()

@property (nonatomic, strong) FeedbackMonitor *feedbackMonitor;

@end

@implementation AppDelegate

+ (AppDelegate *)sharedDelegate
{
    return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    
    [self startMonitoringReachability];
    
    [Crashlytics startWithAPIKey:@"6621dbca453461988440d16db5e4fbe9a79da991"];
    
    [ContactManager sharedContactManager];
   
    [self checkLaunchOptions:launchOptions];
    
    [Mixpanel sharedInstanceWithToken:[Environment sharedInstance].mixpanelToken];
    
    [self bindMixpanelToUser];
    
    [self bindCrashlyticsToUser];
    
    [[YapsCache sharedCache] loadYapsWithCallback:nil];
    
    [[TracksCache sharedCache] loadTracksWithCallback:nil];

    return YES;
}

- (void) checkLaunchOptions:(NSDictionary *)launchOptions
{
    NSDictionary *remoteInfo = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
    if (remoteInfo && [remoteInfo isKindOfClass:[NSDictionary class]] && remoteInfo.count > 0) {
        [[YSPushManager sharedPushManager] receivedNotification:remoteInfo inAppState:[UIApplication sharedApplication].applicationState];
    }
}

- (void)startMonitoringReachability
{
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        
        NSLog(@"Reachability changed: %@", AFStringFromNetworkReachabilityStatus(status));
        
        
        switch (status) {
            case AFNetworkReachabilityStatusReachableViaWWAN:
            case AFNetworkReachabilityStatusReachableViaWiFi:
                // -- Reachable -- //
                NSLog(@"Reachable");
                break;
            case AFNetworkReachabilityStatusNotReachable:
            default:
                // -- Not reachable -- //
                NSLog(@"Not Reachable");
                break;
        }
        
    }];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    NSLog(@"Will Resign Active");

    [[API sharedAPI] unopenedYapsCountWithCallback:^(NSNumber *count, NSError *error) {
        if (error) {
            NSLog(@"Error getting unopened yaps count for badge");
        } else {
            NSLog(@"Unopened Yaps Count: %d", count.description.intValue);
            [UIApplication sharedApplication].applicationIconBadgeNumber = count.description.intValue;
        }
    }];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    NSLog(@"Did Enter Background");
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    NSLog(@"Will Enter Foreground");
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.

    NSLog(@"Did Become Active");
    
    if ([YSUser currentUser] && [YSUser currentUser].userID) {
        [[YSPushManager sharedPushManager] refresh];
        [[YSPushManager sharedPushManager] registerForNotifications];
        //The following line is specifically for push_enabled (btw updateUser is reduntantly called if push notifications are enabled because if push notifications are enabled it triggers didRegisterForRemoteNotificationsWithDeviceToken, which leads to updateUserPushToken to be called)
        [[API sharedAPI] updateUserData:nil withCallback:^(BOOL success, NSError *error) {
            NSLog(@"updated push enabled");
        }];
    }
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Opened App"];
    [mixpanel.people increment:@"Opened App #" by:[NSNumber numberWithInt:1]];
    
    [self increaseAppOpenedCount];
    [self.feedbackMonitor appOpened];
    
    [[SpotifyAPI sharedApi] getAccessToken]; //Activate to get access token
        
    NSLog(@"App Opened Count: %ld", (long)self.appOpenedCount);
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - Push Stuff

// Delegation methods
- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)devToken {
    NSLog(@"Device Token: %@", devToken);
    [[YSPushManager sharedPushManager] registeredWithDeviceToken:devToken];
}

- (void) application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    [application registerForRemoteNotifications];
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err {
    [[YSPushManager sharedPushManager] registrationFailedWithError:err];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    [[YSPushManager sharedPushManager] receivedNotification:userInfo inAppState:application.applicationState];
}

- (void)bindMixpanelToUser
{
    if ([YSUser currentUser] && [YSUser currentUser].userID) {
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel identify:[YSUser currentUser].userID.stringValue];
        [mixpanel.people set:@{
                                @"ID": [YSUser currentUser].userID == nil ? [NSNull null] : [YSUser currentUser].userID,
                                @"$first_name": [YSUser currentUser].firstName == nil ? [NSNull null] : [YSUser currentUser].firstName,
                                @"Last Name": [YSUser currentUser].lastName == nil ? [NSNull null] : [YSUser currentUser].lastName,
                                @"Registered At": [YSUser currentUser].createdAt == nil ? [NSNull null] : [YSUser currentUser].createdAt,
                                @"$email": [YSUser currentUser].email == nil ? [NSNull null] : [YSUser currentUser].email,
                                @"Phone": [YSUser currentUser].phone == nil ? [NSNull null] : [YSUser currentUser].phone,
                                @"Score": [YSUser currentUser].score == nil ? [NSNull null] : [YSUser currentUser].score,
                                }];
        }
}

- (void)bindCrashlyticsToUser
{
    if ([YSUser currentUser] && [YSUser currentUser].userID) {
        NSString *userID = [NSString stringWithFormat:@"%@", [YSUser currentUser].userID];
        
        [Crashlytics setUserIdentifier:userID];
        [Crashlytics setUserName:[YSUser currentUser].firstName];
    }
}

- (FeedbackMonitor *) feedbackMonitor
{
    if (!_feedbackMonitor) {
        _feedbackMonitor = [FeedbackMonitor new];
    }
    
    return _feedbackMonitor;
}

#pragma mark - App Opening Tracker
- (void) increaseAppOpenedCount
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger appOpenedCounter = [defaults integerForKey:APP_OPENED_COUNTER];
    appOpenedCounter++;
    [defaults setInteger:appOpenedCounter forKey:APP_OPENED_COUNTER];
    [defaults synchronize];
}

- (NSInteger) appOpenedCount
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:APP_OPENED_COUNTER];
}

@end
