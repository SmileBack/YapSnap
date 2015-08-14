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
#import "Mixpanel/MPTweakInline.h"

@interface YSSpotifySourceController ()
@property (nonatomic, strong) NSArray *songs;
@property (strong, nonatomic) STKAudioPlayer *player;
@property (nonatomic) BOOL playerAlreadyStartedPlayingForThisSong;
@property (nonatomic, strong) NSMutableArray *tracks;

@property (strong, nonatomic) YTTrackGroup *trackGroupCategoryOne;
@property (strong, nonatomic) YTTrackGroup *trackGroupCategoryTwo;
@property (strong, nonatomic) YTTrackGroup *trackGroupCategoryThree;
@property (strong, nonatomic) YTTrackGroup *trackGroupCategoryFour;
@property (strong, nonatomic) YTTrackGroup *trackGroupPool;
 
@end

@implementation YSSpotifySourceController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Viewed Spotify Page"];
    [self setupNotifications];
    self.view.backgroundColor = THEME_BACKGROUND_COLOR;
    [self createTrackGroups];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.playerAlreadyStartedPlayingForThisSong = NO;
    if ([self shouldLoadSongsFromPool] && self.didPlaySongForFirstTime) {
        [self retrieveAndLoadTracksForCategory:self.trackGroupPool];
    }
}

