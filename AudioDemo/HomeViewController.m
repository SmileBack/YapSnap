//
//  HomeViewController.m
//  YapTap
//
//  Created by Dan B on 5/7/15.
//

#import "HomeViewController.h"
#import "WelcomePopupViewController.h"
#import "FriendsViewController.h"
#import "YapsViewController.h"
#import "API.h"
#import "UIViewController+MJPopupViewController.h"
#import "AudioCaptureViewController.h"
#import "YSPushManager.h"
#import "YSSegmentedControl.h"

@interface HomeViewController () <UITextFieldDelegate, UINavigationControllerDelegate>

@property (nonatomic, strong) IBOutlet UILabel *pageLabel;
@property (nonatomic, strong) NSNumber *unopenedYapsCount;
@property (strong, nonatomic) NSTimer *pulsatingTimer;
@property (strong, nonatomic) WelcomePopupViewController *welcomePopupVC;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *pageLabelConstraint;
@property (weak, nonatomic) IBOutlet UITextField *searchBar;
@property (strong, nonatomic) IBOutlet UIButton *resetButton;
@property (weak, nonatomic) IBOutlet UIImageView *magnifyingGlassImageView;
@property (weak, nonatomic) AudioCaptureViewController *audioCapture;
@property (strong, nonatomic) UIView *searchOverlay;
@property (weak, nonatomic) IBOutlet UIView *container;

@end

@implementation HomeViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Viewed Home Page"];

    self.view.backgroundColor = THEME_BACKGROUND_COLOR;

    self.navigationController.navigationBar.barTintColor = THEME_BACKGROUND_COLOR;

    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@""
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:nil
                                                                            action:nil];
    [self setupNotifications];
    [self setupSearchBox];
    if (IS_IPHONE_4_SIZE) {
        self.pageLabelConstraint.constant = 20;
    } else if (IS_IPHONE_6_SIZE) {
        self.pageLabelConstraint.constant = 80;
    } else if (IS_IPHONE_6_PLUS_SIZE) {
        self.pageLabelConstraint.constant = 100;
    }

    self.resetButton.alpha = 0;
    self.pageLabel.textColor = THEME_SECONDARY_COLOR;
}

- (void)viewDidAppear:(BOOL)animated {
    if (![YSUser currentUser].hasSessionToken) { // Force log in
        [self performSegueWithIdentifier:@"Login" sender:nil];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationItem.backBarButtonItem.tintColor = UIColor.whiteColor;
    [self.navigationController setNavigationBarHidden:YES animated:animated];

    //Nav bar should not be transparent after finishing registration process
    self.navigationController.navigationBar.translucent = NO;

    [self setupNavBarStuff];

    [self reloadUnopenedYapsCount];
    [self updateYapsButtonAnimation];

    self.topLeftButton.alpha = 1;
    self.yapsPageButton.alpha = 1;
    self.pageLabel.alpha = 1;
}

#pragma mark - Search box stuff
- (void)setupSearchBox {
    self.searchBar.autocapitalizationType = UITextAutocapitalizationTypeWords;
    self.searchBar.textColor = THEME_SECONDARY_COLOR;
    self.searchBar.backgroundColor = [UIColor colorWithRed:1/255.0 green:160.0/255.0 blue:230.0/255.0 alpha:1.0f];//THEME_BACKGROUND_COLOR;
    [self.searchBar setTintColor:THEME_SECONDARY_COLOR];
    self.searchBar.font = [UIFont fontWithName:@"Futura-Medium" size:15];
    self.searchBar.delegate = self;
    [self.searchBar addTarget:self
                       action:@selector(textFieldDidChange:)
             forControlEvents:UIControlEventEditingChanged];
    self.searchBar.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Search YapTap" attributes:@{NSForegroundColorAttributeName : [UIColor colorWithWhite:1.0 alpha:0.75]}];
    self.searchBar.layer.cornerRadius = 4.0f;
    self.searchBar.layer.masksToBounds = YES;
    self.searchBar.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.7].CGColor;
    self.searchBar.layer.borderWidth = 1.0f;
}

