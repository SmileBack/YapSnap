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

@interface HomeViewController () {
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
@property IBOutlet UIActivityIndicatorView* activityIndicator;


@end

@implementation HomeViewController

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
    
    if (IS_IPHONE_4_SIZE) {
        self.pageLabelConstraint.constant = 20;
    } else if (IS_IPHONE_6_SIZE) {
        self.pageLabelConstraint.constant = 80;
    } else if (IS_IPHONE_6_PLUS_SIZE) {
        self.pageLabelConstraint.constant = 100;
    }
}

- (void) setupNotifications {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserverForName:SHOW_FEEDBACK_PAGE
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                        NSLog(@"Show Feedback Page");
                        [self showFeedbackEmailViewControllerWithCompletion:^{
                        }];
                    }];
    
    [center addObserverForName:DISMISS_WELCOME_POPUP
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                        NSLog(@"Dismiss Welcome Popup");
                        [self dismissPopupViewControllerWithanimationType:MJPopupViewAnimationFade];
                    }];
    
    [center addObserverForName:AUDIO_CAPTURE_DID_START_NOTIFICATION
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                        NSLog(@"Audio Capture Did Start");
                        [self showAndStartTimer];
                    }];
    
    [center addObserverForName:STOP_LOADING_SPINNER_NOTIFICATION
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                        [self.activityIndicator stopAnimating];
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
                                             self.countdownTimerLabel.alpha = 0;
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
                                             self.countdownTimerLabel.alpha = 0;
                                         }
                                         completion:nil];
                    }];
    
    [center addObserverForName:DID_START_AUDIO_CAPTURE_NOTIFICATION
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                        [self hideTopButtons];
                        self.countdownTimerLabel.alpha = 0;
                    }];
    
    [center addObserverForName:WILL_START_AUDIO_CAPTURE_NOTIFICATION
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                        self.countdownTimerLabel.alpha = 0;
                        [self.activityIndicator startAnimating];
                        [self hideTopButtons];
                    }];
    
    [center addObserverForName:COMPLETED_REGISTRATION_NOTIFICATION
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                        if (!self.didSeeWelcomePopup) {
                            [self showWelcomePopup];
                        }
                    }];
    
    [center addObserverForName:RESET_BANNER_UI
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                        [self showTopButtons];
                        self.countdownTimerLabel.alpha = 0;
                    }];
    
    __weak HomeViewController *weakSelf = self;
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
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated
{
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

- (void) showTopButtons {
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

- (void) hideTopButtons {
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

- (void)viewDidAppear:(BOOL)animated
{
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

-(void) startCountdownTimer
{
    NSLog(@"Start Countdown Timer");
    [countdownTimer invalidate];
    countdownTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(countdownTimerFired) userInfo:nil repeats:YES];
}

-(void) countdownTimerFired
{
    //NSLog(@"countdownTimer fired");
    //NSLog(@"currMinute: %d; currSeconds: %d", currMinute, currSeconds);
    if((currMinute>0 || currSeconds>=0) && currMinute>=0)
    {
        if(currSeconds>0)
        {
      //      NSLog(@"currSeconds: %d", currSeconds);
            currSeconds-=1;
        }
        
        self.countdownTimerLabel.text = [NSString stringWithFormat:@"%d",currSeconds];
    }
    else
    {
        NSLog(@"countdownTimer invalidate");
        [countdownTimer invalidate];
    }
}

- (void) reloadUnopenedYapsCount
{
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

- (void) showAndStartTimer {
    self.countdownTimerLabel.alpha = 1;
    self.countdownTimerLabel.text = @"12";
    currSeconds=12;
    [self startCountdownTimer];
}

- (BOOL) isInReplyMode
{
    return self.contactReplyingTo != nil;
}

- (void) showWelcomePopup {
    NSLog(@"tapped Welcome Popup");
    double delay = 1;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.welcomePopupVC = [[WelcomePopupViewController alloc] initWithNibName:@"WelcomePopupViewController" bundle:nil];
        [self presentPopupViewController:self.welcomePopupVC animationType:MJPopupViewAnimationSlideTopTop];

        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:DID_SEE_WELCOME_POPUP_KEY];
    });
}

- (void) setupNavBarStuff
{
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

- (void) pulsateYapsButton
{
    CABasicAnimation * animation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    [animation setFromValue:[NSNumber numberWithFloat:1.3]];
    [animation setToValue:[NSNumber numberWithFloat:1]];
    [animation setDuration:.5];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithControlPoints:.1 :1.3 :1 :1]];
    [self.yapsPageButton.layer addAnimation:animation forKey:@"bounceAnimation"];
}

- (void) updateYapsButtonAnimation {
    if (!self.didOpenYapForFirstTime) {
        if (self.pulsatingTimer){
            [self.pulsatingTimer invalidate];
        }
        NSLog(@"Add pulsating animation");
        self.pulsatingTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                               target:self
                                                             selector:@selector(pulsateYapsButton)
                                                             userInfo:nil
                                                              repeats:YES];
    } else {
        if (self.pulsatingTimer){
            [self.pulsatingTimer invalidate];
        }
        [self.yapsPageButton.layer removeAnimationForKey:@"bounceAnimation"];
        NSLog(@"Remove pulsating animation");
    }
}

- (IBAction)leftButtonPressed:(id)sender
{
    if ([self isInReplyMode]) {
        [self.navigationController popViewControllerAnimated:NO];
    } else {
        [self performSegueWithIdentifier:@"Friends Segue" sender:nil];
    }
}

- (IBAction) didTapYapsPageButton
{
    [self performSegueWithIdentifier:@"YapsPageViewControllerSegue" sender:self];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Tapped Yaps Page Button"];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
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
        AudioCaptureViewController* audio = segue.destinationViewController;
        if (sender) { // The presence of a sender means that there was a spotify genre specified

            if (self.replyWithVoice) {
                audio.type = AudioCaptureTypeMic;
            } else {
                audio.type = AudioCapTureTypeSpotify;
            }
            
            audio.audioCaptureContext = @{
                                          AudioCaptureContextGenreName: sender
                                          };
        } else {
            audio.type = AudioCaptureTypeMic;
        }
        audio.contactReplyingTo = self.contactReplyingTo;
    }
}

#pragma mark - Feedback
- (void) showFeedbackEmailViewControllerWithCompletion:(void (^)(void))completion
{
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
                                              otherButtonTitles: nil];
        [alert show];
    }
}

#pragma mark - Mail Delegate
- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [controller dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL) didOpenYapForFirstTime
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:OPENED_YAP_FOR_FIRST_TIME_KEY];
}

- (BOOL) didSeeWelcomePopup
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:DID_SEE_WELCOME_POPUP_KEY];
}

@end
