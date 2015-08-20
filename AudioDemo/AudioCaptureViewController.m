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
#import "ContactsViewController.h"
#import "ContactManager.h"
#import "YapsViewController.h"
#import "NextButton.h"
#import "YTTrackGroup.h"

@interface AudioCaptureViewController () <YSAudioSourceControllerDelegate> {
    NSTimer *audioProgressTimer;
}
@property (strong, nonatomic) IBOutlet UIView *audioSourceContainer;
@property (nonatomic) float elapsedTime;
@property (weak, nonatomic) IBOutlet UIButton *switchButton;
@property (weak, nonatomic) IBOutlet UILabel *receiverLabel;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (strong, nonatomic) IBOutlet NextButton *continueButton;
@property (nonatomic, strong) YapBuilder *yapBuilder;
@property (weak, nonatomic) IBOutlet UILabel *bottomViewLabel;
@property (strong, nonatomic)
    IBOutlet NSLayoutConstraint *continueButtonRightConstraint;
@property (weak, nonatomic) IBOutlet YSSegmentedControlScrollView *categorySelectorContainer;

- (void)switchToSpotifyMode;
- (void)switchToMicMode;
- (IBAction)didTapNextButton;
- (IBAction)didTapCancelButton;

@end

@implementation AudioCaptureViewController

static const float MAX_CAPTURE_TIME = 12.0;
static const float TIMER_INTERVAL = .05; //.02;

- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil {
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
    self.categorySelectorContainer.control = self.categorySelectorView;
    self.navigationController.navigationBar.barTintColor = THEME_BACKGROUND_COLOR;
    [self.recordButton
        setBackgroundImage:[UIImage
                               imageNamed:@"RecordButtonBlueBorder10Pressed.png"]
                  forState:UIControlStateHighlighted];
    self.recordProgressView.progress = 0;

    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]
        initWithTarget:self
                action:@selector(tappedProgressView)];
    [self.recordProgressView addGestureRecognizer:tapGesture];

    if (self.type == AudioCaptureTypeMic) {
        [self switchToMicMode];
        self.bottomViewLabel.text = @"Send Yap";
    } else {
        [self switchToSpotifyMode];
        self.bottomViewLabel.text = @"Choose This Clip";
    }

    [self setupNotifications];

    if (IS_IPHONE_4_SIZE || IS_IPHONE_5_SIZE) {
        self.continueButtonRightConstraint.constant = -128;
    } else if (IS_IPHONE_6_SIZE) {
        self.continueButtonRightConstraint.constant = -150;
    } else if (IS_IPHONE_6_PLUS_SIZE) {
        self.continueButtonRightConstraint.constant = -170;
    }

    [self.continueButton startToPulsate];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.recordProgressView.alpha = 0;
    self.recordProgressView.progress = 0.0;

    self.bottomView.hidden = YES;
    
    self.recordProgressView.trackTintColor = [UIColor whiteColor];
    
    if (!self.categorySelectorView.items) {
        NSArray *categories = self.audioSource.availableCategories;
        NSMutableArray *items = [NSMutableArray arrayWithCapacity:categories.count];
        for (YTTrackGroup *group in categories) {
            [items addObject:[YSSegmentedControlItem itemWithTitle:group.name]];
        }
        self.categorySelectorView.items = items;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    if (audioProgressTimer) {
        [audioProgressTimer invalidate];
        NSLog(@"Audio Progress Timer Invalidate 1");
    }

    [self.audioSource stopAudioCapture];
}

