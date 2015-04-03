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

@interface PlaybackVC ()
@property (strong, nonatomic) IBOutlet YSRecordProgressView *progressView;
@property (strong, nonatomic) STKAudioPlayer *player;
@property (strong, nonatomic) NSTimer *timer;
@property (nonatomic) CGFloat elapsedTime;
@property (strong, nonatomic) IBOutlet UITextView *textView;
@property (strong, nonatomic) UIView *progressViewRemainder;
@property (strong, nonatomic) IBOutlet UIImageView *yapPhoto;

@end

#define TIME_INTERVAL .01f

@implementation PlaybackVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupNotifications];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Viewed Playback Page"];
    
    self.player = [STKAudioPlayer new];
    self.player.delegate = self;
    
    if ([self.yap.type isEqual:@"VoiceMessage"]) {
        // To get pitch value in pitchShift unit, divide self.yap.pitchValueInCentUnits by STK_PITCHSHIFT_TRANSFORM
        self.player.pitchShift = self.yap.pitchValueInCentUnits.floatValue/1000;
        NSLog(@"Pitch Shift: %f", self.player.pitchShift);
    }

    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:nil];

    NSDictionary *headers = [[SpotifyAPI sharedApi] getAuthorizationHeaders];
    NSLog(@"Playing URL: %@ %@ auth token", self.yap.playbackURL, headers ? @"with" : @"without");
    if (headers) {
        [self.player play:self.yap.playbackURL withHeaders:headers];
    } else {
        [self.player play:self.yap.playbackURL];
    }

    [self.progressView.activityIndicator startAnimating];
    
    // Snapchat allows for 48 characters horizontally; 31 vertically 
    self.textView.text = self.yap.text;  //TODO REPLACE THIS
    
    if ([self.textView.text length] == 0) {
        self.textView.hidden = YES;
    } else {
        self.textView.hidden = NO;
    }
    
    self.view.backgroundColor = THEME_BACKGROUND_COLOR; //[UIColor colorWithRed:[self.yap.rgbColorComponents[0] floatValue]/255 green:[self.yap.rgbColorComponents[1] floatValue]/255 blue:[self.yap.rgbColorComponents[2] floatValue]/255 alpha:1];
    
    float volume = [[AVAudioSession sharedInstance] outputVolume];
    if (volume < 0.5) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[YTNotifications sharedNotifications] showVolumeText:@"Turn Up The Volume!"];
        });
    }

    // If there's no photo URL, don't attempt to show photo
    if (self.yap.yapPhotoURL && ![self.yap.yapPhotoURL isEqual: [NSNull null]]) {
        [self.yapPhoto sd_setImageWithURL:[NSURL URLWithString:self.yap.yapPhotoURL]];
    }
    
    // Pitch possibilities: 1000, 500, 0, -400
    if (self.yap.pitchValueInCentUnits.intValue > 750) {
        if (self.isiPhone5Size) {
            [self.progressView setProgressImage:[UIImage imageNamed:@"ProgressViewYellowiPhone5.png"]];
        } else if (self.isiPhone4Size) {
            [self.progressView setProgressImage:[UIImage imageNamed:@"ProgressViewYellowiPhone4.png"]];
        } else {
            [self.progressView setProgressImage:[UIImage imageNamed:@"ProgressViewYellow.png"]];
        }
    } else if (self.yap.pitchValueInCentUnits.intValue < 750 && self.yap.pitchValueInCentUnits.intValue > 250) {
        if (self.isiPhone5Size) {
            [self.progressView setProgressImage:[UIImage imageNamed:@"ProgressViewGreeniPhone5.png"]];
        } else if (self.isiPhone4Size) {
            [self.progressView setProgressImage:[UIImage imageNamed:@"ProgressViewGreeniPhone4.png"]];
        } else {
            [self.progressView setProgressImage:[UIImage imageNamed:@"ProgressViewGreen.png"]];
        }
    } else if (self.yap.pitchValueInCentUnits.intValue < -250) {
        if (self.isiPhone5Size) {
            [self.progressView setProgressImage:[UIImage imageNamed:@"ProgressViewLightBlueiPhone5.png"]];
        } else if (self.isiPhone4Size) {
            [self.progressView setProgressImage:[UIImage imageNamed:@"ProgressViewLightBlueiPhone4.png"]];
        } else {
            [self.progressView setProgressImage:[UIImage imageNamed:@"ProgressViewLightBlue.png"]];
        }
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [UIView animateWithDuration:.1
                          delay:.9
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.volumeView.alpha = .8;
                     }
                     completion:nil];
}

