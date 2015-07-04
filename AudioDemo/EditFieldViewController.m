//
//  EditFieldViewController.m
//  YapSnap
//
//  Created by Jon Deokule on 1/31/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "EditFieldViewController.h"
#import "SettingsViewController.h"
#import "YSUser.h"
#import "API.h"

@interface EditFieldViewController ()
@property (strong, nonatomic) IBOutlet UITextField *textField;
@end

@implementation EditFieldViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor]; //[UIColor colorWithRed:240.0f/255.0f green:245.0f/255.0f blue:250.0f/255.0f alpha:1.0];

    YSUser *user = [YSUser currentUser];
    NSString *text;

    if ([FIRST_NAME_SECTION isEqualToString:self.editingField]) {
        text = user.displayFirstName;
    } else if ([LAST_NAME_SECTION isEqualToString:self.editingField]) {
        text = user.displayLastName;
    } else if ([EMAIL_SECTION isEqualToString:self.editingField]) {
        text = user.displayEmail;
    }

    self.textField.text = text;
    
    double delay = 0.7;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.textField becomeFirstResponder];
    });
    
    self.navigationItem.title = [NSString stringWithFormat:@"%@", self.editingField];
    
    self.textField.layer.masksToBounds=YES;
    self.textField.layer.borderColor=[[UIColor grayColor]CGColor];
    self.textField.layer.borderWidth= 1.0f;
}

- (void) viewWillDisappear:(BOOL)animated
{
    self.textField.text = [self.textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    NSLog(@"About to disappear!");
    UIViewController *vc = [self.navigationController.viewControllers lastObject];
    if ([vc isKindOfClass:[SettingsViewController class]]) {
        if ([EMAIL_SECTION isEqualToString:self.editingField]) {
                if (![self NSStringIsValidEmail:self.textField.text]) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Email didn't save"
                                                                message:@"You didn't enter a valid email."
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
            } else {
                SettingsViewController *settingsVC = (SettingsViewController *)vc;
                [settingsVC saveField:self.editingField withText:self.textField.text];
                Mixpanel *mixpanel = [Mixpanel sharedInstance];
                [mixpanel track:@"Edited Email"];
            }
        } else if ([FIRST_NAME_SECTION isEqualToString:self.editingField]) {
            if ([self.textField.text length] < 2) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Name didn't save"
                                                                message:@"You didn't enter a valid name."
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
            } else {
                SettingsViewController *settingsVC = (SettingsViewController *)vc;
                [settingsVC saveField:self.editingField withText:self.textField.text];
                Mixpanel *mixpanel = [Mixpanel sharedInstance];
                [mixpanel track:@"Edited First Name"];
            }
        } else if ([LAST_NAME_SECTION isEqualToString:self.editingField]) {
            if ([self.textField.text length] < 1) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Name didn't save"
                                                                message:@"You didn't enter a valid name."
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
            } else {
                SettingsViewController *settingsVC = (SettingsViewController *)vc;
                [settingsVC saveField:self.editingField withText:self.textField.text];
                Mixpanel *mixpanel = [Mixpanel sharedInstance];
                [mixpanel track:@"Edited Last Name"];
            }
        }
    }

    [super viewWillDisappear:animated];
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
