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
#import "SpotifyTrackView.h"
#import "OpenInSpotifyAlertView.h"
#import <AVFoundation/AVAudioSession.h>
#import "AppDelegate.h"
#import "SpotifyTrackFactory.h"
#import "UIViewController+MJPopupViewController.h"
#import "SearchArtistAlertView.h"
#import "YTTrackGroup.h"
#import "YSSongCollectionViewDataSource.h"
#import "Mixpanel/MPTweakInline.h"

@interface YSSpotifySourceController ()<UICollectionViewDelegate, YSSongCollectionViewDelegate>
@property (nonatomic, strong) NSArray *songs;
@property (strong, nonatomic) STKAudioPlayer *player;
@property (nonatomic) BOOL playerAlreadyStartedPlayingForThisSong;
@property (nonatomic, strong) NSMutableArray *tracks;

@property (strong, nonatomic) YTTrackGroup *trackGroupCategoryOne;
@property (strong, nonatomic) YTTrackGroup *trackGroupCategoryTwo;
@property (strong, nonatomic) YTTrackGroup *trackGroupCategoryThree;
@property (strong, nonatomic) YTTrackGroup *trackGroupCategoryFour;
@property (strong, nonatomic) YTTrackGroup *trackGroupPool;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) YSSongCollectionViewDataSource* songDataSource;
 
@end

@implementation YSSpotifySourceController

- (void)setSongs:(NSArray *)songs {
    _songs = songs;
    self.songDataSource.songs = songs;
    [self.collectionView reloadData];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Viewed Spotify Page"];
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      if ([self shouldLoadSongsFromPool] && self.didPlaySongForFirstTime) {
                                                          [self retrieveAndLoadTracksForCategory:self.trackGroupPool];
                                                      }
                                                  }];
    self.view.backgroundColor = THEME_BACKGROUND_COLOR;
    self.songDataSource = [[YSSongCollectionViewDataSource alloc] init];
    self.songDataSource.delegate = self;
    self.collectionView.dataSource = self.songDataSource;
    self.collectionView.delegate = self;
    [self.collectionView registerClass:[SpotifyTrackCollectionViewCell class] forCellWithReuseIdentifier:@"track"];
    [self createTrackGroups];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.playerAlreadyStartedPlayingForThisSong = NO;
    // RUDD TODO:
//    if ([self shouldLoadSongsFromPool] && self.didPlaySongForFirstTime) {
        [self retrieveAndLoadTracksForCategory:self.trackGroupPool];
//    }
}

#pragma mark - YSSongCollectionViewDataSourceDelegate

- (void)songCollectionDataSource:(YSSongCollectionViewDataSource *)dataSource didTapSongAtIndexPath:(NSIndexPath *)indexPath {
    [self.collectionView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionNone];
    [self startAudioCapture];
}

- (void)songCollectionDataSource:(YSSongCollectionViewDataSource *)dataSource didTapArtistAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (void)songCollectionDataSource:(YSSongCollectionViewDataSource *)dataSource didTapSongOptionOneAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"Tapped Song Version One Button");
    SpotifyTrackView *trackView = ((SpotifyTrackCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath]).trackView;
    if (IS_IPHONE_4_SIZE) {
        [trackView.songVersionOneButton setImage:[UIImage imageNamed:@"SongVersionOneSelectediPhone4.png"] forState:UIControlStateNormal];
        [trackView.songVersionTwoButton setImage:[UIImage imageNamed:@"TwoNotSelectediPhone4.png"] forState:UIControlStateNormal];
    } else if (IS_IPHONE_6_SIZE) {
        [trackView.songVersionOneButton setImage:[UIImage imageNamed:@"SongVersionOneSelectediPhone6.png"] forState:UIControlStateNormal];
        [trackView.songVersionTwoButton setImage:[UIImage imageNamed:@"TwoNotSelectediPhone6.png"] forState:UIControlStateNormal];
    } else {
        [trackView.songVersionOneButton setImage:[UIImage imageNamed:@"SongVersionOneSelected.png"] forState:UIControlStateNormal];
        [trackView.songVersionTwoButton setImage:[UIImage imageNamed:@"TwoNotSelected.png"] forState:UIControlStateNormal];
    }
    
    YSTrack *selectedTrack = self.songs[indexPath.row];
    selectedTrack.secondsToFastForward = [NSNumber numberWithInt:0];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Tapped Song Version One"];
}

