//
//  ControlCenterViewController.m
//  YapTap
//
//  Created by Jon Deokule on 5/2/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "ControlCenterViewController.h"
#import "MusicGenreViewController.h"

@interface ControlCenterViewController ()

- (IBAction)didTapMicButton;
- (IBAction)didTapMusicButton;

@end

@implementation ControlCenterViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self styleControlCenterButtons];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    //[self setupNotifications];
}

- (void) styleControlCenterButtons {
    self.controlCenterButtonMic.layer.cornerRadius = 60;
    self.controlCenterButtonMic.layer.borderWidth = 1;
    self.controlCenterButtonMic.layer.borderColor = [UIColor whiteColor].CGColor;
    
    self.controlCenterButtonMusic.layer.cornerRadius = 60;
    self.controlCenterButtonMusic.layer.borderWidth = 1;
    self.controlCenterButtonMusic.layer.borderColor = [UIColor whiteColor].CGColor;
}

#pragma mark - Song Genre Buttons

- (IBAction)didTapMicButton {
    [self.delegate tappedMicButton];
    
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"Music Genre"]) {
        MusicGenreViewController* vc = segue.destinationViewController;
        vc.delegate = self.delegate;
    }
}

- (IBAction)didTapMusicButton {
    [self performSegueWithIdentifier:@"Music Genre" sender:nil];
}

- (BOOL) didTapMicButtonForFirstTime {
    return [[NSUserDefaults standardUserDefaults] boolForKey:TAPPED_MIC_BUTTON_FOR_FIRST_TIME_KEY];
}

@end