//
//  YSSpotifySourceController.m
//  YapSnap
//
//  Created by Jon Deokule on 12/20/14.
//  Copyright (c) 2014 Appcoda. All rights reserved.
//

#import "YSSpotifySourceController.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "API.h"
#import "SpotifyAPI.h"
#import "TrackCollectionViewCell.h"
#import "OpenInSpotifyAlertView.h"
#import <AVFoundation/AVAudioSession.h>
#import "AppDelegate.h"
#import "SpotifyTrackFactory.h"
#import "UIViewController+MJPopupViewController.h"
#import "SearchArtistAlertView.h"
#import "YTTrackGroup.h"
#import "YSSongCollectionViewDataSource.h"
#import "Mixpanel/MPTweakInline.h"
#import "NSArray+Shuffle.h"
#import "UICollectionViewFlowLayout+YS.h"

@interface YSSpotifySourceController () <UICollectionViewDelegate,
                                         YSSongCollectionViewDelegate>
@property (strong, nonatomic) STKAudioPlayer *player;
@property (nonatomic) BOOL playerAlreadyStartedPlayingForThisSong;
@property (nonatomic, strong) NSMutableArray *tracks;
@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) YSSongCollectionViewDataSource *songDataSource;

@end

@implementation YSSpotifySourceController

- (void)viewDidLoad {
    [super viewDidLoad];
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Viewed Spotify Page"];
    self.songDataSource = [[YSSongCollectionViewDataSource alloc] init];
    self.songDataSource.delegate = self;
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:[UICollectionViewFlowLayout appLayout]];
    self.collectionView.dataSource = self.songDataSource;
    self.collectionView.delegate = self;
    [self.collectionView registerClass:[SpotifyTrackCollectionViewCell class]
            forCellWithReuseIdentifier:@"track"];
    self.collectionView.backgroundColor = [UIColor colorWithRed:239/255.0 green:239/255.0 blue:244/255.0 alpha:1.0];
    
    self.view.backgroundColor = THEME_BACKGROUND_COLOR;
    
    // Constraints
    [self.collectionView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:self.collectionView];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[v]|" options:0 metrics:nil views:@{@"v": self.collectionView}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[top][v][bottom]" options:0 metrics:nil views:@{@"v": self.collectionView, @"top": self.topLayoutGuide, @"bottom": self.bottomLayoutGuide}]];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.playerAlreadyStartedPlayingForThisSong = NO;
    [self retrieveAndLoadTracksForCategory:self.trackGroup];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.player.state == STKAudioPlayerStatePlaying) {
        [self cancelPlayingAudio];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    for (NSIndexPath *indexPath in self.collectionView.indexPathsForSelectedItems) {
        [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
    }
}

#pragma mark - Setters/Getters

- (void)setSongs:(NSArray *)songs {
    _songs = songs;
    self.songDataSource.songs = songs;
    [self.collectionView reloadData];
}

#pragma mark - YSSongCollectionViewDataSourceDelegate

- (void)songCollectionDataSource:(YSSongCollectionViewDataSource *)dataSource
           didTapSongAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath isEqual:self.collectionView.indexPathsForSelectedItems.firstObject]) {
        if (self.player.state == STKAudioPlayerStatePlaying) {
            [self.player pause];
        } else {
            [self startAudioCapture];
        }

    } else {
        [self playSongAtIndexPath:indexPath withOffsetStartTime:0];
    }
}

- (void)songCollectionDataSource:(YSSongCollectionViewDataSource *)dataSource didTapArtistAtIndexPath:(NSIndexPath *)indexPath {
}

