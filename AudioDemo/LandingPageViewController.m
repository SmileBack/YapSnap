//
//  LandingPageViewController.m
//  YapSnap
//
//  Created by Dan Berenholtz on 9/20/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import "LandingPageViewController.h"
#import "AudioCaptureViewController.h"
#import "YSUser.h"
#import "EnterPhoneNumberViewController.h"

@implementation LandingPageViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@""
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:nil
                                                                            action:nil];
    
    self.logInButton.titleLabel.font = [UIFont fontWithName:@"Futura-Medium" size:30];
    [self.logInButton setTitleColor:THEME_BACKGROUND_COLOR forState:UIControlStateNormal];
    
    YSUser *user = [YSUser currentUser];
    
    // if we're already authenticated, go right to the recording page
    if (user.hasSessionToken) {
        if (user.isUserInfoComplete) {
            [self dismissViewControllerAnimated:NO completion:nil];
        } else {
            AudioCaptureViewController* rvvc = [self.storyboard instantiateViewControllerWithIdentifier:@"EnterNameEmailViewController"];
            [self.navigationController pushViewController:rvvc animated:NO];
        }
    } else {
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel track:@"Viewed Landing Page"];
    }
    
    if (self.isiPhone4Size || self.isiPhone5Size) {
        self.imageView.image = [UIImage imageNamed:@"LoginPageImageSmalleriPhonesMusicNotes.png"];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    self.view.backgroundColor = THEME_BACKGROUND_COLOR;
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (IBAction) didTapLogInButton
{
    [self performSegueWithIdentifier:@"LogInWithPhoneNumberViewControllerSegue" sender:self];
}

@end
