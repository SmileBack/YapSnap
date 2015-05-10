//
//  MusicGenreViewController.m
//  YapTap
//
//  Created by Dan B on 5/7/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "MusicGenreViewController.h"
#import "AudioCaptureViewController.h"

@interface MusicGenreViewController ()

- (IBAction)didTapMusicButtonOne;
- (IBAction)didTapMusicButtonTwo;
- (IBAction)didTapMusicButtonThree;
- (IBAction)didTapMusicButtonFour;
- (IBAction)didTapMusicButtonFive;
- (IBAction)didTapMusicButtonSix;
- (IBAction)didTapMusicButtonSeven;
- (IBAction)didTapMusicButtonEight;
- (IBAction)didTapMusicButtonNine;
- (IBAction)didTapMusicButtonSearch;

@end

@implementation MusicGenreViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self styleButtons];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)didTapMusicButtonOne {
    [self tappedSpotifyButton:@"One"];
}

- (IBAction)didTapMusicButtonTwo {
    [self tappedSpotifyButton:@"Two"];
}

- (IBAction)didTapMusicButtonThree {
    [self tappedSpotifyButton:@"Three"];
}

- (IBAction)didTapMusicButtonFour {
    [self tappedSpotifyButton:@"Four"];
}

- (IBAction)didTapMusicButtonFive {
    [self tappedSpotifyButton:@"Five"];
}

- (IBAction)didTapMusicButtonSix {
    [self tappedSpotifyButton:@"Six"];
}

- (IBAction)didTapMusicButtonSeven {
    [self tappedSpotifyButton:@"Seven"];
}

- (IBAction)didTapMusicButtonEight {
    [self tappedSpotifyButton:@"Eight"];
}

- (IBAction)didTapMusicButtonNine {
    [self tappedSpotifyButton:@"Nine"];
}

- (IBAction)didTapMusicButtonSearch {
    [self tappedSpotifyButton:@"Search"];
}

- (void) styleButtons {
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
    
    self.musicButtonSeven.layer.cornerRadius = radius;
    self.musicButtonSeven.layer.borderWidth = 1;
    self.musicButtonSeven.layer.borderColor = [UIColor whiteColor].CGColor;
    
    self.musicButtonEight.layer.cornerRadius = radius;
    self.musicButtonEight.layer.borderWidth = 1;
    self.musicButtonEight.layer.borderColor = [UIColor whiteColor].CGColor;
    
    self.musicButtonNine.layer.cornerRadius = radius;
    self.musicButtonNine.layer.borderWidth = 1;
    self.musicButtonNine.layer.borderColor = [UIColor whiteColor].CGColor;
    
    self.musicButtonSearch.layer.cornerRadius = radius;
    self.musicButtonSearch.layer.borderWidth = 1;
    self.musicButtonSearch.layer.borderColor = [UIColor whiteColor].CGColor;
}


- (void) tappedSpotifyButton:(NSString *)type
{
    [self performSegueWithIdentifier:@"Audio Record" sender:type];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UINavigationController *navVC = segue.destinationViewController;
    AudioCaptureViewController* audio = navVC.topViewController;

    if (sender) { // The presence of a sender means that there was a spotify genre specified
        audio.type = AudioCapTureTypeSpotify;
        audio.audioCaptureContext = @{
                                      AudioCaptureContextGenreName: sender
                                      };
    } else {
        audio.type = AudioCaptureTypeMic;
    }
    audio.contactReplyingTo = self.contactReplyingTo;
}

- (IBAction) didTapBackButton
{
    [self.navigationController popViewControllerAnimated:YES];
}

@end
