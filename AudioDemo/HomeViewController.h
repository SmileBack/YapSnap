//
//  HomeViewController.h
//  YapTap
//
//  Created by Dan B on 5/7/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "PhoneContact.h"

#define SHOW_FEEDBACK_PAGE @"yaptap.ShowFeedbackPage"
#define OPENED_YAP_FOR_FIRST_TIME_KEY @"yaptap.OpenedYapForFirstTimeKey"
#define DISMISS_WELCOME_POPUP @"DismissWelcomePopup"
#define AUDIO_CAPTURE_DID_START_NOTIFICATION @"yaptap.AudioCaptureDidStartNotification"
#define UNTAPPED_RECORD_BUTTON_BEFORE_THRESHOLD_NOTIFICATION @"yaptap.UntappedRecordButtonBeforeThresholdNotification"
#define STOP_LOADING_SPINNER_NOTIFICATION @"com.yapsnap.StopLoadingSpinnerNotification"
#define COMPLETED_REGISTRATION_NOTIFICATION @"com.yapsnap.CompletedRegistrationNotification2"
#define DID_START_AUDIO_CAPTURE_NOTIFICATION @"com.yapsnap.StartAudioCaptureLoadingSpinnerNotification"
#define WILL_START_AUDIO_CAPTURE_NOTIFICATION @"com.yapsnap.WillStartAudioCaptureLoadingSpinnerNotification"
#define LISTENED_TO_CLIP_NOTIFICATION @"com.yapsnap.ListenedToClipNotification"
#define RESET_BANNER_UI @"com.yapsnap.ResetSpotifyUINotification"
#define SHOW_SEND_YAP_POPUP @"com.yapsnap.SendYapPopupNotification"
#define DID_SEE_SEND_YAP_POPUP_KEY @"yaptap.DidSeeSendYapPopupKey"

@interface HomeViewController : UIViewController<MFMailComposeViewControllerDelegate>

// This is set if the recording is initiated as a reply to a contact
@property (nonatomic) YSContact *contactReplyingTo;
@property (weak, nonatomic) IBOutlet UIButton *topLeftButton;
@property (weak, nonatomic) IBOutlet UIButton *yapsPageButton;

- (IBAction)didTapYapsPageButton;
- (IBAction)didTapOverlayButton;
- (IBAction)leftButtonPressed:(id)sender;


@end