- (void)addCancelButton {
    UIImage *cancelModalImage = [UIImage imageNamed:@"WhiteDownArrow2.png"];
    UIButton *cancelModalButton =
        [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
    [cancelModalButton setBackgroundImage:cancelModalImage
                                 forState:UIControlStateNormal];
    [cancelModalButton addTarget:self
                          action:@selector(cancelPressed)
                forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *cancelButton =
        [[UIBarButtonItem alloc] initWithCustomView:cancelModalButton];
    [self.navigationItem setLeftBarButtonItem:cancelButton];
}

- (BOOL)internetIsNotReachable {
    return ![AFNetworkReachabilityManager sharedManager].reachable;
}

- (void)setupNotifications {
    __weak AudioCaptureViewController *weakSelf = self;

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];

    [center addObserverForName:NOTIFICATION_LOGOUT
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                      [weakSelf.navigationController
                          popToRootViewControllerAnimated:YES];
                    }];
    /*
     [center addObserverForName:UIApplicationWillResignActiveNotification
     object:nil
     queue:nil
     usingBlock:^(NSNotification *note) {
     [audioProgressTimer invalidate];
     NSLog(@"Audio Progress Timer Invalidate 5");
     self.recordProgressView.progress = 0.0;
     [self.audioSource stopAudioCapture];
     }];
     */

    [center addObserverForName:REMOVE_BOTTOM_BANNER_NOTIFICATION
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                      self.bottomView.hidden = YES;
                      self.recordProgressView.alpha = 0;
                      self.recordProgressView.progress = 0.0;
                    }];
    [center addObserverForName:CANCEL_AUDIO_PLAYBACK object:nil queue:nil usingBlock:^(NSNotification *note) {
        [self.audioSource cancelPlayingAudio];
    }];
}

- (void)updateProgress {
    self.elapsedTime += TIMER_INTERVAL;

    [self.recordProgressView setProgress:(self.elapsedTime / MAX_CAPTURE_TIME)];

    // Added the minus .02 because otherwise the page would transition .02 seconds
    // too early
    if (self.elapsedTime - .02 >= MAX_CAPTURE_TIME) {
        [audioProgressTimer invalidate];
        NSLog(@"Audio Progress Timer Invalidate 6");
        [self.audioSource stopAudioCapture];
    }
}

/*
 - (void) timerFired
 {
 self.elapsedTime += TIME_INTERVAL;
 
 CGFloat trackLength = [self.yap.duration floatValue];
 CGFloat progress = self.elapsedTime / 12;
 [self.progressView setProgress:progress];
 
 if (self.elapsedTime >= trackLength) {
 [self stop];
 }
 }
 */

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([@"Prepare Yap For Text Segue" isEqualToString:segue.identifier]) {
        CustomizeYapViewController *addTextVC = segue.destinationViewController;

        // Create yap object
        self.yapBuilder = [self.audioSource getYapBuilder];
        self.yapBuilder.duration = self.elapsedTime;
        addTextVC.yapBuilder = self.yapBuilder;
        if (self.contactReplyingTo) {
            self.yapBuilder.contacts = @[ self.contactReplyingTo ];
        }

        self.elapsedTime = 0;

        // The following only applies to Voice Messages
    } else if ([@"Contacts Segue" isEqualToString:segue.identifier]) {
        ContactsViewController *vc = segue.destinationViewController;

        // Create yap object
        self.yapBuilder = [self.audioSource getYapBuilder];
        self.yapBuilder.duration = self.elapsedTime;
        self.yapBuilder.text = @"";
        self.yapBuilder.color = self.view.backgroundColor;
        // To get pitch value in 'cent' units, multiply self.pitchShiftValue by
        // STK_PITCHSHIFT_TRANSFORM
        self.yapBuilder.pitchValueInCentUnits = [NSNumber numberWithFloat:0];

        vc.builder = self.yapBuilder;

        if (self.contactReplyingTo) {
            self.yapBuilder.contacts = @[ self.contactReplyingTo ];
        }
    } else if ([@"YapsViewControllerSegue" isEqualToString:segue.identifier]) {
        YapsViewController *yapsVC = segue.destinationViewController;
        NSArray *pendingYaps = sender;
        yapsVC.pendingYaps = pendingYaps;
        yapsVC.comingFromContactsOrCustomizeYapPage = YES;

        self.yapBuilder = [self.audioSource getYapBuilder];
        self.yapBuilder.duration = self.elapsedTime;
        if (self.contactReplyingTo) {
            self.yapBuilder.contacts = @[ self.contactReplyingTo ];
        }
    }
}

