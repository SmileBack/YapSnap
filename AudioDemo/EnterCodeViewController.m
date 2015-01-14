//
//  EnterCodeViewController.m
//  YapSnap
//
//  Created by Dan Berenholtz on 9/20/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import "Global.h"
#import "EnterCodeViewController.h"
#import "API.h"

@interface EnterCodeViewController ()

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
    /*
    if ([self.textField.text length] == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Enter code"
                                                        message:@"We sent you a code. Please enter it here to continue."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        
        [alert show];
        return;
    }

    NSString *code = self.textField.text;

    [[API sharedAPI] confirmSessionWithCode:code withCallback:^(BOOL success, NSError *error) {
        if (success) {
            [self performSegueWithIdentifier:@"RecordViewControllerSegue" sender:self];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Try Again"
                                                            message:@"That was the wrong code. Try again."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            
            [alert show];
        }
    }];
     */
    
    [self performSegueWithIdentifier:@"RecordViewControllerSegue" sender:self]; // UNDO - DELETE THIS
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