- (void)songCollectionDataSource:(YSSongCollectionViewDataSource *)dataSource didTapSongOptionTwoAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"Tapped Song Version Two Button");
    SpotifyTrackView *trackView = ((SpotifyTrackCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath]).trackView;
    if (IS_IPHONE_4_SIZE) {
        [trackView.songVersionOneButton setImage:[UIImage imageNamed:@"OneNotSelectediPhone4.png"] forState:UIControlStateNormal];
        [trackView.songVersionTwoButton setImage:[UIImage imageNamed:@"SongVersionTwoSelectediPhone4.png"] forState:UIControlStateNormal];
    } else if (IS_IPHONE_6_SIZE) {
        [trackView.songVersionOneButton setImage:[UIImage imageNamed:@"OneNotSelectediPhone6.png"] forState:UIControlStateNormal];
        [trackView.songVersionTwoButton setImage:[UIImage imageNamed:@"SongVersionTwoSelectediPhone6.png"] forState:UIControlStateNormal];
    } else {
        [trackView.songVersionOneButton setImage:[UIImage imageNamed:@"OneNotSelected.png"] forState:UIControlStateNormal];
        [trackView.songVersionTwoButton setImage:[UIImage imageNamed:@"SongVersionTwoSelected.png"] forState:UIControlStateNormal];
    }
    
    YSTrack *selectedTrack = self.songs[indexPath.row];
    selectedTrack.secondsToFastForward = [NSNumber numberWithInt:17];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Tapped Song Version Two"];
}

- (void)songCollectionDataSource:(YSSongCollectionViewDataSource *)dataSource didTapSpotifyAtIndexPath:(NSIndexPath *)indexPath {
    YSTrack *selectedTrack = self.songs[indexPath.row];
    OpenInSpotifyAlertView *alert = [[OpenInSpotifyAlertView alloc] initWithTrack:selectedTrack];
    [alert show];
}

#pragma mark - Track Category Stuff

- (void) createTrackGroups {
    self.trackGroupCategoryOne = [YTTrackGroup new];
    self.trackGroupCategoryOne.name = @"Popular"; //MPTweakValue(@"Category1", @"Popular");
    self.trackGroupCategoryOne.apiString = @"trending_tracks";
    
    self.trackGroupCategoryTwo = [YTTrackGroup new];
    self.trackGroupCategoryTwo.name = @"Funny"; //MPTweakValue(@"Category2", @"Funny");
    self.trackGroupCategoryTwo.apiString = @"funny_tracks";
    
    self.trackGroupCategoryThree = [YTTrackGroup new];
    self.trackGroupCategoryThree.name = @"Nostalgic"; //MPTweakValue(@"Category3", @"Nostalgic");
    self.trackGroupCategoryThree.apiString = @"nostalgic_tracks";
    
    self.trackGroupCategoryFour = [YTTrackGroup new];
    self.trackGroupCategoryFour.name = @"Flirtatious"; //MPTweakValue(@"Category4", @"Flirtatious");
    self.trackGroupCategoryFour.apiString = @"flirtatious_tracks";
    
    self.trackGroupPool = [YTTrackGroup new];
    self.trackGroupPool.name = @"Pool";
    self.trackGroupPool.apiString = @"pool_tracks";
}

- (void) retrieveAndLoadTracksForCategory:(YTTrackGroup *)trackGroup
{
    if (trackGroup.songs) {
        self.songs = trackGroup.songs;
        [self loadSongsForCategory:trackGroup];
    } else {
        [[API sharedAPI] retrieveTracksForCategory:trackGroup withCallback:^(NSArray *songs, NSError *error) {
            if (songs) {
                trackGroup.songs = songs;
                self.songs = trackGroup.songs;
                [self loadSongsForCategory:trackGroup];
            } else {
                NSLog(@"Something went wrong");
            }
        }];
    }
}