- (IBAction)didTapStopButton:(id)sender {
    [self stop];
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Tapped Cancel PlayBack"];
}

- (void) stop
{
    NSLog(@"Stopping");
    [self.timer invalidate];
    [self.player stop];
    //self.player.volume = 0;
}

- (void) setupNotifications
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserverForName:UIApplicationWillResignActiveNotification
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                        [self stop];
                        /*
                        [[API sharedAPI] updateYapStatus:self.yap toStatus:@"unopened" withCallback:^(BOOL success, NSError *error) {
                            if (error) {

                            }
                        }];
                         */
                    }];
}

#pragma mark - Progress Stuff
- (void) timerFired
{
    self.elapsedTime += TIME_INTERVAL;

    CGFloat trackLength = [self.yap.duration floatValue];
    CGFloat progress = self.elapsedTime / 10;
    [self.progressView setProgress:progress];
    
    if (self.elapsedTime >= trackLength) {
        [self stop];
    }
}

#pragma mark - STKAudioPlayerDelegate
-(void) audioPlayer:(STKAudioPlayer*)audioPlayer didStartPlayingQueueItemId:(NSObject*)queueItemId
{
}

-(void) audioPlayer:(STKAudioPlayer*)audioPlayer didFinishBufferingSourceWithQueueItemId:(NSObject*)queueItemId
{
}

-(void) audioPlayer:(STKAudioPlayer*)audioPlayer stateChanged:(STKAudioPlayerState)state previousState:(STKAudioPlayerState)previousState
{
    if (state == STKAudioPlayerStatePlaying) {
        NSLog(@"Playing!");
        self.elapsedTime = 0.0f;
        self.timer = [NSTimer scheduledTimerWithTimeInterval:TIME_INTERVAL
                                                      target:self
                                                    selector:@selector(timerFired)
                                                    userInfo:nil
                                                     repeats:YES];
        [self.progressView.activityIndicator stopAnimating];
        
        CGFloat width = self.view.frame.size.width;
        CGFloat progressViewRemainderWidth = (10 - [self.yap.duration floatValue]) * width/10;
        self.progressViewRemainder = [[UIView alloc] init];
        [self.view addSubview:self.progressViewRemainder];
        [self.progressViewRemainder setTranslatesAutoresizingMaskIntoConstraints:NO];
        
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.progressViewRemainder attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.progressView attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0]];
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.progressViewRemainder attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.progressView attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.progressViewRemainder attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.progressView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0.0]];
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
        
        [[API sharedAPI] updateYapStatus:self.yap toStatus:@"opened" withCallback:^(BOOL success, NSError *error) {
            if (error) {

            }
        }];
    }
    
    if (state == STKAudioPlayerStateStopped) {
        NSLog(@"Stopped!");
        [self.timer invalidate];
        self.timer = nil;
        [self.progressView.activityIndicator stopAnimating]; // This line may not be necessary
        [[NSNotificationCenter defaultCenter] postNotificationName:PLAYBACK_STOPPED_NOTIFICATION object:nil]; //Not currently used
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self dismissViewControllerAnimated:NO completion:nil];
            if ([self.yap.text isEqual: @"Welcome to YapTap :)"] && self.yap.senderID.intValue == 1)
            {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [[YTNotifications sharedNotifications] showNotificationText:@"Now Send Someone a Yap :)"];
                });
            }
        });
    }
    
    if (state == STKAudioPlayerStateBuffering && previousState == STKAudioPlayerStatePlaying) {
        NSLog(@"state changed from playing to buffering");
        [audioPlayer stop];
        [[API sharedAPI] updateYapStatus:self.yap toStatus:@"unopened" withCallback:^(BOOL success, NSError *error) {
            if (error) {

            }
        }];
        
        double delay = .1;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[YTNotifications sharedNotifications] showNotificationText:@"Oops, Connection Was Lost!"];
            Mixpanel *mixpanel = [Mixpanel sharedInstance];
            [mixpanel track:@"Connection Lost - Playback"];
        });
    }
}

-(void) audioPlayer:(STKAudioPlayer*)audioPlayer didFinishPlayingQueueItemId:(NSObject*)queueItemId withReason:(STKAudioPlayerStopReason)stopReason andProgress:(double)progress andDuration:(double)duration
{
    NSLog(@"didFinishPlayingQueueItemId");
}

-(void) audioPlayer:(STKAudioPlayer*)audioPlayer unexpectedError:(STKAudioPlayerErrorCode)errorCode
{
    [audioPlayer stop];
}

@end