#pragma mark - Actions

- (IBAction)segmentedControlDidChanage:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:CHANGE_CATEGORY_NOTIFICATION object:nil];
    [self.audioSource cancelPlayingAudio];
    [self.audioSource didSelectCategory:[self.audioSource availableCategories][self.categorySelectorView.selectedSegmentIndex]];
}

#pragma mark - YSAudioSourceControllerDelegate

- (void)audioSourceControllerWillStartAudioCapture:
    (YSAudioSourceController *)controller {
    NSLog(@"Will Start Audio Capture");
    [UIView animateWithDuration:.2
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                       self.recordProgressView.alpha = 1;
                     }
                     completion:nil];

    [[NSNotificationCenter defaultCenter]
        postNotificationName:WILL_START_AUDIO_CAPTURE_NOTIFICATION
                      object:nil];
}

- (void)audioSourceControllerDidStartAudioCapture:
    (YSAudioSourceController *)controller {
    NSLog(@"Did Start Audio Capture");
    self.recordProgressView.trackTintColor = [UIColor whiteColor];

    [[NSNotificationCenter defaultCenter]
        postNotificationName:DID_START_AUDIO_CAPTURE_NOTIFICATION
                      object:nil];

    self.recordProgressView.alpha = 1;
    [[NSNotificationCenter defaultCenter]
        postNotificationName:STOP_LOADING_SPINNER_NOTIFICATION
                      object:nil];
    self.elapsedTime = 0;
    [self.recordProgressView setProgress:0];

    if (audioProgressTimer) {
        [audioProgressTimer invalidate];
    }
    audioProgressTimer =
        [NSTimer scheduledTimerWithTimeInterval:TIMER_INTERVAL
                                         target:self
                                       selector:@selector(updateProgress)
                                       userInfo:nil
                                        repeats:YES];
    NSLog(@"Start Audio Progress Timer!");

    [[NSNotificationCenter defaultCenter]
        postNotificationName:AUDIO_CAPTURE_DID_START_NOTIFICATION
                      object:nil];

    self.bottomView.hidden = NO;
}

- (void)audioSourceControllerdidFinishAudioCapture:
    (YSAudioSourceController *)controller {
    [audioProgressTimer invalidate];
    [[NSNotificationCenter defaultCenter]
        postNotificationName:STOP_LOADING_SPINNER_NOTIFICATION
                      object:nil];

    if (self.elapsedTime <= CAPTURE_THRESHOLD) {
        NSLog(@"Didn't hit threshold");
        self.recordProgressView.progress = 0.0;
        [[NSNotificationCenter defaultCenter]
            postNotificationName:
                UNTAPPED_RECORD_BUTTON_BEFORE_THRESHOLD_NOTIFICATION
                          object:nil];
        [UIView animateWithDuration:.1
                              delay:0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                           self.recordProgressView.alpha = 0;
                         }
                         completion:nil];
        if (self.type == AudioCaptureTypeMic) {
            double delay = .1;
            dispatch_after(
                dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)),
                dispatch_get_main_queue(), ^{
                  [[YTNotifications sharedNotifications]
                      showNotificationText:@"Keep Holding"];
                });
        }
    } else {
        NSLog(@"Hit threshold");
        [[NSNotificationCenter defaultCenter]
            postNotificationName:LISTENED_TO_CLIP_NOTIFICATION
                          object:nil];

        if (self.type == AudioCapTureTypeSpotify) {
            self.recordProgressView.progress = 1.0; // DEFAULT EVERY YAP TO 12 SECONDS
        }
        self.recordProgressView.trackTintColor =
            [UIColor colorWithWhite:0.85
                              alpha:1.0];
    }

    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Untapped Record Button"];
}

