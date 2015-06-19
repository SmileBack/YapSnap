//
//  AudioCaptureViewController.h
//  AudioDemo
//
//  Created by Simon on 24/2/13.
//  Copyright (c) 2013 Appcoda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "YSAudioSourceController.h"
#import "YSRecordProgressView.h"
#import "PhoneContact.h"
#import "OffsetImageButton.h"

#define DISMISS_KEYBOARD_NOTIFICATION @"DismissKeyboardNotification"
#define UNTAPPED_RECORD_BUTTON_BEFORE_THRESHOLD_NOTIFICATION @"yaptap.UntappedRecordButtonBeforeThresholdNotification"
#define AUDIO_CAPTURE_DID_START_NOTIFICATION @"yaptap.AudioCaptureDidStartNotification"
#define LISTENED_TO_CLIP_NOTIFICATION @"com.yapsnap.ListenedToClipNotification"
#define REMOVE_BOTTOM_BANNER_NOTIFICATION @"com.yapsnap.RemoveBottomBannerNotification"

typedef NS_ENUM(NSUInteger, AudioCaptureType) {
    AudioCaptureTypeMic,
    AudioCapTureTypeSpotify
};

static NSString* const AudioCaptureContextGenreName = @"genre";

@interface AudioCaptureViewController : UIViewController <AVAudioRecorderDelegate, AVAudioPlayerDelegate>

@property AudioCaptureType type;
@property NSDictionary* audioCaptureContext; // A bag of data that specifies the context in which we should start recording, e.g. Spotify music genre. See above constants for related dictionary keys
@property (nonatomic) YSContact *contactReplyingTo;
@property (weak, nonatomic) IBOutlet UIButton *recordButton;
@property (nonatomic, strong) YSAudioSourceController *audioSource;
@property (weak, nonatomic) IBOutlet YSRecordProgressView *recordProgressView;
@property (assign, nonatomic) BOOL replyWithVoice;

@end
