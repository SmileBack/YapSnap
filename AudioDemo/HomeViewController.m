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

@interface HomeViewController () <UITextFieldDelegate> {
    NSTimer *countdownTimer;
    int currMinute;
    int currSeconds;
}

@property (nonatomic, strong) IBOutlet UILabel *pageLabel;
@property (nonatomic, strong) NSNumber *unopenedYapsCount;
@property (strong, nonatomic) NSTimer *pulsatingTimer;
@property (strong, nonatomic) WelcomePopupViewController *welcomePopupVC;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *pageLabelConstraint;
@property (strong, nonatomic) IBOutlet UILabel *countdownTimerLabel;
@property IBOutlet UIActivityIndicatorView *activityIndicator;
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
    self.countdownTimerLabel.textColor = THEME_SECONDARY_COLOR;
}

- (void)viewDidAppear:(BOOL)animated {
    if (![YSUser currentUser].hasSessionToken) { // Force log in
        [self performSegueWithIdentifier:@"Login" sender:nil];
    }

    if (countdownTimer) {
        [countdownTimer invalidate];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    if (countdownTimer) {
        [countdownTimer invalidate];
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

    self.countdownTimerLabel.alpha = 0;

    self.topLeftButton.alpha = 1;
    self.yapsPageButton.alpha = 1;
    self.pageLabel.alpha = 1;
}

#pragma mark - Search box stuff
- (void)setupSearchBox {
    self.searchBar.autocapitalizationType = UITextAutocapitalizationTypeWords;
    self.searchBar.textColor = THEME_SECONDARY_COLOR;
    self.searchBar.backgroundColor = THEME_DARK_BLUE_COLOR;
    [self.searchBar setTintColor:THEME_SECONDARY_COLOR];
    self.searchBar.font = [UIFont fontWithName:@"Futura-Medium" size:15];
    self.searchBar.delegate = self;
    [self.searchBar addTarget:self
                       action:@selector(textFieldDidChange:)
             forControlEvents:UIControlEventEditingChanged];
    self.searchBar.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Search YapTap" attributes:@{NSForegroundColorAttributeName : [UIColor colorWithWhite:1.0 alpha:0.35]}];
    self.searchBar.layer.cornerRadius = 1.0f;
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
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    self.searchBar.text = [self.searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    [self.view endEditing:YES];
    if ([self.searchBar.text length] > 0) {
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
    CGRect frame = [self.audioCapture.audioSource.view convertRect:self.audioCapture.audioSource.view.frame toView:self.view];
    self.searchOverlay = [[UIView alloc] initWithFrame:frame];
    self.searchOverlay.backgroundColor = [UIColor colorWithWhite:0.0 alpha:1.0];
    self.searchOverlay.alpha = 0.0;
    [self.searchOverlay addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self.searchBar action:@selector(resignFirstResponder)]];
    [self.view addSubview:self.searchOverlay];
    [UIView animateWithDuration:0.3 animations:^{
        self.searchOverlay.alpha = 0.5;
    }];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [UIView animateWithDuration:0.3 animations:^{
        self.searchOverlay.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self.searchOverlay removeFromSuperview];
        self.searchOverlay = nil;
    }];
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

    [center addObserverForName:AUDIO_CAPTURE_DID_START_NOTIFICATION
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                      NSLog(@"Audio Capture Did Start");
                      [weakSelf showAndStartTimer];
                    }];

    [center addObserverForName:STOP_LOADING_SPINNER_NOTIFICATION
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                      [weakSelf.activityIndicator stopAnimating];
                    }];

    [center addObserverForName:UNTAPPED_RECORD_BUTTON_BEFORE_THRESHOLD_NOTIFICATION
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                      NSLog(@"Home VC received threshold notification");
                      [self showTopButtons];
                      [countdownTimer invalidate];
                      [UIView animateWithDuration:.1
                                            delay:0
                                          options:UIViewAnimationOptionCurveEaseOut
                                       animations:^{
                                         weakSelf.countdownTimerLabel.alpha = 0;
                                       }
                                       completion:nil];
                    }];

    [center addObserverForName:LISTENED_TO_CLIP_NOTIFICATION
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                      [countdownTimer invalidate];
                      [UIView animateWithDuration:.2
                                            delay:0
                                          options:UIViewAnimationOptionCurveEaseOut
                                       animations:^{
                                         weakSelf.countdownTimerLabel.alpha = 0;
                                       }
                                       completion:nil];
                    }];

    [center addObserverForName:DID_START_AUDIO_CAPTURE_NOTIFICATION
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                      [weakSelf hideTopButtons];
                      weakSelf.countdownTimerLabel.alpha = 0;
                    }];

    [center addObserverForName:WILL_START_AUDIO_CAPTURE_NOTIFICATION
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                      weakSelf.countdownTimerLabel.alpha = 0;
                      [weakSelf.activityIndicator startAnimating];
                      [weakSelf hideTopButtons];
                    }];

    [center addObserverForName:COMPLETED_REGISTRATION_NOTIFICATION
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                      if (!weakSelf.didSeeWelcomePopup) {
                          [weakSelf showWelcomePopup];
                      }
                    }];

    [center addObserverForName:RESET_BANNER_UI
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                      [weakSelf showTopButtons];
                      weakSelf.countdownTimerLabel.alpha = 0;
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

- (void)showTopButtons {
    [UIView animateWithDuration:.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                       self.topLeftButton.alpha = 1;
                       self.yapsPageButton.alpha = 1;
                       self.pageLabel.alpha = 1;
                     }
                     completion:nil];
}

- (void)hideTopButtons {
    self.pageLabel.alpha = 0;

    [UIView animateWithDuration:.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                       self.topLeftButton.alpha = 0;
                       self.yapsPageButton.alpha = 0;
                     }
                     completion:nil];
}

- (void)startCountdownTimer {
    NSLog(@"Start Countdown Timer");
    [countdownTimer invalidate];
    countdownTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(countdownTimerFired) userInfo:nil repeats:YES];
}

- (void)countdownTimerFired {
    //NSLog(@"countdownTimer fired");
    //NSLog(@"currMinute: %d; currSeconds: %d", currMinute, currSeconds);
    if ((currMinute > 0 || currSeconds >= 0) && currMinute >= 0) {
        if (currSeconds > 0) {
            //      NSLog(@"currSeconds: %d", currSeconds);
            currSeconds -= 1;
        }

        self.countdownTimerLabel.text = [NSString stringWithFormat:@"%d", currSeconds];
    } else {
        NSLog(@"countdownTimer invalidate");
        [countdownTimer invalidate];
    }
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

- (void)showAndStartTimer {
    self.countdownTimerLabel.alpha = 1;
    self.countdownTimerLabel.text = @"12";
    currSeconds = 12;
    [self startCountdownTimer];
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
        [self performSegueWithIdentifier:@"Friends Segue" sender:nil];
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
        if (sender) { // The presence of a sender means that there was a spotify genre specified
            if (self.replyWithVoice) {
                self.audioCapture.type = AudioCaptureTypeMic;
            } else {
                self.audioCapture.type = AudioCapTureTypeSpotify;
            }

            self.audioCapture.audioCaptureContext = @{
                AudioCaptureContextGenreName : sender
            };
        } else {
            self.audioCapture.type = AudioCaptureTypeMic;
        }
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

@end
