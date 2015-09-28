//
//  AcceptFriendAlertView.m
//  YapTap
//
//  Created by Jon Deokule on 5/2/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "AddFriendAlertView.h"

@implementation AddFriendAlertView

- (id) initWithYap:(YSYap *)yap andDelegate:(id<UIAlertViewDelegate>)delegate
{
    NSString *message = [NSString stringWithFormat:@"%@ wants to be your friend. Would you like to accept?", yap.displaySenderName];

    self = [super initWithTitle:@"Friend Request"
                        message:message
                       delegate:delegate
              cancelButtonTitle:@"Decline" otherButtonTitles:@"Accept", nil];
    return self;
}

@end
