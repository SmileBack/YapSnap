//
//  LoginViewController.m
//  YapSnap
//
//  Created by Dan Berenholtz on 9/20/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import "Global.h"
#import "EnterPhoneNumberViewController.h"
#import "API.h"

@interface EnterPhoneNumberViewController ()

@property (weak, nonatomic) IBOutlet UIButton *continueButton;
@property (weak, nonatomic) IBOutlet UITextField *textField;

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
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Retry"
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:nil
                                                                            action:nil];
    
    self.view.backgroundColor = THEME_BACKGROUND_COLOR;
    
    self.textField.keyboardType = UIKeyboardTypeNumberPad;
    
    double delay = 0.6;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.textField becomeFirstResponder];
    });
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.continueButton.userInteractionEnabled = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction) didTapContinueButton
{
    // This is to prevent user from clicking this multiple times before segue occurs (results in multiple segues)
    self.continueButton.userInteractionEnabled = NO;

    if ([self.textField.text length] < 10) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Enter your number"
                                                        message:@"Please enter your full number so we can verify that you're real"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        
        [alert show];
        
        // Enable the continue button again
        self.continueButton.userInteractionEnabled = YES;
        return;
    }
    
    NSString *phoneNumber = self.textField.text;

    [[API sharedAPI] postSessions:phoneNumber withCallback:^(BOOL success, NSError *error) {
        if (success) {
            [self performSegueWithIdentifier:@"EnterCodeViewControllerSegue" sender:self];
        } else {
            // TODO - ADD A UIALERT TELLING USER TO TRY AGAIN (WRONG CODE)
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:error.localizedDescription
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"otherButtonTitles:nil];
            [alert show];
            
            // Enable the continue button again
            self.continueButton.userInteractionEnabled = YES;
        }
    }];
}


- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

@end
