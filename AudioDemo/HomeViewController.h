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
#define DID_SEE_WELCOME_POPUP_KEY @"yaptap.DidSeeWelcomePopupKey44"
#define TAPPED_MIC_BUTTON_FOR_FIRST_TIME_KEY @"yaptap.TappedMicButtonForFirstTimeNotification"
#define DISMISS_WELCOME_POPUP @"DismissWelcomePopup"

@interface HomeViewController : UIViewController<MFMailComposeViewControllerDelegate>

// This is set if the recording is initiated as a reply to a contact
@property (nonatomic) YSContact *contactReplyingTo;
@property (weak, nonatomic) IBOutlet UIButton *topLeftButton;
@property (weak, nonatomic) IBOutlet UIButton *yapsPageButton;
@property (nonatomic, strong) IBOutlet UIButton *micButton;
@property (nonatomic, strong) IBOutlet UIButton *musicButton;

- (IBAction)didTapYapsPageButton;
- (IBAction)leftButtonPressed:(id)sender;
- (void) tappedSpotifyButton:(NSString *)type;


@end
