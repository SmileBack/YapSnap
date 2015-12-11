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

@interface YSYapsCollectionViewDataSource()

@property STKAudioPlayerState audioState;

@end

@implementation YSYapsCollectionViewDataSource

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    YSYap *yap = self.yaps[indexPath.row];
    YSTrack *track = yap.track;
    SpotifyTrackCollectionViewCell *trackViewCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"track" forIndexPath:indexPath];
    SpotifyTrackView *trackView = trackViewCell.trackView;
    
    if (track.albumImageURL && ![track.albumImageURL isEqual:[NSNull null]]) {
        [trackView.imageView sd_setImageWithURL:[NSURL URLWithString:track.albumImageURL]];
    }
    
    trackView.songVersionOneButton.hidden = YES;
    trackView.songVersionTwoButton.hidden = YES;
    trackView.songNameLabel.text = track.name;
    [trackView.artistButton setTitle:[NSString stringWithFormat:@"by %@", track.artistName] forState:UIControlStateNormal];
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
