//
//  FriendsViewController.h
//  YapSnap
//
//  Created by Jon Deokule on 2/4/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^YapsSentCallback)();

@interface FriendsViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) YapsSentCallback yapsSentCallback;

#define TAPPED_CANCEL_BUTTON_ON_FRIENDS_EXPLANATION_VIEW_KEY @"yaptap.FriendsExplanationCancelled"

@end
