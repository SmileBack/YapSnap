//
//  UIViewController+Alerts.m
//  YapSnap
//
//  Created by Jon Deokule on 2/10/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "UIViewController+Alerts.h"

@implementation UIViewController (Alerts)
- (void) showNoInternetAlert {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Internet Connection"
                                                    message:@"Please connect to the internet and try again."
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}
@end
