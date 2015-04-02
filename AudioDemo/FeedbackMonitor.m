//
//  FeedbackMonitor.m
//  NightOut
//
//  Created by Jon Deokule on 11/2/14.
//  Copyright (c) 2014 WhoWentOut. All rights reserved.
//

#import "FeedbackMonitor.h"
#import "AppDelegate.h"

@interface FeedbackMonitor()
@property (nonatomic, strong) UIAlertView *initialQuestionAlert;
@property (nonatomic, strong) UIAlertView *reviewAlert;
@property (nonatomic, strong) UIAlertView *feedbackAlert;
@end

@implementation FeedbackMonitor

- (BOOL) feedbackPopupShown
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:FEEDBACK_POPUP_SHOWN_KEY];

}

- (void) feedbackPopupWasShown
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:FEEDBACK_POPUP_SHOWN_KEY];
}

- (void) appOpened
{
    if ([AppDelegate sharedDelegate].appOpenedCount >= COUNT_THRESHOLD &&
        !self.feedbackPopupShown) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self showInitialPopup];
            [self feedbackPopupWasShown];
        });
    }
}

- (void) showInitialPopup
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Hey There"
                                                    message:@"We've been wanting to ask.\nDo you love YapTap?"
                                                   delegate:self
                                          cancelButtonTitle:@"No"
                                          otherButtonTitles:@"Yes", nil];
    self.initialQuestionAlert = alert;
    [alert show];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Ratings - Saw Initial Popup"];
    [mixpanel.people increment:@"Ratings - Saw Initial Popup #" by:[NSNumber numberWithInt:1]];
}

- (void) showReviewPopup
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Rate Us?"
                                                    message:@"Would you mind taking a moment to rate us? Each review helps us a lot!"
                                                   delegate:self
                                          cancelButtonTitle:@"No"
                                          otherButtonTitles:@"Sure", nil];
    self.reviewAlert = alert;
    [alert show];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Ratings - Saw Review Popup"];
}

- (void) showFeedbackPopup
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Feedback"
                                                    message:@"Would you mind telling us how we can improve the app? We read and respond to all feedback."
                                                   delegate:self
                                          cancelButtonTitle:@"No"
                                          otherButtonTitles:@"Sure", nil];
    self.feedbackAlert = alert;
    [alert show];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Ratings - Saw Feedback Popup"];
}

#pragma mark - UIAlertViewDelegate
- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView == self.initialQuestionAlert) {
        self.initialQuestionAlert = nil;
        if (buttonIndex == 1) {
            [self showReviewPopup];
        } else {
            [self showFeedbackPopup];
        }
    } else if (alertView == self.reviewAlert){
        self.reviewAlert = nil;
        if (buttonIndex == 1) {
            NSString *iTunesLink = @"itms-apps://itunes.apple.com/app/id972004073";
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:iTunesLink]];
            
            Mixpanel *mixpanel = [Mixpanel sharedInstance];
            [mixpanel track:@"Ratings - Said Yes To Review"];
        }
    } else if (alertView == self.feedbackAlert) {
        self.feedbackAlert = nil;
        if (buttonIndex == 1) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:SHOW_FEEDBACK_PAGE object:nil];
            });
            
            Mixpanel *mixpanel = [Mixpanel sharedInstance];
            [mixpanel track:@"Ratings - Said Yes To Feedback"];
        }
    }
}


@end
