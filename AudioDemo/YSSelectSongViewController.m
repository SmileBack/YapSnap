//
//  YSSelectSongViewController.m
//  YapTap
//
//  Created by Jon Deokule on 8/26/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "YSSelectSongViewController.h"
#import "YSiTunesUpload.h"
#import "YSTrimSongViewController.h"
#import "UICollectionViewFlowLayout+YS.h"
#import "TrackCollectionViewCell.h"
#import "UploadCell.h"
#import "YSTrimSongViewController.h"
#import "API.h"
#import <UIImageView+WebCache.h>
#import "YSSpinnerView.h"
#import "YSSTKAudioPlayerDelegate.h"
#import "YSTrack.h"
#import "UploadedTracksCache.h"

@interface YSSelectSongViewController () <UICollectionViewDataSource, UICollectionViewDelegate, STKAudioPlayerDelegate>

@property UICollectionView *collectionView;
@property NSArray *tracks;
@property YSSTKAudioPlayerDelegate *audioPlayerDelegate;
@property STKAudioPlayer *player;
@property (strong, nonatomic) YSSpinnerView *spinnerView;
@property (strong, nonatomic) UIView *onboardingView;
@property (weak, nonatomic) UIButton *onboardingButton;
@property (strong, nonatomic) UILabel *onboardingLabel;
@property (strong, nonatomic) UIImageView *onboardingImageView;

@end

@implementation YSSelectSongViewController

@synthesize tracks = _tracks, audioCaptureDelegate;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:[UICollectionViewFlowLayout appLayout]];
    [self.view addSubview:self.collectionView];
    [self.collectionView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[v]|" options:0 metrics:nil views:@{ @"v" : self.collectionView }]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[top][v][bottom]|" options:0 metrics:nil views:@{ @"v" : self.collectionView,
                                                                                                                                     @"top" : self.topLayoutGuide,
                                                                                                                                     @"bottom" : self.bottomLayoutGuide }]];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    [self.collectionView registerClass:[UploadCell class]
            forCellWithReuseIdentifier:@"upload"];
    [self.collectionView registerClass:[TrackCollectionViewCell class]
            forCellWithReuseIdentifier:@"track"];
    self.collectionView.backgroundColor = [UIColor colorWithRed:239 / 255.0 green:239 / 255.0 blue:244 / 255.0 alpha:1.0];
    
    self.audioPlayerDelegate = [[YSSTKAudioPlayerDelegate alloc] init];
    self.audioPlayerDelegate.collectionView = self.collectionView;
    self.audioPlayerDelegate.audioSource = self;
    self.audioPlayerDelegate.audioCaptureDelegate = self.audioCaptureDelegate;
    
    [self setupOnboardingView];
    self.onboardingView.hidden = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //
    
    self.tracks = [UploadedTracksCache sharedCache].uploadedTracks;
    if (self.tracks.count < 1) {
        // Loading spinner
        [self.spinnerView removeFromSuperview];
        self.spinnerView = [[YSSpinnerView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        [self.view addSubview:self.spinnerView];
        self.spinnerView.center = self.view.center;
    }
    
    [self loadiTunesTracks];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.spinnerView removeFromSuperview];
}

