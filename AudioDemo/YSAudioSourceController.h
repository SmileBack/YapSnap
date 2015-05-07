//
//  YSAudioSourceController.h
//  YapSnap
//
//  Created by Jon Deokule on 12/20/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YapBuilder.h"

#define AUDIO_CAPTURE_DID_START_NOTIFICATION @"com.yapsnap.AudioCaptureDidStartNotification"
#define AUDIO_CAPTURE_UNEXPECTED_ERROR_NOTIFICATION @"com.yapsnap.AudioCaptureErrorNotification"
#define AUDIO_CAPTURE_LOST_CONNECTION_NOTIFICATION @"com.yapsnap.AudioCaptureLostConnectionNotification"
#define STOP_LOADING_SPINNER_NOTIFICATION @"com.yapsnap.StopLoadingSpinnerNotification"
#define CAPTURE_THRESHOLD 1 //seconds


/*
 * Base class for audio sources (i.e. Spotify or recording through the mic)
 */
@interface YSAudioSourceController : UIViewController

- (BOOL) startAudioCapture;
- (void) stopAudioCapture:(float)elapsedTime;

- (void) startPlayback;
- (void) stopPlayback;

- (void) resetUI;

// Spotify source will return the YSTrack.
// Mic source could return the audio file. for now will return nothing.
- (YapBuilder *) getYapBuilder;

// These are only relevant for Spotify!
- (void) tappedControlCenterButton:(NSString*)genre;

@end