- (void)updateVisibilityOfMagnifyingGlassAndResetButtons {
    CGSize stringsize = [[NSString stringWithFormat:@"%@", self.searchBar.text] sizeWithAttributes:@{ NSFontAttributeName : [UIFont fontWithName:@"Futura-Medium" size:18] }];
    CGFloat maxStringSizeWidth = 170;
    if (IS_IPHONE_6_SIZE) {
        maxStringSizeWidth = 220;
    } else if (IS_IPHONE_6_PLUS_SIZE) {
        maxStringSizeWidth = 260;
    }

    if (stringsize.width > maxStringSizeWidth) {
        self.resetButton.alpha = 0;
        self.magnifyingGlassImageView.hidden = YES;
    } else {
        [UIView animateWithDuration:.3
                              delay:0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                           self.resetButton.alpha = 0.9;
                         }
                         completion:nil];
        self.magnifyingGlassImageView.hidden = NO;
    }
    
    if ([self.searchBar.text length] == 0) {
        self.resetButton.alpha = 0;
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    self.searchBar.text = [self.searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    [self.view endEditing:YES];
    if ([self.searchBar.text length] > 0) {
        [self.navigationController popToRootViewControllerAnimated:NO];
        [self navigationController:self.navigationController willShowViewController:self animated:NO]; // Refreshes back button
        
        [self.audioCapture searchWithText:textField.text];
        [[API sharedAPI] sendSearchTerm:textField.text
                           withCallback:^(BOOL success, NSError *error){
                           }];
    } else {
        [self.audioCapture clearSearchResults];
    }
    return YES;
}

- (void)textFieldDidChange:(UITextField *)searchBox {
    if ([self.searchBar.text length] == 0) {
        NSLog(@"Empty String");
        self.resetButton.alpha = 0;
    } else {
        [self updateVisibilityOfMagnifyingGlassAndResetButtons];
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if ([self.audioCapture.audioSource isKindOfClass:[UIViewController class]]) {
        UIViewController *vc = (UIViewController *)self.audioCapture.audioSource;
        [[NSNotificationCenter defaultCenter] postNotificationName:CANCEL_AUDIO_PLAYBACK object:nil];
        CGRect frame = [vc.view convertRect:vc.view.frame toView:self.view];
        self.searchOverlay = [[UIView alloc] initWithFrame:frame];
        self.searchOverlay.backgroundColor = [UIColor colorWithWhite:0.0 alpha:1.0];
        self.searchOverlay.alpha = 0.0;
        [self.searchOverlay addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cancelSearch)]];
        [self.view addSubview:self.searchOverlay];
        [UIView animateWithDuration:0.3 animations:^{
            self.searchOverlay.alpha = 0.75;
        }];
        self.audioCapture.categorySelectorView.isInactive = YES;
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    self.audioCapture.categorySelectorView.isInactive = textField.text.length != 0;
    [UIView animateWithDuration:0.3 animations:^{
        self.searchOverlay.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self.searchOverlay removeFromSuperview];
        self.searchOverlay = nil;
    }];
    [self updateVisibilityOfMagnifyingGlassAndResetButtons];
}

- (void)cancelSearch {
    self.searchBar.text = nil;
    [self.searchBar resignFirstResponder];
}

#pragma mark - Other

- (IBAction)didTapResetButton {
    double delay = .1;
    self.searchBar.text = nil;
    [self.audioCapture clearSearchResults];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      [self.searchBar becomeFirstResponder];
    });
}

