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
- (void) showErrorText:(NSString *)text;
- (void) showWelcomeText:(NSString *)text;
- (void) showVolumeText:(NSString *)text;
- (void) showModeText:(NSString *)text;
- (void) showSongVersionText:(NSString *)text;
- (void) showBufferingText:(NSString *)text;
- (void) showRandomPickText:(NSString *)text;
- (void) showMusicNoteText:(NSString *)text;

@end
