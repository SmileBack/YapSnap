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

@interface HomeViewController ()

@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *doubleTapLabel;
@property (nonatomic, strong) NSNumber *unopenedYapsCount;
@property (strong, nonatomic) NSTimer *pulsatingTimer;
@property (strong, nonatomic) WelcomePopupViewController *welcomePopupVC;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *doubleTapConstraint;
@property (nonatomic, strong) IBOutlet UIImageView *cartoonsImage;


- (IBAction)didTapMegaphoneButton;

@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Viewed Home Page"];
    
    if (!self.didSeeWelcomePopup) {
        [self showWelcomePopup];
    }
    
    self.view.backgroundColor = THEME_BACKGROUND_COLOR;
    
    self.navigationController.navigationBar.barTintColor = THEME_BACKGROUND_COLOR;
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@""
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:nil
                                                                            action:nil];
    [self setupNotifications];
        
    [self setupNavBarStuff];
    [self styleButtons];
    
    if (IS_IPHONE_4_SIZE) {
        self.doubleTapConstraint.constant = 20;
    } else if (IS_IPHONE_6_SIZE) {
        self.doubleTapConstraint.constant = 80;
    } else if (IS_IPHONE_6_PLUS_SIZE) {
        self.doubleTapConstraint.constant = 100;
    }
    
    if (IS_IPHONE_6_SIZE) {
        self.cartoonsImage.image = [UIImage imageNamed:@"CartooniPhone6.png"];
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
                                                      // HACKKKKKKKKKKK
                                                      // This goes through all the view controllers in the stack, finds the first HomeViewController,
                                                      // then pops to it.
                                                      UIViewController* vcToPopTo = nil;
                                                      for (UIViewController* vc in self.navigationController.viewControllers) {
                                                          if ([vc isKindOfClass:[HomeViewController class]]) {
                                                              vcToPopTo = vc;
                                                              break;
                                                          }
                                                      }
                                                      if (vcToPopTo) {
                                                          [self.navigationController popToViewController:vcToPopTo animated:NO];
                                                      }
                                                  }];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:DID_DISMISS_AFTER_SENDING_YAP object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationItem.backBarButtonItem.tintColor = UIColor.whiteColor;
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    
    //Nav bar should not be transparent after finishing registration process
    self.navigationController.navigationBar.translucent = NO;
    [self reloadUnopenedYapsCount];
    [self updateYapsButtonAnimation];
}

- (void) styleButtons {
    self.micButton.layer.cornerRadius = 65;
    self.micButton.layer.borderWidth = 1;
    self.micButton.layer.borderColor = [UIColor whiteColor].CGColor;
    
    self.musicButton.layer.cornerRadius = 65;
    self.musicButton.layer.borderWidth = 1;
    self.musicButton.layer.borderColor = [UIColor whiteColor].CGColor;
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

- (BOOL) isInReplyMode
{
    return self.contactReplyingTo != nil;
}

- (void) showWelcomePopup {
    NSLog(@"tapped Welcome Popup");
    double delay = .5;
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
        UIImage *buttonImage = [UIImage imageNamed:@"WhiteBackArrow5.png"];
        [self.topLeftButton setImage:buttonImage forState:UIControlStateNormal];
        self.topLeftButton.alpha = 1;
        
        self.doubleTapLabel.hidden = NO;
        self.doubleTapLabel.text = [NSString stringWithFormat:@"For: %@", self.contactReplyingTo.name];
        
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
        [self.navigationController popViewControllerAnimated:YES];
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

#pragma mark - Mic and Music Buttons

- (IBAction)didTapMegaphoneButton {
    [self performSegueWithIdentifier:@"Audio Record" sender:nil];
}

- (IBAction)didTapMusicButton {
    [self tappedSpotifyButton:@"Search"];
}

- (void) tappedSpotifyButton:(NSString *)type
{
    [self performSegueWithIdentifier:@"Audio Record" sender:type];
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
        UINavigationController *navVC = segue.destinationViewController;
        AudioCaptureViewController* audio = navVC.topViewController;
        if (sender) { // The presence of a sender means that there was a spotify genre specified
            audio.type = AudioCapTureTypeSpotify;
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
