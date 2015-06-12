//
//  YTYapCreatorDelegate.h
//  YapTap
//
//  Created by Dan B on 6/12/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import <Foundation/Foundation.h>

@class YSYap;

/*
 This class is passed between view controllers that originate yaps (e.g. a view controller that has a reply/forward feature)
 and things that need to take action when a new Yap needs to be created (e.g. the home screen, which needs to push several VCs
 when a reply/forward is created, with some context).

 */
@protocol YTYapCreatingDelegate <NSObject>

@required

- (void)didOriginateReplyFromYap:(YSYap *)yap;

- (void)didOriginateForwardFromYap:(YSYap *)yap;

@end