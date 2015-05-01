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

#define SHOW_FEEDBACK_PAGE @"yaptap.ShowFeedbackPage"
#define OPENED_YAP_FOR_FIRST_TIME_KEY @"yaptap.OpenedYapForFirstTimeKey"
#define DID_SEE_WELCOME_POPUP_KEY @"yaptap.DidSeeWelcomePopupKey"
#define SHOW_CONTROL_CENTER_NOTIFICATION @"yaptap.ShowControlCenterViewNotification"
#define HIDE_CONTROL_CENTER_VIEW_NOTIFICATION @"yaptap.HideControlCenterViewNotification"

@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIButton *recordButton;
@property (weak, nonatomic) IBOutlet UIButton *yapsPageButton;
@property (weak, nonatomic) IBOutlet UIButton *topLeftButton;
@property (nonatomic, strong) YSAudioSourceController *audioSource;
@property (weak, nonatomic) IBOutlet YSRecordProgressView *recordProgressView;

// This is set if the recording is initiated as a reply to a contact
@property (nonatomic) YSContact *contactReplyingTo;


- (IBAction)recordTapped:(id)sender;
- (IBAction)playTapped:(id)sender;

- (IBAction)didTapYapsPageButton;
- (BOOL)isInRecordMode;

- (void) flipController:(UIViewController *)from to:(YSAudioSourceController *)to;

@end
