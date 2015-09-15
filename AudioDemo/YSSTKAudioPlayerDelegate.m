//
//  YSSTKAudioPlayerDelegate.m
//  YapTap
//
//  Created by Rudd Taylor on 9/11/15.
//  Copyright © 2015 Appcoda. All rights reserved.
//

#import "YSSTKAudioPlayerDelegate.h"
#import <AFNetworking/AFNetworkReachabilityManager.h>

@interface YSSTKAudioPlayerDelegate()

@end

@implementation YSSTKAudioPlayerDelegate

@synthesize player = _player;

- (STKAudioPlayer *)player {
    return _player;
}

- (void)setPlayer:(STKAudioPlayer *)player {
    if (_player) {
        [_player stop];
    }
    _player = player;
}

#pragma mark - YSAudioSource

- (BOOL)startAudioCaptureWithPreviewUrl:(NSString *)url withHeaders:(NSDictionary *)headers {
    if (![AFNetworkReachabilityManager sharedManager].reachable) {
        double delay = 0.1;
        dispatch_after(
                       dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
                           [[YTNotifications sharedNotifications]
                            showNotificationText:@"No Internet Connection!"];
                       });
        return NO;
    } else {
        [[AVAudioSession sharedInstance]
         setCategory:AVAudioSessionCategoryPlayAndRecord
         withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker
         error:nil];
        
        float volume = [[AVAudioSession sharedInstance] outputVolume];
        if (volume <= 0.125) {
            double delay = 0.1;
            dispatch_after(
                           dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{
                               [[YTNotifications sharedNotifications]
                                showBlueNotificationText:@"Turn Up The Volume!"];
                               Mixpanel *mixpanel = [Mixpanel sharedInstance];
                               [mixpanel track:@"Volume Notification - Spotify"];
                           });
        }
        if ([self.audioCaptureDelegate
             respondsToSelector:
             @selector(audioSourceControllerWillStartAudioCapture:)]) {
            [self.audioCaptureDelegate
             audioSourceControllerWillStartAudioCapture:self.audioSource];
        }
        
        NSLog(@"Playing URL: %@ %@ auth token", url,
              headers ? @"with" : @"without");
        if (headers) {
            [self.player play:url withHeaders:headers];
        } else {
            [self.player play:url];
        }
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel track:@"Played a Song"];
        [mixpanel.people increment:@"Played a Song #"
                                by:[NSNumber numberWithInt:1]];
        return YES;
    }
}

- (void)cancelPlayingAudio {
    [self stopAudioCaptureFromCancel:YES];
    for (NSIndexPath *indexPath in self.collectionView
         .indexPathsForSelectedItems) {
        [self.collectionView deselectItemAtIndexPath:indexPath animated:YES];
    }
}

- (void)stopAudioCapture {
    [self stopAudioCaptureFromCancel:NO];
}

- (void)stopAudioCaptureFromCancel:(BOOL)fromCancel {
    if ((self.player.state & STKAudioPlayerStateRunning) != 0) {
        [self.player stop];
        if (fromCancel) {
            if ([self.audioCaptureDelegate
                 respondsToSelector:
                 @selector(audioSourceControllerdidCancelAudioCapture:)]) {
                [self.audioCaptureDelegate
                 audioSourceControllerdidCancelAudioCapture:self.audioSource];
            }
        } else {
            if ([self.audioCaptureDelegate
                 respondsToSelector:
                 @selector(audioSourceControllerdidFinishAudioCapture:)]) {
                [self.audioCaptureDelegate
                 audioSourceControllerdidFinishAudioCapture:self.audioSource];
            }
        }
    }
}

- (void)updatePlaybackProgress:(NSTimeInterval)playbackTime {
    TrackCollectionViewCell *trackViewCell = ((TrackCollectionViewCell *)[self.collectionView
                                                                          cellForItemAtIndexPath:((NSIndexPath *)[self.collectionView
                                                                                                                  indexPathsForSelectedItems].firstObject)]);
    trackViewCell.countdownTimer = playbackTime;
}

#pragma mark - STKAudioPlayerDelegate

- (void)audioPlayer:(STKAudioPlayer *)audioPlayer
didStartPlayingQueueItemId:(NSObject *)queueItemId {}

- (void)audioPlayer:(STKAudioPlayer *)audioPlayer
didFinishBufferingSourceWithQueueItemId:(NSObject *)queueItemId {}

- (void)audioPlayer:(STKAudioPlayer *)audioPlayer
didFinishPlayingQueueItemId:(NSObject *)queueItemId
         withReason:(STKAudioPlayerStopReason)stopReason
        andProgress:(double)progress
        andDuration:(double)duration {}

- (void)audioPlayer:(STKAudioPlayer *)audioPlayer
    unexpectedError:(STKAudioPlayerErrorCode)errorCode {
    NSLog(@"audioPlayer unexpected error: %u", errorCode);
    [audioPlayer stop];
    if ([self.audioCaptureDelegate
         respondsToSelector:@selector(audioSourceController:
                                      didReceieveUnexpectedError:)]) {
             [self.audioCaptureDelegate
              audioSourceController:self.audioSource
              didReceieveUnexpectedError:
              [NSError errorWithDomain:@"YSSpotifySourceController"
                                  code:errorCode
                              userInfo:nil]];
         }
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Player Unexpected Error - Spotify"];
}

- (void)audioPlayer:(STKAudioPlayer *)audioPlayer
       stateChanged:(STKAudioPlayerState)state
      previousState:(STKAudioPlayerState)previousState {
    if (state == STKAudioPlayerStatePlaying) {
        NSLog(@"state == STKAudioPlayerStatePlaying");
        
        if ([self.audioCaptureDelegate
             respondsToSelector:
             @selector(audioSourceControllerDidStartAudioCapture:)]) {
            [self.audioCaptureDelegate
             audioSourceControllerDidStartAudioCapture:self.audioSource];
        }
    }
    
    if (state == STKAudioPlayerStateError) {
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel track:@"Player State Error - Spotify"];
    }
}

@end