- (void) setupOnboardingView {
    self.onboardingView =[[UIView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    self.onboardingView.backgroundColor = [UIColor colorWithRed:239 / 255.0 green:239 / 255.0 blue:244 / 255.0 alpha:1.0];
    [self.view addSubview:self.onboardingView];

    self.onboardingImageView =[[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    self.onboardingImageView.image=[UIImage imageNamed:@"AlbumImagePlaceholder2.png"];
    [self.onboardingView addSubview:self.onboardingImageView];
    
    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    UIVisualEffectView *effectView = [[UIVisualEffectView alloc]initWithEffect:blur];
    effectView.frame =  CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    [self.onboardingView addSubview:effectView];
    
    self.onboardingButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.onboardingButton addTarget:self
                              action:@selector(didTapOnboardingButton)
                    forControlEvents:UIControlEventTouchUpInside];
    [self.onboardingButton setTitle:@"Upload & Trim" forState:UIControlStateNormal];
    self.onboardingButton.frame = CGRectMake(15, self.view.frame.size.height-112-64-40-20, self.view.frame.size.width - 30, 112.0);
    self.onboardingButton.layer.cornerRadius = 8;
    self.onboardingButton.backgroundColor = THEME_RED_COLOR;
    self.onboardingButton.layer.borderColor = [UIColor whiteColor].CGColor;
    self.onboardingButton.layer.borderWidth = 1;
    [self.onboardingButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.onboardingButton.titleLabel setFont:[UIFont fontWithName:@"Futura-Medium" size:22]];
    [self.onboardingView addSubview:self.onboardingButton];
    
    self.onboardingLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 100, self.view.frame.size.width, 120)];
    self.onboardingLabel.text = @"Use music from your library";
    self.onboardingLabel.textColor = [UIColor whiteColor];
    self.onboardingLabel.textAlignment = NSTextAlignmentCenter;
    self.onboardingLabel.font = [UIFont fontWithName:@"Futura-Medium" size:40];
    self.onboardingLabel.numberOfLines = 2;
    self.onboardingLabel.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.onboardingLabel.layer.shadowOffset = CGSizeMake(1.0f, 1.0f);
    self.onboardingLabel.layer.shadowOpacity = 1.0f;
    self.onboardingLabel.layer.shadowRadius = 1.0f;
    [self.onboardingView addSubview:self.onboardingLabel];

}

- (void) loadiTunesTracks {
    __weak YSSelectSongViewController *weakSelf = self;
    [[UploadedTracksCache sharedCache] loadUploadedTracksWithCallback:^(NSArray *songs, NSError *error) {
        if (error) {
            // TODO: Display error callback
        } else {
            [self.spinnerView removeFromSuperview];
            weakSelf.tracks = songs;
            if (songs.count < 1) {
                self.onboardingView.hidden = NO;
                
            } else {
                self.onboardingView.hidden = YES;
            }
        }
    }];
}

#pragma mark - Actions

- (IBAction)didPressCancel:(UIBarButtonItem *)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)pickSongs:(id)sender {
    MPMediaPickerController *picker = [[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeAnyAudio];
    picker.delegate = self;
    picker.allowsPickingMultipleItems = NO;
    picker.showsCloudItems = NO;
    [self presentViewController:picker animated:YES completion:nil];
}

- (IBAction)didPressNext:(YSiTunesUpload *)sender {
    YSTrimSongViewController *vc = [[YSTrimSongViewController alloc] init];
    vc.iTunesUpload = sender;
    
    if (vc.iTunesUpload.trackURL) {
        //[self dismissViewControllerAnimated:YES completion:nil];
        [self.navigationController pushViewController:vc animated:NO];
    } else {
        NSLog(@"NO TRACK URL!!!");
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops, wrong file format"
                                                        message:@"Try another song!"
                                                       delegate:self
                                              cancelButtonTitle:@"Ok"
                                              otherButtonTitles:nil];
        [alert show];
    }
    
    //YSTrimSongViewController *vc = [[YSTrimSongViewController alloc] init];
    //vc.iTunesUpload = sender;
    //[self.navigationController pushViewController:vc animated:NO];
}

#pragma mark - UICollectionViewDelegate/DataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (self.tracks.count > 0) {
        return self.tracks.count + 1;
    } else {
        return 0;
    }
}

