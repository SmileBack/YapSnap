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
@property (nonatomic, strong) IBOutlet UIView *songGenreView;
@property (nonatomic, strong) IBOutlet UIButton *songGenreButtonOne;
@property (nonatomic, strong) IBOutlet UIButton *songGenreButtonTwo;
@property (nonatomic, strong) IBOutlet UIButton *songGenreButtonThree;
@property (nonatomic, strong) IBOutlet UIButton *songGenreButtonFour;
@property (nonatomic, strong) IBOutlet UIButton *songGenreButtonFive;
@property (nonatomic, strong) IBOutlet UIButton *songGenreButtonSix;

- (IBAction)didTapSongGenreButtonOne;
- (IBAction)didTapSongGenreButtonTwo;
- (IBAction)didTapSongGenreButtonThree;
- (IBAction)didTapSongGenreButtonFour;
- (IBAction)didTapSongGenreButtonFive;
- (IBAction)didTapSongGenreButtonSix;

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
    self.micModeButton.reverseImageOffset = YES;
    self.spotifyModeButton.image = [UIImage imageNamed:@"MusicIconBlue3"];
    self.micModeButton.image = [UIImage imageNamed:@"MicModeButtonIcon"];
    [self.recordButton setBackgroundImage:[UIImage imageNamed:@"RecordButtonBlueBorder10Pressed.png"] forState:UIControlStateHighlighted];
    
    self.recordProgressView.progress = 0;
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self  action:@selector(didTapProgressView)];
    [self.recordProgressView addGestureRecognizer:tapGesture];

    if ([AppDelegate sharedDelegate].appOpenedCount <= 2) {
        YSSpotifySourceController *spotifySource = [self.storyboard instantiateViewControllerWithIdentifier:@"SpotifySourceController"];
        [self addChildViewController:spotifySource];
        spotifySource.view.frame = self.audioSourceContainer.bounds;
        [self.audioSourceContainer addSubview:spotifySource.view];
        self.audioSource = spotifySource;
        self.micModeButton.alpha = .3;
        self.spotifyModeButton.alpha = 1;
    } else {
        YSMicSourceController *micSource = [self.storyboard instantiateViewControllerWithIdentifier:@"MicSourceController"];
        [self addChildViewController:micSource];
        micSource.view.frame = self.audioSourceContainer.bounds;
        [self.audioSourceContainer addSubview:micSource.view];
        self.audioSource = micSource;
        self.micModeButton.alpha = 1;
        self.spotifyModeButton.alpha = .3;
    }
    
    [self setupNotifications];
    
    [self setupNavBarStuff];
    
    if (!self.didSeeWelcomePopup) {
        [self showWelcomePopup];
    }
    
    [self designSongGenreButtons];
    
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
}

- (void) didTapProgressView
{
    [[NSNotificationCenter defaultCenter] postNotificationName:TAPPED_PROGRESS_VIEW_NOTIFICATION object:self];
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
        [self micModeButtonPressed:nil]; //This line is a hacky fix to an issue where spotify songs remain on screen after pop
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
    
    [center addObserverForName:UPDATE_SONG_GENRE_VIEW_VISIBILITY
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                        NSLog(@"Show Song Genre View");
                        if (self.songGenreView.hidden == YES) {
                            [self showSongGenreView];
                        } else {
                            [self hideSongGenreView];
                        }
                    }];
    
    [center addObserverForName:HIDE_SONG_GENRE_VIEW
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                        NSLog(@"Show Song Genre View");
                        [self hideSongGenreView];
                    }];
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

    self.explanation.hidden = YES;

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
            [[YTNotifications sharedNotifications] showNotificationText:@"Hold Down to Record"];
        });
        
        self.explanation.hidden = YES;
        //Make explanation label disappear
        double delay2 = 2.0;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.explanation.hidden = YES;
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
    }
}

- (void) resetUI
{
    if ([AppDelegate sharedDelegate].appOpenedCount <= 2) {
        [self spotifyModeButtonPressed:nil];
    } else {
        [self micModeButtonPressed:nil];
    }
}

#pragma mark - Mode Changing
- (IBAction)spotifyModeButtonPressed:(UIButton *)sender
{
    if (![self isInSpotifyMode]) {
        YSSpotifySourceController *spotifySource = [self.storyboard instantiateViewControllerWithIdentifier:@"SpotifySourceController"];
        self.micModeButton.alpha = .3;
        self.spotifyModeButton.alpha = 1;
        [self flipController:self.audioSource to:spotifySource];
    }
    
    if (sender) {
        if (!self.didTapMusicModeButtonForFirstTime) {
            double delay = .1;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                //[[YTNotifications sharedNotifications] showModeText:@"Music Mode"];
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:TAPPED_MUSIC_MODE_BUTTON_FOR_FIRST_TIME_KEY];
            });
        }
    }
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Tapped Music Mode Button"];
}

