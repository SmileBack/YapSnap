//
//  AudioCaptureViewController.m
//  AudioDemo
//
//  Created by Simon on 24/2/13.
//  Copyright (c) 2013 Appcoda. All rights reserved.
//

#import "AudioCaptureViewController.h"
#import "AddTextViewController.h"
#import "YSAudioSourceController.h"
#import "YSSpotifySourceController.h"
#import "YSMicSourceController.h"
#import "API.h"
#import "YapBuilder.h"


@interface AudioCaptureViewController () {
    NSTimer *timer;
}
@property (strong, nonatomic) IBOutlet UIView *audioSourceContainer;
@property (nonatomic, strong) YSAudioSourceController *audioSource;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *recordButtonSpinner;
@property (strong, nonatomic) IBOutlet UIButton *spotifyModeButton;
@property (strong, nonatomic) IBOutlet UIButton *micModeButton;


@property (nonatomic) float elapsedTime;

@end

@implementation AudioCaptureViewController

static const float MAX_CAPTURE_TIME = 10.0;
static const float TIMER_INTERVAL = 0.1;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = THEME_BACKGROUND_COLOR;
    
    self.navigationController.navigationBar.barTintColor = THEME_BACKGROUND_COLOR;

    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@""
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:nil
                                                                            action:nil];
    
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
    [self.playButton setEnabled:YES];

    [self setupNotifications];
    
    if ([self internetIsNotReachable]) {
        NSLog(@"Internet is not reachable");
    } else {
        NSLog(@"Internet is reachable");
    }
}

-(BOOL) internetIsNotReachable
{
    return ![AFNetworkReachabilityManager sharedManager].reachable;
}

- (void) showNoInternetAlert {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Internet Connection"
                                                    message:@"Please connect to the internet and try again."
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
    
    //Nav bar should not be transparent after finishing registration process
    self.navigationController.navigationBar.translucent = NO;
    
    /*
    [[API sharedAPI] unopenedYapsCountWithCallback:^(NSNumber *count, NSError *error) {
        if (error) {
            [self.yapsPageButton setTitle:@"E" forState:UIControlStateNormal];
        } else {
            [self.yapsPageButton setTitle:count.description forState:UIControlStateNormal];
        }
    }];
     */
}

- (void)viewWillDisappear:(BOOL)animated {
    // TODO: Confirm the following change with Jon
    //[self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillDisappear:animated];
}

- (void) setupNotifications
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserverForName:AUDIO_CAPTURE_DID_END_NOTIFICATION
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                        // [self.playButton setEnabled:YES]; This isn't in the UI currently
                    }];
    
    [center addObserverForName:AUDIO_CAPTURE_DID_START_NOTIFICATION
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                        [self.recordButtonSpinner stopAnimating];
                        
                        //Uncomment the following lines after you handle cases where recording gets "interrupted"
                        //self.yapsPageButton.userInteractionEnabled = NO;
                        //self.spotifyModeButton.userInteractionEnabled = NO;
                        //self.micModeButton.userInteractionEnabled = NO;
                        
                        NSLog(@"Loading spinner stopped animating");
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
    
    [center addObserverForName:STOP_LOADING_SPINNER_NOTIFICATION
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                        [self.recordButtonSpinner stopAnimating];
                        NSLog(@"Loading spinner stopped animating");
                    }];
}

- (void) updateProgress{
    self.elapsedTime += TIMER_INTERVAL;
    
    [self.progressView setProgress:(self.elapsedTime / MAX_CAPTURE_TIME)];
    
    if (self.elapsedTime >= MAX_CAPTURE_TIME) {
        [timer invalidate];
        //[self performSegueWithIdentifier:@"Prepare Yap For Text Segue" sender:nil];
        [self.audioSource stopAudioCapture:self.elapsedTime];
    }
}

- (IBAction)recordTapped:(id)sender
{    
    self.elapsedTime = 0;
    [self.progressView setProgress:0];

    self.explanation.hidden = YES;

    if ([self.audioSource startAudioCapture]) {
        if (self.audioSource.class == [YSSpotifySourceController class]) {
            [self.recordButtonSpinner startAnimating];
            NSLog(@"Loading spinner started animating");
        }
    }
}

- (IBAction)recordUntapped:(id)sender
{
    [timer invalidate];
    
    self.spotifyModeButton.userInteractionEnabled = YES;
    self.micModeButton.userInteractionEnabled = YES;
    self.yapsPageButton.userInteractionEnabled = YES;
    
    if (self.elapsedTime <= CAPTURE_THRESHOLD) {
        self.progressView.progress = 0.0;
        self.explanation.hidden = NO;
        //Make explanation label disappear
        double delay = 2.0;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
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
}


- (IBAction)playTapped:(id)sender {
    [self.audioSource startPlayback]; //Play button isn't in the UI currently
}

- (IBAction) didTapYapsPageButton
{
    if ([self internetIsNotReachable]){
        [self showNoInternetAlert];
    } else {
        [self performSegueWithIdentifier:@"YapsPageViewControllerSegue" sender:self];
    }
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
        AddTextViewController *vc = segue.destinationViewController;

        //Create yap object
        YapBuilder *yapBuilder = [self.audioSource getYapBuilder];
        yapBuilder.duration = self.elapsedTime;
        vc.yapBuilder = yapBuilder;
        
        self.progressView.progress = 0.0;
        self.elapsedTime = 0;
    }
}

#pragma mark - Mode Changing
- (IBAction)spotifyModeButtonPressed:(UIButton *)sender
{
    if (![self isInSpotifyMode]) {
        YSSpotifySourceController *spotifySource = [self.storyboard instantiateViewControllerWithIdentifier:@"SpotifySourceController"];
        self.micModeButton.alpha = .2;
        self.spotifyModeButton.alpha = 1;
        [self flipController:self.audioSource to:spotifySource];
    }
}

- (IBAction)micModeButtonPressed:(UIButton *)sender
{
    if (![self isInRecordMode]) {
        YSMicSourceController *micSource = [self.storyboard instantiateViewControllerWithIdentifier:@"MicSourceController"];
        self.micModeButton.alpha = 1;
        self.spotifyModeButton.alpha = .2;
        [self flipController:self.audioSource to:micSource];
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
