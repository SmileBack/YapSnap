//
//  MusicPlaybackVC.m
//  YapSnap
//
//  Created by Jon Deokule on 12/24/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import "PlaybackVC.h"
#import "API.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <AVFoundation/AVAudioSession.h>
#import "YSRecordProgressView.h"
#import "SpotifyAPI.h"
#import "OpenInSpotifyAlertView.h"
#import "Flurry.h"


@interface PlaybackVC ()  {
    NSTimer *countdownTimer;
    int currMinute;
    int currSeconds;
}

@property (strong, nonatomic) IBOutlet YSRecordProgressView *progressView;
@property (strong, nonatomic) STKAudioPlayer *player;
@property (strong, nonatomic) NSTimer *timer;
@property (nonatomic) CGFloat elapsedTime;
@property (nonatomic) CGFloat trackLength;
@property (nonatomic) CGFloat progressViewRemainderWidth;
@property (strong, nonatomic) IBOutlet UITextView *textView;
@property (strong, nonatomic) UIView *progressViewRemainder;
@property (strong, nonatomic) IBOutlet UIImageView *yapPhoto;
@property (nonatomic) BOOL playerAlreadyStartedPlayingForThisSong;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UIImageView *albumImage;
@property IBOutlet UIActivityIndicatorView* activityIndicator;
@property IBOutlet UIActivityIndicatorView* friendRequestActivityIndicator;
@property (nonatomic) BOOL audioHasBegun;
@property (strong, nonatomic) IBOutlet UILabel *albumLabel;

@property (weak, nonatomic) IBOutlet UIButton *forwardButton;
@property (weak, nonatomic) IBOutlet UIButton *replyButton;
@property (weak, nonatomic) IBOutlet UIButton *sendTextButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;

@property (weak, nonatomic) IBOutlet UIButton *replayButton;
@property (weak, nonatomic) IBOutlet UIButton *spotifyButton;
@property (weak, nonatomic) IBOutlet UIButton *friendRequestButton;
@property (weak, nonatomic) IBOutlet UIButton *createOwnYapButton;

@property (strong, nonatomic) IBOutlet UILabel *countdownTimerLabel;
@property (strong, nonatomic) IBOutlet UILabel *listenCountLabel;

@property (nonatomic) BOOL acceptedFriendRequest;

// nil means we don't know yet. YES/NO means the backend told us.
@property (nonatomic, strong) NSNumber *isFromFriend;

- (IBAction)didTapReplayButton;
- (IBAction)didTapSpotifyButton;
- (IBAction)didTapFriendRequestButton;
- (IBAction)didTapCreateOwnYapButton;

@end

#define TIME_INTERVAL .05f

