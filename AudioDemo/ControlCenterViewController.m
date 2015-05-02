//
//  ControlCenterViewController.m
//  YapTap
//
//  Created by Jon Deokule on 5/2/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "ControlCenterViewController.h"

@interface ControlCenterViewController ()

- (IBAction)didTapControlCenterButtonOne;
- (IBAction)didTapControlCenterButtonTwo;
- (IBAction)didTapControlCenterButtonThree;
- (IBAction)didTapControlCenterButtonFour;
- (IBAction)didTapControlCenterButtonFive;
- (IBAction)didTapControlCenterButtonSix;
- (IBAction)didTapControlCenterButtonTop100;
- (IBAction)didTapControlCenterButtonSearch;
- (IBAction)didTapControlCenterButtonMic;

@end

@implementation ControlCenterViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self styleControlCenterButtons];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) styleControlCenterButtons {
//    CGFloat radius = self.controlCenterButtonOne.frame.size.height / 2.0f;
    CGFloat spacing = 18 + 16 + 16 + 18;
    CGFloat radius = ([[UIScreen mainScreen] bounds].size.width - spacing) / 3 / 2;

    self.controlCenterButtonOne.clipsToBounds = YES;
    self.controlCenterButtonOne.layer.cornerRadius = radius;
    self.controlCenterButtonOne.layer.borderWidth = 1;
    self.controlCenterButtonOne.layer.borderColor = [UIColor whiteColor].CGColor;
    
    self.controlCenterButtonTwo.layer.cornerRadius = radius;
    self.controlCenterButtonTwo.layer.borderWidth = 1;
    self.controlCenterButtonTwo.layer.borderColor = [UIColor whiteColor].CGColor;
    
    self.controlCenterButtonThree.layer.cornerRadius = radius;
    self.controlCenterButtonThree.layer.borderWidth = 1;
    self.controlCenterButtonThree.layer.borderColor = [UIColor whiteColor].CGColor;
    
    self.controlCenterButtonFour.layer.cornerRadius = radius;
    self.controlCenterButtonFour.layer.borderWidth = 1;
    self.controlCenterButtonFour.layer.borderColor = [UIColor whiteColor].CGColor;
    
    self.controlCenterButtonFive.layer.cornerRadius = radius;
    self.controlCenterButtonFive.layer.borderWidth = 1;
    self.controlCenterButtonFive.layer.borderColor = [UIColor whiteColor].CGColor;
    
    self.controlCenterButtonSix.layer.cornerRadius = radius;
    self.controlCenterButtonSix.layer.borderWidth = 1;
    self.controlCenterButtonSix.layer.borderColor = [UIColor whiteColor].CGColor;
    
    self.controlCenterButtonSearch.layer.cornerRadius = radius;
    self.controlCenterButtonSearch.layer.borderWidth = 1;
    self.controlCenterButtonSearch.layer.borderColor = [UIColor whiteColor].CGColor;
    
    self.controlCenterButtonTop100.layer.cornerRadius = radius;
    self.controlCenterButtonTop100.layer.borderWidth = 1;
    self.controlCenterButtonTop100.layer.borderColor = [UIColor whiteColor].CGColor;
    
    self.controlCenterButtonMic.layer.cornerRadius = radius;
    self.controlCenterButtonMic.layer.borderWidth = 1;
    self.controlCenterButtonMic.layer.borderColor = [UIColor whiteColor].CGColor;
}

#pragma mark - Song Genre Buttons

- (IBAction)didTapControlCenterButtonOne {
    [self.delegate tappedSpotifyButton:@"One"];
}

- (IBAction)didTapControlCenterButtonTwo {
    [self.delegate tappedSpotifyButton:@"Two"];
}

- (IBAction)didTapControlCenterButtonThree {
    [self.delegate tappedSpotifyButton:@"Three"];
}

- (IBAction)didTapControlCenterButtonFour {
    [self.delegate tappedSpotifyButton:@"Four"];
}

- (IBAction)didTapControlCenterButtonFive {
    [self.delegate tappedSpotifyButton:@"Five"];
}

- (IBAction)didTapControlCenterButtonSix {
    [self.delegate tappedSpotifyButton:@"Six"];
}

- (IBAction)didTapControlCenterButtonTop100 {
    [self.delegate tappedSpotifyButton:@"Top100"];
}

- (IBAction)didTapControlCenterButtonSearch {
    [self.delegate tappedSpotifyButton:@"Search"];
}

- (IBAction)didTapControlCenterButtonMic {
    [self.delegate tappedRecordButton];
}


@end
