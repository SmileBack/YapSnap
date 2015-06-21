//
//  YSUninvitedContactInviter.h
//  YapTap
//
//  Created by Dan B on 5/28/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import <Foundation/Foundation.h>

#define PROMPT_SMS_NOTIFICATION @"com.yaptap.PromptSMSNotification"

@class YTUnregisteredUserSMSInviter;

@protocol YTUnregisteredUserSMSInviterDelegate <NSObject>
- (void)showSMS:(NSString *)message toRecipients:(NSArray *)recipients;
@end

@interface YTUnregisteredUserSMSInviter : NSObject

@property (nonatomic, weak) id <YTUnregisteredUserSMSInviterDelegate> delegate;

- (void)promptSMSAlertForYapIfRelevant:(NSArray *)yaps
                             fromViewController:(UIViewController *)viewController;

- (void)promptSMSAlertForFriendRequestIfRelevant:(NSArray *)yaps
                    fromViewController:(UIViewController *)viewController;

@end
