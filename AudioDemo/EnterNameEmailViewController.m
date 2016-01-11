//
//  EnterNameViewController.m
//  YapSnap
//
//  Created by Dan Berenholtz on 9/23/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import "EnterNameEmailViewController.h"
#import "API.h"
#import "YSPushManager.h"
#import "UIViewController+Alerts.h"
#import "AppDelegate.h"
#import "Flurry.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>

#define COMPLETED_REGISTRATION_NOTIFICATION @"com.yapsnap.CompletedRegistrationNotification2"

@interface EnterNameEmailViewController ()<FBSDKLoginButtonDelegate>

@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *loadingSpinner;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *topConstraint;
@property (strong, nonatomic) IBOutlet UIProgressView *progressView;

@end

@implementation EnterNameEmailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Viewed Name Email Page"];
    [Flurry logEvent:@"Viewed Name Email Page"];
    
    self.view.backgroundColor = THEME_BACKGROUND_COLOR;
    if (self.isiPhone4Size) {
        self.topConstraint.constant = 0;
        self.progressView.hidden = YES;
    }
    
    if ([AppDelegate sharedDelegate].appOpenedCount <= 2) {
        [self.progressView setProgress:0.66 animated:NO];
        double delay2 = 0.5;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.progressView setProgress:1.0 animated:YES];
        });
    }
    
    CGRect frame = CGRectMake(0, 0, self.view.frame.size.width - 60, 100);
    FBSDKLoginButton *loginButton = [[FBSDKLoginButton alloc] initWithFrame:frame];
    // Optional: Place the button in the center of your view.
    loginButton.readPermissions = @[@"public_profile", @"email", @"user_friends"];
    loginButton.center = self.view.center;
    loginButton.delegate = self;
    [self.view addSubview:loginButton];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
}

#pragma mark - FBSDKLoginButtonDelegate

- (void)  loginButton:(FBSDKLoginButton *)loginButton
didCompleteWithResult:(FBSDKLoginManagerLoginResult *)result
                error:(NSError *)error {
    if (error || result.isCancelled || result.grantedPermissions.count == 0 || ![FBSDKAccessToken currentAccessToken]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Couldn't log in with Facebook" message:@"Something went wrong connecting your Facebook account, please try again" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    } else {
        [self.loadingSpinner startAnimating];
        [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields": @"id,first_name,last_name,email"}]
         startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
             if (!error && [result isKindOfClass:[NSDictionary class]]) {
                    NSLog(@"RESULT: %@", result);
                     [[API sharedAPI] updateFirstName:result[@"first_name"]
                                             lastName:result[@"last_name"]
                                                email:result[@"email"]
                                   facebookIdentifier:result[@"id"]
                                         withCallBack:^(BOOL success, NSError *error) {
                                             [self.loadingSpinner stopAnimating];
                                             
                                             if (!result[@"first_name"] || ([result[@"first_name"] isEqual: [NSNull null]])) {
                                                 NSLog(@"FIRST NAME IS NULL!!!");
                                             } else if (!result[@"last_name"] || ([result[@"last_name"] isEqual: [NSNull null]])) {
                                                 NSLog(@"LAST NAME IS NULL!!!");
                                             } else if (!result[@"email"] || ([result[@"email"] isEqual: [NSNull null]])) {
                                                 NSLog(@"EMAIL IS NULL");
                                             } else if (!result[@"id"] || ([result[@"id"] isEqual: [NSNull null]])) {
                                                 NSLog(@"id IS NULL");
                                             }
                                             
                                             if (success) {
                                                 [self.view endEditing:YES];
                                                 [[NSNotificationCenter defaultCenter] postNotificationName:COMPLETED_REGISTRATION_NOTIFICATION object:nil];
                                                 [self dismissViewControllerAnimated:YES completion:nil];
                                                 [[YSPushManager sharedPushManager] registerForNotifications];
                                                 Mixpanel *mixpanel = [Mixpanel sharedInstance];
                                                 [mixpanel track:@"Completed Registration"];
                                                 [Flurry logEvent:@"Completed Registration"];
                                             } else {
                                                 NSLog(@"Error! %@", error);
                                                 [[[UIAlertView alloc] initWithTitle:@"Try Again" message:@"There was an error saving your info. Please try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                                                 Mixpanel *mixpanel = [Mixpanel sharedInstance];
                                                 [mixpanel track:@"API Error - updateNameEmail (reg)"];
                                                 [self dismissViewControllerAnimated:YES completion:nil];
                                             }
                                         }];
             } else {
                 [self dismissViewControllerAnimated:YES completion:nil];
             }
         }];
    }
}

- (void)loginButtonDidLogOut:(FBSDKLoginButton *)loginButton {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