@implementation PlaybackVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupNotifications];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Viewed Playback Page"];
    [Flurry logEvent:@"Viewed Playback Page"];
    
    self.replyButton.backgroundColor = [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0.0/255.0 alpha:0.5f];
    self.sendTextButton.backgroundColor = [UIColor colorWithRed:0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:0.5f];
    self.friendRequestButton.backgroundColor = THEME_BACKGROUND_COLOR;
    
    if (self.yap.sentByCurrentUser) {
        if ([self.yap.receiverPhone isEqualToString:@"+13245678910"] || [self.yap.receiverPhone isEqualToString:@"+13027865701"]) {
            self.titleLabel.text = @"Sent to YapTap Team";
            [self.replyButton setTitle:@"Send Another Yap" forState:UIControlStateNormal];
        } else {
            [self.replyButton setTitle:@"Yap Reply"/*[NSString stringWithFormat:@"Send %@ Another Yap", receiverFirstName]*/ forState:UIControlStateNormal];
            [self.sendTextButton setTitle:@"Text Reply" forState:UIControlStateNormal];
        }
        
        if (self.yap.isFriendRequest) {
            self.forwardButton.hidden = YES; // we should just not show these yaps
        }
    } else if (self.yap.receivedByCurrentUser) {
        if (self.yap.isFriendRequest) {
            self.forwardButton.hidden = YES;
            [self.replyButton setTitle:@"Yap Reply" forState:UIControlStateNormal];
            [self.sendTextButton setTitle:@"Text Reply" forState:UIControlStateNormal];
            NSLog(@"Yap status: %@", self.yap.status);
            if ([self.yap.status isEqualToString:@"unopened"]) {
                self.friendRequestButton.hidden = NO;
            }
        }
        
        if ([self.yap.senderPhone isEqualToString:@"+13245678910"]) {
            self.cancelButton.hidden = YES;
            self.replyButton.hidden = YES;
            self.sendTextButton.hidden = YES;
            self.createOwnYapButton.hidden = NO;
        }
    }
    
    if (self.yap.isPublic) {
        self.sendTextButton.hidden = YES;
        self.replyButton.hidden = YES;
        self.listenCountLabel.hidden = NO;
        self.listenCountLabel.text = [NSString stringWithFormat:@"Listen Count: %@", self.yap.playCount];
    }
    
    self.player = [STKAudioPlayer new];
    self.player.delegate = self;
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:nil];
    
    [self handleImageAndPlayAudio];
    
    [self.activityIndicator startAnimating];
    
    self.textView.text = self.yap.text;
    
    if ([self.textView.text length] == 0) {
        self.textView.hidden = YES;
    } else {
        self.textView.hidden = NO;
    }
    
    self.textView.textContainer.maximumNumberOfLines = 6;
    self.textView.textContainer.lineBreakMode = NSLineBreakByTruncatingTail;
    
    self.view.backgroundColor = THEME_BACKGROUND_COLOR;
    
    float volume = [[AVAudioSession sharedInstance] outputVolume];
    if (volume < 0.5) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[YTNotifications sharedNotifications] showBlueNotificationText:@"Turn Up The Volume!"];
            Mixpanel *mixpanel = [Mixpanel sharedInstance];
            [mixpanel track:@"Volume Notification - PlayBack"];
        });
    }
    
    if (([self.yap.type isEqual:@"SpotifyMessage"] || [self.yap.type isEqual:@"UploadedMessage"]) && self.yap.albumImageURL && ![self.yap.albumImageURL isEqual: [NSNull null]]) {
        [self.albumImage sd_setImageWithURL:[NSURL URLWithString:self.yap.albumImageURL]completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            if (cacheType == SDImageCacheTypeDisk) {
                NSLog(@"Album Photo from disk");
            } else if (cacheType == SDImageCacheTypeMemory) {
                NSLog(@"Album Photo from memory");
            } else {
                NSLog(@"Album Photo from web");
            }
        }];
        
        UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        UIVisualEffectView *effectView = [[UIVisualEffectView alloc]initWithEffect:blur];
        effectView.frame =  CGRectMake(0, 0, 2208, 2208); // 2208 is as big as iphone plus height
        
        [self.albumImage addSubview:effectView];
        
        
    } else if ([self.yap.type isEqual:@"VoiceMessage"]) {
        [self.albumImage setImage:[UIImage imageNamed:@"YapTapCartoonLarge2.png"]];
    }
    
    [self addShadowToTextView];
    
    [self styleActionButtons];
    
    self.isFromFriend = [NSNumber numberWithInt:1]; // We are setting self.isFromFriend.boolValue to True so that friends popup doesn't come up if you press the X before back end response comes in. It'll get updated to the correct value once back end response comes in
    
    // CHECK IF SONG CAN BE FORWARDED TO SPOTIFY
    if (self.yap.spotifyID && ![self.yap.spotifyID isEqual: [NSNull null]] && ([self.yap.spotifyID length] > 10)) {
        self.spotifyButton.hidden = NO;
    } else {
        //self.spotifyButton.hidden = YES;
    }
    
    if ([self.yap.type isEqual:@"SpotifyMessage"] || [self.yap.type isEqual:@"UploadedMessage"]) {
        self.albumLabel.text = [NSString stringWithFormat:@"%@, by %@", self.yap.songName, self.yap.artist];
    } else {
        self.albumLabel.text = [NSString stringWithFormat:@"by %@", self.yap.senderName];
    }
    
    self.albumLabel.adjustsFontSizeToFitWidth = NO;
    self.albumLabel.opaque = YES;
    self.albumLabel.backgroundColor = [UIColor clearColor];
    self.albumLabel.shadowColor = [UIColor blackColor];
    self.albumLabel.shadowOffset = CGSizeMake(.5, .5);
    self.albumLabel.layer.masksToBounds = NO;
    
    if (IS_IPHONE_4_SIZE) {
        self.textView.font = [UIFont fontWithName:@"Futura-Medium" size:32];
    } else if (IS_IPHONE_6_PLUS_SIZE) {
        self.textView.font = [UIFont fontWithName:@"Futura-Medium" size:45];
        //self.textViewHeightConstraint.constant = 320;
    } else if (IS_IPHONE_6_SIZE) {
        self.textView.font = [UIFont fontWithName:@"Futura-Medium" size:40];
    } else if (IS_IPHONE_5_SIZE) {
        self.textView.font = [UIFont fontWithName:@"Futura-Medium" size:34];
    }
    
    self.acceptedFriendRequest = NO;
}

