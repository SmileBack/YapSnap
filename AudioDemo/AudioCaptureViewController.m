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
#import "YSMoodGroupViewController.h"
#import "YSGenreGroupViewController.h"
#import "YSAudioSourceNavigationController.h"
#import "YSRecentSourceController.h"
#import "YSSelectSongViewController.h"

@interface AudioCaptureViewController () <YSAudioSourceControllerDelegate, UINavigationControllerDelegate> {
    NSTimer *audioProgressTimer;
}
@property (strong, nonatomic) IBOutlet UIView *audioSourceContainer;
@property (nonatomic) NSTimeInterval elapsedTime;
@property (weak, nonatomic) IBOutlet UILabel *receiverLabel;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (strong, nonatomic) IBOutlet NextButton *continueButton;
@property (nonatomic, strong) YapBuilder *yapBuilder;
@property (weak, nonatomic) IBOutlet UILabel *bottomViewLabel;
@property (weak, nonatomic) IBOutlet UILabel *songNameLabel;
@property (strong, nonatomic)
    IBOutlet NSLayoutConstraint *continueButtonRightConstraint;
@property (weak, nonatomic) IBOutlet YSSegmentedControlScrollView *categorySelectorContainer;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomBarBottomConstraint;
@property (strong, nonatomic) NSArray *audioSourceNames;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *categoryBarWidthConstraint;

- (IBAction)didTapNextButton;
- (IBAction)didTapCancelButton;

@end

@implementation AudioCaptureViewController

static const NSTimeInterval MAX_CAPTURE_TIME = 15.0;
static const NSTimeInterval TIMER_INTERVAL = .05; //.02;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = THEME_BACKGROUND_COLOR;
    self.audioSourceNames = @[@"Recent", @"Trending", @"Moods", @"Genres", @"Library"];
    
    self.categorySelectorContainer.control = self.categorySelectorView;
    self.navigationController.navigationBar.barTintColor = THEME_BACKGROUND_COLOR;
    [self.recordButton
        setBackgroundImage:[UIImage
                               imageNamed:@"RecordButtonBlueBorder10Pressed.png"]
                  forState:UIControlStateHighlighted];

    self.audioSource = [[YSSpotifySourceController alloc] init];
    self.bottomViewLabel.text = @"Send This Clip";
    
    [self setupNotifications];
    if (IS_IPHONE_4_SIZE || IS_IPHONE_5_SIZE) {
        self.continueButtonRightConstraint.constant = -128;
        self.categoryBarWidthConstraint.constant = 365;
    } else if (IS_IPHONE_6_SIZE) {
        self.continueButtonRightConstraint.constant = -150;
        self.categoryBarWidthConstraint.constant = 375;
    } else if (IS_IPHONE_6_PLUS_SIZE) {
        self.continueButtonRightConstraint.constant = -170;
        self.categoryBarWidthConstraint.constant = 414;
    }

    [self.continueButton startToPulsate];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setBottomBarVisible:NO animated:NO];
    
    if (!self.categorySelectorView.items) {
        NSArray *categories = self.audioSourceNames;
        NSMutableArray *items = [NSMutableArray arrayWithCapacity:categories.count];
        for (NSString *name in categories) {
            [items addObject:[YSSegmentedControlItem itemWithTitle:name]];
        }
        self.categorySelectorView.items = items;
        self.categorySelectorView.selectedSegmentIndex = 1;
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
    [center addObserverForName:CANCEL_AUDIO_PLAYBACK object:nil queue:nil usingBlock:^(NSNotification *note) {
        [self.audioSource cancelPlayingAudio];
    }];
    
    [center addObserverForName:UIApplicationWillResignActiveNotification
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                        [self.audioSource cancelPlayingAudio];
                        [self audioSourceControllerdidCancelAudioCapture:self.audioSource];
                    }];
    
    // This is a hack
    [center addObserverForName:HIDE_BOTTOM_BAR_NOTIFICATION
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                        [self setBottomBarVisible:NO animated:NO];
                    }];
}

