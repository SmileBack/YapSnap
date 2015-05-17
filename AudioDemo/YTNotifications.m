//
//  YTNotifications.m
//  YapTap
//
//  Created by Jon Deokule on 3/7/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "YTNotifications.h"

#import <CRToast/CRToast.h>

static CGFloat const YTNotificationDuplicateNotificationPreventedByDelay = 3;

@interface YTNotifications()

@property NSMutableSet* recentNotifications;

@end

@implementation YTNotifications

static YTNotifications *_sharedNotifications;

+ (YTNotifications *) sharedNotifications
{
    if (!_sharedNotifications) {
        _sharedNotifications = [YTNotifications new];

        NSDictionary *options = @{
                                  kCRToastFontKey: [UIFont fontWithName:@"Futura-Medium" size:20],
                                  kCRToastBackgroundColorKey: THEME_RED_COLOR,
                                  kCRToastNotificationPresentationTypeKey: @(CRToastPresentationTypeCover),
                                  kCRToastNotificationTypeKey: @(CRToastTypeNavigationBar),
                                  kCRToastAnimationInTypeKey : @(CRToastAnimationTypeLinear),
                                  kCRToastAnimationOutTypeKey : @(CRToastAnimationTypeLinear),
                                  kCRToastAnimationInDirectionKey : @(CRToastAnimationDirectionTop),
                                  kCRToastAnimationOutDirectionKey : @(CRToastAnimationDirectionTop),
                                  kCRToastInteractionRespondersKey: @[[CRToastInteractionResponder interactionResponderWithInteractionType:CRToastInteractionTypeAll
                                                                                                                      automaticallyDismiss:YES
                                                                                                                                     block:^(CRToastInteractionType interactionType){
                                                                                                                                     }]]
                                  };


        [CRToastManager setDefaultOptions:options];
    }

    return _sharedNotifications;
}

- (id)init
{
    if (self = [super init])
    {
        self.recentNotifications = [NSMutableSet set];
    }
    return self;
}

- (void) showBlueNotificationText:(NSString *)text
{
    NSDictionary *options = @{
                              kCRToastTextKey: text,
                              kCRToastBackgroundColorKey: THEME_BACKGROUND_COLOR,
                              };
    
    [self showNotificationWithKey:text options:options];
}

- (void) showPitchVolumeText:(NSString *)text andSubtitleText:(NSString *)subtitleText
{
    NSDictionary *options = @{
                              kCRToastTextKey: text,
                              kCRToastSubtitleTextKey: subtitleText,
                              kCRToastBackgroundColorKey: THEME_BACKGROUND_COLOR,
                              };
    
    [self showNotificationWithKey:text options:options];
}

- (void) showBufferingText:(NSString *)text
{
    NSDictionary *options = @{
                              kCRToastTextKey: text,
                              kCRToastTimeIntervalKey: @2.5,
                              kCRToastBackgroundColorKey: THEME_BACKGROUND_COLOR
                              };
    
    [self showNotificationWithKey:text options:options];
}

- (void) showSongVersionText:(NSString *)text
{
    NSDictionary *options = @{
                              kCRToastTextKey: text,
                              kCRToastTimeIntervalKey: @1.5,
                              kCRToastAnimationInTimeIntervalKey: @.3,
                              };
    
    [self showNotificationWithKey:text options:options];
}

- (void) showStatusBarText:(NSString *)text
{
    NSDictionary *options = @{
                              kCRToastTextKey: text,
                              kCRToastNotificationTypeKey: @(CRToastTypeStatusBar),
                              kCRToastTimeIntervalKey: @8,
                              kCRToastFontKey: [UIFont fontWithName:@"Futura-Medium" size:12],
                              };
    
    [self showNotificationWithKey:text options:options];
}

- (void)showNotificationWithKey:(NSString*)key options:(NSDictionary*)options
{
    if (![self.recentNotifications containsObject:key])
    {
        [self.recentNotifications addObject:key];
        [CRToastManager showNotificationWithOptions:options completionBlock:nil];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(YTNotificationDuplicateNotificationPreventedByDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.recentNotifications removeObject:key];
        });
    }
}

- (void) showNotificationText:(NSString *)text
{
    if (![self.recentNotifications containsObject:text])
    {
        [self.recentNotifications addObject:text];
        [CRToastManager showNotificationWithMessage:text completionBlock:nil];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(YTNotificationDuplicateNotificationPreventedByDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.recentNotifications removeObject:text];
        });
    }
}

@end