- (void) styleActionButtons {
     self.replyButton.layer.cornerRadius = 4;
     self.replyButton.layer.borderWidth = 1;
     self.replyButton.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.7].CGColor;
    
    self.forwardButton.layer.cornerRadius = 4;
    self.forwardButton.layer.borderWidth = 1;
    self.forwardButton.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.7].CGColor;
    
    self.friendRequestButton.layer.cornerRadius = 4;
    self.friendRequestButton.layer.borderWidth = 1;
    self.friendRequestButton.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.7].CGColor;
    
    self.sendTextButton.layer.cornerRadius = 4;
    self.sendTextButton.layer.borderWidth = 1;
    self.sendTextButton.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.7].CGColor;
    
    self.createOwnYapButton.layer.cornerRadius = 4;
    self.createOwnYapButton.layer.borderWidth = 1;
    self.createOwnYapButton.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.7].CGColor;
}

- (void) handleImageAndPlayAudio
{
    __weak PlaybackVC *weakSelf = self;
    if (self.yap.yapPhotoURL && ![self.yap.yapPhotoURL isEqual: [NSNull null]]) {
        [self addShadowToTextView];
        self.yapPhoto.layer.borderWidth = 1;
        self.yapPhoto.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:1.0].CGColor;
        self.yapPhoto.clipsToBounds = YES;
        [self.yapPhoto sd_setImageWithURL:[NSURL URLWithString:self.yap.yapPhotoURL] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            if (cacheType == SDImageCacheTypeDisk) {
                NSLog(@"Photo from disk");
            } else if (cacheType == SDImageCacheTypeMemory) {
                NSLog(@"Photo from memory");
            } else {
                NSLog(@"Photo from web");
            }
            [weakSelf playYapAudio];
        }];
    } else {
        [self playYapAudio];
    }
}

- (void) playYapAudio
{
    NSDictionary *headers = [[SpotifyAPI sharedApi] getAuthorizationHeaders];
    NSLog(@"Playing URL: %@ %@ auth token", self.yap.playbackURL, headers ? @"with" : @"without");
    //if (headers && [self.yap.type isEqualToString:MESSAGE_TYPE_SPOTIFY]) {
    // Check if preview url is spotify song
    if (headers && [self.yap.track.previewURL containsString:@"scdn"]) {
        [self.player play:self.yap.playbackURL withHeaders:headers];
    } else {
        [self.player play:self.yap.playbackURL];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [UIView animateWithDuration:.1
                          delay:.9
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.volumeView.alpha = .6;
                     }
                     completion:nil];
    
    // set self.playerAlreadyStartedPlayingForThisSong to False!
    self.playerAlreadyStartedPlayingForThisSong = NO;
    NSLog(@"Set playerAlreadyStartedPlayingForThisSong to FALSE");
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (countdownTimer) {
        [countdownTimer invalidate];
    }
    
    [self stop];
}

