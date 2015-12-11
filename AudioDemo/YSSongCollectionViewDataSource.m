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
@property (nonatomic, strong) UIImage *songVersionOneButtonImage;
@property (nonatomic, strong) UIImage *songVersionTwoButtonImage;
@property (nonatomic, strong) UIImage *albumPlaceholderImage;

@end

@implementation YSSongCollectionViewDataSource

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    YSTrack *track = self.songs[indexPath.row];
    SpotifyTrackCollectionViewCell *trackViewCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"track" forIndexPath:indexPath];
    SpotifyTrackView *trackView = trackViewCell.trackView;
    
    [trackView.songVersionOneButton setImage:self.songVersionOneButtonImage forState:UIControlStateNormal];
    [trackView.songVersionTwoButton setImage:self.songVersionTwoButtonImage forState:UIControlStateNormal];
    
    if (track.secondsToFastForward.intValue > 1) {
        NSLog(@"Backend is giving us this info");
    } else {
        track.secondsToFastForward = [NSNumber numberWithInt:0];
    }
    
    if (track.albumImageURL && ![track.albumImageURL isEqual:[NSNull null]]) {
        [trackView.imageView sd_setImageWithURL:[NSURL URLWithString:track.albumImageURL]];
    } else {
        trackView.imageView.image = self.albumPlaceholderImage;
    }
   
    trackView.songNameLabel.text = track.name;
    [trackView.artistButton setTitle:[NSString stringWithFormat:@"by %@", track.artistName] forState:UIControlStateNormal];
    [trackView.artistButton addTarget:self action:@selector(didTapArtistButton:) forControlEvents:UIControlEventTouchUpInside];
    [trackView.albumImageButton addTarget:self action:@selector(didTapAlbumButton:) forControlEvents:UIControlEventTouchUpInside];
    
    [trackView.songVersionOneButton addTarget:self action:@selector(didTapSongVersionOneButton:) forControlEvents:UIControlEventTouchDown];
    [trackView.songVersionTwoButton addTarget:self action:@selector(didTapSongVersionTwoButton:) forControlEvents:UIControlEventTouchDown];
    [trackView.spotifyButton addTarget:self action:@selector(didTapSpotifyButton:) forControlEvents:UIControlEventTouchUpInside];
    trackView.tag = indexPath.row; // Used for tap actions
    
    trackView.spotifyButton.hidden = !(track.spotifyID && ![track.spotifyID isEqual:[NSNull null]] && [track.spotifyID length] > 10);
    trackView.songVersionOneButton.hidden = !track.isFromSpotify;
    trackView.songVersionTwoButton.hidden = !track.isFromSpotify;
    
    
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
    [cell updateWithState:state];
}

#pragma mark - Image Getters
- (UIImage *) songVersionOneButtonImage
{
    if (!_songVersionOneButtonImage) {
        if (IS_IPHONE_4_SIZE) {
            _songVersionOneButtonImage = [UIImage imageNamed:@"SongVersionOneSelectediPhone4.png"];
        } else if (IS_IPHONE_6_SIZE) {
            _songVersionOneButtonImage = [UIImage imageNamed:@"SongVersionOneSelectediPhone6.png"];
        } else {
            _songVersionOneButtonImage = [UIImage imageNamed:@"SongVersionOneSelected.png"];
        }
    }
    
    return _songVersionOneButtonImage;
}

- (UIImage *) songVersionTwoButtonImage
{
    if (!_songVersionTwoButtonImage) {
        
        if (IS_IPHONE_4_SIZE) {
            _songVersionTwoButtonImage = [UIImage imageNamed:@"TwoNotSelectediPhone4.png"];
        } else if (IS_IPHONE_6_SIZE) {
            _songVersionTwoButtonImage = [UIImage imageNamed:@"TwoNotSelectediPhone6.png"];
        } else {
            _songVersionTwoButtonImage = [UIImage imageNamed:@"TwoNotSelected.png"];
        }
    }
    return _songVersionTwoButtonImage;
}

- (UIImage *) albumPlaceholderImage
{
    if (!_albumPlaceholderImage) {
            _albumPlaceholderImage = [UIImage imageNamed:@"AlbumImagePlaceholder2.png"];
    }
    
    return _albumPlaceholderImage;
}

@end
