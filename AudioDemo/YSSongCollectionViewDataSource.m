//
//  YSSongCollectionViewDataSource.m
//  YapTap
//
//  Created by Dan B on 8/14/15.
//  Copyright (c) 2015 Appcoda. All rights reserved.
//

#import "YSSongCollectionViewDataSource.h"
#import "YSTrack.h"
#import "TrackCollectionViewCell.h"
#import <UIImageView+WebCache.h>

@interface YSSongCollectionViewDataSource()

@property STKAudioPlayerState audioState;

@end

@implementation YSSongCollectionViewDataSource

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    YSTrack *track = self.songs[indexPath.row];
    SpotifyTrackCollectionViewCell *trackViewCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"track" forIndexPath:indexPath];
    SpotifyTrackView *trackView = trackViewCell.trackView;
    // Set song version button selections
    
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
    
    
    if (track.secondsToFastForward.intValue > 1) {
        NSLog(@"Backend is giving us this info");
    } else {
        track.secondsToFastForward = [NSNumber numberWithInt:0];
    }
    
    if (track.imageURL && ![track.imageURL isEqual:[NSNull null]]) {
        [trackView.imageView sd_setImageWithURL:[NSURL URLWithString:track.imageURL]];
    } else {
        trackView.imageView.image = [UIImage imageNamed:@"AlbumImagePlaceholder.png"];
    }
    
    trackView.songNameLabel.text = track.name;
    [trackView.artistButton setTitle:[NSString stringWithFormat:@"by %@", track.artistName] forState:UIControlStateNormal];
    [trackView.artistButton addTarget:self action:@selector(didTapArtistButton:) forControlEvents:UIControlEventTouchUpInside];
    [trackView.albumImageButton addTarget:self action:@selector(didTapAlbumButton:) forControlEvents:UIControlEventTouchUpInside];
    
    [trackView.songVersionOneButton addTarget:self action:@selector(didTapSongVersionOneButton:) forControlEvents:UIControlEventTouchDown];
    [trackView.songVersionTwoButton addTarget:self action:@selector(didTapSongVersionTwoButton:) forControlEvents:UIControlEventTouchDown];
    [trackView.spotifyButton addTarget:self action:@selector(didTapSpotifyButton:) forControlEvents:UIControlEventTouchUpInside];
    trackView.tag = indexPath.row; // Used for tap actions
    
    // IF A SPOTIFY TRACK
    if ([track.previewURL containsString:@"scdn"]) {
        trackView.spotifyButton.hidden = NO;
        trackView.songVersionOneButton.hidden = NO;
        trackView.songVersionTwoButton.hidden = NO;
    } else {
        trackView.spotifyButton.hidden = YES;
        trackView.songVersionOneButton.hidden = YES;
        trackView.songVersionTwoButton.hidden = YES;
    }
    
    
    if ([[collectionView indexPathsForSelectedItems].firstObject isEqual:indexPath]) {
        [self updateCell:trackViewCell withState:self.audioState];
    }
    
    return trackViewCell;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.songs.count;
}

#pragma mark - Actions

- (void)didTapArtistButton:(id)sender {
    if ([self.delegate respondsToSelector:@selector(songCollectionDataSource:didTapArtistAtIndexPath:)]) {
        [self.delegate songCollectionDataSource:self didTapArtistAtIndexPath:[NSIndexPath indexPathForItem:[sender superview].tag inSection:0]];
    }
}

- (void)didTapAlbumButton:(id)sender {
    if ([self.delegate respondsToSelector:@selector(songCollectionDataSource:didTapSongAtIndexPath:)]) {
        [self.delegate songCollectionDataSource:self didTapSongAtIndexPath:[NSIndexPath indexPathForItem:[sender superview].tag inSection:0]];
    }
}

- (void)didTapSongVersionOneButton:(id)sender {
    if ([self.delegate respondsToSelector:@selector(songCollectionDataSource:didTapSongOptionOneAtIndexPath:)]) {
        [self.delegate songCollectionDataSource:self didTapSongOptionOneAtIndexPath:[NSIndexPath indexPathForItem:[sender superview].tag inSection:0]];
    }
}

- (void)didTapSongVersionTwoButton:(id)sender {
    if ([self.delegate respondsToSelector:@selector(songCollectionDataSource:didTapSongOptionTwoAtIndexPath:)]) {
        [self.delegate songCollectionDataSource:self didTapSongOptionTwoAtIndexPath:[NSIndexPath indexPathForItem:[sender superview].tag inSection:0]];
    }
}

- (void)didTapSpotifyButton:(id)sender {
    if ([self.delegate respondsToSelector:@selector(songCollectionDataSource:didTapSpotifyAtIndexPath:)]) {
        [self.delegate songCollectionDataSource:self didTapSpotifyAtIndexPath:[NSIndexPath indexPathForItem:[sender superview].tag inSection:0]];
    }
}

#pragma mark - Methods

- (void)updateCell:(TrackCollectionViewCell *)cell withState:(STKAudioPlayerState)state {
    self.audioState = state;
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

@end
