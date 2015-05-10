//
//  YapsViewController.h
//  AudioDemo
//
//  Created by Dan Berenholtz on 9/7/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YapsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>

#define VIEWED_PUSH_NOTIFICATION_POPUP @"yaptap.ViewedPushNotificationPopup"
#define VIEWED_FIRST_SENT_YAP_ALERT @"yaptap.ViewedFirstYapAlert"
#define OPENED_YAP_FOR_FIRST_TIME_KEY @"yaptap.OpenedYapForFirstTimeKey"
#define DID_DISMISS_AFTER_SENDING_YAP @"DidDismissAfterSendingYap"

@property (nonatomic, strong) NSArray *pendingYaps;
@property (assign, nonatomic) BOOL comingFromContactsOrCustomizeYapPage;
@property (nonatomic, strong) NSNumber *unopenedYapsCount;

@end