- (void) setupNotifications {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserverForName:DISMISS_KEYBOARD_NOTIFICATION
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                        [self.view endEditing:YES];
                    }];
    
    [center addObserverForName:UIApplicationWillEnterForegroundNotification
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                        if ([self shouldLoadSongsFromPool] && self.didPlaySongForFirstTime) {
                            [self retrieveAndLoadTracksForCategory:self.trackGroupPool];
                        }
                    }];
    
    [center addObserverForName:UIApplicationDidEnterBackgroundNotification
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *note) {
                        [self.view endEditing:YES];
                        [self resetSuggestedSongsIfNeeded];
                    }];
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
    NSArray *shuffledSongs = [self shuffleTracks:[NSMutableArray arrayWithArray:self.songs]];
    
    if (trackGroup == self.trackGroupPool) {
        // Only take first five
        self.songs = @[shuffledSongs[0], shuffledSongs[1], shuffledSongs[2], shuffledSongs[3], shuffledSongs[4]];
    } else {
        self.songs = shuffledSongs;
    }
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
            if ([self internetIsNotReachable]) {
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

-(BOOL) internetIsNotReachable
{
    return ![AFNetworkReachabilityManager sharedManager].reachable;
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
    // RUDD TODO: GET TRACK THAT WAS TAPPED AND SET IN YAPBUILDER

    NSLog(@"Seconds to fast forward: %@", builder.track.secondsToFastForward);
    
    return builder;
}

#pragma mark - iCarousel Stuff
//- (NSInteger) numberOfItemsInCarousel:(iCarousel *)carousel
//{
//    return self.songs.count;
//}
//
//- (UIView *) carousel:(iCarousel *)carousel viewForItemAtIndex:(NSInteger)index reusingView:(UIView *)view
//{
//    YSTrack *track = self.songs[index];
//    SpotifyTrackView *trackView;
//
//    if (view && [view isKindOfClass:[SpotifyTrackView class]]) {
//        trackView = (SpotifyTrackView *) view;
//    } else {
//        // TRACKVIEW RUDD TODO: FIGURE OUT HEIGHT
//        CGFloat carouselHeight = 100;
//        CGRect frame = CGRectMake(0, 0, carouselHeight, carouselHeight);
//        trackView = [[SpotifyTrackView alloc] initWithFrame:frame];
//        
//        // ALBUM IMAGE
//        trackView.imageView = [[UIImageView alloc] initWithFrame:frame];
//        [trackView addSubview:trackView.imageView];
//        
//        // SONG NAME LABEL
//        trackView.songNameLabel = [[UILabel alloc]initWithFrame:
//                           CGRectMake(0, carouselHeight + 6, carouselHeight, 25)];
//        trackView.songNameLabel.textColor = THEME_SECONDARY_COLOR;
//        trackView.songNameLabel.backgroundColor = [UIColor clearColor];
//        trackView.songNameLabel.textAlignment = NSTextAlignmentCenter;
//        CGFloat size = IS_IPHONE_4_SIZE ? 14 : 18;
//        trackView.songNameLabel.font = [UIFont fontWithName:@"Futura-Medium" size:size];
//        [trackView addSubview:trackView.songNameLabel];
//        
//        // ALBUM BUTTON
//        trackView.albumImageButton = [UIButton buttonWithType:UIButtonTypeCustom];
//        trackView.albumImageButton.frame = CGRectMake(0, 0, carouselHeight, carouselHeight);
//        [trackView.albumImageButton setImage:nil forState:UIControlStateNormal];
//        [trackView addSubview:trackView.albumImageButton];
//        
//        // SPOTIFY BUTTON
//        trackView.spotifyButton = [UIButton buttonWithType:UIButtonTypeCustom];
//        trackView.spotifyButton.frame = CGRectMake(carouselHeight-40, 5, 35, 35);
//        [trackView.spotifyButton setImage:[UIImage imageNamed:@"SpotifyLogo.png"] forState:UIControlStateNormal];
//        [trackView addSubview:trackView.spotifyButton];
//        
//        // ARTIST BUTTON
//        trackView.artistButton = [UIButton buttonWithType:UIButtonTypeCustom];
//        [trackView.artistButton.titleLabel setFont:[UIFont fontWithName:@"Futura-Medium" size:14]];
//        trackView.artistButton.backgroundColor = THEME_DARK_BLUE_COLOR;
//        [trackView addSubview:trackView.artistButton];
//
//        // SONG VERSION ONE BUTTON
//        trackView.songVersionOneButton = [UIButton buttonWithType:UIButtonTypeCustom];
//        trackView.songVersionOneButton.frame = CGRectMake(5, carouselHeight -55, carouselHeight/2 - 6, 50);
//        [trackView.songVersionOneButton addTarget:self action:@selector(tappedSongVersionOneButton:) forControlEvents:UIControlEventTouchDown];
//        [trackView addSubview:trackView.songVersionOneButton];
//        
//            // Hack:
//        UITapGestureRecognizer *tapGestureButtonOne = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(shortTappedSongVersionOneButton)];
//        tapGestureButtonOne.numberOfTapsRequired = 1;
//        tapGestureButtonOne.numberOfTouchesRequired = 1;
//        [trackView.songVersionOneButton addGestureRecognizer:tapGestureButtonOne];
//
//        // SONG VERSION TWO BUTTON
//        trackView.songVersionTwoButton = [UIButton buttonWithType:UIButtonTypeCustom];
//        trackView.songVersionTwoButton.frame = CGRectMake(carouselHeight/2 + 1, carouselHeight -55, carouselHeight/2 - 6, 50);
//        [trackView.songVersionTwoButton addTarget:self action:@selector(tappedSongVersionTwoButton:) forControlEvents:UIControlEventTouchDown];
//        [trackView addSubview:trackView.songVersionTwoButton];
//        
//            // Hack:
//        UITapGestureRecognizer *tapGestureButtonTwo = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(shortTappedSongVersionTwoButton)];
//        tapGestureButtonTwo.numberOfTapsRequired = 1;
//        tapGestureButtonTwo.numberOfTouchesRequired = 1;
//        [trackView.songVersionTwoButton addGestureRecognizer:tapGestureButtonTwo];
//
//        // RIBBON IMAGE
//        trackView.ribbonImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 110, 110)];
//        trackView.ribbonImageView.image = [UIImage imageNamed:@"TrendingRibbon6.png"];
//        [trackView addSubview:trackView.ribbonImageView];
//        
//        // ALBUM BANNER LABEL
//        trackView.bannerLabel = [[UILabel alloc]initWithFrame:
//                                               CGRectMake(0, 0, carouselHeight, 42)];
//        /*
//        CALayer *bottomBorder = [CALayer layer];
//        bottomBorder.frame = CGRectMake(0.0f, 41.0f, trackView.bannerLabel.frame.size.width, 2.0f);
//        bottomBorder.backgroundColor = [THEME_SECONDARY_COLOR CGColor];
//        [trackView.bannerLabel.layer addSublayer:bottomBorder];
//         */
//        
//        trackView.bannerLabel.backgroundColor = THEME_RED_COLOR;
//        trackView.bannerLabel.textAlignment = NSTextAlignmentCenter;
//        trackView.bannerLabel.textColor = [UIColor whiteColor];
//        trackView.bannerLabel.font = [UIFont fontWithName:@"Futura-Medium" size:18];
//        trackView.bannerLabel.layer.borderWidth = 2;
//        trackView.bannerLabel.layer.borderColor = [UIColor whiteColor].CGColor;
//        
//        [trackView addSubview:trackView.bannerLabel];
//        
//        trackView.imageView.layer.borderWidth = 2;
//        trackView.imageView.layer.borderColor = [THEME_SECONDARY_COLOR CGColor];
//        [trackView.imageView setBackgroundColor:[UIColor colorWithWhite:1.0 alpha:0.05]];
//        
//        [trackView.spotifyButton addTarget:self action:@selector(confirmOpenInSpotify:) forControlEvents:UIControlEventTouchUpInside];
//    }
//    
//    // Set song version button selections
//    if (IS_IPHONE_4_SIZE) {
//        [trackView.songVersionOneButton setImage:[UIImage imageNamed:@"SongVersionOneSelectediPhone4.png"] forState:UIControlStateNormal];
//        [trackView.songVersionTwoButton setImage:[UIImage imageNamed:@"TwoNotSelectediPhone4.png"] forState:UIControlStateNormal];
//    } else if (IS_IPHONE_6_SIZE) {
//        [trackView.songVersionOneButton setImage:[UIImage imageNamed:@"SongVersionOneSelectediPhone6.png"] forState:UIControlStateNormal];
//        [trackView.songVersionTwoButton setImage:[UIImage imageNamed:@"TwoNotSelectediPhone6.png"] forState:UIControlStateNormal];
//    } else {
//        [trackView.songVersionOneButton setImage:[UIImage imageNamed:@"SongVersionOneSelected.png"] forState:UIControlStateNormal];
//        [trackView.songVersionTwoButton setImage:[UIImage imageNamed:@"TwoNotSelected.png"] forState:UIControlStateNormal];
//    }
//    
//    if (track.secondsToFastForward.intValue > 1) {
//        NSLog(@"Backend is giving us this info");
//    } else {
//        track.secondsToFastForward = [NSNumber numberWithInt:0];
//    }
//        
//    if (track.imageURL) {
//        [trackView.imageView sd_setImageWithURL:[NSURL URLWithString:track.imageURL]];
//    } else {
//        trackView.imageView.image = [UIImage imageNamed:@"AlbumImagePlaceholder.png"];
//    }
//    
//    if (track.isExplainerTrack) {
//        trackView.imageView.image = [UIImage imageNamed:@"ExplainerTrackImage3.png"];
//    }
//    
//    trackView.songNameLabel.text = track.name;
//    trackView.spotifySongID = track.spotifyID;
//    trackView.spotifyURL = track.spotifyURL;
//    [trackView.artistButton setTitle:[NSString stringWithFormat:@"by %@", track.artistName] forState:UIControlStateNormal];
//    [trackView.artistButton setTitleColor:THEME_SECONDARY_COLOR forState:UIControlStateNormal];
//    CGSize stringsize = [[NSString stringWithFormat:@"by %@", track.artistName] sizeWithAttributes:@{NSFontAttributeName: [UIFont fontWithName:@"Futura-Medium" size:14]}];
//    // RUDD TODO:
////    if ((stringsize.width + 20) > self.carouselHeightConstraint.constant) {
////        stringsize.width = self.carouselHeightConstraint.constant-24;
////    }
////    [trackView.artistButton setFrame:CGRectMake((self.carouselHeightConstraint.constant-stringsize.width-20)/2, self.carouselHeightConstraint.constant + 35, stringsize.width+20, stringsize.height + 8)];
////    
//    if (track.isExplainerTrack) {
//        trackView.spotifyButton.hidden = YES;
//        trackView.songVersionOneButton.hidden = YES;
//        trackView.songVersionTwoButton.hidden = YES;
//        trackView.albumImageButton.hidden = YES;
//        trackView.artistButton.hidden = YES;
//        trackView.songNameLabel.hidden = YES;
//        trackView.bannerLabel.hidden = YES;
//        trackView.ribbonImageView.hidden = YES;
//    } else {
//        trackView.spotifyButton.hidden = NO;
//        trackView.songVersionOneButton.hidden = NO;
//        trackView.songVersionTwoButton.hidden = NO;
//        trackView.albumImageButton.hidden = NO;
//        trackView.artistButton.hidden = NO;
//        trackView.songNameLabel.hidden = NO;
//        trackView.bannerLabel.hidden = NO;
//        trackView.ribbonImageView.hidden = YES;
//    }
//    
//    // For Onboarding:
//    if (!self.didPlaySongForFirstTime) {
//        trackView.bannerLabel.alpha = 1;
//    } else {
//        trackView.bannerLabel.alpha = 0;
//    }
//    
//    return trackView;
//}

- (void) tappedSongVersionOneButton:(UIButton *)button {
    NSLog(@"Tapped Song Version One Button");
    UIView *parent = button.superview;
    if ([parent isKindOfClass:[SpotifyTrackView class]]) {
        SpotifyTrackView *trackView = (SpotifyTrackView *)parent;
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
        
        YSTrack *selectedTrack = nil;
        for (YSTrack *track in self.songs) {
            if ([track.spotifyID isEqualToString:trackView.spotifySongID]) {
                selectedTrack = track;
                break;
            }
        }
        selectedTrack.secondsToFastForward = [NSNumber numberWithInt:0];
    }
    
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Tapped Song Version One"];
}

- (void) tappedSongVersionTwoButton:(UIButton *)button {
    NSLog(@"Tapped Song Version Two Button");
    UIView *parent = button.superview;
    if ([parent isKindOfClass:[SpotifyTrackView class]]) {
        SpotifyTrackView *trackView = (SpotifyTrackView *)parent;
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
        
        YSTrack *selectedTrack = nil;
        for (YSTrack *track in self.songs) {
            if ([track.spotifyID isEqualToString:trackView.spotifySongID]) {
                selectedTrack = track;
                NSLog(@"selected track: %@", selectedTrack);
                break;
            }
        }
        selectedTrack.secondsToFastForward = [NSNumber numberWithInt:17];
    }
        
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Tapped Song Version Two"];
}

- (void) confirmOpenInSpotify:(UIButton *)button
{
    UIView *parent = button.superview;
    if ([parent isKindOfClass:[SpotifyTrackView class]]) {
        SpotifyTrackView *trackView = (SpotifyTrackView *)parent;
        YSTrack *selectedTrack = nil;
        for (YSTrack *track in self.songs) {
            if ([track.spotifyID isEqualToString:trackView.spotifySongID]) {
                selectedTrack = track;
                break;
            }
        }
        OpenInSpotifyAlertView *alert = [[OpenInSpotifyAlertView alloc] initWithTrack:selectedTrack];
        [alert show];
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

#pragma mark - STKAudioPlayerDelegate

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
        
        // RUDD TODO: GET THE TRACK HERE
        YSTrack *track = nil;
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
        // RUDD TODO: GET TRACK VIEW
        SpotifyTrackView* trackView = nil;
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
    if ([self internetIsNotReachable]){
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
        // RUDD TODO: GET SONG
        YSTrack *song = nil;
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
