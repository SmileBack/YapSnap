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
@end

@implementation MusicPlaybackVC

- (void)viewDidLoad {
    [super viewDidLoad];

    self.player = [STKAudioPlayer new];
    self.player.delegate = self;
    [self.player play:self.yap.playbackURL];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void) stop
{
    self.player.volume = 0;
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
    } else if (state == STKAudioPlayerStateDisposed) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"Playback stopped" object:nil];
    }
}

-(void) audioPlayer:(STKAudioPlayer*)audioPlayer didFinishPlayingQueueItemId:(NSObject*)queueItemId withReason:(STKAudioPlayerStopReason)stopReason andProgress:(double)progress andDuration:(double)duration
{
}

-(void) audioPlayer:(STKAudioPlayer*)audioPlayer unexpectedError:(STKAudioPlayerErrorCode)errorCode
{
    [audioPlayer stop];
}

@end
