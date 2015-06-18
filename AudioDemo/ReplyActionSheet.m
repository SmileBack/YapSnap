//
//  BlockFriendAlertView.m
//  YapTap
//
//  Created by Jon Deokule on 5/2/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "ReplyActionSheet.h"

@implementation ReplyActionSheet

- (id) initWithYap:(YSYap *)yap andDelegate:(id<UIActionSheetDelegate>)delegate
{
    self = [super initWithTitle:@"How would you like to reply?"
                        delegate:delegate
                    cancelButtonTitle:@"Cancel"
              destructiveButtonTitle:nil
              otherButtonTitles:@"Use Same Song", @"Select New Song", @"No Song. Just Voice", nil];
    return self;
}

@end
