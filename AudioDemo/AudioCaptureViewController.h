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
#import "PhoneContact.h"
#import "YSRecordProgressView.h"
#import "OffsetImageButton.h"
#import <MessageUI/MessageUI.h>

@interface AudioCaptureViewController : UIViewController <AVAudioRecorderDelegate, AVAudioPlayerDelegate, MFMailComposeViewControllerDelegate>

#define TAPPED_MIC_MODE_BUTTON_FOR_FIRST_TIME_KEY @"yaptap.TappedMicModeButtonForFirstTimeKey"
#define TAPPED_MUSIC_MODE_BUTTON_FOR_FIRST_TIME_KEY @"yaptap.TappedMusicModeButtonForFirstTimeKey"
#define SHOW_FEEDBACK_PAGE @"yaptap.ShowFeedbackPage"
#define TAPPED_PROGRESS_VIEW_NOTIFICATION @"yaptap.TappedProgressViewNotification"
#define OPENED_YAP_FOR_FIRST_TIME_KEY @"yaptap.OpenedYapForFirstTimeKey"
#define DID_SEE_WELCOME_POPUP_KEY @"yaptap.DidSeeWelcomePopupKey"

@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIButton *recordButton;
@property (weak, nonatomic) IBOutlet UIButton *yapsPageButton;
@property (weak, nonatomic) IBOutlet UIButton *topLeftButton;
@property (weak, nonatomic) IBOutlet UIView *explanation;
@property (strong, nonatomic) IBOutlet OffsetImageButton *spotifyModeButton;
@property (strong, nonatomic) IBOutlet OffsetImageButton *micModeButton;
@property (nonatomic, strong) YSAudioSourceController *audioSource;
@property (weak, nonatomic) IBOutlet YSRecordProgressView *recordProgressView;

// This is set if the recording is initiated as a reply to a contact
@property (nonatomic) YSContact *contactReplyingTo;


- (IBAction)recordTapped:(id)sender;
- (IBAction)playTapped:(id)sender;

- (IBAction)didTapYapsPageButton;
- (BOOL)isInRecordMode;

- (void) flipController:(UIViewController *)from to:(YSAudioSourceController *)to;

- (void) resetUI;

@end
