//
//  AudioCaptureViewController.m
//  AudioDemo
//
//  Created by Simon on 24/2/13.
//  Copyright (c) 2013 Appcoda. All rights reserved.
//

#import "AudioCaptureViewController.h"
#import "AddTextViewController.h"
#import "YSSpotifySourceController.h"
#import "YSMicSourceController.h"
#import "API.h"
#import "YapBuilder.h"
#import "YapsViewController.h"
#import "AppDelegate.h"
#import "UIViewController+MJPopupViewController.h"
#import "WelcomePopupViewController.h"
#import "FriendsViewController.h"

#define CONTROL_CENTER_HEIGHT 503.0f

@interface AudioCaptureViewController () {
    NSTimer *timer;
}
@property (strong, nonatomic) IBOutlet UIView *audioSourceContainer;
@property (nonatomic) float elapsedTime;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *bottomConstraint;
@property (nonatomic, strong) NSNumber *unopenedYapsCount;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) NSTimer *pulsatingTimer;
@property (strong, nonatomic) WelcomePopupViewController *welcomePopupVC;
@property (nonatomic, strong) IBOutlet UIView *controlCenterView;
@property (nonatomic, strong) IBOutlet UIView *controlCenterMusicHeaderView;
@property (nonatomic, strong) IBOutlet UIButton *openControlCenterButton;

@property (assign, nonatomic) BOOL controlCenterIsVisible;



- (IBAction)didTapOpenControlCenterButton;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *controlCenterBottomConstraint;

@end

@implementation AudioCaptureViewController

static const float MAX_CAPTURE_TIME = 12.0;
static const float TIMER_INTERVAL = .01;

- (void)viewDidLoad
{
    [super viewDidLoad];
        
    self.view.backgroundColor = THEME_BACKGROUND_COLOR;
    
    self.navigationController.navigationBar.barTintColor = THEME_BACKGROUND_COLOR;

    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@""
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:nil
                                                                            action:nil];

    [self.recordButton setBackgroundImage:[UIImage imageNamed:@"RecordButtonBlueBorder10Pressed.png"] forState:UIControlStateHighlighted];
    self.recordProgressView.progress = 0;
    
    if (!self.didSeeWelcomePopup) {
        [self showWelcomePopup];
    }

    YSSpotifySourceController *spotifySource = [self.storyboard instantiateViewControllerWithIdentifier:@"SpotifySourceController"];
    [self addChildViewController:spotifySource];
    spotifySource.view.frame = self.audioSourceContainer.bounds;
    [self.audioSourceContainer addSubview:spotifySource.view];
    self.audioSource = spotifySource;
    
    [self setupNotifications];
    
    [self setupNavBarStuff];
    
    [self setupControlCenter];
    //[self.playButton setEnabled:YES];
}

- (void) showWelcomePopup {
    NSLog(@"tapped Welcome Popup");
    double delay = 1;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.welcomePopupVC = [[WelcomePopupViewController alloc] initWithNibName:@"WelcomePopupViewController" bundle:nil];
        [self presentPopupViewController:self.welcomePopupVC animationType:MJPopupViewAnimationSlideTopTop];
        
        UITapGestureRecognizer *tappedWelcomePopup = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedWelcomePopup)];
        [self.welcomePopupVC.view addGestureRecognizer:tappedWelcomePopup];
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:DID_SEE_WELCOME_POPUP_KEY];
    });
}

- (void) tappedWelcomePopup {
    NSLog(@"tapped Welcome Popup");
    [self dismissPopupViewControllerWithanimationType:MJPopupViewAnimationSlideTopTop];
    double delay = .2;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self didTapYapsPageButton];
    });

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

- (BOOL) isInReplyMode
{
    return self.contactReplyingTo != nil;
}

- (void) setupNavBarStuff
{
    if ([self isInReplyMode]) {
        self.yapsPageButton.hidden = YES;
        UIImage *buttonImage = [UIImage imageNamed:@"WhiteBackArrow5.png"];
        [self.topLeftButton setImage:buttonImage forState:UIControlStateNormal];
        self.topLeftButton.alpha = 1;
        NSLog(@"In reply mode");
    } else {
        NSLog(@"Not in reply mode");
    }
}

