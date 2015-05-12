//
//  BlockFriendAlertView.m
//  YapTap
//
//  Created by Jon Deokule on 5/2/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "BlockFriendAlertView.h"

@implementation BlockFriendAlertView

- (id) initWithYap:(YSYap *)yap andDelegate:(id<UIAlertViewDelegate>)delegate
{
    NSString *message = [NSString stringWithFormat:@"Do you want to block %@? This cannot be undone.", yap.displaySenderName];
    
    self = [super initWithTitle:@"Block User?"
                        message:message
                       delegate:delegate
              cancelButtonTitle:@"No" otherButtonTitles:@"Block", nil];
    return self;
}

@end