- (void)setupNotifications {
    __weak HomeViewController *weakSelf = self;

    [[NSNotificationCenter defaultCenter] addObserverForName:CHANGE_CATEGORY_NOTIFICATION object:nil queue:[NSOperationQueue currentQueue] usingBlock:^(NSNotification *note) {
        weakSelf.searchBar.text = nil;
        [weakSelf textFieldDidChange:self.searchBar];
        [weakSelf.searchBar resignFirstResponder];
        [self.topLeftButton setImage:[UIImage imageNamed:@"SettingsIconWhite8"] forState:UIControlStateNormal];
    }];
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserverForName:SHOW_FEEDBACK_PAGE
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                      NSLog(@"Show Feedback Page");
                      [weakSelf showFeedbackEmailViewControllerWithCompletion:^{
                      }];
                    }];

    [center addObserverForName:DISMISS_WELCOME_POPUP
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                      NSLog(@"Dismiss Welcome Popup");
                      [weakSelf dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
                    }];

    [center addObserverForName:COMPLETED_REGISTRATION_NOTIFICATION
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                      if (!weakSelf.didSeeWelcomePopup) {
                          //[weakSelf showWelcomePopup];
                      }
                    }];

    [center addObserverForName:UIApplicationDidBecomeActiveNotification
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                      [weakSelf reloadUnopenedYapsCount];
                    }];

    [[NSNotificationCenter defaultCenter] addObserverForName:DID_DISMISS_AFTER_SENDING_YAP
                                                      object:nil
                                                       queue:[NSOperationQueue currentQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                    [weakSelf.navigationController popToRootViewControllerAnimated:YES];
                                                  }];

    [[NSNotificationCenter defaultCenter] addObserverForName:NEW_FRIEND_NOTIFICATION
                                                      object:nil
                                                       queue:[NSOperationQueue currentQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                    if (weakSelf.navigationController.topViewController == weakSelf) {
                                                        [weakSelf performSegueWithIdentifier:@"Friends Segue" sender:nil];
                                                    }
                                                  }];
    [[NSNotificationCenter defaultCenter] addObserverForName:NEW_YAP_NOTIFICATION
                                                      object:nil
                                                       queue:[NSOperationQueue currentQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                    if (weakSelf.navigationController.topViewController == weakSelf) {
                                                        [weakSelf performSegueWithIdentifier:@"YapsPageViewControllerSegue" sender:nil];
                                                    }
                                                  }];

    [[NSNotificationCenter defaultCenter] addObserverForName:RELOAD_YAPS_COUNT_NOTIFICATION
                                                      object:nil
                                                       queue:[NSOperationQueue currentQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                    [weakSelf reloadUnopenedYapsCount];
                                                  }];
}

- (void)reloadUnopenedYapsCount {
    [[API sharedAPI] unopenedYapsCountWithCallback:^(NSNumber *count, NSError *error) {
      if (error) {
          [self.yapsPageButton setTitle:@"" forState:UIControlStateNormal];
      } else if (count.description.intValue == 0) {
          NSLog(@"0 Yaps");
          UIImage *buttonImage = [UIImage imageNamed:@"YapsButtonNoYaps.png"];
          [self.yapsPageButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
          [self.yapsPageButton setBackgroundImage:buttonImage forState:UIControlStateHighlighted];
          // Remove number from button
          [self.yapsPageButton setTitle:@"" forState:UIControlStateNormal];
      } else {
          UIImage *buttonImage = [UIImage imageNamed:@"YapsButton100.png"];
          [self.yapsPageButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
          [self.yapsPageButton setBackgroundImage:buttonImage forState:UIControlStateHighlighted];

          // Add number to button
          [self.yapsPageButton setTitle:count.description forState:UIControlStateNormal];
          self.unopenedYapsCount = count;
      }
    }];
}

- (BOOL)isInReplyMode {
    return self.contactReplyingTo != nil;
}

- (void)showWelcomePopup {
    NSLog(@"tapped Welcome Popup");
    double delay = 1;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      self.welcomePopupVC = [[WelcomePopupViewController alloc] initWithNibName:@"WelcomePopupViewController" bundle:nil];
      [self presentPopupViewController:self.welcomePopupVC animationType:MJPopupViewAnimationSlideTopTop];

      [[NSUserDefaults standardUserDefaults] setBool:YES forKey:DID_SEE_WELCOME_POPUP_KEY];
    });
}

