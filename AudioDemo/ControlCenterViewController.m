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

- (IBAction)didTapMicButton;
- (IBAction)didTapMusicButton;
- (IBAction)didTapGoToFirstControlCenterViewButton;

@end

@implementation ControlCenterViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self styleControlCenterButtons];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self setupNotifications];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) setupNotifications {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserverForName:TRANSITION_TO_FIRST_CONTROL_CENTER_VIEW
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                        NSLog(@"Show First Control Center View");
                        [self transitionToFirstControlCenterView];
                    }];
    
    [center addObserverForName:UIApplicationDidEnterBackgroundNotification
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                        NSLog(@"popToBaseAudioCaptureController");
                        self.secondControlCenterView.alpha = 0;
                        self.firstControlCenterView.alpha = 1;
                    }];
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
    
    self.controlCenterButtonMic.layer.cornerRadius = 60;
    self.controlCenterButtonMic.layer.borderWidth = 1;
    self.controlCenterButtonMic.layer.borderColor = [UIColor whiteColor].CGColor;
    
    self.controlCenterButtonMusic.layer.cornerRadius = 60;
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

- (IBAction)didTapMicButton {
    [self.delegate tappedRecordButton];
    
    if (!self.didTapMicButtonForFirstTime) {
        double delay = .3;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Add Helium to Your Voice"
            message:@"Record your voice and then tap the white balloons!"
            delegate:nil
            cancelButtonTitle:@"OK"
            otherButtonTitles: nil];
            [alert show];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:TAPPED_MIC_BUTTON_FOR_FIRST_TIME_KEY];
        });
    }
}

- (IBAction)didTapMusicButton {
    //[[NSNotificationCenter defaultCenter] postNotificationName:SHOW_CONTROL_CENTER_MUSIC_HEADER_VIEW object:nil];
    
    [UIView animateWithDuration:.2
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.firstControlCenterView.alpha = 0;
                     }
                     completion:^(BOOL finished) {
                         [self unhideSecondControlCenterView];
                     }];
}

- (void) unhideSecondControlCenterView {
    [UIView animateWithDuration:.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.secondControlCenterView.alpha = 1;
                     }
                     completion:nil];
}

- (void) unhideFirstControlCenterView {
    [UIView animateWithDuration:.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.firstControlCenterView.alpha = 1;
                     }
                     completion:nil];
}


- (void) transitionToFirstControlCenterView {
    [UIView animateWithDuration:.2
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.secondControlCenterView.alpha = 0;
                     }
                     completion:^(BOOL finished) {
                         [self unhideFirstControlCenterView];
                     }];
}

- (IBAction)didTapGoToFirstControlCenterViewButton
{
    [self transitionToFirstControlCenterView];
}

- (BOOL) didTapMicButtonForFirstTime
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:TAPPED_MIC_BUTTON_FOR_FIRST_TIME_KEY];
}


@end
