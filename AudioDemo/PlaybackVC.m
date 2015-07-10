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

@interface PlaybackVC ()
@property (strong, nonatomic) IBOutlet YSRecordProgressView *progressView;
@property (strong, nonatomic) STKAudioPlayer *player;
@property (strong, nonatomic) NSTimer *timer;
@property (nonatomic) CGFloat elapsedTime;
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

@property (weak, nonatomic) IBOutlet UIButton *replayButton;
@property (weak, nonatomic) IBOutlet UIButton *spotifyButton;
@property (weak, nonatomic) IBOutlet UIButton *friendRequestButton;

// nil means we don't know yet. YES/NO means the backend told us.
@property (nonatomic, strong) NSNumber *isFromFriend;

- (IBAction)didTapReplayButton;
- (IBAction)didTapSpotifyButton;
- (IBAction)didTapFriendRequestButton;

@end

#define TIME_INTERVAL .05f

@implementation PlaybackVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupNotifications];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Viewed Playback Page"];
    
    if (self.yap.sentByCurrentUser) {
        //self.replyButton.hidden = YES;
        NSString *receiverFirstName = [[self.yap.displayReceiverName componentsSeparatedByString:@" "] objectAtIndex:0];
        
        if ([self.yap.receiverPhone isEqualToString:@"+13245678910"] || [self.yap.receiverPhone isEqualToString:@"+13027865701"]) {
            self.titleLabel.text = @"Sent to YapTap Team";
            [self.replyButton setTitle:@"Send Another Yap" forState:UIControlStateNormal];
        } else {
            [self.replyButton setTitle:[NSString stringWithFormat:@"Send %@ Another Yap", receiverFirstName] forState:UIControlStateNormal];
        }
        
        if (self.yap.isFriendRequest) {
            self.forwardButton.hidden = YES; // we should just not show these yaps
        }
    } else if (self.yap.receivedByCurrentUser) {
        if (self.yap.isFriendRequest) {
            self.forwardButton.hidden = YES;
            NSString *senderFirstName = [[self.yap.displaySenderName componentsSeparatedByString:@" "] objectAtIndex:0];
            self.replyButton.backgroundColor = THEME_RED_COLOR;
            [self.replyButton setTitle:[NSString stringWithFormat:@"Send %@ a Yap", senderFirstName] forState:UIControlStateNormal];
            NSLog(@"Yap status: %@", self.yap.status);
            if ([self.yap.status isEqualToString:@"unopened"]) {
                self.friendRequestButton.hidden = NO;
            }
        }
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
    
    self.textView.textContainer.maximumNumberOfLines = 5;
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
    if ([self.yap.type isEqual:@"SpotifyMessage"] && self.yap.imageURL) {
        [self.albumImage sd_setImageWithURL:[NSURL URLWithString:self.yap.imageURL]];
    } else if ([self.yap.type isEqual:@"VoiceMessage"]) {
        [self.albumImage setImage:[UIImage imageNamed:@"YapTapCartoonLarge2.png"]];
    }
    
    [self addShadowToTextView];
    
    [self styleActionButtons];
    
    self.isFromFriend = [NSNumber numberWithInt:1]; // We are setting self.isFromFriend.boolValue to True so that friends popup doesn't come up if you press the X before back end response comes in. It'll get updated to the correct value once back end response comes in
    
    if ([self.yap.type isEqual:@"SpotifyMessage"]) {
        self.albumLabel.text = [NSString stringWithFormat:@"%@, by %@", self.yap.songName, self.yap.artist];
        self.spotifyButton.hidden = NO;
    } else {
        self.albumLabel.text = [NSString stringWithFormat:@"by %@", self.yap.senderName];
    }
    
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
}