- (IBAction)leftButtonPressed:(id)sender
{
    // In case recording is in progress when button is pressed
    [timer invalidate];
    self.recordProgressView.progress = 0.0;
    [self.audioSource stopAudioCapture:self.elapsedTime];
    
    if ([self isInReplyMode]) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self performSegueWithIdentifier:@"Friends Segue" sender:nil];
    }
}

-(BOOL) internetIsNotReachable
{
    return ![AFNetworkReachabilityManager sharedManager].reachable;
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

- (void) viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
    
    //Nav bar should not be transparent after finishing registration process
    self.navigationController.navigationBar.translucent = NO;

    [self reloadUnopenedYapsCount];
    
    if (IS_BEFORE_IOS_8) {
        self.bottomConstraint.constant = 9;
    }
    
    [self updateYapsButtonAnimation];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void) setupNotifications
{
    __weak AudioCaptureViewController *weakSelf = self;

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserverForName:AUDIO_CAPTURE_DID_END_NOTIFICATION
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                        [self.playButton setEnabled:YES]; //This isn't in the UI currently
                    }];
    
    [center addObserverForName:AUDIO_CAPTURE_DID_START_NOTIFICATION
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                        [weakSelf.recordProgressView.activityIndicator stopAnimating];
                        
                        if (note.object == weakSelf.audioSource) {
                            timer = [NSTimer scheduledTimerWithTimeInterval:TIMER_INTERVAL
                                                                     target:weakSelf
                                                                   selector:@selector(updateProgress)
                                                                   userInfo:nil
                                                                    repeats:YES];
                        }
                    }];
    
    [center addObserverForName:AUDIO_CAPTURE_UNEXPECTED_ERROR_NOTIFICATION
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                        
                        double delay = .1;
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            [[YTNotifications sharedNotifications] showNotificationText:@"Oops, Something Went Wrong!"];
                        });
                        [weakSelf.recordProgressView setProgress:0];
                        weakSelf.elapsedTime = 0;
                        [timer invalidate];
                    }];
    
    [center addObserverForName:AUDIO_CAPTURE_LOST_CONNECTION_NOTIFICATION
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                        
                        double delay = .1;
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            [[YTNotifications sharedNotifications] showNotificationText:@"Oops, Connection Was Lost!"];
                        });
                        [weakSelf.recordProgressView setProgress:0];
                        weakSelf.elapsedTime = 0;
                        [timer invalidate];
                    }];
    
    [center addObserverForName:STOP_LOADING_SPINNER_NOTIFICATION
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                        [self.recordProgressView.activityIndicator stopAnimating];
                    }];
    
    [center addObserverForName:NOTIFICATION_LOGOUT object:nil queue:nil usingBlock:^ (NSNotification *note) {
        [weakSelf.navigationController popToRootViewControllerAnimated:YES];
    }];
    
    [center addObserverForName:UIApplicationDidBecomeActiveNotification
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                        [weakSelf reloadUnopenedYapsCount];
                    }];

    [center addObserverForName:UIApplicationWillResignActiveNotification
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                        [timer invalidate];
                        self.recordProgressView.progress = 0.0;
                        [self.audioSource stopAudioCapture:self.elapsedTime];
                    }];
    
    [center addObserverForName:SHOW_FEEDBACK_PAGE
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                        NSLog(@"Show Feedback Page");
                        [self showFeedbackEmailViewControllerWithCompletion:^{
                        }];
                    }];
    
    [center addObserverForName:SHOW_CONTROL_CENTER
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                        NSLog(@"Show Control Center");
                        [self showControlCenter];
                    }];
    /*
    [center addObserverForName:SHOW_CONTROL_CENTER_MUSIC_HEADER_VIEW
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                        NSLog(@"Show Control Center");
                        [self showControlCenterMusicHeaderView];
                    }];
    
    [center addObserverForName:HIDE_CONTROL_CENTER_MUSIC_HEADER_VIEW
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                        NSLog(@"Show Control Center");
                        [self hideControlCenterMusicHeaderView];
                    }];
     */
}

