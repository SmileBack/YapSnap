//
//  EnterCodeViewController.m
//  YapSnap
//
//  Created by Dan Berenholtz on 9/20/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import "EnterCodeViewController.h"
#import "API.h"
#import "UIViewController+Alerts.h"

@interface EnterCodeViewController ()

@property (weak, nonatomic) IBOutlet UIButton *continueButton;
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *loadingSpinner;

- (IBAction)didTapContinueButton;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *topTextConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *topPhoneConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *buttonConstraint;

@end

@implementation EnterCodeViewController

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.continueButton.userInteractionEnabled = YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Viewed Enter Code Page"];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@""
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:nil
                                                                            action:nil];
    
    self.view.backgroundColor = THEME_BACKGROUND_COLOR;
    
    self.textField.keyboardType = UIKeyboardTypeNumberPad;
    
    double delay = 0.8;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.textField becomeFirstResponder];
    });
    
    [self makeNavBarTransparent];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];

    if (self.isiPhone4Size) {
        CGFloat scale = .5f;
        self.topTextConstraint.constant = 0;
        self.topPhoneConstraint.constant *= scale;
        self.buttonConstraint.constant *= scale;
    }
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
    if ([self.textField.text length] == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Enter code"
                                                        message:@"We sent you a code. Please enter it here to continue."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        
        [alert show];
        
        return;
    }
    
    [self disableContinueButton];

    if ([self internetIsNotReachable]) {
        [self showNoInternetAlert];
        [self enableContinueButton];
    } else {
        NSString *code = self.textField.text;
        [[API sharedAPI] confirmSessionWithCode:code withCallback:^(YSUser *user, NSError *error) {
            [self enableContinueButton];
            
            if (user) {
                // TODO save user state??? - do in API
                
                if (!user.isUserInfoComplete) {
                    [self performSegueWithIdentifier:@"EnterNameAndEmailViewControllerSegue" sender:self];
                } else {
                    [self performSegueWithIdentifier:@"Push Audio Capture Segue" sender:nil];
                }
            } else {
                // TODO: different UIAlert depending on error (no internet, wrong code, etc.)
                //NSLog([NSString stringWithFormat:@"error: %@", error]);
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Try Again"
                                                                message:@"That was the wrong code. Please try again."
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
                [self enableContinueButton]; // Adding this line a second time just in case
            }
        }];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:animated]; //UNDO
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillDisappear:animated];
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
