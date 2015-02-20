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

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    
    [self startMonitoringReachability];
    
    [Crashlytics startWithAPIKey:@"6621dbca453461988440d16db5e4fbe9a79da991"];
    
    [ContactManager sharedContactManager];
   
    [self checkLaunchOptions:launchOptions];
    
    return YES;
}

- (void) checkLaunchOptions:(NSDictionary *)launchOptions
{
    NSDictionary *remoteInfo = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
    if (remoteInfo && [remoteInfo isKindOfClass:[NSDictionary class]] && remoteInfo.count > 0) {
        // TODO do something with launch options.  For example:
        //   NSNumber *smileGameID = remoteInfo[@"smile_game_id"];
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
    NSLog(@"Did Resign Active");
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
        [[YSPushManager sharedPushManager] registerForNotifications];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - Push Stuff

// Delegation methods
- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)devToken {
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
    [[YSPushManager sharedPushManager] receivedNotification:userInfo];
}


@end
