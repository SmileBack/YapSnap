//
//  BlockFriendAlertView.h
//  YapTap
//
//  Created by Jon Deokule on 5/2/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YSYap.h"

@interface ReplyActionSheet : UIActionSheet

- (id) initWithYap:(YSYap *)yap andDelegate:(id<UIActionSheetDelegate>)delegate;

@end
