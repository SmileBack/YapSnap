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
}
@property (strong, nonatomic) IBOutlet UIView *audioSourceContainer;
@property (nonatomic) float elapsedTime;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *bottomConstraint;

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
    
    UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(cancelPressed)];
    cancel.tintColor = UIColor.whiteColor;
    [self.navigationItem setLeftBarButtonItem:cancel];
    
    self.view.backgroundColor = THEME_BACKGROUND_COLOR;
    
    self.navigationController.navigationBar.barTintColor = THEME_BACKGROUND_COLOR;
    [self.recordButton setBackgroundImage:[UIImage imageNamed:@"RecordButtonBlueBorder10Pressed.png"] forState:UIControlStateHighlighted];
    self.recordProgressView.progress = 0;
    
    if (self.type == AudioCaptureTypeMic) {
        [self switchToMicMode];
    } else {
        [self switchToSpotifyMode];
    }
    
    [self setupNotifications];
}

- (void)cancelPressed
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(BOOL) internetIsNotReachable
{
    return ![AFNetworkReachabilityManager sharedManager].reachable;
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (IS_BEFORE_IOS_8) {
        self.bottomConstraint.constant = 9;
    }
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