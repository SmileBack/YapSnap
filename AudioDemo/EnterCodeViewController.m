//
//  EnterCodeViewController.m
//  YapSnap
//
//  Created by Dan Berenholtz on 9/20/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import "EnterCodeViewController.h"
#import "API.h"

@interface EnterCodeViewController ()

@property (weak, nonatomic) IBOutlet UIButton *continueButton;
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *loadingSpinner;

- (IBAction)didTapContinueButton;

@end

@implementation EnterCodeViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.continueButton.userInteractionEnabled = YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
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
        
        // Enable the continue button again
        self.continueButton.userInteractionEnabled = YES;
        
        return;
    }
    
    // This is to prevent user from clicking this multiple times before segue occurs (results in multiple segues)
    self.continueButton.userInteractionEnabled = NO;
    
    // Start loading spinner
    [self.loadingSpinner startAnimating];
    NSLog(@"Loading spinner started animating");

    NSString *code = self.textField.text;

    [[API sharedAPI] confirmSessionWithCode:code withCallback:^(YSUser *user, NSError *error) {
        [self.loadingSpinner stopAnimating];
        if (user) {
            // TODO save user state??? - do in API
            
            if (user.isUserInfoComplete) {
                [self performSegueWithIdentifier:@"EnterNameAndEmailViewControllerSegue" sender:self];
            } else {
                [self performSegueWithIdentifier:@"Push Audio Capture Segue" sender:nil];
            }
        } else {
            // TODO: different UIAlert depending on error (no internet, wrong code, etc.)
            // NSLog([NSString stringWithFormat:@"error: %@", error]);
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Try Again"
                                                            message:@"That was the wrong code. Try again."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            
            [alert show];
            
            // Enable the continue button again
            self.continueButton.userInteractionEnabled = YES;
        }
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:animated]; //UNDO
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillDisappear:animated];
}

@end
