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
#define TAPPED_PROGRESS_BAR_NOTIFICATION @"TappedProgressBarNotification"
#define TAPPED_DICE_BUTTON_NOTIFICATION @"yaptap.TappedDiceButtonNotification"
#define TAPPED_ALBUM_COVER_FIRST_TIME_NOTIFICATION @"yaptap.TappedAlbumCoverFirstTimeNotification5"
#define UNTAPPED_RECORD_BUTTON_BEFORE_THRESHOLD_NOTIFICATION @"yaptap.UntappedRecordButtonBeforeThresholdNotification"
#define DID_TAP_DICE_BUTTON @"yaptap.DidTapDiceButtonKey10"

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

@end
