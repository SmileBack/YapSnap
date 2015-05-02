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
    NSString *message = [NSString stringWithFormat:@"Block %@", yap.displaySenderName];

    self = [super initWithTitle:@"Block them?"
                        message:message
                       delegate:delegate
              cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
    return self;
}

@end
