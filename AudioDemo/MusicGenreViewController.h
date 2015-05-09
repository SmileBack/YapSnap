//
//  MusicGenreViewController.h
//  YapTap
//
//  Created by Dan B on 5/7/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ControlCenterViewController.h"

@interface MusicGenreViewController : UIViewController

@property (nonatomic, strong) id<ControlCenterDelegate> delegate;

@property (nonatomic, strong) IBOutlet UIButton *musicButtonOne;
@property (nonatomic, strong) IBOutlet UIButton *musicButtonTwo;
@property (nonatomic, strong) IBOutlet UIButton *musicButtonThree;
@property (nonatomic, strong) IBOutlet UIButton *musicButtonFour;
@property (nonatomic, strong) IBOutlet UIButton *musicButtonFive;
@property (nonatomic, strong) IBOutlet UIButton *musicButtonSix;
@property (nonatomic, strong) IBOutlet UIButton *musicButtonTop100;
@property (nonatomic, strong) IBOutlet UIButton *musicButtonSearch;

@end
