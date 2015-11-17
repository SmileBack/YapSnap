//
//  YapsViewController.h
//  AudioDemo
//
//  Created by Dan Berenholtz on 9/7/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YTYapCreatorDelegate.h"
#import "YTUnregisteredUserSMSInviter.h"

@interface YapsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate, YTYapCreatingDelegate, UIActionSheetDelegate, YTUnregisteredUserSMSInviterDelegate>

#define VIEWED_PUSH_NOTIFICATION_POPUP @"yaptap.ViewedPushNotificationPopup"
#define OPENED_YAP_FOR_FIRST_TIME_KEY @"yaptap.OpenedYapForFirstTimeKey"
#define DID_DISMISS_AFTER_SENDING_YAP @"DidDismissAfterSendingYap"
#define CLEARED_YAPS_NOTIFICATION @"com.yaptap.ClearedYapsNotification"
#define SHOW_SEND_YAP_POPUP @"com.yapsnap.SendYapPopupNotification"

@property (nonatomic, strong) NSArray *pendingYaps;
@property (assign, nonatomic) BOOL comingFromContactsOrCustomizeYapPage;
@property (assign, nonatomic) BOOL openWelcomeYapAutomatically;
@property (nonatomic, strong) NSNumber *unopenedYapsCount;

- (void)showSMS:(NSString *)message toRecipients:(NSArray *)recipients;

@end
