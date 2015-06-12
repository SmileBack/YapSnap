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
#import "YTYapCreatorDelegate.h"

#define PLAYBACK_STOPPED_NOTIFICATION @"com.yapsnap.PlaybackStoppedNotification"
#define OPENED_YAP_FOR_FIRST_TIME_KEY @"yaptap.OpenedYapForFirstTimeKey"
#define DID_SEE_DOUBLE_TAP_BANNER @"yaptap.DidSeeDoubleTapBannerKey2"
#define DID_SEE_WELCOME_YAP_BANNER @"yaptap.DidSeeWelcomeYapBannerKey"

typedef void (^StrangerCallback)(YSYap *yap);

@interface PlaybackVC : UIViewController<STKAudioPlayerDelegate> {
    MPVolumeView *_mpVolumeView;
}
@property (nonatomic, strong) YSYap *yap;
@property (nonatomic, strong) IBOutlet MPVolumeView *volumeView;
@property (nonatomic, weak) id<YTYapCreatingDelegate> yapCreatingDelegate;
@property (nonatomic, strong) StrangerCallback strangerCallback;

- (void) stop;
@end
