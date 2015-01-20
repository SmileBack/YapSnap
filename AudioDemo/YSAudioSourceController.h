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
#define AUDIO_CAPTURE_DID_END_NOTIFICATION @"com.yapsnap.AudioCaptureDidEndNotification"
#define AUDIO_CAPTURE_ERROR_NOTIFICATION @"com.yapsnap.AudioCaptureErrorNotification"
#define STOP_LOADING_SPINNER_NOTIFICATION @"com.yapsnap.StopLoadingSpinnerNotification"
#define CAPTURE_THRESHOLD .2 //seconds


/*
 * Base class for audio sources (i.e. Spotify or recording through the mic)
 */
@interface YSAudioSourceController : UIViewController

- (BOOL) startAudioCapture;
- (void) stopAudioCapture:(float)elapsedTime;

- (void) resetUI;

- (void) startPlayback;
- (void) stopPlayback;

// Spotify source will return the YSTrack.
// Mic source could return the audio file. for now will return nothing.
- (YapBuilder *) getYapBuilder;

@end
