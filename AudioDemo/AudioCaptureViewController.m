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

@interface AudioCaptureViewController ()<YSAudioSourceControllerDelegate> {
    NSTimer *audioProgressTimer;
}
@property (strong, nonatomic) IBOutlet UIView *audioSourceContainer;
@property (nonatomic) float elapsedTime;
@property (nonatomic, strong) NSString *titleString;
@property (strong, nonatomic) UIImage *diceImage;
@property (weak, nonatomic) IBOutlet UIButton *switchButton;
@property (weak, nonatomic) IBOutlet UILabel *receiverLabel;

- (void)switchToSpotifyMode;
- (void)switchToMicMode;
- (IBAction)didTapSwitchRecordSource:(id)sender;

@end

@implementation AudioCaptureViewController

static const float MAX_CAPTURE_TIME = 12.0;
static const float TIMER_INTERVAL = .02;

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
    self.type = AudioCapTureTypeSpotify;
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
    
    if (self.contactReplyingTo) {
        self.receiverLabel.hidden = NO;
        self.receiverLabel.text = self.contactReplyingTo.name;
    }
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.recordProgressView.hidden = YES;
    
    if (self.type == AudioCaptureTypeMic) {
        self.titleString = @"Start Yappin'";
    } else if (self.type == AudioCapTureTypeSpotify) {
        self.titleString = @"Find a Song";
    }
    [self updateTitleLabel];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (audioProgressTimer) {
        [audioProgressTimer invalidate];
        NSLog(@"Audio Progress Timer Invalidate 1");
    }
    
    [self.audioSource stopAudioCapture];
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
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Dismiss Audio Capture Modal"];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:DISMISS_KEYBOARD_NOTIFICATION object:nil];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)diceButtonPressed
{
    NSLog(@"Tapped Right Button");
    [[NSNotificationCenter defaultCenter] postNotificationName:TAPPED_DICE_BUTTON_NOTIFICATION object:nil];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Tapped Dice Button"];
    [mixpanel.people increment:@"Tapped Dice Button #" by:[NSNumber numberWithInt:1]];
}

-(BOOL) internetIsNotReachable
{
    return ![AFNetworkReachabilityManager sharedManager].reachable;
}

- (void) setupNotifications
{
    __weak AudioCaptureViewController *weakSelf = self;

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

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
                        [audioProgressTimer invalidate];
                        NSLog(@"Audio Progress Timer Invalidate 5");
                        self.recordProgressView.progress = 0.0;
                        [self.audioSource stopAudioCapture];
                    }];
}

- (void) updateProgress {
    self.elapsedTime += TIMER_INTERVAL;
    
    [self.recordProgressView setProgress:(self.elapsedTime / MAX_CAPTURE_TIME)];
    
    // Added the minus .02 because otherwise the page would transition .02 seconds too early
    if (self.elapsedTime - .02 >= MAX_CAPTURE_TIME) {
        [audioProgressTimer invalidate];
        NSLog(@"Audio Progress Timer Invalidate 6");
        [self.audioSource stopAudioCapture];
        
        /*
        // This delay is necessary to avoid apple's built in red nav bar to indicate phone is recording
        double delay1 = .1;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self performSegueWithIdentifier:@"Prepare Yap For Text Segue" sender:nil];
        });
        */
    }
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

- (BOOL) didTapDiceButtonForFirstTime
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:DID_TAP_DICE_BUTTON];
}

#pragma mark - YSAudioSourceControllerDelegate

- (void)audioSourceControllerWillStartAudioCapture:(YSAudioSourceController *)controller {
    self.recordProgressView.hidden = NO;
    [self.recordProgressView.activityIndicator startAnimating];
}