- (void)setupNavBarStuff {
    if ([self isInReplyMode]) {
        self.yapsPageButton.hidden = YES;
        UIImage *buttonImage = [UIImage imageNamed:@"CancelImageWhite2.png"];
        [self.topLeftButton setImage:buttonImage forState:UIControlStateNormal];
        self.topLeftButton.alpha = 1;

        //self.pageLabel.alpha = 1;
        NSString *contactReplyingToFirstName = [[self.contactReplyingTo.name componentsSeparatedByString:@" "] objectAtIndex:0];
        if ([self.contactReplyingTo.phoneNumber isEqualToString:@"+13245678910"] || [self.contactReplyingTo.phoneNumber isEqualToString:@"+13027865701"]) {
            self.pageLabel.text = @"Reply to YapTap Team";
        } else {
            self.pageLabel.text = [NSString stringWithFormat:@"Reply to %@", contactReplyingToFirstName];
        }

        NSLog(@"In reply mode");
    } else {
        NSLog(@"Not in reply mode");
    }
}

- (void)pulsateYapsButton {
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    [animation setFromValue:[NSNumber numberWithFloat:1.3]];
    [animation setToValue:[NSNumber numberWithFloat:1]];
    [animation setDuration:.5];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithControlPoints:.1:1.3:1:1]];
    [self.yapsPageButton.layer addAnimation:animation forKey:@"bounceAnimation"];
}

- (void)updateYapsButtonAnimation {
    if (!self.didOpenYapForFirstTime) {
        if (self.pulsatingTimer) {
            [self.pulsatingTimer invalidate];
        }
        NSLog(@"Add pulsating animation");
        self.pulsatingTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                               target:self
                                                             selector:@selector(pulsateYapsButton)
                                                             userInfo:nil
                                                              repeats:YES];
    } else {
        if (self.pulsatingTimer) {
            [self.pulsatingTimer invalidate];
        }
        [self.yapsPageButton.layer removeAnimationForKey:@"bounceAnimation"];
        NSLog(@"Remove pulsating animation");
    }
}

- (IBAction)leftButtonPressed:(id)sender {
    if ([self isInReplyMode]) {
        [self.navigationController popViewControllerAnimated:NO];
    } else {
        //[self performSegueWithIdentifier:@"Friends Segue" sender:nil];
        [self performSegueWithIdentifier:@"Settings Segue" sender:nil];
    }
}

- (IBAction)didTapYapsPageButton {
    [self performSegueWithIdentifier:@"YapsPageViewControllerSegue" sender:self];

    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Tapped Yaps Page Button"];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([@"YapsPageViewControllerSegue" isEqualToString:segue.identifier]) {
        YapsViewController *yapsVC = segue.destinationViewController;
        yapsVC.unopenedYapsCount = self.unopenedYapsCount;
    } else if ([@"Friends Segue" isEqualToString:segue.identifier]) {
        UINavigationController *navVC = segue.destinationViewController;
        FriendsViewController *vc = navVC.viewControllers[0];
        vc.yapsSentCallback = ^() {
          [self performSegueWithIdentifier:@"YapsPageViewControllerSegue" sender:nil];
        };
    } else if ([@"Audio Record" isEqualToString:segue.identifier]) {
        self.audioCapture = segue.destinationViewController;
        self.audioCapture.contactReplyingTo = self.contactReplyingTo;
    }
}

- (BOOL)didOpenYapForFirstTime {
    return [[NSUserDefaults standardUserDefaults] boolForKey:OPENED_YAP_FOR_FIRST_TIME_KEY];
}

- (BOOL)didSeeWelcomePopup {
    return [[NSUserDefaults standardUserDefaults] boolForKey:DID_SEE_WELCOME_POPUP_KEY];
}

#pragma mark - Feedback
- (void)showFeedbackEmailViewControllerWithCompletion:(void (^)(void))completion {
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
        mailer.mailComposeDelegate = self;
        [mailer setSubject:@"Feedback"];
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
                                              otherButtonTitles:nil];
        [alert show];
    }
}

#pragma mark - Mail Delegate
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [controller dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController
      willShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated {
    BOOL back = navigationController.viewControllers.count > 1;
    [self.topLeftButton setImage:back ? [UIImage imageNamed:@"back"] : [UIImage imageNamed:@"SettingsIconWhite8"] forState:UIControlStateNormal];
    [self.topLeftButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    if (back) {
        [self.topLeftButton addTarget:navigationController action:@selector(popViewControllerAnimated:) forControlEvents:UIControlEventTouchUpInside];
    } else {
        [self.topLeftButton addTarget:self action:@selector(leftButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
}

@end
