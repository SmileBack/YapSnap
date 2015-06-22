//
//  FriendsViewController.h
//  YapSnap
//
//  Created by Jon Deokule on 2/4/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YTUnregisteredUserSMSInviter.h"

typedef void (^YapsSentCallback)();

@interface FriendsViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate, YTUnregisteredUserSMSInviterDelegate>

@property (nonatomic, strong) YapsSentCallback yapsSentCallback;

- (void)showSMS:(NSString *)message toRecipients:(NSArray *)recipients;

- (void)showFriendsSuccessAlert;

@end
