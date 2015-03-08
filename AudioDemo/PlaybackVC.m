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

@interface PlaybackVC ()
@property (strong, nonatomic) IBOutlet JEProgressView *progressView;
@property (strong, nonatomic) STKAudioPlayer *player;
@property (strong, nonatomic) NSTimer *timer;
@property (nonatomic) CGFloat elapsedTime;
@property (strong, nonatomic) IBOutlet UITextView *textView;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *recordButtonSpinner;
@property (strong, nonatomic) UIView *progressViewRemainder;
@property (strong, nonatomic) IBOutlet UIImageView *progressViewNotchesView;
@property (strong, nonatomic) IBOutlet UIImageView *yapPhoto;

@end

#define TIME_INTERVAL .01f

@implementation PlaybackVC

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.progressView setTrackImage:[UIImage imageNamed:@"ProgressViewBackgroundWhite.png"]];
    [self.progressView setProgressImage:[UIImage imageNamed:@"ProgressViewBackgroundRed.png"]];
    
    self.player = [STKAudioPlayer new];
    self.player.delegate = self;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:nil];
    NSLog(@"URL: %@", self.yap.playbackURL);
    [self.player play:self.yap.playbackURL];
    
    [self.recordButtonSpinner startAnimating];
    
    // Snapchat allows for 48 characters horizontally; 31 vertically 
    self.textView.text = self.yap.text;  //TODO REPLACE THIS
    
    if ([self.textView.text length] == 0) {
        self.textView.hidden = YES;
    } else {
        self.textView.hidden = NO;
    }
    
    self.view.backgroundColor = [UIColor colorWithRed:[self.yap.rgbColorComponents[0] floatValue]/255 green:[self.yap.rgbColorComponents[1] floatValue]/255 blue:[self.yap.rgbColorComponents[2] floatValue]/255 alpha:1];

    // If there's no photo URL, don't attempt to show photo
    if (self.yap.yapPhotoURL && ![self.yap.yapPhotoURL isEqual: [NSNull null]]) {
        [self.yapPhoto sd_setImageWithURL:[NSURL URLWithString:self.yap.yapPhotoURL]];
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
}

- (void) stop
{
    NSLog(@"Stopping");
    [self.timer invalidate];
    [self.player stop];
    self.player.volume = 0;
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
        [self.recordButtonSpinner stopAnimating];
        
        // We muted yap recordings in ViewDidLoad because we want to cut out the first 0.25 seconds of the yap in order to cut out the notification tone
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{

        });
        
        CGFloat width = self.view.frame.size.width;
        CGFloat progressViewRemainderWidth = (10 - [self.yap.duration floatValue])*width/10;
        self.progressViewRemainder = [[UIView alloc] init];
        self.progressViewRemainder.frame = CGRectMake(width - progressViewRemainderWidth, 64, progressViewRemainderWidth, 40);
        self.progressViewRemainder.backgroundColor = [UIColor lightGrayColor];
        self.progressViewRemainder.alpha = 0;
        [self.view addSubview:self.progressViewRemainder];
        [UIView animateWithDuration:0.4
                              delay:0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             self.progressViewRemainder.alpha = 1;
                         }
                         completion:nil];
        
        [self.view bringSubviewToFront:self.progressViewNotchesView];
        
        [[API sharedAPI] yapOpened:self.yap withCallback:^(BOOL success, NSError *error) {
            //TODO do something?
        }];
    } else if (state == STKAudioPlayerStateStopped) {
        NSLog(@"Stopped!");
        [self.timer invalidate];
        self.timer = nil;
        [[NSNotificationCenter defaultCenter] postNotificationName:PLAYBACK_STOPPED_NOTIFICATION object:nil]; //May not be needed
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self dismissViewControllerAnimated:NO completion:nil];
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
