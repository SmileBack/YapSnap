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
#import "YapsCache.h"

#define LOGOUT @"logout"
#define CLEAR_YAPS @"clear_yaps"
#define DOWNLOAD_SPOTIFY @"download_spotify"
#define CLEARED_YAPS_NOTIFICATION @"com.yaptap.ClearedYapsNotification"

@interface SettingsViewController ()
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray *sections;
@property (nonatomic, strong) NSString *alertViewString;

@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Viewed Settings Page"];
    
    self.navigationController.navigationBar.barTintColor = THEME_BACKGROUND_COLOR;
    
    CGRect frame = CGRectMake(0, 0, 160, 44);
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont fontWithName:@"Futura-Medium" size:18];
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = @"Settings";
    self.navigationItem.titleView = label;
    
    [self.navigationController.navigationBar
     setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];
    
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Save"
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:nil
                                                                            action:nil];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    __weak SettingsViewController *weakSelf = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:NOTIFICATION_LOGOUT
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      [weakSelf dismissViewControllerAnimated:YES completion:nil];
                                                  }];

    self.automaticallyAdjustsScrollViewInsets = NO;
    
    [self addCancelButton];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.navigationController setNavigationBarHidden:NO];
    [self.tableView reloadData];
}

- (void) addCancelButton {
    UIImage* cancelModalImage = [UIImage imageNamed:@"WhiteDownArrow2.png"];
    UIButton *cancelModalButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
    [cancelModalButton setBackgroundImage:cancelModalImage forState:UIControlStateNormal];
    [cancelModalButton addTarget:self action:@selector(cancelPressed)
                forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *cancelButton =[[UIBarButtonItem alloc] initWithCustomView:cancelModalButton];
    [self.navigationItem setLeftBarButtonItem:cancelButton];
}

- (void) cancelPressed
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSArray *) sections
{
    if (!_sections) {
        _sections = @[FIRST_NAME_SECTION, LAST_NAME_SECTION, EMAIL_SECTION, PHONE_NUMBER_SECTION, CLEAR_YAPS_SECTION, FEEDBACK_SECTION, DOWNLOAD_SPOTIFY_SECTION, LOGOUT_SECTION];
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
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Logout"
                                    message:@"Are you sure you want to logout?"
                                   delegate:self
                          cancelButtonTitle:@"No"
                          otherButtonTitles:@"Yes", nil];
        self.alertViewString = LOGOUT;
        [alert show];
    } else if ([PHONE_NUMBER_SECTION isEqualToString:section]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Phone Number"
                                                        message:@"You cannot edit your number. If you have a new number, create a new account with that number."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel track:@"Tapped Phone Number"];
    } else if ([FEEDBACK_SECTION isEqualToString:section]) {
        [self showFeedbackEmailViewControllerWithCompletion:^{
        }];
    } else if ([CLEAR_YAPS_SECTION isEqualToString:section]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Clear All Yaps"
                                                        message:@"Are you sure you want to clear all of your sent and received yaps? This will also clear your 'Recent' tab."
                                                       delegate:self
                                              cancelButtonTitle:@"No"
                                              otherButtonTitles:@"Yes", nil];
        self.alertViewString = CLEAR_YAPS;
        [alert show];
    } else if ([DOWNLOAD_SPOTIFY_SECTION isEqualToString:section]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Download Spotify"
                                                        message:@"We link song snippets to full songs on Spotify!"
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Download", nil];
        self.alertViewString = DOWNLOAD_SPOTIFY;
        [alert show];
    }
}

#pragma mark - UIAlertViewDelegate
- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([LOGOUT isEqualToString:self.alertViewString]) {
        if (buttonIndex == 1) {
            [[API sharedAPI] logout:^(BOOL success, NSError *error) {
                Mixpanel *mixpanel = [Mixpanel sharedInstance];
                [mixpanel track:@"Logged Out"];
            }];
        }
    } else if ([CLEAR_YAPS isEqualToString:self.alertViewString]) {
        if (buttonIndex == 1) {
            [[API sharedAPI] clearYaps:^(BOOL success, NSError *error) {
                if (success) {
                    NSLog(@"Cleared yaps successfully");
                    [[YapsCache sharedCache] loadYapsWithCallback:nil];
                    [[NSNotificationCenter defaultCenter] postNotificationName:CLEARED_YAPS_NOTIFICATION object:nil];
                    
                    double delay = .1;
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [[YTNotifications sharedNotifications] showNotificationText:@"Yaps Cleared!"];
                    });

                    Mixpanel *mixpanel = [Mixpanel sharedInstance];
                    [mixpanel track:@"Cleared Yaps"];
                } else {
                    NSLog(@"Error clearing yaps: %@", error);
                    double delay = .2;
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [[YTNotifications sharedNotifications] showNotificationText:@"Oops, Error Clearing Yaps!"];
                    });
                }
                
            }];
        }
    } else if ([DOWNLOAD_SPOTIFY isEqualToString:self.alertViewString]) {
        if (buttonIndex == 1) {
            NSString *iTunesLink = @"itms-apps://itunes.apple.com/app/id324684580";
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:iTunesLink]];
        }
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
            double delay = .5;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[YTNotifications sharedNotifications] showNotificationText:@"Oops, Info Didn't Save!"];
            });
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
