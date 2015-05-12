//
//  AudioCaptureViewController.m
//  AudioDemo
//
//  Created by Simon on 24/2/13.
//  Copyright (c) 2013 Appcoda. All rights reserved.
//

#import "AudioCaptureViewController.h"
#import "CustomizeYapViewController.h"
#import "YSSpotifySourceController.h"
#import "YSMicSourceController.h"
#import "API.h"
#import "YapBuilder.h"
#import "AppDelegate.h"

#define CONTROL_CENTER_HEIGHT 503.0f

@interface AudioCaptureViewController (){
    NSTimer *timer;
    NSTimer *countdownTimer;
    int currMinute;
    int currSeconds;
}
@property (strong, nonatomic) IBOutlet UIView *audioSourceContainer;
@property (nonatomic) float elapsedTime;
@property (nonatomic, strong) NSString *titleString;
@property (strong, nonatomic) UIButton *countdownTimerButton;

- (void)switchToSpotifyMode;
- (void)switchToMicMode;

@end

@implementation AudioCaptureViewController

static const float MAX_CAPTURE_TIME = 12.0;
static const float TIMER_INTERVAL = .01;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [self commonInit];
    }
    return self;
}

- (void)awakeFromNib {
    [self commonInit];
}

- (void)commonInit {
    self.type = AudioCaptureTypeMic;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self addCancelButton];
    
    self.view.backgroundColor = THEME_BACKGROUND_COLOR;
    
    self.navigationController.navigationBar.barTintColor = THEME_BACKGROUND_COLOR;
    [self.recordButton setBackgroundImage:[UIImage imageNamed:@"RecordButtonBlueBorder10Pressed.png"] forState:UIControlStateHighlighted];
    self.recordProgressView.progress = 0;

    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedProgressView)];
    [self.recordProgressView addGestureRecognizer:tapGesture];
    
    if (self.type == AudioCaptureTypeMic) {
        [self switchToMicMode];
    } else {
        [self switchToSpotifyMode];
    }
    
    [self setupNotifications];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (countdownTimer) {
        [self stopCountdownTimer];
    }
    
    if (timer) {
        [timer invalidate];
    }
}

-(void) startCountdownTimer
{
    NSLog(@"Start");
    if (countdownTimer){
        [self stopCountdownTimer];
    }
    countdownTimer=[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(countdownTimerFired) userInfo:nil repeats:YES];
}

-(void) stopCountdownTimer {
    [countdownTimer invalidate];
}

-(void) countdownTimerFired
{
    NSLog(@"countdownTimer fired");
    NSLog(@"currMinute: %d; currSeconds: %d", currMinute, currSeconds);
    if((currMinute>0 || currSeconds>=0) && currMinute>=0)
    {
        if(currSeconds>0)
        {
            NSLog(@"currSeconds: %d", currSeconds);
            currSeconds-=1;
        }
        
        [self.countdownTimerButton setTitle:[NSString stringWithFormat:@"%d",currSeconds] forState:UIControlStateNormal];
    }
    else
    {
        NSLog(@"countdownTimer invalidate");
        [self stopCountdownTimer];
    }
}

- (void) tappedProgressView {
    NSLog(@"Tapped Progress Bar");
    if (self.type == AudioCaptureTypeMic) {
        [[YTNotifications sharedNotifications] showNotificationText:@"Hold Red Button"];
    } else if (self.type == AudioCapTureTypeSpotify) {
        [[NSNotificationCenter defaultCenter] postNotificationName:TAPPED_PROGRESS_BAR_NOTIFICATION object:nil];
    }
}

- (void) updateTitleLabel {
    CGRect frame = CGRectMake(40, 0, 160, 44);
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont fontWithName:@"Futura-Medium" size:18];
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = self.titleString;
    self.navigationItem.titleView = label;
}

