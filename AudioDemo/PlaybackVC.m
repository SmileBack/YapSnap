//
//  MusicPlaybackVC.m
//  YapSnap
//
//  Created by Jon Deokule on 12/24/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import "PlaybackVC.h"
#import "API.h"

@interface PlaybackVC ()
@property (strong, nonatomic) IBOutlet JEProgressView *progressView;
@property (strong, nonatomic) STKAudioPlayer *player;
@property (strong, nonatomic) NSTimer *timer;
@property (nonatomic) CGFloat elapsedTime;
@property (strong, nonatomic) IBOutlet UILabel *textLabel;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *recordButtonSpinner;

@end

#define TIME_INTERVAL .01f

@implementation PlaybackVC

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.progressView setTrackImage:[UIImage imageNamed:@"ProgressViewBackgroundWhite.png"]];
    [self.progressView setProgressImage:[UIImage imageNamed:@"ProgressViewBackgroundRed.png"]];

    self.player = [STKAudioPlayer new];
    self.player.delegate = self;
    NSLog(@"URL: %@", self.yap.playbackURL);
    [self.player play:self.yap.playbackURL];
    
    [self.recordButtonSpinner startAnimating];
    
    self.textLabel.text = @"TEXT HERE";//self.yap.text;  //TODO REPLACE THIS
    
    [[API sharedAPI] yapOpened:self.yap withCallback:^(BOOL success, NSError *error) {
        //TODO do something?
    }];
}

- (void)viewDidAppear:(BOOL)animated {
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

    CGFloat trackLength = 8.0f;//TODO replace with duration from yap object when available
    CGFloat progress = self.elapsedTime / trackLength;
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