- (void) updateProgress {
    self.elapsedTime += TIMER_INTERVAL;
    
    [self.recordProgressView setProgress:(self.elapsedTime / MAX_CAPTURE_TIME)];
    
    if (self.elapsedTime >= MAX_CAPTURE_TIME) {
        [timer invalidate];
        [self performSegueWithIdentifier:@"Prepare Yap For Text Segue" sender:nil];
        
        // The following 0.1 second delay is here because otherwise the page takes an extra half second to transition to the AddTextViewController (not sure why that happens)
        double delay = .1;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.audioSource stopAudioCapture:self.elapsedTime];
        });
    }
}

-(void)loadingSpinnerTapped
{
    [self didTapYapsPageButton];
}

- (IBAction)recordTapped:(id)sender
{
    self.elapsedTime = 0;
    [self.recordProgressView setProgress:0];
    
    if ([self.audioSource startAudioCapture]) {
        if (self.audioSource.class == [YSSpotifySourceController class]) {
            [self.recordProgressView.activityIndicator startAnimating];
        }
    }
}

- (IBAction)recordUntapped:(id)sender
{
    [timer invalidate];
    
    if (self.elapsedTime <= CAPTURE_THRESHOLD) {
        self.recordProgressView.progress = 0.0;
        double delay = .1;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self.audioSource.class == [YSSpotifySourceController class]) {
                [[YTNotifications sharedNotifications] showNotificationText:@"Keep Holding to Play"];
            } else {
                [[YTNotifications sharedNotifications] showNotificationText:@"Keep Holding to Record"];
            }
        });
        
    } else {
        [self performSegueWithIdentifier:@"Prepare Yap For Text Segue" sender:nil];
    }

    // The following 0.1 second delay is here because otherwise the page takes an extra half second to transition to the AddTextViewController (not sure why that happens)
    double delay = .1;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.audioSource stopAudioCapture:self.elapsedTime];
    });
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Untapped Record Button"];
}


- (IBAction)playTapped:(id)sender {
    [self.audioSource startPlayback]; //Play button isn't in the UI currently
}

- (IBAction) didTapYapsPageButton
{
    // In case recording is in progress when button is pressed
    [timer invalidate];
    self.recordProgressView.progress = 0.0;
    [self.audioSource stopAudioCapture:self.elapsedTime];
        
    [self performSegueWithIdentifier:@"YapsPageViewControllerSegue" sender:self];
}


- (BOOL) isInSpotifyMode
{
    return [self.audioSource isKindOfClass:[YSSpotifySourceController class]];
}

- (BOOL) isInRecordMode
{
    return [self.audioSource isKindOfClass:[YSMicSourceController class]];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([@"Prepare Yap For Text Segue" isEqualToString:segue.identifier]) {
        AddTextViewController *addTextVC = segue.destinationViewController;

        //Create yap object
        YapBuilder *yapBuilder = [self.audioSource getYapBuilder];
        yapBuilder.duration = self.elapsedTime;
        addTextVC.yapBuilder = yapBuilder;
        if (self.contactReplyingTo) {
            yapBuilder.contacts = @[self.contactReplyingTo];
        }
        
        self.recordProgressView.progress = 0.0;
        self.elapsedTime = 0;
    } else if ([@"YapsPageViewControllerSegue" isEqualToString:segue.identifier]) {
        YapsViewController *yapsVC = segue.destinationViewController;
        yapsVC.unopenedYapsCount = self.unopenedYapsCount;
    } else if ([@"Friends Segue" isEqualToString:segue.identifier]) {
        UINavigationController *navVC = segue.destinationViewController;
        FriendsViewController *vc = navVC.viewControllers[0];
        vc.yapsSentCallback = ^() {
            [self performSegueWithIdentifier:@"YapsPageViewControllerSegue" sender:nil];
        };
    }
}

#pragma mark - Mode Changing
- (void)switchToSpotifyMode
{
    if (![self isInSpotifyMode]) {
        YSSpotifySourceController *spotifySource = [self.storyboard instantiateViewControllerWithIdentifier:@"SpotifySourceController"];
        [self flipController:self.audioSource to:spotifySource];
    }
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Tapped Music Mode Button"];
}

