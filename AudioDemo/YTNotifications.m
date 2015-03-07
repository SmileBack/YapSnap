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
                                  kCRToastFontKey: [UIFont systemFontOfSize:20],
                                  kCRToastBackgroundColorKey: [UIColor blueColor],
                                  kCRToastNotificationPresentationTypeKey: @(CRToastPresentationTypeCover),
                                  kCRToastNotificationTypeKey: @(CRToastTypeNavigationBar),
                                  kCRToastAnimationInTypeKey : @(CRToastAnimationTypeGravity),
                                  kCRToastAnimationOutTypeKey : @(CRToastAnimationTypeLinear),
                                  kCRToastAnimationInDirectionKey : @(CRToastAnimationDirectionTop),
                                  kCRToastAnimationOutDirectionKey : @(CRToastAnimationDirectionTop)
                                  };

        [CRToastManager setDefaultOptions:options];
    }

    return _sharedNotifications;
}

- (void) showNotificationText:(NSString *)text
{
    [CRToastManager showNotificationWithMessage:text completionBlock:nil];
}

- (void) showErrorText:(NSString *)text
{
    NSDictionary *options = @{
                              kCRToastTextKey: text,
                              kCRToastBackgroundColorKey: [UIColor blueColor]
                              };
    
    [CRToastManager showNotificationWithOptions:options completionBlock:nil];
}

@end
