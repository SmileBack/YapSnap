//
//  MusicPlaybackVC.h
//  YapSnap
//
//  Created by Jon Deokule on 12/24/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <StreamingKit/STKAudioPlayer.h>
#import "JEProgressView.h"
#import "YSYap.h"
#import <MediaPlayer/MediaPlayer.h>

#define PLAYBACK_STOPPED_NOTIFICATION @"com.yapsnap.PlaybackStoppedNotification"

@interface PlaybackVC : UIViewController<STKAudioPlayerDelegate> {
    MPVolumeView *_mpVolumeView;
}
@property (nonatomic, strong) YSYap *yap;
@property (nonatomic, strong) IBOutlet MPVolumeView *volumeView;

- (void) stop;
@end