- (void)audioSourceController:(YSAudioSourceController *)controller
   didReceieveUnexpectedError:(NSError *)error {
    //[self.recordProgressView.activityIndicator stopAnimating];
    [[NSNotificationCenter defaultCenter]
        postNotificationName:STOP_LOADING_SPINNER_NOTIFICATION
                      object:nil];
    double delay = .1;
    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)),
        dispatch_get_main_queue(), ^{
          [[YTNotifications sharedNotifications]
              showNotificationText:@"Oops, Something Went Wrong!"];
        });
    [self.recordProgressView setProgress:0];
    self.elapsedTime = 0;
    [audioProgressTimer invalidate];
    NSLog(@"Audio Progress Timer Invalidate 3");
}

- (void)audioSourceControllerdidCancelAudioCapture:(YSAudioSourceController *)controller {
    self.elapsedTime = 0;
    self.bottomView.hidden = YES;
    self.recordProgressView.alpha = 0;
    [self.recordProgressView setProgress:0];
    self.recordProgressView.trackTintColor = [UIColor whiteColor];
    [[NSNotificationCenter defaultCenter] postNotificationName:RESET_BANNER_UI
                                                        object:nil];
}

#pragma mark - Audio Capture Search

- (void)clearSearchResults {
    [self.audioSource clearSearchResults];
}

- (void)searchWithText:(NSString *)text {
    [self.audioSource searchWithText:text];
}

#pragma mark - Bottom View
- (IBAction)didTapNextButton {
    if (self.type == AudioCapTureTypeSpotify) {
        [self performSegueWithIdentifier:@"Prepare Yap For Text Segue" sender:nil];
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel track:@"Tapped Choose Clip"];
    } else if (self.type == AudioCaptureTypeMic) {
        if (self.contactReplyingTo) {
            // Create yap object
            self.yapBuilder = [self.audioSource getYapBuilder];
            self.yapBuilder.duration = self.elapsedTime;
            self.yapBuilder.pitchValueInCentUnits = [NSNumber numberWithFloat:0];
            self.yapBuilder.color = self.view.backgroundColor;
            self.yapBuilder.contacts = @[ self.contactReplyingTo ];

            NSLog(@"sendYapBuilder Triggered");
            NSArray *pendingYaps =
                [[API sharedAPI] sendYapBuilder:self.yapBuilder
                                   withCallback:^(BOOL success, NSError *error) {
                                     if (success) {
                                         [[ContactManager sharedContactManager]
                                             sentYapTo:self.yapBuilder.contacts];
                                     } else {
                                         NSLog(@"Error Sending Yap: %@", error);
                                         // uh oh spaghettios
                                         // TODO: tell the user something went wrong
                                     }
                                   }];
            NSLog(@"Sent yaps call");

            [self performSegueWithIdentifier:@"YapsViewControllerSegue"
                                      sender:pendingYaps];
        } else {
            [self performSegueWithIdentifier:@"Contacts Segue" sender:nil];
        }
    }
}

- (IBAction)didTapCancelButton {
    [self.audioSource cancelPlayingAudio];
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Tapped Cancel Clip"];
}

#pragma mark - Mode Changing

- (void)switchToSpotifyMode {
    self.type = AudioCapTureTypeSpotify;
    [self.switchButton setImage:[UIImage imageNamed:@"MicrophoneButton.png"]
                       forState:UIControlStateNormal];
    YSSpotifySourceController *spotifySource = [self.storyboard
        instantiateViewControllerWithIdentifier:@"SpotifySourceController"];
    [self setRecordSourceViewController:spotifySource];
}

- (void)switchToMicMode {
    //[self.switchButton setTitle:@"Music" forState:UIControlStateNormal];
    [self.switchButton setImage:[UIImage imageNamed:@"MusicButton.png"]
                       forState:UIControlStateNormal];
    self.type = AudioCaptureTypeMic;
    YSMicSourceController *micSource = [self.storyboard
        instantiateViewControllerWithIdentifier:@"MicSourceController"];
    [self setRecordSourceViewController:micSource];
}

- (void)setRecordSourceViewController:(YSAudioSourceController *)to {
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