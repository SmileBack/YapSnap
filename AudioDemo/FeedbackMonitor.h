//
//  FeedbackMonitor.h
//  NightOut
//
//  Created by Jon Deokule on 11/2/14.
//  Copyright (c) 2014 WhoWentOut. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FeedbackMonitor : NSObject<UIAlertViewDelegate>

#define FEEDBACK_POPUP_SHOWN_KEY @"yaptap.FeedbackPopupShown"
#define COUNT_THRESHOLD 20
#define SHOW_FEEDBACK_PAGE @"yaptap.ShowFeedbackPage"

@property (nonatomic, readonly) BOOL feedbackPopupShown;
- (void) appOpened;

@end