-(void) startCountdownTimer
{
    NSLog(@"Start Countdown Timer");
    [countdownTimer invalidate];
    countdownTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(countdownTimerFired) userInfo:nil repeats:YES];
}

-(void) countdownTimerFired
{
    //NSLog(@"countdownTimer fired");
    //NSLog(@"currMinute: %d; currSeconds: %d", currMinute, currSeconds);
    if((currMinute>0 || currSeconds>=0) && currMinute>=0)
    {
        if(currSeconds>0)
        {
            //      NSLog(@"currSeconds: %d", currSeconds);
            currSeconds-=1;
        }
        
        self.countdownTimerLabel.text = [NSString stringWithFormat:@"%d",currSeconds];
    }
    else
    {
        NSLog(@"countdownTimer invalidate");
        [countdownTimer invalidate];
    }
}

- (void) showAndStartTimer {
    self.countdownTimerLabel.alpha = 1;
    self.countdownTimerLabel.text = @"15";//@"12";
    currSeconds=15;//12;
    [self startCountdownTimer];
}

#pragma mark - Actions

- (IBAction)didTapCancelButton:(id)sender {
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Tapped Cancel PlayBack"];
    [self dismissThis];
}

- (IBAction)didTapSendText:(id)sender {
    [self dismissThis];
    [self.yapCreatingDelegate didOriginateReplyFromYapSameClip:self.yap];
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Tapped Reply Text (from Playback)"];
    [Flurry logEvent:@"Tapped Reply Text (from Playback)"];
}

- (IBAction)didTapReply:(id)sender {
    
    if (self.yap.isFriendRequest) {
        [self dismissThis];
        [self.yapCreatingDelegate didOriginateReplyFromYapNewClip:self.yap];
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel track:@"Sent Yap From Friend Request"];
    } else if (self.yap.receivedByCurrentUser) {
        [self dismissThis];
        [self.yapCreatingDelegate didOriginateReplyFromYapNewClip:self.yap];
        NSString *senderFirstName = [[self.yap.displaySenderName componentsSeparatedByString:@" "] objectAtIndex:0];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[YTNotifications sharedNotifications] showNotificationText:[NSString stringWithFormat:@"Replying to %@", senderFirstName]];
        });
    } else {
        [self dismissThis];
        [self.yapCreatingDelegate didOriginateReplyFromYapNewClip:self.yap];
        NSString *receiverFirstName = [[self.yap.displayReceiverName componentsSeparatedByString:@" "] objectAtIndex:0];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[YTNotifications sharedNotifications] showNotificationText:[NSString stringWithFormat:@"Replying to %@", receiverFirstName]];
        });
    }
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Tapped Reply (from Playback)"];
    [Flurry logEvent:@"Tapped Reply (from Playback)"];
}

- (IBAction)didTapForward:(id)sender {
    [self dismissThis];
    [self.yapCreatingDelegate didOriginateForwardFromYap:self.yap];
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Tapped Forward (from Playback)"];
}

- (void) stop
{
    NSLog(@"Stopping");
    [self.timer invalidate];
    [self.player stop];
}

- (void) setupNotifications
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserverForName:UIApplicationWillResignActiveNotification
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                        [self stop];
                    }];
}

- (void) dismissThis
{
    [self dismissViewControllerAnimated:NO completion:nil];
    
    if (!self.isFromFriend.boolValue && self.audioHasBegun) {
        __weak YSYap *weakYap = self.yap;
        if (self.strangerCallback) {
            self.strangerCallback(weakYap);
        }
        self.isFromFriend = [NSNumber numberWithInt:1]; // We are setting self.isFromFriend.boolValue to True so that the same code isn't triggered when user dismisses the page
    }
}

