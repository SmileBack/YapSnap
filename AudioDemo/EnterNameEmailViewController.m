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

#define COMPLETED_REGISTRATION_NOTIFICATION @"com.yapsnap.CompletedRegistrationNotification"

@interface EnterNameEmailViewController ()

@property (weak, nonatomic) IBOutlet UIButton *continueButton;
@property (weak, nonatomic) IBOutlet UITextField *firstNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *lastNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *loadingSpinner;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *topConstraint;
@property (strong, nonatomic) IBOutlet UIProgressView *progressView;

- (IBAction)didTapContinueButton;

@end

@implementation EnterNameEmailViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Viewed Name Email Page"];
    
    [self setupTextFields];
    
    self.view.backgroundColor = THEME_BACKGROUND_COLOR;
    
    double delay = 0.6;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.firstNameTextField becomeFirstResponder];
    });
    
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
}

- (void)setupTextFields {
    self.firstNameTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.firstNameTextField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    self.firstNameTextField.layer.borderColor=[[UIColor lightGrayColor]CGColor];
    self.firstNameTextField.layer.borderWidth = 1;
    self.firstNameTextField.layer.masksToBounds = true;
    
    self.lastNameTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.lastNameTextField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    self.lastNameTextField.layer.borderColor=[[UIColor lightGrayColor]CGColor];
    self.lastNameTextField.layer.borderWidth = 1;
    self.lastNameTextField.layer.masksToBounds = true;
    
    self.emailTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.emailTextField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    self.emailTextField.layer.borderColor=[[UIColor lightGrayColor]CGColor];
    self.emailTextField.layer.borderWidth = 1;
    self.emailTextField.layer.masksToBounds = true;
    
    self.firstNameTextField.delegate = self;
    self.lastNameTextField.delegate = self;
    self.emailTextField.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
}

- (IBAction) didTapContinueButton
{
    self.emailTextField.text = [self.emailTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    self.firstNameTextField.text = [self.firstNameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    self.lastNameTextField.text = [self.lastNameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if ([self.firstNameTextField.text length] < 2) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Enter your name"
                                                        message:@"Please enter your name."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    
    } else if ([self.lastNameTextField.text length] < 1) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Enter your name"
                                                        message:@"Please enter your last name."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    
    } else if ([self.emailTextField.text length] > 0 && ![self NSStringIsValidEmail:self.emailTextField.text]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Enter your email"
                                                        message:@"Please enter a valid email. We will never spam you."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
        else {
        [self disableContinueButton];
        
        if ([self internetIsNotReachable]) {
            [self showNoInternetAlert];
            [self enableContinueButton];
        } else {
            [[API sharedAPI] updateFirstName:self.firstNameTextField.text
                                    lastName:self.lastNameTextField.text
                                       email:self.emailTextField.text
                                withCallBack:^(BOOL success, NSError *error) {
                                    [self enableContinueButton];
                                    
                                    if (success) {
                                        [self.view endEditing:YES];
                                        [[NSNotificationCenter defaultCenter] postNotificationName:COMPLETED_REGISTRATION_NOTIFICATION object:nil];
                                        [self dismissViewControllerAnimated:YES completion:nil];
                                        [[YSPushManager sharedPushManager] registerForNotifications];
                                    } else {
                                        NSLog(@"Error! %@", error);
                                        [[[UIAlertView alloc] initWithTitle:@"Try Again" message:@"There was an error saving your info. Please try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                                        Mixpanel *mixpanel = [Mixpanel sharedInstance];
                                        [mixpanel track:@"API Error - updateNameEmail (reg)"];
                                        [self enableContinueButton]; // Adding this line a second time just in case
                                    }
                                }];
        }
    }
}

-(BOOL) NSStringIsValidEmail:(NSString *)checkString
{
    BOOL stricterFilter = NO; // Discussion on the logic behind this code: blog.logichigh.com/2010/09/02/validating-an-e-mail-address/
    NSString *stricterFilterString = @"[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}";
    NSString *laxString = @".+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2}[A-Za-z]*";
    NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:checkString];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.firstNameTextField) {
        [self.lastNameTextField becomeFirstResponder];
    } else if (textField == self.lastNameTextField) {
        [self.emailTextField becomeFirstResponder];
    } else if (textField == self.emailTextField) {
        [self didTapContinueButton];
    }
    
    return YES;
}

-(BOOL) internetIsNotReachable
{
    return ![AFNetworkReachabilityManager sharedManager].reachable;
}

-(void) disableContinueButton
{
    self.continueButton.userInteractionEnabled = NO;
    [self.loadingSpinner startAnimating];
    [self.continueButton setImage:[UIImage imageNamed:@"WhiteCircle.png"] forState:UIControlStateNormal];
}

-(void) enableContinueButton
{
    [self.loadingSpinner stopAnimating];
    [self.continueButton setImage:[UIImage imageNamed:@"ArrowWhite.png"] forState:UIControlStateNormal];
    self.continueButton.userInteractionEnabled = YES;
}

@end