- (void) loadSongsForCategory:(YTTrackGroup *)trackGroup
{
    // Shuffle all
    self.songs = [self shuffleTracks:[NSMutableArray arrayWithArray:self.songs]];
}

- (NSMutableArray*) shuffleTracks:(NSMutableArray *)tracks {
    NSUInteger count = [tracks count];
    for (NSUInteger i = 0; i < count; ++i) {
        NSInteger remainingCount = count - i;
        NSInteger exchangeIndex = i + arc4random_uniform((u_int32_t )remainingCount);
        [tracks exchangeObjectAtIndex:i withObjectAtIndex:exchangeIndex];
    }
    
    return tracks;
}

-(BOOL) shouldLoadSongsFromPool {
    YSTrack *lastTrack = [self.songs lastObject];
    if (!self.songs || self.songs.count < 1 || lastTrack.isExplainerTrack) {
        return YES;
    } else {
        return NO;
    }
}

#pragma mark - Spotify Search

- (void) searchForTracksWithString:(NSString *)searchString
{
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Searched Songs"];
    [mixpanel.people increment:@"Searched Songs #" by:[NSNumber numberWithInt:1]];
    
    self.songs = nil;
    
    __weak YSSpotifySourceController *weakSelf = self;
    void (^callback)(NSArray*, NSError*) = ^(NSArray *songs, NSError *error) {
        if (songs) {
            weakSelf.songs = songs;
            if (songs.count == 0) {
                NSLog(@"No Songs Returned For Search Query");
                
                double delay = 0.2;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [[YTNotifications sharedNotifications] showNotificationText:@"No Songs. Try New Search."];
                });
            }
        } else if (error) {
            if (![AFNetworkReachabilityManager sharedManager].reachable) {
                double delay = 0.1;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [[YTNotifications sharedNotifications] showNotificationText:@"No Internet Connection!"];
                });
            } else {
                NSLog(@"Error Returning Songs %@", error);
                double delay = 0.1;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [[YTNotifications sharedNotifications] showNotificationText:@"Oops, Something Went Wrong! Try Again."];
                });
                
                [mixpanel track:@"Spotify Error - search (other)"];
            }
        }
    };

    [[SpotifyAPI sharedApi] retrieveTracksFromSpotifyForSearchString:searchString withCallback:callback];
}

- (void) setPlayer:(STKAudioPlayer *)player
{
    if (_player) {
        [_player stop];
    }
    _player = player;
}

- (YapBuilder *) getYapBuilder
{
    YapBuilder *builder = [YapBuilder new];
    
    builder.messageType = MESSAGE_TYPE_SPOTIFY;
    builder.track = self.songs[((NSIndexPath *)[self.collectionView indexPathsForSelectedItems].firstObject).row];

    NSLog(@"Seconds to fast forward: %@", builder.track.secondsToFastForward);
    
    return builder;
}

#pragma mark - STKAudioPlayerDelegate

-(void) audioPlayer:(STKAudioPlayer*)audioPlayer didStartPlayingQueueItemId:(NSObject*)queueItemId {}
-(void) audioPlayer:(STKAudioPlayer*)audioPlayer didFinishBufferingSourceWithQueueItemId:(NSObject*)queueItemId {}
-(void) audioPlayer:(STKAudioPlayer*)audioPlayer didFinishPlayingQueueItemId:(NSObject*)queueItemId withReason:(STKAudioPlayerStopReason)stopReason andProgress:(double)progress andDuration:(double)duration {}


-(void) audioPlayer:(STKAudioPlayer*)audioPlayer unexpectedError:(STKAudioPlayerErrorCode)errorCode
{
    NSLog(@"audioPlayer unexpected error: %u", errorCode);
    [audioPlayer stop];
    if ([self.audioCaptureDelegate respondsToSelector:@selector(audioSourceController:didReceieveUnexpectedError:)]) {
        [self.audioCaptureDelegate audioSourceController:self didReceieveUnexpectedError:[NSError errorWithDomain:@"YSSpotifySourceController" code:errorCode userInfo:nil]];
    }
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Player Unexpected Error - Spotify"];
}

