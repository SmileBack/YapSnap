//
//  ControlCenterViewController.h
//  YapTap
//
//  Created by Jon Deokule on 5/2/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ControlCenterDelegate

- (void) tappedSpotifyButton:(NSString *)type;
- (void) tappedMicButton;

@end

@interface ControlCenterViewController : UIViewController

@property (nonatomic, strong) id<ControlCenterDelegate> delegate;

#define TAPPED_MIC_BUTTON_FOR_FIRST_TIME_KEY @"yaptap.TappedMicButtonForFirstTimeNotification"

@end
