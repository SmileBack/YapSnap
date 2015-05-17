//
//  YTNotifications.h
//  YapTap
//
//  Created by Jon Deokule on 3/7/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YTNotifications : NSObject

+ (YTNotifications *) sharedNotifications;

- (void) showNotificationText:(NSString *)text;
- (void) showBlueNotificationText:(NSString *)text;
- (void) showSongVersionText:(NSString *)text;
- (void) showBufferingText:(NSString *)text;
- (void) showStatusBarText:(NSString *)text;
- (void) showPitchVolumeText:(NSString *)text andSubtitleText:(NSString *)subtitleText;

@end