- (IBAction)micModeButtonPressed:(UIButton *)sender
{
    if (![self isInRecordMode]) {
        YSMicSourceController *micSource = [self.storyboard instantiateViewControllerWithIdentifier:@"MicSourceController"];
        self.micModeButton.alpha = 1;
        self.spotifyModeButton.alpha = .3;
        [self flipController:self.audioSource to:micSource];
    }
    
    if (sender) {
        if (!self.didTapMicModeButtonForFirstTime) {
            double delay = 1;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                //[[YTNotifications sharedNotifications] showModeText:@"Mic Mode"];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Add Helium to Your Voice"
                                                                message:@"Record your voice and then tap the white balloon!"
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles: nil];
                [alert show];
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:TAPPED_MIC_MODE_BUTTON_FOR_FIRST_TIME_KEY];
            });
        }
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

- (BOOL) didTapMicModeButtonForFirstTime
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:TAPPED_MIC_MODE_BUTTON_FOR_FIRST_TIME_KEY];
}

- (BOOL) didTapMusicModeButtonForFirstTime
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:TAPPED_MUSIC_MODE_BUTTON_FOR_FIRST_TIME_KEY];
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

#pragma mark - Song Genre Buttons

- (IBAction)didTapSongGenreButtonOne {
    [self.audioSource tappedSongGenreButton:@"Top100"];
    [self hideSongGenreView];
}

- (IBAction)didTapSongGenreButtonTwo {
    [self.audioSource tappedSongGenreButton:@"Top100"];
    [self hideSongGenreView];
}

- (IBAction)didTapSongGenreButtonThree {
    [self.audioSource tappedSongGenreButton:@"Top100"];
    [self hideSongGenreView];
}

- (IBAction)didTapSongGenreButtonFour {
    [self.audioSource tappedSongGenreButton:@"Top100"];
    [self hideSongGenreView];
}

- (IBAction)didTapSongGenreButtonFive {
    [self.audioSource tappedSongGenreButton:@"Top100"];
    [self hideSongGenreView];
}

- (IBAction)didTapSongGenreButtonSix {
    [self.audioSource tappedSongGenreButton:@"Top100"];
    [self hideSongGenreView];
}

- (void)hideSongGenreView {
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenHeight = screenRect.size.height;
    CGFloat screenWidth = screenRect.size.width;
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.songGenreView.frame = CGRectMake(0, screenHeight, screenWidth, 201);
                     }
                     completion:^(BOOL finished) {
                         self.songGenreView.hidden = YES;
                     }];
}

- (void)showSongGenreView {
    self.songGenreView.hidden = NO;
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenHeight = screenRect.size.height;
    CGFloat screenWidth = screenRect.size.width;
    
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.songGenreView.frame = CGRectMake(0, screenHeight-211, screenWidth, 211);
                     }
                     completion:^(BOOL finished) {
                     }];
}

- (void) designSongGenreButtons {
    self.songGenreButtonOne.layer.cornerRadius = 42;
    self.songGenreButtonOne.layer.borderWidth = 1;
    self.songGenreButtonOne.layer.borderColor = [UIColor whiteColor].CGColor;
    
    self.songGenreButtonTwo.layer.cornerRadius = 42;
    self.songGenreButtonTwo.layer.borderWidth = 1;
    self.songGenreButtonTwo.layer.borderColor = [UIColor whiteColor].CGColor;
    
    self.songGenreButtonThree.layer.cornerRadius = 42;
    self.songGenreButtonThree.layer.borderWidth = 1;
    self.songGenreButtonThree.layer.borderColor = [UIColor whiteColor].CGColor;
    
    self.songGenreButtonFour.layer.cornerRadius = 42;
    self.songGenreButtonFour.layer.borderWidth = 1;
    self.songGenreButtonFour.layer.borderColor = [UIColor whiteColor].CGColor;
    
    self.songGenreButtonFive.layer.cornerRadius = 42;
    self.songGenreButtonFive.layer.borderWidth = 1;
    self.songGenreButtonFive.layer.borderColor = [UIColor whiteColor].CGColor;
    
    self.songGenreButtonSix.layer.cornerRadius = 42;
    self.songGenreButtonSix.layer.borderWidth = 1;
    self.songGenreButtonSix.layer.borderColor = [UIColor whiteColor].CGColor;
}

@end