- (void)audioSourceControllerDidStartAudioCapture:(YSAudioSourceController *)controller {
    self.recordProgressView.hidden = NO;
    [self.recordProgressView.activityIndicator stopAnimating];
    self.elapsedTime = 0;
    [self.recordProgressView setProgress:0];
    
    if (audioProgressTimer) {
        [audioProgressTimer invalidate];
    }
    audioProgressTimer = [NSTimer scheduledTimerWithTimeInterval:TIMER_INTERVAL
                                                          target:self
                                                        selector:@selector(updateProgress)
                                                        userInfo:nil
                                                         repeats:YES];
    NSLog(@"Start Audio Progress Timer!");
    
    if (self.type == AudioCaptureTypeMic) {
        self.titleString = @"Recording...";
    } else {
        self.titleString = @"Playing...";
    }
    [self updateTitleLabel];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:AUDIO_CAPTURE_DID_START_NOTIFICATION object:nil];
}

- (void)audioSourceControllerdidFinishAudioCapture:(YSAudioSourceController *)controller {
    [audioProgressTimer invalidate];
    NSLog(@"Audio Progress Timer Invalidate 7");
    [self.recordProgressView.activityIndicator stopAnimating];
    
    if (self.elapsedTime <= CAPTURE_THRESHOLD) {
        self.recordProgressView.progress = 0.0;
        double delay = .1;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self.type == AudioCapTureTypeSpotify) {
                [[YTNotifications sharedNotifications] showNotificationText:@"Keep Holding to Play"];
            } else {
                [[YTNotifications sharedNotifications] showNotificationText:@"Keep Holding to Record"];
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:UNTAPPED_RECORD_BUTTON_BEFORE_THRESHOLD_NOTIFICATION object:nil];
        });
        
        if (self.type == AudioCaptureTypeMic) {
            self.titleString = @"Start Yappin'";
        } else if (self.type == AudioCapTureTypeSpotify) {
            self.titleString = @"Find a Song";
        }
        
        [self updateTitleLabel];
    } else {
        // This delay is necessary to avoid apple's built in red nav bar to indicate phone is recording
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self performSegueWithIdentifier:@"Prepare Yap For Text Segue" sender:nil];
        });
    }
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Untapped Record Button"];
}

- (void)audioSourceController:(YSAudioSourceController *)controller didReceieveUnexpectedError:(NSError *)error {
    [self.recordProgressView.activityIndicator stopAnimating];
    double delay = .1;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[YTNotifications sharedNotifications] showNotificationText:@"Oops, Something Went Wrong!"];
    });
    [self.recordProgressView setProgress:0];
    self.elapsedTime = 0;
    [audioProgressTimer invalidate];
    NSLog(@"Audio Progress Timer Invalidate 3");
}

#pragma mark - Mode Changing

- (void)switchToSpotifyMode {
    self.type = AudioCapTureTypeSpotify;
    [self.switchButton setTitle:@"Mic" forState:UIControlStateNormal];
    YSSpotifySourceController *spotifySource = [self.storyboard instantiateViewControllerWithIdentifier:@"SpotifySourceController"];
    [self setRecordSourceViewController:spotifySource];
}

- (void)switchToMicMode {
    [self.switchButton setTitle:@"Music" forState:UIControlStateNormal];
    self.type = AudioCaptureTypeMic;
    YSMicSourceController *micSource = [self.storyboard instantiateViewControllerWithIdentifier:@"MicSourceController"];
    [self setRecordSourceViewController:micSource];
}

- (IBAction)didTapSwitchRecordSource:(id)sender {
    if (self.type == AudioCapTureTypeSpotify) {
        [self switchToMicMode];
    } else {
        [self switchToSpotifyMode];
    }
}

- (void) setRecordSourceViewController:(YSAudioSourceController *)to {
    NSAssert(to != nil, @"To controller cannot be nil");
    [self.audioSource removeFromParentViewController];
    to.audioCaptureDelegate = self;
    [self addChildViewController:to];
    to.view.frame = self.audioSourceContainer.bounds;
    [self.audioSourceContainer addSubview:to.view];
    self.audioSource = to;
    [to didMoveToParentViewController:self];
}

@end