- (void)switchToMicMode {
    if (![self isInRecordMode]) {
        YSMicSourceController *micSource = [self.storyboard instantiateViewControllerWithIdentifier:@"MicSourceController"];
        [self flipController:self.audioSource to:micSource];
    }
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Tapped Mic Mode Button"];
}

- (void) flipController:(UIViewController *)from to:(YSAudioSourceController *)to
{
    to.view.frame = from.view.bounds;
    [self addChildViewController:to];
    [from willMoveToParentViewController:self];

    __weak AudioCaptureViewController *weakSelf = self;
    [self transitionFromViewController:from
                      toViewController:to
                              duration:.25
                               options:UIViewAnimationOptionCurveEaseInOut
                            animations:^{
                            }
                            completion:^(BOOL finished) {
                                [to didMoveToParentViewController:weakSelf];
                                [from.view removeFromSuperview];
                                [from removeFromParentViewController];
                                weakSelf.audioSource = to;
                            }];
}

- (BOOL) didOpenYapForFirstTime
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:OPENED_YAP_FOR_FIRST_TIME_KEY];
}

- (BOOL) didSeeWelcomePopup
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:DID_SEE_WELCOME_POPUP_KEY];
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

- (IBAction)didTapOpenControlCenterButton {
    [self switchToSpotifyMode];
    [self showControlCenter];
}

- (void)hideControlCenter {
    //[self hideControlCenterMusicHeaderView];

    [UIView animateWithDuration:.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.openControlCenterButton.alpha = 1;
                     }
                     completion:nil];
    __weak typeof(self) weakSelf = self;

    CGRect frame = self.controlCenterView.frame;
    frame.origin.y += CONTROL_CENTER_HEIGHT;
    
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         weakSelf.controlCenterView.frame = frame;
                         weakSelf.controlCenterBottomConstraint.constant = -CONTROL_CENTER_HEIGHT;
                     }
                     completion:nil];
    
    
}

- (void)showControlCenter {
    self.openControlCenterButton.alpha = 0;

    __weak typeof(self) weakSelf = self;
    
    [self.audioSource resetUI];
    
    CGRect frame = self.controlCenterView.frame;
    frame.origin.y -= CONTROL_CENTER_HEIGHT;

    [UIView animateWithDuration:.4
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         weakSelf.controlCenterView.frame = frame;
                         weakSelf.controlCenterBottomConstraint.constant = 0;
                     }
                     completion:nil];
}

#pragma mark - Control Center
- (void) setupControlCenter
{
    for (UIViewController *vc in self.childViewControllers) {
        if ([vc isKindOfClass:[ControlCenterViewController class]]) {
            ControlCenterViewController *controlVC = (ControlCenterViewController *)vc;
            controlVC.delegate = self;
        }
    }
}

- (void) tappedSpotifyButton:(NSString *)type
{
    [self switchToSpotifyMode];
    [self.audioSource tappedControlCenterButton:type];
    [self hideControlCenter];
}

- (void) tappedRecordButton
{
    [self switchToMicMode];
    
    double delay = .1;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self hideControlCenter];
    });
}

/*
- (void) showControlCenterMusicHeaderView
{
    [UIView animateWithDuration:.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.controlCenterMusicHeaderView.alpha = 1;
                     }
                     completion:nil];
}

- (void) hideControlCenterMusicHeaderView
{
    [UIView animateWithDuration:.3
                          delay:.2
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.controlCenterMusicHeaderView.alpha = 0;
                     }
                     completion:nil];
}
*/

- (IBAction) didTapGoToFirstControlCenterViewButton
{
    NSLog(@"tapped first control center view button");
    [[NSNotificationCenter defaultCenter] postNotificationName:TRANSITION_TO_FIRST_CONTROL_CENTER_VIEW object:nil];
    //[[NSNotificationCenter defaultCenter] postNotificationName:HIDE_CONTROL_CENTER_MUSIC_HEADER_VIEW object:nil];
}

@end
