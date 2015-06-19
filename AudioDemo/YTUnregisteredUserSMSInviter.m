//
//  YSUninvitedContactInviter.m
//  YapTap
//
//  Created by Dan B on 5/28/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "YTUnregisteredUserSMSInviter.h"
#import "YSYap.h"
#import "UIAlertView+Blocks.h"
#import <MessageUI/MessageUI.h>

@interface YTUnregisteredUserSMSInviter()<MFMessageComposeViewControllerDelegate>

@property (nonatomic, weak) UIViewController* viewController;
@property BOOL smsAlertWasAlreadyPrompted;
@property (nonatomic, weak) NSString* alertMessage;

@end

@implementation YTUnregisteredUserSMSInviter

- (id)init {
    if (self = [super init]) {
        self.smsAlertWasAlreadyPrompted = NO;
    }
    return self;
}

- (void)promptSMSAlertIfRelevant:(NSArray *)yaps
                             fromViewController:(UIViewController *)viewController {
    if (self.viewController != viewController) {
        self.viewController = viewController;
        NSMutableArray* uninvitedContacts = [NSMutableArray arrayWithCapacity:yaps.count];
        NSMutableArray* uninvitedNames = [NSMutableArray arrayWithCapacity:yaps.count];
        for (YSYap* yap in yaps) {
            if ([yap.status isEqualToString:@"pending"]) {
                [uninvitedContacts addObject:yap.receiverPhone];
                [uninvitedNames addObject:yap.displayReceiverName];
            }
        }
        
        if (uninvitedNames.count > 0 && uninvitedContacts.count > 0 && !self.smsAlertWasAlreadyPrompted) {
            self.smsAlertWasAlreadyPrompted = YES;
            
            NSString *firstNameOne = [[uninvitedNames.firstObject componentsSeparatedByString:@" "] objectAtIndex:0];
            
            if (uninvitedNames.count == 1) {
                self.alertMessage = [NSString stringWithFormat:@"%@ doesn't have the app yet, but he/she will get your yap as soon as they download it!", firstNameOne];
            } else if (uninvitedNames.count == 2) {
                NSString *firstNameTwo = [[uninvitedNames[1] componentsSeparatedByString:@" "] objectAtIndex:0];
                self.alertMessage = [NSString stringWithFormat:@"%@ and %@ don't have the app yet, but they'll get your yap as soon as they download it!", firstNameOne, firstNameTwo];
            } else if (uninvitedNames.count == 3){
                NSString *firstNameTwo = [[uninvitedNames[1] componentsSeparatedByString:@" "] objectAtIndex:0];
                NSString *firstNameThree = [[uninvitedNames[2] componentsSeparatedByString:@" "] objectAtIndex:0];
                self.alertMessage = [NSString stringWithFormat:@"%@, %@, and %@ don't have the app yet, but they'll get your yap as soon as they download it!", firstNameOne, firstNameTwo, firstNameThree];
            } else {
               self.alertMessage = [NSString stringWithFormat:@"%@ and a few others don't have the app yet, but they'll get your yap as soon as they download it!", firstNameOne];
            }
            
            [UIAlertView showWithTitle:@"Yap Sent!"
                               message:self.alertMessage
                     cancelButtonTitle:@"Skip" otherButtonTitles:@[@"Tell Them"]
                              tapBlock:^(UIAlertView* view, NSInteger index) {
                                  if (index != view.cancelButtonIndex) {
                                      [self showSMS:@"I sent you something on YapTap. Download the app to see it: https://itunes.apple.com/gb/app/YapTap/id972004073"
                                       toRecipients:uninvitedContacts];
                                  } else {
                                      self.smsAlertWasAlreadyPrompted = NO;
                                  }
                              }];
        }
    }
}

#pragma mark - SMS

- (void)showSMS:(NSString *)message toRecipients:(NSArray *)recipients {
    if(![MFMessageComposeViewController canSendText]) {
        UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Your device doesn't support SMS!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [warningAlert show];
        return;
    }
    
    MFMessageComposeViewController *messageController = [[MFMessageComposeViewController alloc] init];
    messageController.messageComposeDelegate = self;
    [messageController setRecipients:recipients];
    [messageController setBody:message];
    
    // Present message view controller on screen
    [self.viewController presentViewController:messageController animated:YES completion:nil];
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    switch (result) {
        case MessageComposeResultCancelled:
            break;
            
        case MessageComposeResultFailed:
        {
            UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Failed to send SMS!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [warningAlert show];
            break;
        }
            
        case MessageComposeResultSent:
            break;
            
        default:
            break;
    }
    
    self.smsAlertWasAlreadyPrompted = NO;
    [self.viewController dismissViewControllerAnimated:YES completion:nil];
}

@end