//
//  MusicGenreViewController.h
//  YapTap
//
//  Created by Dan B on 5/7/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PhoneContact.h"

@interface MusicGenreViewController : UIViewController

@property (nonatomic, strong) IBOutlet UIButton *musicButtonOne;
@property (nonatomic, strong) IBOutlet UIButton *musicButtonTwo;
@property (nonatomic, strong) IBOutlet UIButton *musicButtonThree;
@property (nonatomic, strong) IBOutlet UIButton *musicButtonFour;
@property (nonatomic, strong) IBOutlet UIButton *musicButtonFive;
@property (nonatomic, strong) IBOutlet UIButton *musicButtonSix;
@property (nonatomic, strong) IBOutlet UIButton *musicButtonSeven;
@property (nonatomic, strong) IBOutlet UIButton *musicButtonEight;
@property (nonatomic, strong) IBOutlet UIButton *musicButtonNine;
@property (nonatomic, strong) IBOutlet UIButton *musicButtonSearch;
@property (nonatomic) YSContact *contactReplyingTo;

- (void) tappedSpotifyButton:(NSString *)type;
- (IBAction) didTapBackButton;

@end
