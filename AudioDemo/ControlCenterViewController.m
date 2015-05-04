//
//  ControlCenterViewController.m
//  YapTap
//
//  Created by Jon Deokule on 5/2/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "ControlCenterViewController.h"

@interface ControlCenterViewController ()

- (IBAction)didTapMusicButtonOne;
- (IBAction)didTapMusicButtonTwo;
- (IBAction)didTapMusicButtonThree;
- (IBAction)didTapMusicButtonFour;
- (IBAction)didTapMusicButtonFive;
- (IBAction)didTapMusicButtonSix;
- (IBAction)didTapMusicButtonTop100;
- (IBAction)didTapMusicButtonSearch;

- (IBAction)didTapControlCenterButtonMic;
- (IBAction)didTapControlCenterButtonMusic;

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

    self.musicButtonOne.clipsToBounds = YES;
    self.musicButtonOne.layer.cornerRadius = radius;
    self.musicButtonOne.layer.borderWidth = 1;
    self.musicButtonOne.layer.borderColor = [UIColor whiteColor].CGColor;
    
    self.musicButtonTwo.layer.cornerRadius = radius;
    self.musicButtonTwo.layer.borderWidth = 1;
    self.musicButtonTwo.layer.borderColor = [UIColor whiteColor].CGColor;
    
    self.musicButtonThree.layer.cornerRadius = radius;
    self.musicButtonThree.layer.borderWidth = 1;
    self.musicButtonThree.layer.borderColor = [UIColor whiteColor].CGColor;
    
    self.musicButtonFour.layer.cornerRadius = radius;
    self.musicButtonFour.layer.borderWidth = 1;
    self.musicButtonFour.layer.borderColor = [UIColor whiteColor].CGColor;
    
    self.musicButtonFive.layer.cornerRadius = radius;
    self.musicButtonFive.layer.borderWidth = 1;
    self.musicButtonFive.layer.borderColor = [UIColor whiteColor].CGColor;
    
    self.musicButtonSix.layer.cornerRadius = radius;
    self.musicButtonSix.layer.borderWidth = 1;
    self.musicButtonSix.layer.borderColor = [UIColor whiteColor].CGColor;
    
    self.musicButtonSearch.layer.cornerRadius = radius;
    self.musicButtonSearch.layer.borderWidth = 1;
    self.musicButtonSearch.layer.borderColor = [UIColor whiteColor].CGColor;
    
    self.musicButtonTop100.layer.cornerRadius = radius;
    self.musicButtonTop100.layer.borderWidth = 1;
    self.musicButtonTop100.layer.borderColor = [UIColor whiteColor].CGColor;
    
    self.controlCenterButtonMic.layer.cornerRadius = radius;
    self.controlCenterButtonMic.layer.borderWidth = 1;
    self.controlCenterButtonMic.layer.borderColor = [UIColor whiteColor].CGColor;
    
    self.controlCenterButtonMusic.layer.cornerRadius = radius;
    self.controlCenterButtonMusic.layer.borderWidth = 1;
    self.controlCenterButtonMusic.layer.borderColor = [UIColor whiteColor].CGColor;
}

#pragma mark - Song Genre Buttons

- (IBAction)didTapMusicButtonOne {
    [self.delegate tappedSpotifyButton:@"One"];
}

- (IBAction)didTapMusicButtonTwo {
    [self.delegate tappedSpotifyButton:@"Two"];
}

- (IBAction)didTapMusicButtonThree {
    [self.delegate tappedSpotifyButton:@"Three"];
}

- (IBAction)didTapMusicButtonFour {
    [self.delegate tappedSpotifyButton:@"Four"];
}

- (IBAction)didTapMusicButtonFive {
    [self.delegate tappedSpotifyButton:@"Five"];
}

- (IBAction)didTapMusicButtonSix {
    [self.delegate tappedSpotifyButton:@"Six"];
}

- (IBAction)didTapMusicButtonTop100 {
    [self.delegate tappedSpotifyButton:@"Top100"];
}

- (IBAction)didTapMusicButtonSearch {
    [self.delegate tappedSpotifyButton:@"Search"];
}

- (IBAction)didTapControlCenterButtonMic {
    [self.delegate tappedRecordButton];
}

- (IBAction)didTapControlCenterButtonMusic {
    [UIView animateWithDuration:.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.controlCenterView.alpha = 0;
                     }
                     completion:^(BOOL finished) {
                         [self showMusicView];
                     }];
}

- (void) showMusicView {
    [UIView animateWithDuration:.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.musicView.alpha = 1;
                     }
                     completion:nil];
}

@end
