//
//  YSYapsCollectionViewDataSource.m
//  YapTap
//
//  Created by Rudd Taylor on 12/11/15.
//  Copyright © 2015 Appcoda. All rights reserved.
//

#import "YSYapsCollectionViewDataSource.h"
#import "TrackCollectionViewCell.h"
#import "YSYap.h"
#import "YSTrack.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <Giphy-iOS/AXCGiphy.h>

@interface YSYapsCollectionViewDataSource()

@property STKAudioPlayerState audioState;

@end

@implementation YSYapsCollectionViewDataSource

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    YSYap *yap = self.yaps[indexPath.row];
    YSTrack *track = yap.track;
    YapTrackCollectionViewCell *trackViewCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"track" forIndexPath:indexPath];
    YapTrackView *trackView = trackViewCell.trackView;
    if (yap.senderFacebookId) {
        trackView.senderProfilePicture.profileID = yap.senderFacebookId;
    }
    if (yap.yapGiphyID && ![yap.yapGiphyID isEqual:[NSNull null]]) {
        [AXCGiphy setGiphyAPIKey:kGiphyPublicAPIKey];
        [AXCGiphy gifForID:yap.yapGiphyID completion:^(AXCGiphy *result, NSError *error) {
            trackView.imageView.contentMode = UIViewContentModeScaleAspectFill;
            trackView.imageView.clipsToBounds = YES;
            [trackView.imageView sd_setImageWithURL:result.originalImage.url completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                trackView.isBlurred = NO;
            }];
        }];
    } else if (yap.yapPhotoURL && ![yap.yapPhotoURL isEqual:[NSNull null]]) {
        [trackView.imageView sd_setImageWithURL:[NSURL URLWithString:yap.yapPhotoURL] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            trackView.isBlurred = NO;
        }];
    } else if (track.albumImageURL && ![track.albumImageURL isEqual:[NSNull null]]) {
        [trackView.imageView sd_setImageWithURL:[NSURL URLWithString:track.albumImageURL] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0  * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ // Unclear why this is needed, but as isBlurred adds a subview to the trackView's imageView, without dispatch_after this will throw away the blur view when sd_imageWithUrl is cached
                trackView.isBlurred = YES;
            });
        }];
    }
    if (yap.playCount && ![yap.playCount isEqual:[NSNull null]]) {
        trackView.playCountLabel.text = [NSString stringWithFormat:@"Listens: %@", yap.playCount];
        trackView.playCountLabel.textColor = THEME_DARK_BLUE_COLOR;
    }
    trackView.yapTextLabel.text = yap.text;
    trackView.songVersionOneButton.hidden = YES;
    trackView.songVersionTwoButton.hidden = YES;
    trackView.songNameLabel.text = [NSString stringWithFormat:@"Made by %@", yap.senderName];
    trackView.artistAndSongLabel.text = [NSString stringWithFormat:@"%@ by %@", yap.songName, yap.artist];
    [trackView.albumImageButton addTarget:self action:@selector(didTapYap:) forControlEvents:UIControlEventTouchUpInside];
    [trackView.spotifyButton addTarget:self action:@selector(didTapSpotifyButton:) forControlEvents:UIControlEventTouchUpInside];
    trackView.tag = indexPath.row; // Used for tap actions
    
    trackView.spotifyButton.hidden = !(track.spotifyID && ![track.spotifyID isEqual:[NSNull null]] && [track.spotifyID length] > 10);
    
    if ([[collectionView indexPathsForSelectedItems].firstObject isEqual:indexPath]) {
        [trackViewCell updateWithState:self.audioState];
    }
    
    return trackViewCell;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.yaps.count;
}

#pragma mark - Actions

- (void)didTapYap:(id)sender {
    if ([self.delegate respondsToSelector:@selector(yapsCollectionDataSource:didTapYapAtIndexPath:)]) {
        [self.delegate yapsCollectionDataSource:self didTapYapAtIndexPath:[NSIndexPath indexPathForItem:[sender superview].tag inSection:0]];
    }
}

- (void)didTapSpotifyButton:(id)sender {
    if ([self.delegate respondsToSelector:@selector(yapsCollectionDataSource:didTapSpotifyAtIndexPath:)]) {
        [self.delegate yapsCollectionDataSource:self didTapSpotifyAtIndexPath:[NSIndexPath indexPathForItem:[sender superview].tag inSection:0]];
    }
}

#pragma mark - Methods

- (void)updateCell:(TrackCollectionViewCell *)cell withState:(STKAudioPlayerState)state {
    self.audioState = state;
    [cell updateWithState:state];
}

@end
