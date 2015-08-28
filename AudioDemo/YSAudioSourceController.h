//
//  YSAudioSourceController.h
//  YapSnap
//
//  Created by Jon Deokule on 12/20/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YapBuilder.h"

#define STOP_LOADING_SPINNER_NOTIFICATION @"com.yapsnap.StopLoadingSpinnerNotification"
#define CAPTURE_THRESHOLD .8 //seconds
#define DID_START_AUDIO_CAPTURE_NOTIFICATION @"com.yapsnap.StartAudioCaptureLoadingSpinnerNotification"
#define WILL_START_AUDIO_CAPTURE_NOTIFICATION @"com.yapsnap.WillStartAudioCaptureLoadingSpinnerNotification"

@class YSAudioSourceController;

@protocol  YSAudioSourceControllerCategory<NSObject>

- (NSString *)name;

@end

@protocol YSAudioSourceControllerDelegate <NSObject>

@optional

// Called before audio capture starts (possibly before related content is loaded from the network)
- (void)audioSourceControllerWillStartAudioCapture:(YSAudioSourceController*)controller;

// Called when audio capture actually has started
- (void)audioSourceControllerDidStartAudioCapture:(YSAudioSourceController*)controller;

- (void)audioSourceControllerdidFinishAudioCapture:(YSAudioSourceController*)controller;

- (void)audioSourceControllerdidCancelAudioCapture:(YSAudioSourceController*)controller;

- (void)audioSourceController:(YSAudioSourceController*)controller didReceieveUnexpectedError:(NSError*)error;

@end

/*
 * Base class for audio sources (i.e. Spotify or recording through the mic)
 */
@interface YSAudioSourceController : UIViewController

@property (weak) id<YSAudioSourceControllerDelegate> audioCaptureDelegate;

- (BOOL) startAudioCapture;
- (void) stopAudioCapture;

- (void) startPlayback;
- (void) cancelPlayingAudio;

- (void)clearSearchResults;
- (void)searchWithText:(NSString *)text;
- (void)updatePlaybackProgress:(NSTimeInterval)playbackTime;

// Spotify source will return the YSTrack.
// Mic source could return the audio file. for now will return nothing.
- (YapBuilder *) getYapBuilder;

@end
