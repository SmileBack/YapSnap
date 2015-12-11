//
//  YSPublicSourceController.m
//  YapTap
//
//  Created by Rudd Taylor on 12/11/15.
//  Copyright © 2015 Appcoda. All rights reserved.
//

#import "YSPublicSourceController.h"
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
#import "YSYapsCollectionViewDataSource.h"
#import "Mixpanel/MPTweakInline.h"
#import "NSArray+Shuffle.h"
#import "UICollectionViewFlowLayout+YS.h"
#import "YSSTKAudioPlayerDelegate.h"
#import "TracksCache.h"

#define RELOAD_COLLECTION_VIEW @"com.yapsnap.ReloadCollectionViewNotification"


@interface YSPublicSourceController () <UICollectionViewDelegate, YSYapsCollectionViewDelegate>
@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) YSYapsCollectionViewDataSource *yapsDataSource;
@property (strong, nonatomic) YSSTKAudioPlayerDelegate *audioPlayerDelegate;
@property (strong, nonatomic) STKAudioPlayer *player;
@property (nonatomic) BOOL loadingSearchResults;

@end

@implementation YSPublicSourceController

- (void)viewDidLoad {
    [super viewDidLoad];
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Viewed Public Page"];
    
    self.yapsDataSource = [[YSYapsCollectionViewDataSource alloc] init];
    self.yapsDataSource.delegate = self;
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:[UICollectionViewFlowLayout screenWidthLayout]];
    self.collectionView.dataSource = self.yapsDataSource;
    self.collectionView.delegate = self;
    [self.collectionView registerClass:[SpotifyTrackCollectionViewCell class] forCellWithReuseIdentifier:@"track"];
    self.collectionView.backgroundColor = [UIColor colorWithRed:239/255.0 green:239/255.0 blue:244/255.0 alpha:1.0];
    self.view.backgroundColor = THEME_BACKGROUND_COLOR;
    
    self.audioPlayerDelegate = [[YSSTKAudioPlayerDelegate alloc] init];
    self.audioPlayerDelegate.collectionView = self.collectionView;
    self.audioPlayerDelegate.audioSource = self;
    self.audioPlayerDelegate.audioCaptureDelegate = self.audioCaptureDelegate;
    
    // Constraints
    [self.collectionView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:self.collectionView];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[v]|" options:0 metrics:nil views:@{@"v": self.collectionView}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[top][v][bottom]" options:0 metrics:nil views:@{@"v": self.collectionView, @"top": self.topLayoutGuide, @"bottom": self.bottomLayoutGuide}]];
}

- (void)viewWillAppear:(BOOL)animated {
    [[API sharedAPI] getPublicYapsWithCallback:^(NSArray *yaps, NSError *error) {
        if (error) {
            NSLog(error.description);
        } else {
            self.yaps = yaps;
        }
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.audioPlayerDelegate.player.state == STKAudioPlayerStatePlaying) {
        [self cancelPlayingAudio];
    }
    self.loadingSearchResults = NO;
}

- (void)viewDidDisappear:(BOOL)animated {
    for (NSIndexPath *indexPath in self.collectionView.indexPathsForSelectedItems) {
        [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
    }
}

#pragma mark - Setters/Getters

- (void)setYaps:(NSArray *)yaps {
    _yaps = yaps;
    self.yapsDataSource.yaps = yaps;
    [self.collectionView reloadData];
}

#pragma mark - YSYapsCollectionViewDataSourceDelegate

- (void)yapsCollectionDataSource:(YSYapsCollectionViewDataSource *)dataSource didTapYapAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath isEqual:self.collectionView.indexPathsForSelectedItems.firstObject]) {
        if (self.audioPlayerDelegate.player.state == STKAudioPlayerStatePlaying) {
            [self.audioPlayerDelegate.player pause];
        } else {
            [self startAudioCapture];
        }
    } else {
        [self playSongAtIndexPath:indexPath withOffsetStartTime:0];
    }
}

- (void)yapsCollectionDataSource:(YSYapsCollectionViewDataSource *)dataSource didTapSpotifyAtIndexPath:(NSIndexPath *)indexPath {
    YSYap *selectedYap = self.yaps[indexPath.row];
    if (selectedYap.track) {
        OpenInSpotifyAlertView *alert = [[OpenInSpotifyAlertView alloc] initWithTrack:selectedYap.track];
        [alert show];
    }
}

