//
//  EnterNameViewController.m
//  YapSnap
//
//  Created by Dan Berenholtz on 9/23/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import "Global.h"
#import "EnterNameEmailViewController.h"
#import "API.h"

@interface EnterNameEmailViewController ()

@property (weak, nonatomic) IBOutlet UIButton *continueButton;
@property (weak, nonatomic) IBOutlet UITextField *firstNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *lastNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;

- (IBAction)didTapContinueButton;

@end

@implementation EnterNameEmailViewController

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
    
    self.view.backgroundColor = THEME_BACKGROUND_COLOR;
    
    self.firstNameTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.firstNameTextField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    
    self.lastNameTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.lastNameTextField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    
    self.emailTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.emailTextField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    
    double delay = 0.6;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.firstNameTextField becomeFirstResponder];
    });
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}


- (IBAction) didTapContinueButton
{
    if ([self.firstNameTextField.text length] < 2) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Enter your name"
                                                        message:@"Please enter your name so people can send you messages"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    } else if ([self.lastNameTextField.text length] < 1) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Enter your name"
                                                        message:@"Please enter your name so people can send you messages"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    } else if (![self NSStringIsValidEmail:self.emailTextField.text]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Enter your email"
                                                        message:@"Please enter a valid email. We will never send you spam."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    } else {
        //ADD API Call here
        [self performSegueWithIdentifier:@"RecordViewControllerSegue" sender:self];
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

@end