- (NSUInteger)trackRowForCollectionViewRow:(NSUInteger)row {
    return row - 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell;
    if (indexPath.row == 0) {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"upload" forIndexPath:indexPath];
    } else {
        TrackCollectionViewCell *trackCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"track" forIndexPath:indexPath];
        YSITunesTrack *track = self.tracks[[self trackRowForCollectionViewRow:indexPath.row]];
        if (track.songName) {
            trackCell.trackView.songNameLabel.text = track.songName;
        }
        
        if (track.awsAlbumImageUrl) {
            [trackCell.trackView.imageView sd_setImageWithURL:[NSURL URLWithString:track.awsAlbumImageUrl]];
        } else {
            trackCell.trackView.imageView.image = [UIImage imageNamed:@"AlbumImagePlaceholder2.png"];
        }
        
        [trackCell.trackView.artistButton setTitle:[NSString stringWithFormat:@"by %@", track.artistName] forState:UIControlStateNormal];
        [trackCell.trackView.albumImageButton addTarget:self action:@selector(didTapAlbumButton:) forControlEvents:UIControlEventTouchUpInside];
        trackCell.trackView.albumImageButton.tag = indexPath.row;
        
        if ([[collectionView indexPathsForSelectedItems].firstObject isEqual:indexPath]) {
            [self updateCell:trackCell withState:self.player.state];
        }
        
        cell = trackCell;
    }
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([[collectionView cellForItemAtIndexPath:indexPath].reuseIdentifier isEqualToString:@"upload"]) {
        [self pickSongs:nil];
        [collectionView deselectItemAtIndexPath:indexPath animated:NO];
        
        // Loading spinner
        [self.spinnerView removeFromSuperview];
        self.spinnerView = [[YSSpinnerView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        [self.view addSubview:self.spinnerView];
        self.spinnerView.center = self.view.center;
    }
}

- (void) didTapOnboardingButton {
    [self pickSongs:nil];
    // Loading spinner
    [self.spinnerView removeFromSuperview];
    self.spinnerView = [[YSSpinnerView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    [self.view addSubview:self.spinnerView];
    self.spinnerView.center = self.view.center;
}

#pragma mark - MediaPickerDelegate

- (void)mediaPicker:(MPMediaPickerController *)mediaPicker
  didPickMediaItems:(MPMediaItemCollection *)collection {
    if (collection.items.count != 1) {
        //TODO what to do if there isn't something selected?
        return;
    }
    
    // Loading spinner
    [self.spinnerView removeFromSuperview];
    self.spinnerView = [[YSSpinnerView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    self.spinnerView.center = mediaPicker.view.center;
    [mediaPicker.view addSubview:self.spinnerView];
    [mediaPicker.view layoutIfNeeded];
    
    MPMediaItem *item = collection.items[0];
    NSLog(@"Song name: %@", item.title);
    YSiTunesUpload *upload = [YSiTunesUpload new];
    upload.artistName = item.artist;
    upload.songName = item.title;
    upload.albumName = item.albumTitle;
    upload.genreName = item.genre;
    upload.persistentID = [NSNumber numberWithLongLong:item.persistentID];
    MPMediaItemArtwork *artwork = item.artwork;
    UIImage *image = [artwork imageWithSize:artwork.imageCropRect.size];
    upload.artworkImage = image;
    upload.trackURL = [item valueForProperty:MPMediaItemPropertyAssetURL];
    upload.trackDuration = item.playbackDuration;
    
    [self didPressNext:upload];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - YSAudioSource

- (NSString *)currentAudioDescription {
    if (self.collectionView.indexPathsForSelectedItems.count > 0) {
        YSITunesTrack *track = ((YSITunesTrack *)self.tracks[[self trackRowForCollectionViewRow:self.collectionView.indexPathsForSelectedItems.firstObject.row]]);
        return track.songName;
    } else {
        return nil;
    }
}

- (BOOL) startAudioCapture {
    self.player = [STKAudioPlayer new];
    self.player.delegate = self;
    self.audioPlayerDelegate.player = self.player;
    YSITunesTrack *track = ((YSITunesTrack *)self.tracks[[self trackRowForCollectionViewRow:self.collectionView.indexPathsForSelectedItems.firstObject.row]]);
    return [self.audioPlayerDelegate startAudioCaptureWithPreviewUrl:track.awsSongUrl withHeaders:nil];
}

- (void) stopAudioCapture {
    [self.audioPlayerDelegate stopAudioCapture];
}

- (void) cancelPlayingAudio {
    [self.audioPlayerDelegate cancelPlayingAudio];
}

- (void)clearSearchResults {}

- (void)searchWithText:(NSString *)text {}

- (void)updatePlaybackProgress:(NSTimeInterval)playbackTime {
    [self.audioPlayerDelegate updatePlaybackProgress:playbackTime];
}

// Spotify source will return the YSTrack.
// Mic source could return the audio file. for now will return nothing.
- (void)prepareYapBuilder {
    [self.audioCaptureDelegate audioSourceControllerIsReadyToProduceYapBuidler:self];
}

- (YapBuilder *) getYapBuilder {
    YSITunesTrack *iTunesTrack = ((YSITunesTrack *)self.tracks[[self trackRowForCollectionViewRow:self.collectionView.indexPathsForSelectedItems.firstObject.row]]);
    YapBuilder *yapBuilder = [[YapBuilder alloc] init];
    YSTrack *track = [YSTrack trackFromiTunesTrack:iTunesTrack];
    yapBuilder.track = track;
    yapBuilder.messageType = MESSAGE_TYPE_ITUNES;
    yapBuilder.duration = 15;//12;
    yapBuilder.awsVoiceEtag = iTunesTrack.awsSongEtag;
    yapBuilder.awsVoiceURL = iTunesTrack.awsSongUrl;
    return yapBuilder;
}

#pragma mark - Actions

- (void)didTapAlbumButton:(UIButton *)button {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:button.tag inSection:0];
    
    if ([indexPath isEqual:self.collectionView.indexPathsForSelectedItems.firstObject] && self.audioPlayerDelegate.player.state == STKAudioPlayerStatePlaying) {
        [self.audioPlayerDelegate.player pause];
    } else {
        [self.collectionView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionNone];
        [self startAudioCapture];
    }
}

- (void)playSongAtIndexPath:(NSIndexPath *)indexPath
        withOffsetStartTime:(NSUInteger)offset {
    [self.collectionView
     selectItemAtIndexPath:indexPath
     animated:YES
     scrollPosition:UICollectionViewScrollPositionNone];
    YSTrack *selectedTrack = self.tracks[indexPath.row];
    selectedTrack.secondsToFastForward =
    [NSNumber numberWithUnsignedInteger:offset];
    [self startAudioCapture];
}

- (void)updateCell:(TrackCollectionViewCell *)cell withState:(STKAudioPlayerState)state {
    if (state == STKAudioPlayerStateBuffering) {
        cell.state = TrackViewCellStateBuffering;
    } else if (state == STKAudioPlayerStatePaused) {
        cell.state = TrackViewCellStatePaused;
    } else if (state == STKAudioPlayerStateStopped) {
        cell.state = TrackViewCellStatePaused;
    } else  if (state == STKAudioPlayerStatePlaying) {
        cell.state = TrackViewCellStatePlaying;
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
    Mixpanel *mixpanel = [Mixpanel sharedInstance];
    [mixpanel track:@"Player Unexpected Error - Spotify"];
}

- (void)audioPlayer:(STKAudioPlayer *)audioPlayer
       stateChanged:(STKAudioPlayerState)state
      previousState:(STKAudioPlayerState)previousState {
    [self.audioPlayerDelegate audioPlayer:audioPlayer stateChanged:state previousState:previousState];
    TrackCollectionViewCell *trackViewCell = ((TrackCollectionViewCell *)[self.collectionView
                                                                          cellForItemAtIndexPath:((NSIndexPath *)[self.collectionView
                                                                                                                  indexPathsForSelectedItems].firstObject)]);
    
    [self updateCell:trackViewCell withState:state];
}


#pragma mark - Getters/Setters

- (void)setTracks:(NSArray *)tracks {
    _tracks = tracks;
    [self.collectionView reloadData];
}

- (NSArray *)tracks {
    return _tracks;
}

@end