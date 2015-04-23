//
//  YTNotifications.m
//  YapTap
//
//  Created by Jon Deokule on 3/7/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "YTNotifications.h"

#import <CRToast/CRToast.h>


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

- (void) showNotificationText:(NSString *)text
{
    [CRToastManager showNotificationWithMessage:text completionBlock:nil];
}

- (void) showMusicNoteText:(NSString *)text
{
    NSDictionary *options = @{
                              kCRToastTextKey: text,
                              kCRToastTimeIntervalKey: @2.5,
                              };
    
    [CRToastManager showNotificationWithOptions:options completionBlock:nil];}

- (void) showVolumeText:(NSString *)text
{
    NSDictionary *options = @{
                              kCRToastTextKey: text,
                              kCRToastBackgroundColorKey: THEME_BACKGROUND_COLOR
                              };
    
    [CRToastManager showNotificationWithOptions:options completionBlock:nil];
}

- (void) showBufferingText:(NSString *)text
{
    NSDictionary *options = @{
                              kCRToastTextKey: text,
                              kCRToastTimeIntervalKey: @2.5,
                              kCRToastBackgroundColorKey: THEME_BACKGROUND_COLOR
                              };
    
    [CRToastManager showNotificationWithOptions:options completionBlock:nil];
}

- (void) showSongVersionText:(NSString *)text
{
    NSDictionary *options = @{
                              kCRToastTextKey: text,
                              kCRToastTimeIntervalKey: @1.5,
                              kCRToastBackgroundColorKey: THEME_BACKGROUND_COLOR,
                              kCRToastAnimationInTimeIntervalKey: @.3,
                              };
    
    [CRToastManager showNotificationWithOptions:options completionBlock:nil];
}

- (void) showRandomSearchText:(NSString *)text
{
    NSDictionary *options = @{
                              kCRToastTextKey: text,
                              kCRToastTimeIntervalKey: @1,
                              kCRToastBackgroundColorKey: THEME_BACKGROUND_COLOR,
                              kCRToastAnimationInTimeIntervalKey: @.3,
                              };
    
    [CRToastManager showNotificationWithOptions:options completionBlock:nil];
}

- (void) showErrorText:(NSString *)text
{
    NSDictionary *options = @{
                              kCRToastTextKey: text,
                              kCRToastBackgroundColorKey: [UIColor yellowColor]
                              };
    
    [CRToastManager showNotificationWithOptions:options completionBlock:nil];
}

- (void) showWelcomeText:(NSString *)text
{
    NSDictionary *options = @{
                              kCRToastTextKey: text,
                              kCRToastFontKey: [UIFont fontWithName:@"Futura-Medium" size:18],
                              kCRToastTimeIntervalKey: @3,
                              kCRToastAnimationInTypeKey : @(CRToastAnimationTypeGravity),
                              };
    
    [CRToastManager showNotificationWithOptions:options completionBlock:nil];
}

- (void) showModeText:(NSString *)text
{
    NSDictionary *options = @{
                              kCRToastTextKey: text,
                              kCRToastFontKey: [UIFont fontWithName:@"Futura-Medium" size:18],
                              kCRToastTimeIntervalKey: @2,
                              kCRToastAnimationInTimeIntervalKey: @.3,
                              };
    
    [CRToastManager showNotificationWithOptions:options completionBlock:nil];
}

@end
