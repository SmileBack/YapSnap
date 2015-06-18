//
//  BlockFriendAlertView.m
//  YapTap
//
//  Created by Jon Deokule on 5/2/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "SearchArtistAlertView.h"

@implementation SearchArtistAlertView

- (id) initWithArtistName:(NSString *)artistName andDelegate:(id<UIAlertViewDelegate>)delegate
{
    NSString *title = [NSString stringWithFormat:@"%@", artistName];
    NSString *message = [NSString stringWithFormat:@"See top tracks by %@.", artistName];
    
    self = [super initWithTitle:title
                        message:message
                       delegate:delegate
              cancelButtonTitle:@"Cancel" otherButtonTitles:@"Continue", nil];
    return self;
}

@end
