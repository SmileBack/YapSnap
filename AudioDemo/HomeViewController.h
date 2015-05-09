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
#import "ControlCenterViewController.h"

#define SHOW_FEEDBACK_PAGE @"yaptap.ShowFeedbackPage"
#define OPENED_YAP_FOR_FIRST_TIME_KEY @"yaptap.OpenedYapForFirstTimeKey"
#define DID_SEE_WELCOME_POPUP_KEY @"yaptap.DidSeeWelcomePopupKey"
#define TAPPED_MIC_BUTTON_FOR_FIRST_TIME_KEY @"yaptap.TappedMicButtonForFirstTimeNotification"

@interface HomeViewController : UIViewController<MFMailComposeViewControllerDelegate, ControlCenterDelegate>

// This is set if the recording is initiated as a reply to a contact
@property (nonatomic) YSContact *contactReplyingTo;
@property (weak, nonatomic) IBOutlet UIButton *topLeftButton;
@property (weak, nonatomic) IBOutlet UIButton *yapsPageButton;
@property (nonatomic, strong) IBOutlet UIView *controlCenterView;
@property (nonatomic, strong) IBOutlet UIButton *controlCenterButtonMic;
@property (nonatomic, strong) IBOutlet UIButton *controlCenterButtonMusic;
@property (nonatomic, strong) id<ControlCenterDelegate> delegate;

- (IBAction)didTapYapsPageButton;
- (IBAction)leftButtonPressed:(id)sender;


@end
