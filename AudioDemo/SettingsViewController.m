//
//  SettingsViewController.m
//  YapSnap
//
//  Created by Jon Deokule on 1/31/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "SettingsViewController.h"
#import "YSUser.h"
#import "EditFieldViewController.h"
#import "API.h"

@interface SettingsViewController ()
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray *sections;
@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.navigationController.navigationBar.barTintColor = THEME_BACKGROUND_COLOR;
    
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    __weak SettingsViewController *weakSelf = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:NOTIFICATION_LOGOUT
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      [weakSelf.navigationController dismissViewControllerAnimated:YES completion:nil];
                                                  }];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.tableView reloadData];
}

- (NSArray *) sections
{
    if (!_sections) {
        _sections = @[FIRST_NAME_SECTION, LAST_NAME_SECTION, EMAIL_SECTION, PHONE_NUMBER_SECTION, FEEDBACK_SECTION, LOGOUT_SECTION];
    }
    return _sections;
}

#pragma mark - TableView Data Source

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.sections.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"Cell"];

    NSString *section = self.sections[indexPath.row];
    cell.textLabel.text = section;
    
    YSUser *user = [YSUser currentUser];

    if ([section isEqualToString:FIRST_NAME_SECTION]) {
        cell.detailTextLabel.text = user.displayFirstName;
    } else if ([section isEqualToString:LAST_NAME_SECTION]) {
        cell.detailTextLabel.text = user.displayLastName;
    } else if ([section isEqualToString:EMAIL_SECTION]) {
        cell.detailTextLabel.text = user.displayEmail;
    } else if ([section isEqualToString:PHONE_NUMBER_SECTION]) {
        cell.detailTextLabel.text = user.phone;
    } else {
        cell.detailTextLabel.text = nil;
    }

    return cell;
}

#pragma mark - TableView Delegate
- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *section = self.sections[indexPath.row];
    if (indexPath.row <= 2) { // First, Last, or Email
        [self performSegueWithIdentifier:@"Edit Field Segue" sender:section];
    } else if ([LOGOUT_SECTION isEqualToString:section]) {
        [[[UIAlertView alloc] initWithTitle:@"Logout"
                                    message:@"Are you sure?"
                                   delegate:self
                          cancelButtonTitle:@"No"
                          otherButtonTitles:@"Yes", nil] show];
    } else if ([PHONE_NUMBER_SECTION isEqualToString:section]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Phone Number"
                                                        message:@"You cannot edit your number. If you have a new number, create a new account with that number."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    } else if ([FEEDBACK_SECTION isEqualToString:section]) {
        [self showFeedbackEmailViewControllerWithCompletion:^{
        }];
    }
}

#pragma mark - UIAlertViewDelegate
- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        [[API sharedAPI] logout:^(BOOL success, NSError *error) {
            [self dismissViewControllerAnimated:YES completion:nil];
        }];
    }
}

#pragma mark - Field Saving
- (void) saveField:(NSString *)field withText:(NSString *)text
{
    __weak SettingsViewController *weakSelf = self;
    SuccessOrErrorCallback callback = ^(BOOL success, NSError *error) {
        if (success) {
            NSInteger row = [weakSelf.sections indexOfObject:field];
            NSIndexPath *path = [NSIndexPath indexPathForRow:row inSection:0];
            [weakSelf.tableView reloadRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationAutomatic];
        } else {
            NSLog(@"Error: %@", error);
            // TODO do something
        }
    };
    
    // TODO VALIDATE THE INPUT
    
    if ([FIRST_NAME_SECTION isEqualToString:field]) {
        [[API sharedAPI] updateFirstName:text withCallBack:callback];
    } else if ([LAST_NAME_SECTION isEqualToString:field]) {
        [[API sharedAPI] updateLastName:text withCallBack:callback];
    } else if ([EMAIL_SECTION isEqualToString:field]) {
        [[API sharedAPI] updateEmail:text withCallBack:callback];
    }
}

#pragma mark - Navigation
- (IBAction)didPressDone:(UIBarButtonItem *)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([@"Edit Field Segue" isEqualToString:segue.identifier]) {
        EditFieldViewController *vc = segue.destinationViewController;
        vc.editingField = sender;
    }
}

#pragma mark - Mail Delegate
- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [controller dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Feedback
- (void) showFeedbackEmailViewControllerWithCompletion:(void (^)(void))completion
{
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
        mailer.mailComposeDelegate = self;
        [mailer setSubject:@"My Feedback"];
        NSArray *toRecipients = [NSArray arrayWithObjects:@"team@yaptapapp.com", nil];
        [mailer setToRecipients:toRecipients];
        NSString *emailBody = @"";
        [mailer setMessageBody:emailBody isHTML:NO];
        [self presentViewController:mailer animated:YES completion:completion];
        [mailer becomeFirstResponder];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Email didn't send"
                                                        message:@"You don't have your e-mail setup. Please contact us at team@yaptapapp.com."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles: nil];
        [alert show];
    }
}


@end