- (void)songCollectionDataSource:(YSSongCollectionViewDataSource *)dataSource
  didTapSongOptionOneAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"Tapped Song Version One Button");
    SpotifyTrackView *trackView =
        ((SpotifyTrackCollectionViewCell *)
             [self.collectionView cellForItemAtIndexPath:indexPath])
            .trackView;
    if (IS_IPHONE_4_SIZE) {
        [trackView.songVersionOneButton
            setImage:[UIImage imageNamed:@"SongVersionOneSelectediPhone4.png"]
            forState:UIControlStateNormal];
        [trackView.songVersionTwoButton
            setImage:[UIImage imageNamed:@"TwoNotSelectediPhone4.png"]
            forState:UIControlStateNormal];
    } else if (IS_IPHONE_6_SIZE) {
        [trackView.songVersionOneButton
            setImage:[UIImage imageNamed:@"SongVersionOneSelectediPhone6.png"]
            forState:UIControlStateNormal];
        [trackView.songVersionTwoButton
            setImage:[UIImage imageNamed:@"TwoNotSelectediPhone6.png"]
            forState:UIControlStateNormal];
    } else {
        [trackView.songVersionOneButton
            setImage:[UIImage imageNamed:@"SongVersionOneSelected.png"]
            forState:UIControlStateNormal];
        [trackView.songVersionTwoButton
            setImage:[UIImage imageNamed:@"TwoNotSelected.png"]
            forState:UIControlStateNormal];
    }

    [self playSongAtIndexPath:indexPath withOffsetStartTime:0];
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Tapped Song Version One"];
}

- (void)songCollectionDataSource:(YSSongCollectionViewDataSource *)dataSource
  didTapSongOptionTwoAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"Tapped Song Version Two Button");
    SpotifyTrackView *trackView =
        ((SpotifyTrackCollectionViewCell *)
             [self.collectionView cellForItemAtIndexPath:indexPath])
            .trackView;
    if (IS_IPHONE_4_SIZE) {
        [trackView.songVersionOneButton
            setImage:[UIImage imageNamed:@"OneNotSelectediPhone4.png"]
            forState:UIControlStateNormal];
        [trackView.songVersionTwoButton
            setImage:[UIImage imageNamed:@"SongVersionTwoSelectediPhone4.png"]
            forState:UIControlStateNormal];
    } else if (IS_IPHONE_6_SIZE) {
        [trackView.songVersionOneButton
            setImage:[UIImage imageNamed:@"OneNotSelectediPhone6.png"]
            forState:UIControlStateNormal];
        [trackView.songVersionTwoButton
            setImage:[UIImage imageNamed:@"SongVersionTwoSelectediPhone6.png"]
            forState:UIControlStateNormal];
    } else {
        [trackView.songVersionOneButton
            setImage:[UIImage imageNamed:@"OneNotSelected.png"]
            forState:UIControlStateNormal];
        [trackView.songVersionTwoButton
            setImage:[UIImage imageNamed:@"SongVersionTwoSelected.png"]
            forState:UIControlStateNormal];
    }

    [self playSongAtIndexPath:indexPath withOffsetStartTime:17];
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Tapped Song Version Two"];
}

- (void)songCollectionDataSource:(YSSongCollectionViewDataSource *)dataSource
        didTapSpotifyAtIndexPath:(NSIndexPath *)indexPath {
    YSTrack *selectedTrack = self.songs[indexPath.row];
    OpenInSpotifyAlertView *alert =
        [[OpenInSpotifyAlertView alloc] initWithTrack:selectedTrack];
    [alert show];
}

#pragma mark - Track Category Stuff

- (void)retrieveAndLoadTracksForCategory:(YTTrackGroup *)trackGroup {
    if (trackGroup.songs) {
        self.songs = [trackGroup.songs shuffledArray];
    } else {
        trackGroup = trackGroup ? trackGroup : [YTTrackGroup defaultTrackGroup];
        [[API sharedAPI]
            retrieveTracksForCategory:trackGroup
                         withCallback:^(NSArray *songs, NSError *error) {
                           if (songs) {
                               trackGroup.songs = songs;
                               self.songs = [trackGroup.songs shuffledArray];
                           } else {
                               NSLog(@"Something went wrong");
                           }
                         }];
    }
}

#pragma mark - Spotify Search

- (void)searchWithText:(NSString *)text {
    [self searchForTracksWithString:text];
}

