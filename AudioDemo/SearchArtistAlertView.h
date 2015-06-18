//
//  BlockFriendAlertView.h
//  YapTap
//
//  Created by Jon Deokule on 5/2/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SearchArtistAlertView : UIAlertView

- (id) initWithArtistName:(NSString *)artist andDelegate:(id<UIAlertViewDelegate>)delegate;

@end
