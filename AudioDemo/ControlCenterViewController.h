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
- (void) tappedRecordButton;

@end

@interface ControlCenterViewController : UIViewController

@property (nonatomic, strong) id<ControlCenterDelegate> delegate;

@property (nonatomic, strong) IBOutlet UIButton *controlCenterButtonOne;
@property (nonatomic, strong) IBOutlet UIButton *controlCenterButtonTwo;
@property (nonatomic, strong) IBOutlet UIButton *controlCenterButtonThree;
@property (nonatomic, strong) IBOutlet UIButton *controlCenterButtonFour;
@property (nonatomic, strong) IBOutlet UIButton *controlCenterButtonFive;
@property (nonatomic, strong) IBOutlet UIButton *controlCenterButtonSix;
@property (nonatomic, strong) IBOutlet UIButton *controlCenterButtonTop100;
@property (nonatomic, strong) IBOutlet UIButton *controlCenterButtonSearch;
@property (nonatomic, strong) IBOutlet UIButton *controlCenterButtonMic;

@end
