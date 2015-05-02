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
    NSString *message = [NSString stringWithFormat:@"Add %@ as a friend?", yap.displaySenderName];

    self = [super initWithTitle:@"Add friend?"
                        message:message
                       delegate:delegate
              cancelButtonTitle:@"Decline" otherButtonTitles:@"Accept", nil];
    return self;
}

@end