-(void) audioPlayer:(STKAudioPlayer*)audioPlayer stateChanged:(STKAudioPlayerState)state previousState:(STKAudioPlayerState)previousState
{
    if (state == STKAudioPlayerStateReady) {
        NSLog(@"state == STKAudioPlayerStateReady");
    }
    
    if (state == STKAudioPlayerStateRunning) {
        NSLog(@"state == STKAudioPlayerStateRunning");
    }
    
    if (state == STKAudioPlayerStatePlaying) {
        NSLog(@"state == STKAudioPlayerStatePlaying");
        
        YSTrack *track = self.songs[((NSIndexPath *)[self.collectionView indexPathsForSelectedItems].firstObject).row];
        if (!self.playerAlreadyStartedPlayingForThisSong) {
            if (track.secondsToFastForward.intValue > 0) {
                [audioPlayer seekToTime:track.secondsToFastForward.intValue];
            }
            // set self.playerAlreadyStartedPlayingForThisSong to True!
            self.playerAlreadyStartedPlayingForThisSong = YES;
            NSLog(@"Set playerAlreadyStartedPlayingForThisSong to TRUE");
        }
        
        if ([self.audioCaptureDelegate respondsToSelector:@selector(audioSourceControllerDidStartAudioCapture:)]) {
            [self.audioCaptureDelegate audioSourceControllerDidStartAudioCapture:self];
        }
        // Show Song Clip buttons when user is playing a song
        SpotifyTrackView* trackView = ((SpotifyTrackCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:((NSIndexPath *)[self.collectionView indexPathsForSelectedItems].firstObject)]).trackView;
        trackView.songVersionOneButton.hidden = NO;
        trackView.songVersionTwoButton.hidden = NO;
        trackView.songVersionBackground.hidden = NO;
        track.songVersionButtonsAreShowing = YES;
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:DID_PLAY_SONG_FOR_FIRST_TIME_KEY];
    }
    
    if (state == STKAudioPlayerStateBuffering) {
        NSLog(@"state == STKAudioPlayerStateBuffering");
        if (self.playerAlreadyStartedPlayingForThisSong) {
            NSLog(@"Buffering for second time!");
            [[YTNotifications sharedNotifications] showBufferingText:@"Buffering (keep holding)"];
            Mixpanel *mixpanel = [Mixpanel sharedInstance];
            [mixpanel track:@"Buffering notification - Spotify"];
        }
    }
    
    if (state == STKAudioPlayerStatePaused) {
        NSLog(@"state == STKAudioPlayerStatePaused");
    }
    
    if (state == STKAudioPlayerStateStopped) {
        NSLog(@"state == STKAudioPlayerStateStopped");
        self.playerAlreadyStartedPlayingForThisSong = NO;
    }
    
    if (state == STKAudioPlayerStateError) {
        NSLog(@"state == STKAudioPlayerStateError");
        Mixpanel *mixpanel = [Mixpanel sharedInstance];
        [mixpanel track:@"Player State Error - Spotify"];
    }
    
    if (state == STKAudioPlayerStateDisposed) {
        NSLog(@"state == STKAudioPlayerStateDisposed");
    }
}

