//
//  SettingsViewController.h
//  YapSnap
//
//  Created by Jon Deokule on 1/31/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

#define FIRST_NAME_SECTION @"First Name"
#define LAST_NAME_SECTION @"Last Name"
#define EMAIL_SECTION @"Email"
#define PHONE_NUMBER_SECTION @"Phone"
#define CLEAR_YAPS_SECTION @"Clear All Yaps"
#define FEEDBACK_SECTION @"Send Us Feedback"
#define DOWNLOAD_SPOTIFY_SECTION @"Download Spotify"
#define LOGOUT_SECTION @"Logout"

@interface SettingsViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate, MFMailComposeViewControllerDelegate>

- (void) saveField:(NSString *)field withText:(NSString *)text;

@end