#pragma mark - STKAudioPlayerDelegate

- (void)audioPlayer:(STKAudioPlayer *)audioPlayer
didStartPlayingQueueItemId:(NSObject *)queueItemId {
    [self.audioPlayerDelegate audioPlayer:audioPlayer didStartPlayingQueueItemId:queueItemId];
}

- (void)audioPlayer:(STKAudioPlayer *)audioPlayer
didFinishBufferingSourceWithQueueItemId:(NSObject *)queueItemId {
    [self.audioPlayerDelegate audioPlayer:audioPlayer didFinishBufferingSourceWithQueueItemId:queueItemId];
}

- (void)audioPlayer:(STKAudioPlayer *)audioPlayer
didFinishPlayingQueueItemId:(NSObject *)queueItemId
         withReason:(STKAudioPlayerStopReason)stopReason
        andProgress:(double)progress
        andDuration:(double)duration {
    [self.audioPlayerDelegate audioPlayer:audioPlayer didFinishPlayingQueueItemId:queueItemId withReason:stopReason andProgress:progress andDuration:duration];
}

- (void)audioPlayer:(STKAudioPlayer *)audioPlayer
    unexpectedError:(STKAudioPlayerErrorCode)errorCode {
    [self.audioPlayerDelegate audioPlayer:audioPlayer unexpectedError:errorCode];
}

- (void)audioPlayer:(STKAudioPlayer *)audioPlayer
       stateChanged:(STKAudioPlayerState)state
      previousState:(STKAudioPlayerState)previousState {
    [self.audioPlayerDelegate audioPlayer:audioPlayer stateChanged:state previousState:previousState];
    TrackCollectionViewCell *trackViewCell = ((TrackCollectionViewCell *)[self.collectionView
                                                                          cellForItemAtIndexPath:((NSIndexPath *)[self.collectionView
                                                                                                                  indexPathsForSelectedItems].firstObject)]);
    
    [self.yapsDataSource updateCell:trackViewCell withState:state];
}

#pragma mark - Implement public audio methods

- (void)playSongAtIndexPath:(NSIndexPath *)indexPath withOffsetStartTime:(NSUInteger)offset {
    [self.collectionView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionNone];
    [self startAudioCapture];
}

- (NSString *)currentAudioDescription {
    if (self.collectionView.indexPathsForSelectedItems.count > 0) {
        YSYap *yap = self.yaps[((NSIndexPath *)[self.collectionView indexPathsForSelectedItems].firstObject).row];
        if (yap.track) {
            return yap.track.name;
        } else {
            return yap.senderName;
        }
    }
    return nil;
}

- (BOOL)startAudioCapture {
    YSYap *yap = self.yaps[((NSIndexPath *)[self.collectionView indexPathsForSelectedItems].firstObject).row];
    if (yap.track) {
        NSDictionary *headers = [[SpotifyAPI sharedApi] getAuthorizationHeaders];
        if ([yap.track.previewURL isEqual:[NSNull null]]) {
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
            self.player = [STKAudioPlayer new];
            self.player.delegate = self;
            self.audioPlayerDelegate.player = self.player;
            return [self.audioPlayerDelegate startAudioCaptureWithPreviewUrl:yap.track.previewURL withHeaders: yap.track.isFromSpotify ? headers : nil];
        }
    }
    return NO;
}

- (void)cancelPlayingAudio {
    [self.audioPlayerDelegate cancelPlayingAudio];
}

- (void)stopAudioCapture {
    [self.audioPlayerDelegate stopAudioCapture];
}

- (void)stopAudioCaptureFromCancel:(BOOL)fromCancel {
    [self.audioPlayerDelegate stopAudioCaptureFromCancel:fromCancel];
}

- (void)updatePlaybackProgress:(NSTimeInterval)playbackTime {
    [self.audioPlayerDelegate updatePlaybackProgress:playbackTime];
}

- (YapBuilder *)getYapBuilder {
    YSYap *yap = self.yaps[((NSIndexPath *)[self.collectionView indexPathsForSelectedItems].firstObject).row];
    YapBuilder *builder = [[YapBuilder alloc] initWithYap:yap sendingAction:YTYapSendingActionForward];
    return builder;
}

@end
