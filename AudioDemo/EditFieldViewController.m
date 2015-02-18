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
}

#pragma mark - Buttons
- (IBAction)cancelPressed:(UIBarButtonItem *)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)savePressed:(UIBarButtonItem *)sender
{
    // TODO CHECK IF EMPTY AND SHOW ALERT VIEW
    // TODO SHOW A HUD WHILE SAVING
    
    SuccessOrErrorCallback callback = ^(BOOL success, NSError *error) {
        if (success) {
            [self.navigationController popViewControllerAnimated:YES];
        } else {
            NSLog(@"Error: %@", error);
            // TODO do something
        }
    };

    if ([FIRST_NAME_SECTION isEqualToString:self.editingField]) {
        [[API sharedAPI] updateFirstName:self.textField.text withCallBack:callback];
    } else if ([LAST_NAME_SECTION isEqualToString:self.editingField]) {
        [[API sharedAPI] updateLastName:self.textField.text withCallBack:callback];
    } else if ([EMAIL_SECTION isEqualToString:self.editingField]) {
        [[API sharedAPI] updateEmail:self.textField.text withCallBack:callback];
    }

}



@end