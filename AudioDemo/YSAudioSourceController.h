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
#define HIDE_BOTTOM_BAR_NOTIFICATION @"HideBottomBarNotification"

@protocol YSAudioSource;

@protocol  YSAudioSourceControllerCategory<NSObject>

- (NSString *)name;

@end

@protocol YSAudioSourceControllerDelegate <NSObject>

@optional

// Called before audio capture starts (possibly before related content is loaded from the network)
- (void)audioSourceControllerWillStartAudioCapture:(id<YSAudioSource>)controller;

// Called when audio capture actually has started
- (void)audioSourceControllerDidStartAudioCapture:(id<YSAudioSource>)controller;

- (void)audioSourceControllerdidFinishAudioCapture:(id<YSAudioSource>)controller;

- (void)audioSourceControllerdidCancelAudioCapture:(id<YSAudioSource>)controller;

- (void)audioSourceController:(id<YSAudioSource>)controller didReceieveUnexpectedError:(NSError*)error;

- (void)audioSourceControllerIsReadyToProduceYapBuidler:(id<YSAudioSource>)controller;

@end

/*
 * Base class for audio sources (i.e. Spotify or recording through the mic)
 */
@protocol YSAudioSource<NSObject>

@property (weak) id<YSAudioSourceControllerDelegate> audioCaptureDelegate;

// To be displayed in the audio capture bar, can be nil
- (NSString *)currentAudioDescription;

- (BOOL) startAudioCapture;
- (void) stopAudioCapture;
- (void) cancelPlayingAudio;

- (void)clearSearchResults;
- (void)searchWithText:(NSString *)text;
- (void)updatePlaybackProgress:(NSTimeInterval)playbackTime;

// Spotify source will return the YSTrack.
// Mic source could return the audio file. for now will return nothing.
- (void)prepareYapBuilder;

- (YapBuilder *) getYapBuilder;

@end

@interface YSAudioSourceViewController : UIViewController<YSAudioSource>
@end
