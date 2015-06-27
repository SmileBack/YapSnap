//
//  YTUnregisteredUserSMSInviter.m
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
                self.alertMessage = [NSString stringWithFormat:@"%@ doesn't have the app yet, but they'll get your yap as soon as they download it!", firstNameOne];
            } else if (unregisteredNames.count == 2) {
                NSString *firstNameTwo = [[unregisteredNames[1] componentsSeparatedByString:@" "] objectAtIndex:0];
                self.alertMessage = [NSString stringWithFormat:@"%@ and %@ don't have the app yet, but they'll get your yap as soon as they download it!", firstNameOne, firstNameTwo];
            } else if (unregisteredNames.count == 3){
                NSString *firstNameTwo = [[unregisteredNames[1] componentsSeparatedByString:@" "] objectAtIndex:0];
                NSString *firstNameThree = [[unregisteredNames[2] componentsSeparatedByString:@" "] objectAtIndex:0];
                self.alertMessage = [NSString stringWithFormat:@"%@, %@, and %@ don't have the app yet, but they'll get your yap as soon as they download it!", firstNameOne, firstNameTwo, firstNameThree];
            } else {
               self.alertMessage = [NSString stringWithFormat:@"%@ and a few others don't have the app yet, but they'll get your yap as soon as they download it!", firstNameOne];
            }
            
            [UIAlertView showWithTitle:@"Yap Sent!"
                               message:self.alertMessage
                     cancelButtonTitle:@"Nah" otherButtonTitles:@[@"Tell Them"]
                              tapBlock:^(UIAlertView* view, NSInteger index) {
                                  self.smsAlertWasAlreadyPrompted = NO;
                                  if (index != view.cancelButtonIndex) {
                                      NSLog(@"Tapped Continue on SMS Prompt");
                                      [self.delegate showSMS:@"Hey I sent you something cool on YapTap! You'll be getting a message from them about it"
                                                toRecipients:unregisteredContacts];
                                      
                                      Mixpanel *mixpanel = [Mixpanel sharedInstance];
                                      [mixpanel track:@"Yes to SMS (Yap)"];
                                  } else {
                                      Mixpanel *mixpanel = [Mixpanel sharedInstance];
                                      [mixpanel track:@"Skipped SMS (Yap)"];
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
                self.alertMessage = [NSString stringWithFormat:@"%@ doesn't have the app yet, but they will get your friend request as soon as they download it!", firstNameOne];
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
                     cancelButtonTitle:@"Nah" otherButtonTitles:@[@"Tell Them"]
                              tapBlock:^(UIAlertView* view, NSInteger index) {
                                  self.smsAlertWasAlreadyPrompted = NO;
                                  if (index != view.cancelButtonIndex) {
                                      NSLog(@"Tapped Continue on SMS Prompt");
                                      [self.delegate showSMS:@"Hey I sent you a friend request on YapTap! You'll be getting a message from them about it" toRecipients:unregisteredContacts];
                                      
                                      Mixpanel *mixpanel = [Mixpanel sharedInstance];
                                      [mixpanel track:@"Yes to SMS (Friend Request)"];
                                  } else {
                                      Mixpanel *mixpanel = [Mixpanel sharedInstance];
                                      [mixpanel track:@"Skipped SMS (Friend Request)"];
                                  }
                              }];
        } else {
            NSLog(@"Yaps Count: %lu", (unsigned long)yaps.count);
            [self.delegate showFriendsSuccessAlert];
        }
    }
}

@end