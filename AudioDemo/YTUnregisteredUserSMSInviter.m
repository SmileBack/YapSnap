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

- (void)promptSMSAlertForYapIfRelevant:(NSArray *)yaps
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
                self.alertMessage = [NSString stringWithFormat:@"%@ doesn't have the app yet, but he/she will get your yap as soon as he/she downloads it!", firstNameOne];
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
                                      [self.delegate showSMS:@"I sent you something on YapTap. Download the app to check it out: https://itunes.apple.com/gb/app/YapTap/id972004073"
                                                toRecipients:uninvitedContacts];
                                      
                                  } else {
                                      self.smsAlertWasAlreadyPrompted = NO;
                                  }
                              }];
        }
    }
}

- (void)promptSMSAlertForFriendRequestIfRelevant:(NSArray *)yaps
                    fromViewController:(UIViewController *)viewController {
    if (self.viewController != viewController) {
        self.viewController = viewController;
        NSMutableArray* unregisteredContacts = [NSMutableArray arrayWithCapacity:yaps.count];
        NSMutableArray* unregisteredNames = [NSMutableArray arrayWithCapacity:yaps.count];
        for (YSYap* yap in yaps) {
            if ([yap.status isEqualToString:@"pending"]) {
                [unregisteredContacts addObject:yap.receiverPhone];
                [unregisteredNames addObject:yap.displayReceiverName];
            }
        }
        
        if (unregisteredNames.count > 0 && unregisteredContacts.count > 0 && !self.smsAlertWasAlreadyPrompted) {
            self.smsAlertWasAlreadyPrompted = YES;
            
            NSString *firstNameOne = [[unregisteredNames.firstObject componentsSeparatedByString:@" "] objectAtIndex:0];
            
            if (unregisteredNames.count == 1) {
                self.alertMessage = [NSString stringWithFormat:@"%@ doesn't have the app yet, but he/she will get your friend request as soon as he/she downloads it!", firstNameOne];
            } else if (unregisteredNames.count == 2) {
                NSString *firstNameTwo = [[unregisteredNames[1] componentsSeparatedByString:@" "] objectAtIndex:0];
                self.alertMessage = [NSString stringWithFormat:@"%@ and %@ don't have the app yet, but they'll get your friend request as soon as they download it!", firstNameOne, firstNameTwo];
            } else if (unregisteredNames.count == 3){
                NSString *firstNameTwo = [[unregisteredNames[1] componentsSeparatedByString:@" "] objectAtIndex:0];
                NSString *firstNameThree = [[unregisteredNames[2] componentsSeparatedByString:@" "] objectAtIndex:0];
                self.alertMessage = [NSString stringWithFormat:@"%@, %@, and %@ don't have the app yet, but they'll get your friend request as soon as they download it!", firstNameOne, firstNameTwo, firstNameThree];
            } else {
                self.alertMessage = [NSString stringWithFormat:@"%@ and a few others don't have the app yet, but they'll get your friend request as soon as they download it!", firstNameOne];
            }
            
            [UIAlertView showWithTitle:@"Friend Request Sent!"
                               message:self.alertMessage
                     cancelButtonTitle:@"Skip" otherButtonTitles:@[@"Tell Them"]
                              tapBlock:^(UIAlertView* view, NSInteger index) {
                                  if (index != view.cancelButtonIndex) {
                                      [self.delegate showSMS:@"I sent you a friend request on YapTap. Download the app to accept it: https://itunes.apple.com/gb/app/YapTap/id972004073" toRecipients:unregisteredContacts];
                                  } else {
                                      self.smsAlertWasAlreadyPrompted = NO;
                                  }
                              }];
        }
    }
}

@end