#pragma mark - Progress Stuff
- (void) timerFired
{
    self.elapsedTime += TIME_INTERVAL;
    self.trackLength = 15;//12;
    CGFloat progress = self.elapsedTime / self.trackLength;
    [self.progressView setProgress:progress];
    
    if (self.elapsedTime >= self.trackLength) {
        [self stop];
    }
}

#pragma mark - STKAudioPlayerDelegate
-(void) audioPlayer:(STKAudioPlayer*)audioPlayer stateChanged:(STKAudioPlayerState)state previousState:(STKAudioPlayerState)previousState
{
    if (state == STKAudioPlayerStatePlaying) {
        NSLog(@"state == STKAudioPlayerStatePlaying");
        
        if (!self.playerAlreadyStartedPlayingForThisSong) {
            [self showAndStartTimer];
            
            //self.countdownTimerLabel.hidden = NO;
            
            NSLog(@"Seconds to Fast Forward: %d", self.yap.secondsToFastForward.intValue);
            
            if (self.yap.secondsToFastForward.intValue > 0) {
                [audioPlayer seekToTime:self.yap.secondsToFastForward.intValue];
            }
            
            self.elapsedTime = 0.0f;
            self.timer = [NSTimer scheduledTimerWithTimeInterval:TIME_INTERVAL
                                                          target:self
                                                        selector:@selector(timerFired)
                                                        userInfo:nil
                                                         repeats:YES];
            [self.activityIndicator stopAnimating];
            [UIView animateWithDuration:0.3
                                  delay:0
                                options:UIViewAnimationOptionCurveEaseOut
                             animations:^{
                                 self.titleLabel.alpha = 1;
                             }
                             completion:nil];
            
            
            if ([self.yap.type isEqual:@"VoiceMessage"]) {
                CGFloat width = self.view.frame.size.width;
                //self.progressViewRemainderWidth = (12 - [self.yap.duration floatValue]) * width/12;
                self.progressViewRemainderWidth = (15 - [self.yap.duration floatValue]) * width/15;
            } else {
                // DEFAULT TO 12 SECONDS
                self.progressViewRemainderWidth = 0;
            }
            
            self.progressViewRemainder = [[UIView alloc] init];
            [self.view addSubview:self.progressViewRemainder];
            [self.progressViewRemainder setTranslatesAutoresizingMaskIntoConstraints:NO];
            
            [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.progressViewRemainder attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.progressView attribute:NSLayoutAttributeHeight multiplier:1.0 constant:-1.0]];
            [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.progressViewRemainder attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.progressView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
            [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.progressViewRemainder attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.progressView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.5]];
            [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.progressViewRemainder attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:self.progressViewRemainderWidth]];
            self.progressViewRemainder.backgroundColor = [UIColor lightGrayColor];
            self.progressViewRemainder.alpha = 0;
            
            [UIView animateWithDuration:0.4
                                  delay:0
                                options:UIViewAnimationOptionCurveEaseOut
                             animations:^{
                                 self.progressViewRemainder.alpha = 1;
                             }
                             completion:nil];
            
            Mixpanel *mixpanel = [Mixpanel sharedInstance];
            [mixpanel track:@"Opened Yap"];
            [mixpanel.people increment:@"Opened Yap #" by:[NSNumber numberWithInt:1]];
            [Flurry logEvent:@"Opened Yap"];
            
            if (self.yap.receivedByCurrentUser) {
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:OPENED_YAP_FOR_FIRST_TIME_KEY];
                [[API sharedAPI] updateYapStatus:self.yap toStatus:@"opened" withCallback:^(BOOL success, NSError *error, NSNumber *isFriend) {
                    if (success) {
                        self.isFromFriend = isFriend;
                    }
                }];
            }
            
            // set self.playerAlreadyStartedPlayingForThisSong to True!
            self.playerAlreadyStartedPlayingForThisSong = YES;
            NSLog(@"Set playerAlreadyStartedPlayingForThisSong to TRUE");
            
            // This is a hack so that if user cancels page before audio begins, they will not see the friend request popup
            self.audioHasBegun = YES;
        }
    }
    
    if (state == STKAudioPlayerStateStopped) {
        NSLog(@"state == STKAudioPlayerStateStopped");
        self.countdownTimerLabel.hidden = YES;
        [self.timer invalidate];
        self.timer = nil;
        [self.activityIndicator stopAnimating];
        [[NSNotificationCenter defaultCenter] postNotificationName:PLAYBACK_STOPPED_NOTIFICATION object:nil]; //Not currently used
        
        // set self.playerAlreadyStartedPlayingForThisSong to FALSE!
        self.playerAlreadyStartedPlayingForThisSong = NO;
        NSLog(@"Set playerAlreadyStartedPlayingForThisSong to FALSE");
    }
    
    if (state == STKAudioPlayerStateBuffering && previousState == STKAudioPlayerStatePlaying) {
        NSLog(@"state changed from playing to buffering");
    }
    
    if (state == STKAudioPlayerStateReady) {
        NSLog(@"state == STKAudioPlayerStateReady");
    }
    
    if (state == STKAudioPlayerStateRunning) {
        NSLog(@"state == STKAudioPlayerStateRunning");
    }
    
    if (state == STKAudioPlayerStateBuffering) {
        NSLog(@"state == STKAudioPlayerStateBuffering");
        if (self.playerAlreadyStartedPlayingForThisSong) {
            NSLog(@"Buffering for second time!");
            [[YTNotifications sharedNotifications] showBufferingText:@"Buffering..."];
            Mixpanel *mixpanel = [Mixpanel sharedInstance];
            [mixpanel track:@"Buffering notification - PlayBack"];
        }
    }
    
    if (state == STKAudioPlayerStatePaused) {
        NSLog(@"state == STKAudioPlayerStatePaused");
    }
    
    if (state == STKAudioPlayerStateError) {
        NSLog(@"state == STKAudioPlayerStateError");
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel track:@"Player State Error - PlayBack"];
    }
    
    if (state == STKAudioPlayerStateDisposed) {
        NSLog(@"state == STKAudioPlayerStateDisposed");
    }
}

