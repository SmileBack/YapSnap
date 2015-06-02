//
//  YSUninvitedContactInviter.h
//  YapTap
//
//  Created by Dan B on 5/28/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YSUninvitedContactInviter : NSObject

- (void)inviteUninvitedContactsFromYapsIfNeeded:(NSArray *)yaps
                             fromViewController:(UIViewController *)viewController;

@end