- (void)updateProgress {
    self.elapsedTime += TIMER_INTERVAL;

    [self.audioSource updatePlaybackProgress:fabs(ceil(MAX_CAPTURE_TIME - self.elapsedTime))]; //fabs needed because this can funkily get rounded to
    // Added the minus .02 because otherwise the page would transition .02 seconds
    // too early
    if (self.elapsedTime - .02 >= MAX_CAPTURE_TIME) {
        [audioProgressTimer invalidate];
        NSLog(@"Audio Progress Timer Invalidate 6");
        [self.audioSource stopAudioCapture];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([@"Prepare Yap For Text Segue" isEqualToString:segue.identifier]) {
        CustomizeYapViewController *addTextVC = segue.destinationViewController;

        // Create yap object
        self.yapBuilder = [self.audioSource getYapBuilder];
        self.yapBuilder.duration = 15;//12;//self.elapsedTime;
        if (self.contactReplyingTo) {
            self.yapBuilder.contacts = @[ self.contactReplyingTo ];
        }
        addTextVC.yapBuilder = self.yapBuilder;
        self.elapsedTime = 0;
    } else if ([@"Contacts Segue" isEqualToString:segue.identifier]) {
        ContactsViewController *vc = segue.destinationViewController;

        // Create yap object
        self.yapBuilder = [self.audioSource getYapBuilder];
        self.yapBuilder.duration = 15;//12;//self.elapsedTime;
        self.yapBuilder.text = @"";
        self.yapBuilder.color = self.view.backgroundColor;
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
        self.yapBuilder.duration = 15;//12;//self.elapsedTime;
        if (self.contactReplyingTo) {
            self.yapBuilder.contacts = @[ self.contactReplyingTo ];
        }
    }
}

#pragma mark - Actions

- (void)setBottomBarVisible:(BOOL)visible {
    [self setBottomBarVisible:visible animated:YES];
}

- (void)setBottomBarVisible:(BOOL)visible animated:(BOOL)animated {
    [self.view layoutIfNeeded];
    self.bottomBarBottomConstraint.constant = visible ? 0 : CGRectGetHeight(self.bottomView.frame);
    self.songNameLabel.text = [self.audioSource currentAudioDescription];
    [UIView animateWithDuration:animated ? 0.3 : 0 animations:^{
        [self.view layoutIfNeeded];
    }];
}
- (IBAction)didTapSegmentedControl:(id)sender {
    if ([self.audioSource isKindOfClass:[UINavigationController class]]) {
        UINavigationController *nc = (UINavigationController *)self.audioSource;
        [nc popToRootViewControllerAnimated:YES];
    }
}

- (IBAction)segmentedControlDidChanage:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:CHANGE_CATEGORY_NOTIFICATION object:nil];
    [self.audioSource cancelPlayingAudio];
    id<YSAudioSource> audioSource = nil;
    switch (self.categorySelectorView.selectedSegmentIndex) {
        case 0:
            audioSource = [[YSRecentSourceController alloc] init];
            break;
        case 1:
            audioSource = [[YSSpotifySourceController alloc] init];
            break;
        case 2:
        {
            YSAudioSourceNavigationController *nc = [[YSAudioSourceNavigationController alloc]  initWithRootViewController:[[YSMoodGroupViewController alloc] init]];
            if ([self.parentViewController conformsToProtocol:@protocol(UINavigationControllerDelegate)]) {
                nc.delegate = (id<UINavigationControllerDelegate>)self.parentViewController;
            }
            audioSource = nc;
        }
            break;
        case 3:
        {
            YSAudioSourceNavigationController *nc = [[YSAudioSourceNavigationController alloc]  initWithRootViewController:[[YSGenreGroupViewController alloc] init]];
            if ([self.parentViewController conformsToProtocol:@protocol(UINavigationControllerDelegate)]) {
                nc.delegate = (id<UINavigationControllerDelegate>)self.parentViewController;
            }
            audioSource = nc;
        }
            break;
        case 4:
        {
            YSAudioSourceNavigationController *nc = [[YSAudioSourceNavigationController alloc]  initWithRootViewController:[[YSSelectSongViewController alloc] init]];
            if ([self.parentViewController conformsToProtocol:@protocol(UINavigationControllerDelegate)]) {
                nc.delegate = (id<UINavigationControllerDelegate>)self.parentViewController;
            }
            audioSource = nc;
            break;
        }
        default:
            NSAssert(false, @"index out of bounds on scroll bar");
            break;
    }
    // HAACKKKKKK: cancelPlayingAudio is ASYNC, but doesn't have a callback. The lib we're using needs to do that, but in the mean time, dispatch this async.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.audioSource = audioSource;
    });
}

