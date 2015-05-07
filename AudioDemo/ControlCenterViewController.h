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

@property (nonatomic, strong) IBOutlet UIButton *musicButtonOne;
@property (nonatomic, strong) IBOutlet UIButton *musicButtonTwo;
@property (nonatomic, strong) IBOutlet UIButton *musicButtonThree;
@property (nonatomic, strong) IBOutlet UIButton *musicButtonFour;
@property (nonatomic, strong) IBOutlet UIButton *musicButtonFive;
@property (nonatomic, strong) IBOutlet UIButton *musicButtonSix;
@property (nonatomic, strong) IBOutlet UIButton *musicButtonTop100;
@property (nonatomic, strong) IBOutlet UIButton *musicButtonSearch;
@property (nonatomic, strong) IBOutlet UIButton *controlCenterButtonMic;
@property (nonatomic, strong) IBOutlet UIButton *controlCenterButtonMusic;

@property (nonatomic, strong) IBOutlet UIView *firstControlCenterView;
@property (nonatomic, strong) IBOutlet UIView *secondControlCenterView;

#define SHOW_CONTROL_CENTER_MUSIC_HEADER_VIEW @"yaptap.ShowControlCenterMusicHeaderViewNotification"
#define TRANSITION_TO_FIRST_CONTROL_CENTER_VIEW @"yaptap.TransitionToFirstControlCenterViewNotification"
#define TAPPED_MIC_BUTTON_FOR_FIRST_TIME_KEY @"yaptap.TappedMicButtonForFirstTimeNotification"

@end
