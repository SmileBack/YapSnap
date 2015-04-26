//
//  MusicPlaybackVC.h
//  YapSnap
//
//  Created by Jon Deokule on 12/24/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <StreamingKit/STKAudioPlayer.h>
#import "YSYap.h"
#import <MediaPlayer/MediaPlayer.h>

#define PLAYBACK_STOPPED_NOTIFICATION @"com.yapsnap.PlaybackStoppedNotification"
#define OPENED_YAP_FOR_FIRST_TIME_KEY @"yaptap.OpenedYapForFirstTimeKey"
#define DID_SEE_DOUBLE_TAP_BANNER @"yaptap.DidSeeDoubleTapBannerKey"
#define DID_SEE_WELCOME_YAP_BANNER @"yaptap.DidSeeWelcomeYapBannerKey"

@interface PlaybackVC : UIViewController<STKAudioPlayerDelegate> {
    MPVolumeView *_mpVolumeView;
}
@property (nonatomic, strong) YSYap *yap;
@property (nonatomic, strong) IBOutlet MPVolumeView *volumeView;

- (void) stop;
@end