#pragma mark - YSAudioSourceControllerDelegate

- (void)audioSourceControllerWillStartAudioCapture:
    (id<YSAudioSource>)controller {
    NSLog(@"Will Start Audio Capture");
    [[NSNotificationCenter defaultCenter]
        postNotificationName:WILL_START_AUDIO_CAPTURE_NOTIFICATION
                      object:nil];
    [self setBottomBarVisible:YES];
}

- (void)audioSourceControllerDidStartAudioCapture:
    (id<YSAudioSource>)controller {
    NSLog(@"Did Start Audio Capture");
    [[NSNotificationCenter defaultCenter]
        postNotificationName:DID_START_AUDIO_CAPTURE_NOTIFICATION
                      object:nil];

    [[NSNotificationCenter defaultCenter]
        postNotificationName:STOP_LOADING_SPINNER_NOTIFICATION
                      object:nil];
    self.elapsedTime = 0;

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
}

- (void)audioSourceControllerdidFinishAudioCapture:
    (id<YSAudioSource>)controller {
    [audioProgressTimer invalidate];
    [[NSNotificationCenter defaultCenter]
        postNotificationName:STOP_LOADING_SPINNER_NOTIFICATION
                      object:nil];

    if (self.elapsedTime <= CAPTURE_THRESHOLD) {
        NSLog(@"Didn't hit threshold");
        [[NSNotificationCenter defaultCenter]
            postNotificationName:
                UNTAPPED_RECORD_BUTTON_BEFORE_THRESHOLD_NOTIFICATION
                          object:nil];
    } else {
        NSLog(@"Hit threshold");
        [[NSNotificationCenter defaultCenter]
            postNotificationName:LISTENED_TO_CLIP_NOTIFICATION
                          object:nil];
    }

    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Untapped Record Button"];
}

- (void)audioSourceController:(id<YSAudioSource>)controller
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
    self.elapsedTime = 0;
    [audioProgressTimer invalidate];
    NSLog(@"Audio Progress Timer Invalidate 3");
}

- (void)audioSourceControllerdidCancelAudioCapture:(id<YSAudioSource>)controller {
    self.elapsedTime = 0;
    [self setBottomBarVisible:NO];
    [[NSNotificationCenter defaultCenter] postNotificationName:RESET_BANNER_UI
                                                        object:nil];
}

#pragma mark - Audio Capture Search

- (void)clearSearchResults {
    [self.audioSource clearSearchResults];
}

- (void)searchWithText:(NSString *)text {
    [self setAudioSource:[[YSSpotifySourceController alloc] init]];
    [self.audioSource searchWithText:text];
}

#pragma mark - Bottom View
- (IBAction)didTapNextButton {
    [self.audioSource prepareYapBuilder];
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Tapped Choose Clip"];
}

- (void)audioSourceControllerIsReadyToProduceYapBuidler:(id<YSAudioSource>)controller {
    [self performSegueWithIdentifier:@"Prepare Yap For Text Segue" sender:nil];
}

- (IBAction)didTapCancelButton {
    [self.audioSource cancelPlayingAudio];
    [self audioSourceControllerdidCancelAudioCapture:self.audioSource];
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Tapped Cancel Clip"];
}

#pragma mark - Mode Changing

- (void)setAudioSource:(id<YSAudioSource>)to {
    if ([to isKindOfClass:[UIViewController class]]) {
        UIViewController *toVC = (UIViewController *)to;
        UIViewController *fromVC = (UIViewController *)_audioSource;
        _audioSource = to;
        if (to) {
            [fromVC.view removeFromSuperview];
            [fromVC removeFromParentViewController];
            to.audioCaptureDelegate = self;
            [self addChildViewController:toVC];
            toVC.view.frame = self.audioSourceContainer.bounds;
            [self.audioSourceContainer addSubview:toVC.view];
            [toVC didMoveToParentViewController:self];
        }
    }
}

@end