#pragma mark - Implement public audio methods
- (BOOL) startAudioCapture
{
    if (![AFNetworkReachabilityManager sharedManager].reachable){
        double delay = 0.1;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[YTNotifications sharedNotifications] showNotificationText:@"No Internet Connection!"];
        });
        return NO;
    } else if (self.songs.count == 0) {
        NSLog(@"Can't Play Because No Song");
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Search Above"
                                                        message:@"Type a song, artist, or phrase above to find a song for your yap!"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        return NO;
    } else {
        YSTrack *song = self.songs[((NSIndexPath *)[self.collectionView indexPathsForSelectedItems].firstObject).row];
        self.player = [STKAudioPlayer new];
        self.player.delegate = self;
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:nil];
        if ([song.previewURL isEqual: [NSNull null]]) {
            NSLog(@"URL is Null");
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Song Not Available"
                                                            message:@"Unfortunately this song is not currently available."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            return NO;
        } else {
            float volume = [[AVAudioSession sharedInstance] outputVolume];
            if (volume <= 0.125) {
                double delay = 0.1;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [[YTNotifications sharedNotifications] showBlueNotificationText:@"Turn Up The Volume!"];
                    Mixpanel *mixpanel = [Mixpanel sharedInstance];
                    [mixpanel track:@"Volume Notification - Spotify"];
                });
            }
            if ([self.audioCaptureDelegate respondsToSelector:@selector(audioSourceControllerWillStartAudioCapture:)]) {
                [self.audioCaptureDelegate audioSourceControllerWillStartAudioCapture:self];
            }
            
            NSDictionary *headers = [[SpotifyAPI sharedApi] getAuthorizationHeaders];
            NSLog(@"Playing URL: %@ %@ auth token", song.previewURL, headers ? @"with" : @"without");
            if (headers) {
                [self.player play:song.previewURL withHeaders:headers];
            } else {
                [self.player play:song.previewURL];
            }
            Mixpanel *mixpanel = [Mixpanel sharedInstance];
            [mixpanel track:@"Played a Song"];
            [mixpanel.people increment:@"Played a Song #" by:[NSNumber numberWithInt:1]];
            return YES;
        }
    }
}

- (void) stopAudioCapture
{
    if ((self.player.state & STKAudioPlayerStateRunning) != 0) {
        [self.player stop];
        if ([self.audioCaptureDelegate respondsToSelector:@selector(audioSourceControllerdidFinishAudioCapture:)]) {
            [self.audioCaptureDelegate audioSourceControllerdidFinishAudioCapture:self];
        }
    }
}

#pragma mark - Setting NSDefaults

- (BOOL) didPlaySongForFirstTime
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:DID_PLAY_SONG_FOR_FIRST_TIME_KEY];
}

- (BOOL) tappedArtistButtonForFirstTime
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:DID_TAP_ARTIST_BUTTON_FOR_FIRST_TIME_KEY];
}

/*
 - (void) retrieveTracksForCategory:(NSString *)playlistName
 {
 Mixpanel *mixpanel = [Mixpanel sharedInstance];
 [mixpanel track:@"Searched Songs"];
 [mixpanel.people increment:@"Searched Songs #" by:[NSNumber numberWithInt:1]];
 
 self.songs = nil;
 [self.carousel reloadData];
 self.carousel.alpha = 1;
 self.loadingIndicator.alpha = 1;
 [self.loadingIndicator startAnimating];
 
 __weak YSSpotifySourceController *weakSelf = self;
 void (^callback)(NSArray*, NSError*) = ^(NSArray *songs, NSError *error) {
 //NSLog(@"Songs: %@", songs);
 if (songs) {
 weakSelf.songs = songs;
 weakSelf.carousel.currentItemIndex = 0;
 [weakSelf.carousel reloadData];
 
 if (songs.count == 0) {
 [self.loadingIndicator stopAnimating];
 
 NSLog(@"No Songs Returned For Search Query");
 
 double delay = 0.2;
 dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
 [[YTNotifications sharedNotifications] showNotificationText:@"No Songs. Try New Search."];
 });
 } else {
 NSLog(@"Returned Songs Successfully");
 [self.loadingIndicator stopAnimating];
 }
 } else if (error) {
 [self.loadingIndicator stopAnimating];
 
 if ([self internetIsNotReachable]) {
 double delay = 0.1;
 dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
 [[YTNotifications sharedNotifications] showNotificationText:@"No Internet Connection!"];
 });
 } else {
 NSLog(@"Error Returning Songs %@", error);
 [mixpanel track:@"Spotify Error - search (other)"];
 }
 }
 };
 
 [[SpotifyAPI sharedApi] retrieveTracksFromSpotifyForPlaylist:playlistName withCallback:callback];
 }
 */


@end
