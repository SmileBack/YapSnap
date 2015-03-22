//
//  EnterPhoneNumberViewController.m
//  YapSnap
//
//  Created by Dan Berenholtz on 9/20/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import "EnterPhoneNumberViewController.h"
#import "API.h"
#import "PhoneNumberChecker.h"
#import <SHSPhoneComponent/SHSPhoneTextField.h>
#import <SHSPhoneComponent/SHSPhoneNumberFormatter.h>
#import "UIViewController+Alerts.h"

@interface EnterPhoneNumberViewController ()

@property (weak, nonatomic) IBOutlet UIButton *continueButton;
//@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (strong, nonatomic) IBOutlet SHSPhoneTextField *textField;
@property (nonatomic, strong) PhoneNumberChecker *phoneNumberChecker;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *loadingSpinner;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *topTextConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *topPhoneConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *buttonConstraint;


- (IBAction)didTapContinueButton;

@end

@implementation EnterPhoneNumberViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Viewed Phone Number Page"];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Retry"
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:nil
                                                                            action:nil];
    
    self.view.backgroundColor = THEME_BACKGROUND_COLOR;
    
    self.textField.delegate = self;
    self.textField.keyboardType = UIKeyboardTypeNumberPad;
    [self.textField.formatter setDefaultOutputPattern:@"(###) ###-####"];
    
    double delay = 0.6;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.textField becomeFirstResponder];
    });
    
    self.phoneNumberChecker = [[PhoneNumberChecker alloc] init];
    
    [self makeNavBarTransparent];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    self.titleLabel.text = self.titleLabelString;
    
    if (self.isiPhone4Size) {
        CGFloat scale = .5f;
        self.topTextConstraint.constant = 0;
        self.topPhoneConstraint.constant *= scale;
        self.buttonConstraint.constant *= scale;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.continueButton.userInteractionEnabled = YES;
}

- (void)makeNavBarTransparent
{
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new]
                                                  forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.translucent = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction) didTapContinueButton
{
    NSLog(@"Tapped Continue Button");
    
    if ([self.textField.text length] < 10) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Enter your number"
                                                        message:@"Please enter your phone number so we can verify that you're real."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    if (![self.phoneNumberChecker isPhoneNumberValid:self.textField.text]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Number not valid"
                                                        message:@"Please enter a valid number."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Confirm Number"
                                                        message:[NSString stringWithFormat:@"Is your mobile number %@?", self.textField.text]
                                                       delegate:self
                                              cancelButtonTitle:@"No"
                                              otherButtonTitles:@"Yes", nil];
        [alert show];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        [self disableContinueButton];
        
        if ([self internetIsNotReachable]) {
            [self showNoInternetAlert];
            [self enableContinueButton];
        } else {
            NSString *phoneNumber = self.textField.text;
            [[API sharedAPI] openSession:phoneNumber withCallback:^(BOOL success, NSError *error) {
                [self enableContinueButton];
                if (success) {
                    [self performSegueWithIdentifier:@"EnterCodeViewControllerSegue" sender:self];
                } else {
                    [[[UIAlertView alloc] initWithTitle:@"Try Again" message:@"There was an error saving your info. Please try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                }
            }];
        }
    }
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