/// Raised when an item has finished buffering (may or may not be the currently playing item)
/// This event may be raised multiple times for the same item if seek is invoked on the player
-(void) audioPlayer:(STKAudioPlayer*)audioPlayer didStartPlayingQueueItemId:(NSObject*)queueItemId
{
    NSLog(@"audioPlayer didStartPlayingQueueItemId");
}

-(void) audioPlayer:(STKAudioPlayer*)audioPlayer didFinishBufferingSourceWithQueueItemId:(NSObject*)queueItemId
{
    NSLog(@"audioPlayer didFinishBufferingSourceWithQueueItemId");
}

// We can get the reason why the player stopped!!!
-(void) audioPlayer:(STKAudioPlayer*)audioPlayer didFinishPlayingQueueItemId:(NSObject*)queueItemId withReason:(STKAudioPlayerStopReason)stopReason andProgress:(double)progress andDuration:(double)duration
{
    NSLog(@"audioPlayer didFinishPlayingQueueItemId; Reason: %u; Progress: %f; Duration: %f", stopReason, progress, duration);
}

-(void) audioPlayer:(STKAudioPlayer*)audioPlayer unexpectedError:(STKAudioPlayerErrorCode)errorCode
{
    NSLog(@"audioPlayer unexpected error: %u", errorCode);
    [audioPlayer stop];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[YTNotifications sharedNotifications] showNotificationText:@"Oops, There Was An Error"];
    });
    
    // TODO: File won't play unfortunately (need to get to the bottom of this). Unclog this yap from user's unopened list
    [[API sharedAPI] updateYapStatus:self.yap toStatus:@"opened" withCallback:^(BOOL success, NSError *error, NSNumber *isFriend) {
        if (error) {
            
        }
    }];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Player Unexpected Error - PlayBack"];
}