- (void) handleImageAndPlayAudio
{
    __weak PlaybackVC *weakSelf = self;
    if (self.yap.yapPhotoURL && ![self.yap.yapPhotoURL isEqual: [NSNull null]]) {
        [self addShadowToTextView];
        self.albumImage.hidden = YES;
        
        //self.yapPhoto.layer.borderWidth = 1;
        //self.yapPhoto.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:1.0].CGColor;
        //self.yapPhoto.clipsToBounds = YES;
         
        
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
    if (headers) {
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
    [self stop];
}

#pragma mark - Actions

- (IBAction)didTapCancelButton:(id)sender {
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Tapped Cancel PlayBack"];
    [self dismissThis];
}

- (IBAction)didTapReply:(id)sender {
        
    if (self.yap.isFriendRequest) {
        [self dismissThis];
        [self.yapCreatingDelegate didOriginateReplyFromYapNewClip:self.yap];
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel track:@"Sent Yap From Friend Request"];
    } else if (self.yap.receivedByCurrentUser) {
        if ([self.yap.type isEqual:@"SpotifyMessage"]) {
            UIActionSheet *actionSheetSpotify = [[UIActionSheet alloc] initWithTitle:@"Reply with the same song, or a new one?"
                                                                            delegate:self
                                                                   cancelButtonTitle:@"Cancel"
                                                              destructiveButtonTitle:nil
                                                                   otherButtonTitles:@"Use Same Song", @"Choose New Song", @"No Song. Just Voice", nil];
            actionSheetSpotify.tag = 100;
            [actionSheetSpotify showInView:self.view];
        } else if ([self.yap.type isEqual:@"VoiceMessage"]) {
            UIActionSheet *actionSheetVoice = [[UIActionSheet alloc] initWithTitle:@"Reply with a song yap or a voice yap"
                                                                          delegate:self
                                                                 cancelButtonTitle:@"Cancel"
                                                            destructiveButtonTitle:nil
                                                                 otherButtonTitles:@"Send a Song Yap", @"Send a Voice Yap", nil];
            actionSheetVoice.tag = 200;
            [actionSheetVoice showInView:self.view];
        }
    } else {
        if ([self.yap.type isEqual:@"SpotifyMessage"]) {
            UIActionSheet *actionSheetSpotify = [[UIActionSheet alloc] initWithTitle:@"Use the same song, or a new one?"
                                                                            delegate:self
                                                                   cancelButtonTitle:@"Cancel"
                                                              destructiveButtonTitle:nil
                                                                   otherButtonTitles:@"Use Same Song", @"Choose New Song", @"No Song. Just Voice", nil];
            actionSheetSpotify.tag = 100;
            [actionSheetSpotify showInView:self.view];
        } else if ([self.yap.type isEqual:@"VoiceMessage"]) {
            UIActionSheet *actionSheetVoice = [[UIActionSheet alloc] initWithTitle:@"Send a song yap or a voice yap?"
                                                                          delegate:self
                                                                 cancelButtonTitle:@"Cancel"
                                                            destructiveButtonTitle:nil
                                                                 otherButtonTitles:@"Send a Song Yap", @"Send a Voice Yap", nil];
            actionSheetVoice.tag = 200;
            [actionSheetVoice showInView:self.view];
        }
    }
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Tapped Reply (from Playback)"];
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
    
    CGFloat trackLength = 12; //[self.yap.duration floatValue]; // DEFAULT TO 12 SECONDS
    CGFloat progress = self.elapsedTime / 12;
    [self.progressView setProgress:progress];
    
    if (self.elapsedTime >= trackLength) {
        [self stop];
    }
}

#pragma mark - STKAudioPlayerDelegate
-(void) audioPlayer:(STKAudioPlayer*)audioPlayer stateChanged:(STKAudioPlayerState)state previousState:(STKAudioPlayerState)previousState
{
    if (state == STKAudioPlayerStatePlaying) {
        NSLog(@"state == STKAudioPlayerStatePlaying");
        
        if (!self.playerAlreadyStartedPlayingForThisSong) {
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
            
            // DEFAULT TO 12 SECONDS
            //CGFloat width = self.view.frame.size.width;
            //CGFloat progressViewRemainderWidth = (12 - [self.yap.duration floatValue]) * width/12;
            CGFloat progressViewRemainderWidth = 0;
            
            self.progressViewRemainder = [[UIView alloc] init];
            [self.view addSubview:self.progressViewRemainder];
            [self.progressViewRemainder setTranslatesAutoresizingMaskIntoConstraints:NO];
            
            [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.progressViewRemainder attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.progressView attribute:NSLayoutAttributeHeight multiplier:1.0 constant:-1.0]];
            [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.progressViewRemainder attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.progressView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
            [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.progressViewRemainder attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.progressView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.5]];
            [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.progressViewRemainder attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:progressViewRemainderWidth]];
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

#pragma mark - UIActionSheet method implementation

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    NSLog(@"Tapped Action Sheet; Button Index: %ld", (long)buttonIndex);
    // Take a photo
    if (actionSheet.tag == 100) {
        if (buttonIndex == 0) {
            [self dismissThis];
            [self.yapCreatingDelegate didOriginateReplyFromYapSameClip:self.yap];
            Mixpanel *mixpanel = [Mixpanel sharedInstance];
            [mixpanel track:@"Tapped Reply to Song from Playback (Same Clip)"];
            // Upload a photo
        } else if (buttonIndex == 1) {
            [self dismissThis];
            [self.yapCreatingDelegate didOriginateReplyFromYapNewClip:self.yap];
            Mixpanel *mixpanel = [Mixpanel sharedInstance];
            [mixpanel track:@"Tapped Reply to Song from Playback (Different Clip)"];
        } else if (buttonIndex == 2) {
            [self dismissThis];
            [self.yapCreatingDelegate didOriginateReplyFromYapVoice:self.yap];
            Mixpanel *mixpanel = [Mixpanel sharedInstance];
            [mixpanel track:@"Tapped Reply to Song from Playback (Voice)"];
        } else {
            NSLog(@"Did tap cancel");
            Mixpanel *mixpanel = [Mixpanel sharedInstance];
            [mixpanel track:@"Canceled Reply to Song from Playback"];
        }
    } else if (actionSheet.tag == 200) {
        if (buttonIndex == 0) {
            [self dismissThis];
            [self.yapCreatingDelegate didOriginateReplyFromYapNewClip:self.yap];
            Mixpanel *mixpanel = [Mixpanel sharedInstance];
            [mixpanel track:@"Tapped Reply to Voice from Playback (Songs)"];
            // Upload a photo
        } else if (buttonIndex == 1) {
            [self dismissThis];
            [self.yapCreatingDelegate didOriginateReplyFromYapVoice:self.yap];
            Mixpanel *mixpanel = [Mixpanel sharedInstance];
            [mixpanel track:@"Tapped Reply to Voice from Playback (Voice)"];
        } else {
            NSLog(@"Did tap cancel");
            Mixpanel *mixpanel = [Mixpanel sharedInstance];
            [mixpanel track:@"Canceled Reply to Voice from Playback"];
        }
    }
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
    NSLog(@"Tapped Friend Request Button");
    [self.friendRequestButton setTitle:@"" forState:UIControlStateNormal];
    [self.friendRequestActivityIndicator startAnimating];
    self.isFromFriend = [NSNumber numberWithInt:1];
    
    [[API sharedAPI] confirmFriendFromYap:self.yap withCallback:^(BOOL success, NSError *error) {
        if (success) {
            [self.friendRequestActivityIndicator stopAnimating];
            self.friendRequestButton.hidden = YES;
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success!"
                                                            message:[NSString stringWithFormat:@"You and %@ are friends. Now tap the button below and send them a yap!", self.yap.displaySenderName]
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles: nil];
            [alert show];
        } else {
            [self.friendRequestActivityIndicator stopAnimating];
            [self.friendRequestButton setTitle:@"Accept Friend Request" forState:UIControlStateNormal];
            [[YTNotifications sharedNotifications] showBlueNotificationText:@"Oops, Something Went Wrong!"];
        }
    }];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Tapped Accept Friend Request"];
}


@end
