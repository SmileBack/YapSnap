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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction) didTapContinueButton
{    
    NSString *path = @"/sessions";
    NSMutableDictionary* parameters = [@{@"phone": self.textField.text, @"name": [Global retrieveValueForKey:@"name"]} mutableCopy];
    
    UNIHTTPJsonResponse *result = [API postToPath:path withParameters:parameters];
    
    if ([self.textField.text length] < 10) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Enter your number"
                                                        message:@"Please enter your full number so we can verify that you're real"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        
        [alert show];
    } else {
        if ([result code] == 201) {
            [Global storeValue:self.textField.text forKey:@"phone_number"];
            [Global storeValue:[[[result body] JSONObject] valueForKey:@"user_id"] forKey:@"current_user_id"];
            [self performSegueWithIdentifier:@"EnterCodeViewControllerSegue" sender:self];
        } else {
            // TODO - ADD A UIALERT TELLING USER TO TRY AGAIN (WRONG CODE)
        }
    }
}


- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    //[self.navigationController setNavigationBarHidden:NO animated:animated];
    //[super viewWillDisappear:animated];
}

@end