/// Optionally implemented to get logging information from the STKAudioPlayer (used internally for debugging)
-(void) audioPlayer:(STKAudioPlayer*)audioPlayer logInfo:(NSString*)line
{
    NSLog(@"Log info: %@", line);
}

/// Raised when items queued items are cleared (usually because of a call to play, setDataSource or stop)
-(void) audioPlayer:(STKAudioPlayer*)audioPlayer didCancelQueuedItems:(NSArray*)queuedItems
{
    NSLog(@"Did cancel queued items: %@", queuedItems);
}

- (void) addShadowToTextView
{
    self.textView.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.textView.layer.shadowOffset = CGSizeMake(1.0f, 1.0f);
    self.textView.layer.shadowOpacity = 1.0f;
    self.textView.layer.shadowRadius = 1.0f;
}

#pragma mark - Spotify Button

- (IBAction) didTapReplayButton {
    [self.timer invalidate];
    [self.player stop];
    self.playerAlreadyStartedPlayingForThisSong = NO;
    [self.progressView setProgress:0];
    [self.activityIndicator startAnimating];
    double delay = 0.1;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self playYapAudio];
    });
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Tapped Replay Button"];
}

- (IBAction) didTapSpotifyButton {
    OpenInSpotifyAlertView *alert = [[OpenInSpotifyAlertView alloc] initWithYap:self.yap];
    [alert show];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Tapped Spotify Button (Playback Page)"];
}

#pragma mark - Friend Request Stuff Button

- (void) didTapFriendRequestButton {
    if (!self.acceptedFriendRequest) {
        NSLog(@"Tapped Friend Request Button");
        [self.friendRequestButton setTitle:@"" forState:UIControlStateNormal];
        [self.friendRequestActivityIndicator startAnimating];
        self.isFromFriend = [NSNumber numberWithInt:1];
        
        NSString *senderFirstName = [[self.yap.displaySenderName componentsSeparatedByString:@" "] objectAtIndex:0];
        
        [[API sharedAPI] confirmFriendFromYap:self.yap withCallback:^(BOOL success, NSError *error) {
            if (success) {
                [self.friendRequestActivityIndicator stopAnimating];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success"
                                                                message:[NSString stringWithFormat:@"You and %@ are now friends. Tap the button below and send them a yap!", self.yap.displaySenderName]
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles: nil];
                [alert show];
                self.acceptedFriendRequest = YES;
                [self.friendRequestButton setTitle:[NSString stringWithFormat:@"Send %@ a Yap", senderFirstName] forState:UIControlStateNormal];
                self.friendRequestButton.backgroundColor = THEME_RED_COLOR;
            } else {
                [self.friendRequestActivityIndicator stopAnimating];
                [self.friendRequestButton setTitle:@"Accept Friend Request" forState:UIControlStateNormal];
                [[YTNotifications sharedNotifications] showBlueNotificationText:@"Oops, Something Went Wrong!"];
            }
        }];
        
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel track:@"Tapped Accept Friend Request"];
    } else {
        if (self.yap.receivedByCurrentUser) {
            [self dismissThis];
            [self.yapCreatingDelegate didOriginateReplyFromYapNewClip:self.yap];
            NSString *senderFirstName = [[self.yap.displaySenderName componentsSeparatedByString:@" "] objectAtIndex:0];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[YTNotifications sharedNotifications] showNotificationText:[NSString stringWithFormat:@"Replying to %@", senderFirstName]];
            });
        } else {
            [self dismissThis];
            [self.yapCreatingDelegate didOriginateReplyFromYapNewClip:self.yap];
            NSString *receiverFirstName = [[self.yap.displayReceiverName componentsSeparatedByString:@" "] objectAtIndex:0];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[YTNotifications sharedNotifications] showNotificationText:[NSString stringWithFormat:@"Replying to %@", receiverFirstName]];
            });
        }
    }
}

#pragma mark - Create Own Yap Button


- (void) didTapCreateOwnYapButton {
    [self dismissThis];
    [self.yapCreatingDelegate didOriginateFromCreateOwnYapButton];
}

@end
