//
//  MusicPlaybackVC.m
//  YapSnap
//
//  Created by Jon Deokule on 12/24/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import "MusicPlaybackVC.h"

@interface MusicPlaybackVC ()
@property (strong, nonatomic) IBOutlet JEProgressView *progressView;
@property (strong, nonatomic) STKAudioPlayer *player;
@property (strong, nonatomic) NSTimer *timer;
@property (nonatomic) CGFloat elapsedTime;
@end

#define TIME_INTERVAL .01f

@implementation MusicPlaybackVC

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.progressView setTrackImage:[UIImage imageNamed:@"ProgressViewBackgroundWhite.png"]];
    [self.progressView setProgressImage:[UIImage imageNamed:@"ProgressViewBackgroundRed.png"]];

    self.player = [STKAudioPlayer new];
    self.player.delegate = self;
    [self.player play:self.yap.playbackURL];
}

- (void) stop
{
    NSLog(@"Stopping");
    [self.player pause];
    self.player.volume = 0;
}

#pragma mark - Progress Stuff
- (void) timerFired
{
    self.elapsedTime += TIME_INTERVAL;

    CGFloat trackLength = 2.5f;//TODO replace with duration from yap object when available
    CGFloat progress = self.elapsedTime / trackLength;
    [self.progressView setProgress:progress];
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
    } else if (state == STKAudioPlayerStateStopped) {
        NSLog(@"Stopped!");
        [self.timer invalidate];
        self.timer = nil;
        [[NSNotificationCenter defaultCenter] postNotificationName:PLAYBACK_STOPPED_NOTIFICATION object:nil];
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
