//
//  AudioCaptureViewController.m
//  AudioDemo
//
//  Created by Simon on 24/2/13.
//  Copyright (c) 2013 Appcoda. All rights reserved.
//

#import "AudioCaptureViewController.h"
#import "ContactsViewController.h"
#import "YSAudioSourceController.h"
#import "YSSpotifySourceController.h"
#import "YSMicSourceController.h"



@interface AudioCaptureViewController () {
    NSTimer *timer;
}
@property (strong, nonatomic) IBOutlet UIView *audioSourceContainer;
@property (nonatomic, strong) YSAudioSourceController *audioSource;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *recordButtonSpinner;
@property (strong, nonatomic) IBOutlet UIButton *modeSelectionButton;

@property (nonatomic) float elapsedTime;

@end

@implementation AudioCaptureViewController
//@synthesize playButton, recordButton; //stopButton

static const float MAX_CAPTURE_TIME = 10.0;
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
    
    
    self.arrowButton.hidden = YES;
    self.cancelButton.hidden = YES;
    
    self.progressView.progress = 0;
    [self.progressView setTrackImage:[UIImage imageNamed:@"ProgressViewBackgroundWhite.png"]];
    [self.progressView setProgressImage:[UIImage imageNamed:@"ProgressViewBackgroundRed.png"]];

    YSMicSourceController *micSource = [self.storyboard instantiateViewControllerWithIdentifier:@"MicSourceController"];
    [self addChildViewController:micSource];
    micSource.view.frame = self.audioSourceContainer.bounds;
    [self.audioSourceContainer addSubview:micSource.view];
    self.audioSource = micSource;
    
    // Disable Stop/Play button when application launches
    //[stopButton setEnabled:NO];
    [self.playButton setEnabled:NO];

    [self setupNotifications];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
    
    //Nav bar should not be transparent after finishing registration process
    self.navigationController.navigationBar.translucent = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillDisappear:animated];
}

- (void) setupNotifications
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserverForName:AUDIO_CAPTURE_DID_END_NOTIFICATION
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                        [self.playButton setEnabled:YES];
                    }];
    
    [center addObserverForName:AUDIO_CAPTURE_DID_START_NOTIFICATION
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                        //[self.recordButtonSpinner stopAnimating];
                        timer = [NSTimer scheduledTimerWithTimeInterval:TIMER_INTERVAL
                                                                 target:self
                                                               selector:@selector(updateProgress)
                                                               userInfo:nil
                                                                repeats:YES];
                    }];
    
    [center addObserverForName:AUDIO_CAPTURE_ERROR_NOTIFICATION
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                        UIAlertView *alert =[[UIAlertView alloc] initWithTitle:@"Something went wrong"
                                                                       message:@"Something didn't work - please try again."
                                                                      delegate:nil
                                                             cancelButtonTitle:@"OK" otherButtonTitles:nil];
                        [self.progressView setProgress:0];
                        self.elapsedTime = 0;
                        [timer invalidate];
                        [alert show];
                    }];
}

- (void) updateProgress {
    self.elapsedTime += TIMER_INTERVAL;
    
    [self.progressView setProgress:(self.elapsedTime / MAX_CAPTURE_TIME)];
    if (self.elapsedTime >= MAX_CAPTURE_TIME) {
        [timer invalidate];
        [self.audioSource stopAudioCapture:self.elapsedTime];
        [self setupEndCaptureInterface];
    }
}

- (void) setupEndCaptureInterface
{
    self.recordButton.hidden = YES;
    self.yapsPageButton.hidden = YES;
    self.arrowButton.hidden = NO;
    self.cancelButton.hidden = NO;
    self.modeSelectionButton.hidden = YES;
}

- (IBAction)recordTapped:(id)sender
{
    self.elapsedTime = 0;
    [self.progressView setProgress:0];

    self.explanation.hidden = YES;
    [self.playButton setEnabled:NO];

    if ([self.audioSource startAudioCapture]) {
        //[self.recordButtonSpinner startAnimating];
    }
}

- (IBAction)recordUntapped:(id)sender
{
    [timer invalidate];
    
    if (self.elapsedTime <= CAPTURE_THRESHOLD) {
        self.progressView.progress = 0.0;
        self.explanation.hidden = NO;
        double delay = 3.0;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.explanation.hidden = YES;
        });
    } else {
        [self setupEndCaptureInterface];
    }

    [self.audioSource stopAudioCapture:self.elapsedTime];
}


- (IBAction)playTapped:(id)sender {
    [self.audioSource startPlayback];
}

- (IBAction)cancelTapped:(id)sender {
    self.arrowButton.hidden = YES;
    self.cancelButton.hidden = YES;
    self.recordButton.hidden = NO;
    self.yapsPageButton.hidden = NO;
    self.modeSelectionButton.hidden = NO;
    self.progressView.progress = 0.0;
    self.elapsedTime = 0;
    [self.audioSource resetUI];
}

- (IBAction) didTapArrowButton
{
    [self performSegueWithIdentifier:@"ContactsViewControllerSegue" sender:self];
}


- (BOOL) isInSpotifyMode
{
    return [self.audioSource isKindOfClass:[YSSpotifySourceController class]];
}

- (BOOL) isInRecordMode
{
    return [self.audioSource isKindOfClass:[YSMicSourceController class]];
}

#pragma mark - Mode Changing
- (IBAction)modeButtonPressed:(UIButton *)sender
{
    if ([self isInSpotifyMode]) {
        // Show Mic
        YSMicSourceController *micSource = [self.storyboard instantiateViewControllerWithIdentifier:@"MicSourceController"];
        [self flipController:self.audioSource to:micSource];

        [self.modeSelectionButton setBackgroundImage:[UIImage imageNamed:@"MusicIconSmall.png"] forState:UIControlStateNormal];
        //[self.modeSelectionButton setTitle:@"MUSIC" forState:UIControlStateNormal];

    } else {
        // Show Spotify
        YSSpotifySourceController *spotifySource = [self.storyboard instantiateViewControllerWithIdentifier:@"SpotifySourceController"];
        
        [self flipController:self.audioSource to:spotifySource];

        [self.modeSelectionButton setBackgroundImage:[UIImage imageNamed:@"Microphone_White2.png"] forState:UIControlStateNormal];
        //[self.modeSelectionButton setTitle:@"MIC" forState:UIControlStateNormal];
    }
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


@end
