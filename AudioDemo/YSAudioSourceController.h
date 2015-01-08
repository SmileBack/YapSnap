//
//  YSAudioSourceController.h
//  YapSnap
//
//  Created by Jon Deokule on 12/20/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import <UIKit/UIKit.h>

#define AUDIO_CAPTURE_DID_START_NOTIFICATION @"com.yapsnap.AudioCaptureDidStartNotification"
#define AUDIO_CAPTURE_DID_END_NOTIFICATION @"com.yapsnap.AudioCaptureDidEndNotification"
#define AUDIO_CAPTURE_ERROR_NOTIFICATION @"com.yapsnap.AudioCaptureErrorNotification"
#define AUDIO_CAPTURE_FAILED_TO_START_DUE_TO_INTERNET @"com.yapsnap.AudioCaptureFailedToStartNotification"
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

@end
