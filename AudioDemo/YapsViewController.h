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

@property (nonatomic, strong) NSArray *pendingYaps;
@property (assign, nonatomic) BOOL comingFromContactsOrAddTextPage;
@property (nonatomic, strong) NSNumber *unopenedYapsCount;

@end
