//
//  YSUninvitedContactInviter.m
//  YapTap
//
//  Created by Dan B on 5/28/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "YSUninvitedContactInviter.h"
#import "YSYap.h"
#import "UIAlertView+Blocks.h"
#import <MessageUI/MessageUI.h>

@interface YSUninvitedContactInviter()<MFMessageComposeViewControllerDelegate>

@property (nonatomic, weak) UIViewController* viewController;

@end

@implementation YSUninvitedContactInviter

- (void)inviteUninvitedContactsFromYapsIfNeeded:(NSArray *)yaps
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
        
        if (uninvitedNames.count > 0 && uninvitedContacts.count > 0) {
            NSString* namesToInvite = uninvitedNames.count == 1 ? uninvitedNames.firstObject : [NSString stringWithFormat:@"%@ and %@ %@", uninvitedNames.firstObject, @(uninvitedNames.count - 1), uninvitedNames.count == 2 ? @"other" : @"others"];
            
            [UIAlertView showWithTitle:@"Invite them to YapTap"
                               message:[NSString stringWithFormat:@"Your yap was sent. Invite %@ to download the app so they can hear it.", namesToInvite]
                     cancelButtonTitle:@"Skip" otherButtonTitles:@[@"Send Invite"]
                              tapBlock:^(UIAlertView* view, NSInteger index) {
                                  if (index != view.cancelButtonIndex) {
                                      [self showSMS:@"Just sent you a message on YapTap, get the app to hear it: https://itunes.apple.com/gb/app/YapTap/id972004073"
                                       toRecipients:uninvitedContacts];
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
    
    [self.viewController dismissViewControllerAnimated:YES completion:nil];
}

@end