- (void)clearSearchResults {
    [self retrieveAndLoadTracksForCategory:self.trackGroup];
}

- (void)searchForTracksWithString:(NSString *)searchString {
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Searched Songs"];
    [mixpanel.people increment:@"Searched Songs #" by:[NSNumber numberWithInt:1]];

    self.songs = nil;

    __weak YSSpotifySourceController *weakSelf = self;
    void (^callback)(NSArray *, NSError *) = ^(NSArray *songs, NSError *error) {
      if (songs) {
          weakSelf.songs = songs;
          if (songs.count == 0) {
              NSLog(@"No Songs Returned For Search Query");

              double delay = 0.2;
              dispatch_after(
                  dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)),
                  dispatch_get_main_queue(), ^{
                    [[YTNotifications sharedNotifications]
                        showNotificationText:@"No Songs. Try New Search."];
                  });
          }
      } else if (error) {
          if (![AFNetworkReachabilityManager sharedManager].reachable) {
              double delay = 0.1;
              dispatch_after(
                  dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)),
                  dispatch_get_main_queue(), ^{
                    [[YTNotifications sharedNotifications]
                        showNotificationText:@"No Internet Connection!"];
                  });
          } else {
              NSLog(@"Error Returning Songs %@", error);
              double delay = 0.1;
              dispatch_after(
                  dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)),
                  dispatch_get_main_queue(), ^{
                    [[YTNotifications sharedNotifications]
                        showNotificationText:
                            @"Oops, Something Went Wrong! Try Again."];
                  });

              [mixpanel track:@"Spotify Error - search (other)"];
          }
      }
    };

    [[SpotifyAPI sharedApi] retrieveTracksFromSpotifyForSearchString:searchString
                                                        withCallback:callback];
}

- (void)setPlayer:(STKAudioPlayer *)player {
    if (_player) {
        [_player stop];
    }
    _player = player;
}

- (YapBuilder *)getYapBuilder {
    YapBuilder *builder = [YapBuilder new];

    builder.messageType = MESSAGE_TYPE_SPOTIFY;
    builder.track =
        self.songs[((NSIndexPath *)
                        [self.collectionView indexPathsForSelectedItems]
                            .firstObject)
                       .row];

    NSLog(@"Seconds to fast forward: %@", builder.track.secondsToFastForward);

    return builder;
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
                 audioSourceController:self
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
    YSTrack *track = self.songs[((NSIndexPath *)[self.collectionView indexPathsForSelectedItems].firstObject).row];
    SpotifyTrackCollectionViewCell *trackViewCell = ((SpotifyTrackCollectionViewCell *)[self.collectionView
                                                                                    cellForItemAtIndexPath:((NSIndexPath *)[self.collectionView
                                                                                                                            indexPathsForSelectedItems].firstObject)]);

    if (state == STKAudioPlayerStateReady) {
        NSLog(@"state == STKAudioPlayerStateReady");
    }

    if (state == STKAudioPlayerStateRunning) {
        NSLog(@"state == STKAudioPlayerStateRunning");
    }

    if (state == STKAudioPlayerStatePlaying) {
        NSLog(@"state == STKAudioPlayerStatePlaying");

        if (!self.playerAlreadyStartedPlayingForThisSong) {
            if (track.secondsToFastForward.intValue > 0) {
                [audioPlayer seekToTime:track.secondsToFastForward.intValue];
            }
            // set self.playerAlreadyStartedPlayingForThisSong to True!
            self.playerAlreadyStartedPlayingForThisSong = YES;
        }

        if ([self.audioCaptureDelegate
                respondsToSelector:
                    @selector(audioSourceControllerDidStartAudioCapture:)]) {
            [self.audioCaptureDelegate
                audioSourceControllerDidStartAudioCapture:self];
        }
    }

    if (state == STKAudioPlayerStateStopped) {
        self.playerAlreadyStartedPlayingForThisSong = NO;
    }

    if (state == STKAudioPlayerStateError) {
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel track:@"Player State Error - Spotify"];
    }
    [self.songDataSource updateCell:trackViewCell withState:state];
}