- (void) addCountDownTimerLabel {
    self.countdownTimerButton.hidden = NO;
    self.countdownTimerButton = [[UIButton alloc] initWithFrame:CGRectMake(240, 0, 24, 44)];
    self.countdownTimerButton.titleLabel.font = [UIFont fontWithName:@"Futura-Medium" size:18];
    UIBarButtonItem *countdownTimerButton =[[UIBarButtonItem alloc] initWithCustomView:self.countdownTimerButton];
    [self.navigationItem setRightBarButtonItem:countdownTimerButton];
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

- (void)cancelPressed
{
    [[NSNotificationCenter defaultCenter] postNotificationName:DISMISS_KEYBOARD_NOTIFICATION object:nil];
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(BOOL) internetIsNotReachable
{
    return ![AFNetworkReachabilityManager sharedManager].reachable;
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.type == AudioCaptureTypeMic) {
        self.titleString = @"Record Voice";
    } else if (self.type == AudioCapTureTypeSpotify) {
        self.titleString = @"";
    }
    [self updateTitleLabel];
    
    self.countdownTimerButton.hidden = YES;
}

- (void) setupNotifications
{
    __weak AudioCaptureViewController *weakSelf = self;

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    [center addObserverForName:AUDIO_CAPTURE_DID_START_NOTIFICATION
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                        [weakSelf.recordProgressView.activityIndicator stopAnimating];
                        
                        if (note.object == weakSelf.audioSource) {
                            if (timer){
                                [timer invalidate];
                            }
                            timer = [NSTimer scheduledTimerWithTimeInterval:TIMER_INTERVAL
                                                                     target:weakSelf
                                                                   selector:@selector(updateProgress)
                                                                   userInfo:nil
                                                                    repeats:YES];
                        }
                        
                        if (self.type == AudioCaptureTypeMic) {
                            self.titleString = @"Recording...";
                        } else {
                            self.titleString = @"Recording Song...";
                        }
                        [self updateTitleLabel];
                        
                        [self addCountDownTimerLabel];
                        [self.countdownTimerButton setTitle:@"12" forState:UIControlStateNormal];
                        currSeconds=12;
                        [self startCountdownTimer];
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

    [center addObserverForName:UIApplicationWillResignActiveNotification
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                        [timer invalidate];
                        self.recordProgressView.progress = 0.0;
                        [self.audioSource stopAudioCapture:self.elapsedTime];
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
        
        if (self.type == AudioCaptureTypeMic) {
            self.titleString = @"Record Voice";
        } else if (self.type == AudioCapTureTypeSpotify) {
            self.titleString = @"";
        }
        
        [self updateTitleLabel];
        
        [self stopCountdownTimer];
        self.countdownTimerButton.hidden = YES;
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
        CustomizeYapViewController *addTextVC = segue.destinationViewController;

        //Create yap object
        YapBuilder *yapBuilder = [self.audioSource getYapBuilder];
        yapBuilder.duration = self.elapsedTime;
        addTextVC.yapBuilder = yapBuilder;
        if (self.contactReplyingTo) {
            yapBuilder.contacts = @[self.contactReplyingTo];
        }
        
        self.recordProgressView.progress = 0.0;
        self.elapsedTime = 0;
    }
}

#pragma mark - Mode Changing
- (void)switchToSpotifyMode
{
    YSSpotifySourceController *spotifySource = [self.storyboard instantiateViewControllerWithIdentifier:@"SpotifySourceController"];
    [self addChildViewController:spotifySource];
    spotifySource.view.frame = self.audioSourceContainer.bounds;
    [self.audioSourceContainer addSubview:spotifySource.view];
    self.audioSource = spotifySource;
    
    spotifySource = [self.storyboard instantiateViewControllerWithIdentifier:@"SpotifySourceController"];
    [self flipController:self.audioSource to:spotifySource];
    
    if (self.audioCaptureContext && self.audioCaptureContext[AudioCaptureContextGenreName]) {
        spotifySource.selectedGenre = self.audioCaptureContext[AudioCaptureContextGenreName];
    }
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Tapped Music Mode Button"];
}

- (void)switchToMicMode {
    YSMicSourceController *micSource = [self.storyboard instantiateViewControllerWithIdentifier:@"MicSourceController"];
    [self addChildViewController:micSource];
    micSource.view.frame = self.audioSourceContainer.bounds;
    [self.audioSourceContainer addSubview:micSource.view];
    self.audioSource = micSource;
    
    micSource = [self.storyboard instantiateViewControllerWithIdentifier:@"MicSourceController"];
    [self flipController:self.audioSource to:micSource];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Tapped Mic Mode Button"];
}

- (void) flipController:(UIViewController *)from to:(YSAudioSourceController *)to
{
    to.view.frame = from.view.bounds;
    [self addChildViewController:to];
    [from willMoveToParentViewController:self];

    __weak AudioCaptureViewController *weakSelf = self;
    if (from && to) {
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
}

@end