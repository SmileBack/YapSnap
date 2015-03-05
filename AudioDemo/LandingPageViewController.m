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
    
    // Do any additional setup after loading the view.
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@""
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:nil
                                                                            action:nil];
    
    self.logInButton.titleLabel.font = [UIFont fontWithName:@"Futura-Medium" size:22];
    [self.logInButton setTitleColor:THEME_BACKGROUND_COLOR forState:UIControlStateNormal];
    
    self.signUpButton.titleLabel.font = [UIFont fontWithName:@"Futura-Medium" size:22];
    [self.signUpButton setTitleColor:THEME_BACKGROUND_COLOR forState:UIControlStateNormal];
    
    YSUser *user = [YSUser currentUser];
    
    // if we're already authenticated, go right to the recording page
    if (user.hasSessionToken) {
        if (user.isUserInfoComplete) {
            AudioCaptureViewController* rvvc = [self.storyboard instantiateViewControllerWithIdentifier:@"AudioCaptureViewController"];
            [self.navigationController pushViewController:rvvc animated:NO];
        } else {
            //TO DO: Uncomment the following and take user straight to step 3 of registration
            AudioCaptureViewController* rvvc = [self.storyboard instantiateViewControllerWithIdentifier:@"EnterNameEmailViewController"];
            [self.navigationController pushViewController:rvvc animated:NO];
        }
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

- (IBAction) didTapSignUpButton
{
    [self performSegueWithIdentifier:@"SignUpWithPhoneNumberViewControllerSegue" sender:self];
}

- (IBAction) didTapLogInButton
{
    [self performSegueWithIdentifier:@"LogInWithPhoneNumberViewControllerSegue" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"SignUpWithPhoneNumberViewControllerSegue"]) {
        EnterPhoneNumberViewController *enterPhoneNumberVC = segue.destinationViewController;
        enterPhoneNumberVC.titleLabelString = @"Verify your number so we know you're real.";

    } else if ([segue.identifier isEqualToString:@"LogInWithPhoneNumberViewControllerSegue"]) {
        EnterPhoneNumberViewController *enterPhoneNumberVC = segue.destinationViewController;
        enterPhoneNumberVC.titleLabelString = @"Log in with your phone number.";
    }
}

@end