#pragma mark - Implement public audio methods

- (void)playSongAtIndexPath:(NSIndexPath *)indexPath
        withOffsetStartTime:(NSUInteger)offset {
    [self.collectionView
        selectItemAtIndexPath:indexPath
                     animated:YES
               scrollPosition:UICollectionViewScrollPositionNone];
    YSTrack *selectedTrack = self.songs[indexPath.row];
    selectedTrack.secondsToFastForward =
        [NSNumber numberWithUnsignedInteger:offset];
    [self startAudioCapture];
}

- (NSString *)currentAudioDescription {
    if (self.collectionView.indexPathsForSelectedItems.count > 0) {
        YSTrack *song = self.songs[((NSIndexPath *)[self.collectionView indexPathsForSelectedItems].firstObject).row];
        return song.name;
    }
    return nil;
}

- (BOOL)startAudioCapture {
    if (![AFNetworkReachabilityManager sharedManager].reachable) {
        double delay = 0.1;
        dispatch_after(
            dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)),
            dispatch_get_main_queue(), ^{
              [[YTNotifications sharedNotifications]
                  showNotificationText:@"No Internet Connection!"];
            });
        return NO;
    } else if (self.songs.count == 0) {
        NSLog(@"Can't Play Because No Song");
        UIAlertView *alert = [[UIAlertView alloc]
                initWithTitle:@"Search Above"
                      message:@"Type a song, artist, or phrase above to find a "
                      @"song for your yap!"
                     delegate:nil
            cancelButtonTitle:@"OK"
            otherButtonTitles:nil];
        [alert show];
        return NO;
    } else {
        YSTrack *song = self.songs[((NSIndexPath *)[self.collectionView indexPathsForSelectedItems].firstObject).row];
        self.player = [STKAudioPlayer new];
        self.player.delegate = self;
        [[AVAudioSession sharedInstance]
            setCategory:AVAudioSessionCategoryPlayAndRecord
            withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker
                  error:nil];
        if ([song.previewURL isEqual:[NSNull null]]) {
            NSLog(@"URL is Null");
            UIAlertView *alert = [[UIAlertView alloc]
                    initWithTitle:@"Song Not Available"
                          message:
                              @"Unfortunately this song is not currently available."
                         delegate:nil
                cancelButtonTitle:@"OK"
                otherButtonTitles:nil];
            [alert show];
            return NO;
        } else {
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
                    audioSourceControllerWillStartAudioCapture:self];
            }

            NSDictionary *headers = [[SpotifyAPI sharedApi] getAuthorizationHeaders];
            NSLog(@"Playing URL: %@ %@ auth token", song.previewURL,
                  headers ? @"with" : @"without");
            if (headers) {
                [self.player play:song.previewURL withHeaders:headers];
            } else {
                [self.player play:song.previewURL];
            }
            Mixpanel *mixpanel = [Mixpanel sharedInstance];
            [mixpanel track:@"Played a Song"];
            [mixpanel.people increment:@"Played a Song #"
                                    by:[NSNumber numberWithInt:1]];
            return YES;
        }
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
                    audioSourceControllerdidCancelAudioCapture:self];
            }
        } else {
            if ([self.audioCaptureDelegate
                    respondsToSelector:
                        @selector(audioSourceControllerdidFinishAudioCapture:)]) {
                [self.audioCaptureDelegate
                    audioSourceControllerdidFinishAudioCapture:self];
            }
        }
    }
}

- (void)updatePlaybackProgress:(NSTimeInterval)playbackTime {
    SpotifyTrackCollectionViewCell *trackViewCell = ((SpotifyTrackCollectionViewCell *)[self.collectionView
                                                                                        cellForItemAtIndexPath:((NSIndexPath *)[self.collectionView
                                                                                                                                indexPathsForSelectedItems].firstObject)]);
    trackViewCell.countdownTimer = playbackTime;
}

@end
